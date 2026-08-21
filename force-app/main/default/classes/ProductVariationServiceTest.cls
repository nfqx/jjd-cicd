@IsTest
public class ProductVariationServiceTest {

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
            'BaseUnitCode__c' => 'ST',
            'GTIN__c' => '4006581001777',
            'OldProductNumber__c' => '700777',
            'EAN__c' => '4006581001777',
            'Description__c' => 'Mövenpick DH 500g VP gem.',
            'NetWeight__c' => '500.000',
            'GrossWeight__c' => '524.000',
            'IsActive' => true,
            'BioProduct__c' => '1',                       // SAP "1" -> true
            'BioFairTradeProduct__c' => '0',              // SAP "0" -> false
            'ActivationDate__c' => '2026-01-15',
            'ERPLastChanged__c' => '2026-06-29T12:00:00.000Z',
            'ReleasedForRetail__c' => true,
            'ReleasedForAHS__c' => true,
            'ReleasedForExport__c' => false               // reset-to-false path
        };
    }

    private static Map<String, Object> childPayload(String sku, Object factor, String unit) {
        return new Map<String, Object>{
            'Name' => 'Mövenpick DH 500g VP gem. - ' + unit,
            'ProductCode' => sku,
            'StockKeepingUnit' => sku,
            'ERPProductNumber__c' => PARENT_SKU,
            'BaseUnitCode__c' => 'ST',
            'GTIN__c' => '4006581700777',                 // per-variation, differs from parent
            'BaseProductCode__c' => PARENT_SKU,           // material without the unit suffix
            'GrossWeight__c' => '6.000',
            'Factor__c' => factor,
            'IsActive' => true,
            'Unit__c' => unit,
            'ReleasedForRetail__c' => true,
            'ReleasedForExport__c' => false
        };
    }

    private static List<Object> oneGroup(Map<String, Object> parent, List<Object> variations) {
        return new List<Object>{
            new Map<String, Object>{ 'parent' => parent, 'variations' => variations }
        };
    }

    @IsTest
    static void processBatch_shouldWriteAllFields_whenRecordsExist() {
        //Having
        List<Object> variations = new List<Object>{ childPayload(CHILD_SKU, 12, 'KAR') };
        List<Object> products = oneGroup(parentPayload(), variations);

        //When
        Test.startTest();
        List<ProductVariationService.ProductResult> results =
            ProductVariationService.processBatch(WEBSTORE_ID, ATTR_SET_ID, products);
        Test.stopTest();

        //Then
        System.assertEquals(1, results.size(), 'one product group');
        ProductVariationService.ProductResult result = results[0];
        System.assertEquals(true, result.success, 'group should succeed: ' + result.message);
        System.assertEquals('updated', result.parentOperation, 'parent already existed');
        System.assertEquals(1, result.variationsUpdated, 'child already existed');
        System.assertEquals(0, result.variationsCreated, 'no new children');

        Product2 parent = [
            SELECT NetWeight__c, GrossWeight__c, BioProduct__c, BioFairTradeProduct__c,
                   ActivationDate__c, ERPLastChanged__c, ERPLastSync__c,
                   ReleasedForRetail__c, ReleasedForAHS__c, ReleasedForExport__c,
                   GTIN__c, OldProductNumber__c, BaseProductCode__c
            FROM Product2 WHERE StockKeepingUnit = :PARENT_SKU LIMIT 1
        ];
        System.assertEquals(500.000, parent.NetWeight__c, 'net weight coerced');
        System.assertEquals(true, parent.BioProduct__c, 'SAP "1" -> true');
        System.assertEquals(false, parent.BioFairTradeProduct__c, 'SAP "0" -> false');
        System.assertEquals(Date.newInstance(2026, 1, 15), parent.ActivationDate__c, 'date coerced');
        System.assertNotEquals(null, parent.ERPLastChanged__c, 'ISO datetime coerced');
        System.assertNotEquals(null, parent.ERPLastSync__c, 'sync stamp set');
        System.assertEquals(true, parent.ReleasedForRetail__c, 'channel 10');
        System.assertEquals(true, parent.ReleasedForAHS__c, 'channel 20');
        System.assertEquals(false, parent.ReleasedForExport__c, 'channel 30 absent -> reset false');
        System.assertEquals('4006581001777', parent.GTIN__c, 'parent keeps the header GTIN');
        System.assertEquals('700777', parent.OldProductNumber__c, 'old product number written on parent');
        System.assertEquals(null, parent.BaseProductCode__c, 'base product code is variation-only');

        Product2 child = [
            SELECT Factor__c, ReleasedForRetail__c, GTIN__c, BaseProductCode__c, OldProductNumber__c
            FROM Product2 WHERE StockKeepingUnit = :CHILD_SKU LIMIT 1
        ];
        System.assertEquals(12, child.Factor__c, 'factor coerced');
        System.assertEquals(true, child.ReleasedForRetail__c, 'child inherits release flag');
        System.assertEquals('4006581700777', child.GTIN__c, 'per-variation GTIN differs from parent');
        System.assertEquals(PARENT_SKU, child.BaseProductCode__c, 'base product code written on variation');
        System.assertEquals(null, child.OldProductNumber__c, 'old product number is parent-only');
    }

    @IsTest
    static void processBatch_shouldFailGracefully_whenParentCreateUnavailable() {
        //Having
        // New SKUs -> create path -> ConnectApi unavailable in test -> per-product failure, no unhandled exception.
        Map<String, Object> parent = parentPayload();
        parent.put('StockKeepingUnit', 'NEW_PARENT');
        parent.put('ProductCode', 'NEW_PARENT');
        parent.put('ERPProductNumber__c', 'NEW_PARENT');

        //When
        Test.startTest();
        List<ProductVariationService.ProductResult> results =
            ProductVariationService.processBatch(WEBSTORE_ID, ATTR_SET_ID, oneGroup(parent, new List<Object>()));
        Test.stopTest();

        //Then
        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].success, 'create path cannot complete in test');
        System.assertEquals('failed', results[0].parentOperation);
        System.assertNotEquals(null, results[0].message, 'failure message captured');
    }

    @IsTest
    static void processBatch_shouldFailGracefully_whenVariationCreateUnavailable() {
        //Having
        // Parent exists (update), but a NEW child triggers the variation create path.
        List<Object> variations = new List<Object>{ childPayload('MAT1-PAL', 720, 'PAL') };

        //When
        Test.startTest();
        List<ProductVariationService.ProductResult> results =
            ProductVariationService.processBatch(WEBSTORE_ID, ATTR_SET_ID, oneGroup(parentPayload(), variations));
        Test.stopTest();

        //Then
        System.assertEquals(false, results[0].success, 'variation create cannot complete in test');
        System.assertEquals('failed', results[0].parentOperation);
    }

    @IsTest
    static void processBatch_shouldThrow_whenParentMissing() {
        //Having
        List<Object> products = new List<Object>{
            new Map<String, Object>{ 'variations' => new List<Object>() }
        };

        //When
        Boolean thrown = false;
        Test.startTest();
        try {
            ProductVariationService.processBatch(WEBSTORE_ID, ATTR_SET_ID, products);
        } catch (ProductVariationService.ProductVariationException e) {
            thrown = true;
        }
        Test.stopTest();

        //Then
        System.assert(thrown, 'missing parent should throw');
    }

    @IsTest
    static void processBatch_shouldNotClearGtin_whenPayloadOmitsGtin() {
        //Having
        // A variation with no main EAN arrives without a GTIN__c key. The shim writes
        // string fields only when present and non-blank, so an already-populated GTIN
        // is left intact rather than cleared (clearing stale values is a separate
        // one-time data cleanup, not part of the sync).
        Product2 seeded = [SELECT Id FROM Product2 WHERE StockKeepingUnit = :CHILD_SKU LIMIT 1];
        update new Product2(Id = seeded.Id, GTIN__c = '4006581700777');

        Map<String, Object> child = childPayload(CHILD_SKU, 12, 'KAR');
        child.remove('GTIN__c');
        List<Object> products = oneGroup(parentPayload(), new List<Object>{ child });

        //When
        Test.startTest();
        ProductVariationService.processBatch(WEBSTORE_ID, ATTR_SET_ID, products);
        Test.stopTest();

        //Then
        Product2 afterSync = [SELECT GTIN__c FROM Product2 WHERE StockKeepingUnit = :CHILD_SKU LIMIT 1];
        System.assertEquals('4006581700777', afterSync.GTIN__c, 'absent GTIN must not clear the existing value');
    }
}