@IsTest
public class ProductVariationBatchTest {

    private static final String PARENT_SKU = 'MAT1';
    private static final String CHILD_SKU = 'MAT1-KAR';
    private static final String WEBSTORE_ID = 'WS_TEST';
    private static final String ATTR_SET_ID = 'AS_TEST';

    @TestSetup
    static void setup() {
        // All SKUs seeded so the service takes the update-only path (no ConnectApi).
        insert new List<Product2>{
            new Product2(Name = 'Seed Parent', ProductCode = PARENT_SKU, StockKeepingUnit = PARENT_SKU,
                ERPProductNumber__c = PARENT_SKU, IsActive = true),
            new Product2(Name = 'Seed Child', ProductCode = CHILD_SKU, StockKeepingUnit = CHILD_SKU,
                ERPProductNumber__c = PARENT_SKU, IsActive = true)
        };
    }

    private static String validGroupJson() {
        return JSON.serialize(new Map<String, Object>{
            'parent' => new Map<String, Object>{
                'Name' => 'Mövenpick DH 500g VP gem.',
                'ProductCode' => PARENT_SKU,
                'StockKeepingUnit' => PARENT_SKU,
                'ERPProductNumber__c' => PARENT_SKU,
                'IsActive' => true
            },
            'variations' => new List<Object>{
                new Map<String, Object>{
                    'Name' => 'Child - KAR',
                    'ProductCode' => CHILD_SKU,
                    'StockKeepingUnit' => CHILD_SKU,
                    'ERPProductNumber__c' => PARENT_SKU,
                    'Factor__c' => 12,
                    'IsActive' => true,
                    'Unit__c' => 'KAR'
                }
            }
        });
    }

    private static Product_Import_Request__c pendingRequest(String payload) {
        return new Product_Import_Request__c(
            Payload__c = payload,
            Status__c = ProductVariationBatch.STATUS_PENDING,
            CorrelationId__c = 'cid-batch-test',
            WebStoreId__c = WEBSTORE_ID,
            AttributeSetId__c = ATTR_SET_ID,
            ParentSKU__c = PARENT_SKU,
            RetryCount__c = 0
        );
    }

    @IsTest
    static void execute_shouldMarkRequestDone_whenGroupValid() {
        //Having
        Product_Import_Request__c request = pendingRequest(validGroupJson());
        insert request;

        //When
        Test.startTest();
        Database.executeBatch(new ProductVariationBatch(), ProductVariationBatch.SCOPE_SIZE);
        Test.stopTest();

        //Then
        request = [SELECT Status__c, ErrorMessage__c, ProcessedAt__c FROM Product_Import_Request__c WHERE Id = :request.Id];
        System.assertEquals(ProductVariationBatch.STATUS_DONE, request.Status__c, 'valid group is processed to Done');
        System.assertEquals(null, request.ErrorMessage__c, 'no error message on success');
        System.assertNotEquals(null, request.ProcessedAt__c, 'terminal timestamp is stamped');

        Product2 parent = [SELECT Name FROM Product2 WHERE StockKeepingUnit = :PARENT_SKU LIMIT 1];
        System.assertEquals('Mövenpick DH 500g VP gem.', parent.Name, 'batch applied parent name via DML');
    }

    @IsTest
    static void execute_shouldMarkRequestFailed_whenGroupMissingParent() {
        //Having
        Product_Import_Request__c request = pendingRequest(
            JSON.serialize(new Map<String, Object>{ 'variations' => new List<Object>() }));
        insert request;

        //When
        Test.startTest();
        Database.executeBatch(new ProductVariationBatch(), ProductVariationBatch.SCOPE_SIZE);
        Test.stopTest();

        //Then
        request = [SELECT Status__c, ErrorMessage__c, ProcessedAt__c FROM Product_Import_Request__c WHERE Id = :request.Id];
        System.assertEquals(ProductVariationBatch.STATUS_FAILED, request.Status__c, 'group without parent fails');
        System.assertNotEquals(null, request.ErrorMessage__c, 'failure reason is recorded on the record');
        System.assertNotEquals(null, request.ProcessedAt__c, 'terminal timestamp is stamped');
    }

    @IsTest
    static void execute_shouldIsolateFailure_whenOneOfTwoGroupsBad() {
        //Having
        Product_Import_Request__c badRequest = pendingRequest(
            JSON.serialize(new Map<String, Object>{ 'variations' => new List<Object>() }));
        insert badRequest; // inserted first -> processed first
        Product_Import_Request__c goodRequest = pendingRequest(validGroupJson());
        insert goodRequest;

        //When
        // Scope 2 here: test context allows only ONE execute() invocation per run,
        // so both records must share a scope. processOne still isolates them.
        Test.startTest();
        Database.executeBatch(new ProductVariationBatch(), 2);
        Test.stopTest();

        //Then
        badRequest = [SELECT Status__c FROM Product_Import_Request__c WHERE Id = :badRequest.Id];
        goodRequest = [SELECT Status__c FROM Product_Import_Request__c WHERE Id = :goodRequest.Id];
        System.assertEquals(ProductVariationBatch.STATUS_FAILED, badRequest.Status__c, 'bad group fails alone');
        System.assertEquals(ProductVariationBatch.STATUS_DONE, goodRequest.Status__c, 'later group still processes');
    }

    @IsTest
    static void finish_shouldSweepExpiredRecords_andKeepRecentOnes() {
        //Having
        Product_Import_Request__c expiredDone = pendingRequest('{}');
        expiredDone.Status__c = ProductVariationBatch.STATUS_DONE;
        expiredDone.ProcessedAt__c = System.now().addDays(-8);
        Product_Import_Request__c recentDone = pendingRequest('{}');
        recentDone.Status__c = ProductVariationBatch.STATUS_DONE;
        recentDone.ProcessedAt__c = System.now().addDays(-2);
        Product_Import_Request__c expiredFailed = pendingRequest('{}');
        expiredFailed.Status__c = ProductVariationBatch.STATUS_FAILED;
        expiredFailed.ProcessedAt__c = System.now().addDays(-31);
        Product_Import_Request__c recentFailed = pendingRequest('{}');
        recentFailed.Status__c = ProductVariationBatch.STATUS_FAILED;
        recentFailed.ProcessedAt__c = System.now().addDays(-10);
        insert new List<Product_Import_Request__c>{ expiredDone, recentDone, expiredFailed, recentFailed };

        //When
        Test.startTest();
        Database.executeBatch(new ProductVariationBatch(), ProductVariationBatch.SCOPE_SIZE); // no Pending -> finish only
        Test.stopTest();

        //Then
        Set<Id> survivorIds = new Map<Id, Product_Import_Request__c>(
            [SELECT Id FROM Product_Import_Request__c]).keySet();
        System.assert(!survivorIds.contains(expiredDone.Id), 'Done older than 7 days is swept');
        System.assert(survivorIds.contains(recentDone.Id), 'recent Done is kept');
        System.assert(!survivorIds.contains(expiredFailed.Id), 'Failed older than 30 days is swept');
        System.assert(survivorIds.contains(recentFailed.Id), 'Failed within 30 days is kept as audit trail');
    }

    @IsTest
    static void startIfIdle_shouldStartBatch_whenNoneActive() {
        //Having
        insert pendingRequest(validGroupJson());

        //When
        Test.startTest();
        Id jobId = ProductVariationBatch.startIfIdle();
        Test.stopTest();

        //Then
        System.assertNotEquals(null, jobId, 'an idle org gets a new drainer job');
        Product_Import_Request__c request = [SELECT Status__c FROM Product_Import_Request__c LIMIT 1];
        System.assertEquals(ProductVariationBatch.STATUS_DONE, request.Status__c, 'started drainer processed the record');
    }
}