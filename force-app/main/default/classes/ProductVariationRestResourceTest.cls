@IsTest
public class ProductVariationRestResourceTest {

    private static final String PARENT_SKU = 'MAT1';
    private static final String CHILD_SKU = 'MAT1-KAR';
    private static final String WEBSTORE_ID = 'WS_TEST';
    private static final String ATTR_SET_ID = 'AS_TEST';

    @TestSetup
    static void setup() {
        insert new List<Product2>{
            new Product2(Name = 'Seed Parent', ProductCode = PARENT_SKU, StockKeepingUnit = PARENT_SKU,
                ERPProductNumber__c = PARENT_SKU, IsActive = true),
            new Product2(Name = 'Seed Child', ProductCode = CHILD_SKU, StockKeepingUnit = CHILD_SKU,
                ERPProductNumber__c = PARENT_SKU, IsActive = true)
        };
    }

    private static Map<String, Object> parentPayload() {
        return new Map<String, Object>{
            'Name' => 'Mövenpick DH 500g VP gem.',
            'ProductCode' => PARENT_SKU,
            'StockKeepingUnit' => PARENT_SKU,
            'ERPProductNumber__c' => PARENT_SKU,
            'NetWeight__c' => '500.000',
            'IsActive' => true,
            'ReleasedForRetail__c' => true,
            'ReleasedForExport__c' => false
        };
    }

    private static Map<String, Object> childPayload(String sku, Object factor, String unit) {
        return new Map<String, Object>{
            'Name' => 'Child - ' + unit,
            'ProductCode' => sku,
            'StockKeepingUnit' => sku,
            'ERPProductNumber__c' => PARENT_SKU,
            'Factor__c' => factor,
            'IsActive' => true,
            'Unit__c' => unit
        };
    }

    private static List<Object> oneGroup(Map<String, Object> parent, List<Object> variations) {
        return new List<Object>{
            new Map<String, Object>{ 'parent' => parent, 'variations' => variations }
        };
    }

    private static void setRestContext(String body) {
        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestUri = '/services/apexrest/product-variation/post';
        if (body != null) {
            request.requestBody = Blob.valueOf(body);
        }
        RestContext.request = request;
        RestContext.response = new RestResponse();
    }

    @IsTest
    static void doPost_shouldReturn202AndStage_whenProductsValid() {
        //Having
        // All SKUs are seeded, so the drainer batch takes the update-only path (no ConnectApi).
        List<Object> products = oneGroup(parentPayload(), new List<Object>{ childPayload(CHILD_SKU, 12, 'KAR') });
        setRestContext(JSON.serialize(new Map<String, Object>{
            'webStoreId' => WEBSTORE_ID,
            'attributeSetId' => ATTR_SET_ID,
            'correlationId' => 'cid-abc',
            'products' => products
        }));

        //When
        Test.startTest();
        ProductVariationRestResource.ResponseWrapper response = ProductVariationRestResource.doPost();
        Test.stopTest(); // started drainer batch runs here

        //Then
        System.assertEquals(true, response.success, 'controller acknowledges the request');
        System.assertEquals(202, response.statusCode, 'async mode returns 202 Accepted');
        System.assertNotEquals(null, response.jobId, 'ACK carries the drainer batch job id');
        System.assertEquals('cid-abc', response.correlationId, 'correlationId is echoed back');
        System.assertEquals(1, response.stagedCount, 'one staging record per product group');
        System.assertEquals(null, response.results, 'per-product results are not returned synchronously');

        Product_Import_Request__c staged = [
            SELECT Status__c, ParentSKU__c, ERPProductNumber__c, CorrelationId__c, WebStoreId__c, AttributeSetId__c
            FROM Product_Import_Request__c LIMIT 1];
        System.assertEquals(ProductVariationBatch.STATUS_DONE, staged.Status__c, 'drainer processed the staged group');
        System.assertEquals(PARENT_SKU, staged.ParentSKU__c, 'parent SKU extracted as index field');
        System.assertEquals(PARENT_SKU, staged.ERPProductNumber__c, 'ERP number extracted as index field');
        System.assertEquals('cid-abc', staged.CorrelationId__c, 'correlationId stored on the staging record');
        System.assertEquals(WEBSTORE_ID, staged.WebStoreId__c, 'webstore id stored per record');
        System.assertEquals(ATTR_SET_ID, staged.AttributeSetId__c, 'attribute set id stored per record');

        // The drainer applied the parent data via the phase-2 DML pass.
        Product2 parent = [SELECT Name FROM Product2 WHERE StockKeepingUnit = :PARENT_SKU LIMIT 1];
        System.assertEquals('Mövenpick DH 500g VP gem.', parent.Name, 'drainer applied parent name via DML');
    }

    @IsTest
    static void doPost_shouldReturn400_whenBodyMissing() {
        //Having
        setRestContext(null);

        //When
        Test.startTest();
        ProductVariationRestResource.ResponseWrapper response = ProductVariationRestResource.doPost();
        Test.stopTest();

        //Then
        System.assertEquals(false, response.success);
        System.assertEquals(400, response.statusCode);
    }

    @IsTest
    static void doPost_shouldReturn400_whenWebStoreMissing() {
        //Having
        setRestContext(JSON.serialize(new Map<String, Object>{
            'products' => oneGroup(parentPayload(), new List<Object>())
        }));

        //When
        Test.startTest();
        ProductVariationRestResource.ResponseWrapper response = ProductVariationRestResource.doPost();
        Test.stopTest();

        //Then
        System.assertEquals(false, response.success);
        System.assertEquals(400, response.statusCode);
    }

    @IsTest
    static void doPost_shouldReturn400_whenProductsEmpty() {
        //Having
        setRestContext(JSON.serialize(new Map<String, Object>{
            'webStoreId' => WEBSTORE_ID,
            'products' => new List<Object>()
        }));

        //When
        Test.startTest();
        ProductVariationRestResource.ResponseWrapper response = ProductVariationRestResource.doPost();
        Test.stopTest();

        //Then
        System.assertEquals(false, response.success);
        System.assertEquals(400, response.statusCode);
    }

    @IsTest
    static void doPost_shouldReturn202_whenGroupMissingParent_errorDeferredToAsync() {
        //Having
        // Envelope is valid (products is a non-empty array), so the controller acks 202.
        // The missing-"parent" problem surfaces on the staging record (Status=Failed +
        // ErrorMessage), not synchronously as a 400 — the fire-and-forget contract.
        setRestContext(JSON.serialize(new Map<String, Object>{
            'webStoreId' => WEBSTORE_ID,
            'products' => new List<Object>{ new Map<String, Object>{ 'variations' => new List<Object>() } }
        }));

        //When
        Test.startTest();
        ProductVariationRestResource.ResponseWrapper response = ProductVariationRestResource.doPost();
        Test.stopTest(); // drainer batch runs, marks the staged group Failed

        //Then
        System.assertEquals(true, response.success, 'valid envelope is accepted');
        System.assertEquals(202, response.statusCode, 'per-group errors are deferred to async, not returned as 400');
        System.assertNotEquals(null, response.jobId, 'ACK carries the drainer batch job id');

        Product_Import_Request__c staged = [SELECT Status__c, ErrorMessage__c FROM Product_Import_Request__c LIMIT 1];
        System.assertEquals(ProductVariationBatch.STATUS_FAILED, staged.Status__c, 'bad group fails on its staging record');
        System.assertNotEquals(null, staged.ErrorMessage__c, 'failure reason recorded for the audit trail');
    }

    @IsTest
    static void doPost_shouldReturn500_whenBodyMalformed() {
        //Having
        setRestContext('this is not json');

        //When
        Test.startTest();
        ProductVariationRestResource.ResponseWrapper response = ProductVariationRestResource.doPost();
        Test.stopTest();

        //Then
        System.assertEquals(false, response.success);
        System.assertEquals(500, response.statusCode, 'malformed JSON falls into the generic error branch');
    }
}