/*
* Created by: Stanley Yin
* Created Date: 09-04-2024
* Purpose: Testing B2BProductPriceCalcStdBatch and B2BProductPriceCalcCstBatch
*/

@isTest 
private class BatchPopulateProduct2ExternalIdTest {
    @isTest 
    private static void testBatch(){        
        Product2 product = new Product2();
        product.ProductCode = '12345';
        product.Name = 'MyTestCoffee';
        product.Tenant__c = '001';
        product.Type = 'Base';
        product.IsActive = true;
        insert product;
        Test.startTest();
            Database.executeBatch(new BatchPopulateProduct2ExternalId(), 100);
        Test.stopTest();
        product = [SELECT Id, ExternalId FROM Product2 LIMIT 1];
        Assert.areEqual(product.ExternalId, '00112345');
    }
}