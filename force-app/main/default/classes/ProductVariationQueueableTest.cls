@IsTest
private class ProductVariationQueueableTest {

    private static final String PARENT_SKU = 'TEST-PVQ-PARENT-001';
    private static final String VARIATION_SKU = 'TEST-PVQ-VAR-ST-001';
    private static final String WEBSTORE_ID = 'TEST_WEBSTORE';
    private static final String ATTRIBUTE_SET_ID = 'TEST_ATTRSET';

    @TestSetup
    static void setup() {
        // Pre-existing parent + variation so the run takes the update-only path
        // (no ConnectApi Commerce calls).
        insert new List<Product2>{
            new Product2(Name = 'Seed Parent', ProductCode = PARENT_SKU, StockKeepingUnit = PARENT_SKU, IsActive = true),
            new Product2(Name = 'Seed Var ST', ProductCode = VARIATION_SKU, StockKeepingUnit = VARIATION_SKU, IsActive = true)
        };
    }

    @IsTest
    static void execute_shouldApplyDataUpdates_whenProductsAlreadyExist() {
        //Having
        List<Object> products = new List<Object>{
            new Map<String, Object>{
                'parent' => new Map<String, Object>{
                    'Name' => 'Updated Parent',
                    'ProductCode' => PARENT_SKU,
                    'StockKeepingUnit' => PARENT_SKU,
                    'ERPProductNumber__c' => '900001',
                    'ReleasedForRetail__c' => true,
                    'ReleasedForAHS__c' => false,
                    'ReleasedForExport__c' => false,
                    'IsActive' => true
                },
                'variations' => new List<Object>{
                    new Map<String, Object>{
                        'Name' => 'Updated Var ST',
                        'ProductCode' => VARIATION_SKU,
                        'StockKeepingUnit' => VARIATION_SKU,
                        'Unit__c' => 'ST',
                        'ReleasedForRetail__c' => true,
                        'IsActive' => true
                    }
                }
            }
        };

        //When
        Test.startTest();
        Id jobId = System.enqueueJob(
            new ProductVariationQueueable(WEBSTORE_ID, ATTRIBUTE_SET_ID, 'cid-update-001', products));
        Test.stopTest();

        //Then
        AsyncApexJob job = [SELECT Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId];
        System.assertEquals('Completed', job.Status, 'Queueable should complete');
        System.assertEquals(0, job.NumberOfErrors, 'Queueable should not error');

        Product2 parent = [
            SELECT ReleasedForRetail__c, ERPProductNumber__c, ERPLastSync__c
            FROM Product2 WHERE StockKeepingUnit = :PARENT_SKU LIMIT 1
        ];
        System.assertEquals(true, parent.ReleasedForRetail__c, 'Parent release flag should be applied via DML');
        System.assertEquals('900001', parent.ERPProductNumber__c, 'Parent ERP number should be applied via DML');
        System.assertNotEquals(null, parent.ERPLastSync__c, 'Data-apply pass should stamp ERPLastSync__c');

        Product2 variation = [
            SELECT ReleasedForRetail__c, ERPLastSync__c
            FROM Product2 WHERE StockKeepingUnit = :VARIATION_SKU LIMIT 1
        ];
        System.assertEquals(true, variation.ReleasedForRetail__c, 'Variation release flag should be applied via DML');
        System.assertNotEquals(null, variation.ERPLastSync__c, 'Variation should be stamped by the data-apply pass');
    }

    @IsTest
    static void execute_shouldCompleteWithoutError_whenParentSkuIsBlank() {
        //Having
        List<Object> products = new List<Object>{
            new Map<String, Object>{
                'parent' => new Map<String, Object>{ 'Name' => 'No SKU parent', 'ProductCode' => 'X' },
                'variations' => new List<Object>()
            }
        };

        //When
        Test.startTest();
        Id jobId = System.enqueueJob(
            new ProductVariationQueueable(WEBSTORE_ID, ATTRIBUTE_SET_ID, 'cid-fail-001', products));
        Test.stopTest();

        //Then
        // A per-product failure is caught, logged, and does NOT fail the job.
        AsyncApexJob job = [SELECT Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId];
        System.assertEquals('Completed', job.Status, 'Job should complete despite a failing product');
        System.assertEquals(0, job.NumberOfErrors, 'Product failures are logged, not thrown');
    }

    @IsTest
    static void execute_shouldCompleteWithoutError_whenProductsEmpty() {
        //Having
        List<Object> products = new List<Object>();

        //When
        Test.startTest();
        Id jobId = System.enqueueJob(
            new ProductVariationQueueable(WEBSTORE_ID, ATTRIBUTE_SET_ID, 'cid-empty-001', products));
        Test.stopTest();

        //Then
        AsyncApexJob job = [SELECT Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId];
        System.assertEquals('Completed', job.Status, 'Empty batch should complete cleanly');
        System.assertEquals(0, job.NumberOfErrors, 'Empty batch should not error');
    }
}