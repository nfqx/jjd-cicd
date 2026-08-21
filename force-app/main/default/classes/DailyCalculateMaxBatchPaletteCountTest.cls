@isTest
private class DailyCalculateMaxBatchPaletteCountTest {
    
    @testSetup
    static void setupTestData() {
        // Create Internal Listprices Quote Pricebook
        Pricebook2 internalPB = new Pricebook2(Name = System.Label.WebshopDoNotTranslateInternalListpricePricebookName, IsActive = true);
        insert internalPB;

        // Create parent products (VariationParent)
        Product2 prod2 = new Product2(
            Name = 'Parent Product',
            IsActive = true,
            Tenant__c = '001',
            Type = 'Base'
        );
        insert prod2;

        ProductAttributeSetProduct attributeSetProduct = new ProductAttributeSetProduct();
        attributeSetProduct.ProductAttributeSetId = [SELECT Id FROM ProductAttributeSet LIMIT 1].get(0).Id;
        attributeSetProduct.ProductId = prod2.Id;
        insert attributeSetProduct;
        
        // Create child products (Variations)
        List<Product2> childProducts = new List<Product2>();
        // Variation with Factor__c (used for both box and palette)
        childProducts.add(new Product2(
            Name = prod2.Name + ' - Box',
            IsActive = true,
            Factor__c = 10,
            Tenant__c = '001'
        ));
        // Piece product (will get BoxCount__c and PaletteCount__c updated)
        childProducts.add(new Product2(
            Name = prod2.Name + ' - Piece',
            IsActive = true,
            Tenant__c = '001'
        ));
        insert childProducts;
        
        // Create ProductAttributes linking parents to children
        List<ProductAttribute> productAttributes = new List<ProductAttribute>();
        Product2 boxProduct = [SELECT Id FROM Product2 WHERE Name = :prod2.Name + ' - Box' LIMIT 1];
        Product2 pieceProduct = [SELECT Id FROM Product2 WHERE Name = :prod2.Name + ' - Piece' LIMIT 1];

        productAttributes.add(new ProductAttribute(
            ProductId = boxProduct.Id,
            VariantParentId = prod2.Id,
            Unit__c = 'KARTON'
        ));
        productAttributes.add(new ProductAttribute(
            ProductId = pieceProduct.Id,
            VariantParentId = prod2.Id,
            Unit__c = 'STUECK'
        ));
        insert productAttributes;
    }
    
    @isTest
    static void testBatchExecution() {
        // Run the batch
        Test.startTest();
        DailyCalculateMaxBatchPaletteCount batch = new DailyCalculateMaxBatchPaletteCount();
        Database.executeBatch(batch, 50);
        Test.stopTest();

        // Verify updates
        List<Product2> updatedProducts = [SELECT Name, BoxCount__c, PaletteCount__c FROM Product2 WHERE Name LIKE '%Piece%'];
        System.assert(!updatedProducts.isEmpty(), 'Expected piece products to be updated');

        for (Product2 prod : updatedProducts) {
            System.assertEquals(10, prod.BoxCount__c, 'BoxCount__c should be updated to 10');
        }
    }
}