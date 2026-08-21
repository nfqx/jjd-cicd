@isTest
private class ProductCategoryProductTriggerTest {

    @TestSetup
    static void makeData(){
        ProductCatalog myCatalog = new ProductCatalog(Name = 'test');
        insert myCatalog;
    
        // Create a ProductCategory
        ProductCategory category = new ProductCategory(Name = 'Test Category', CatalogId = myCatalog.Id);
        insert category;
    
        // Create a ProductCategory
        ProductCategory category2 = new ProductCategory(Name = 'Test Category 2', ParentCategoryId = category.Id, CatalogId = myCatalog.Id);
        insert category2;
    
        // Create a ProductCategory
        ProductCategory category3 = new ProductCategory(Name = 'Test Category 3', ParentCategoryId = category2.Id, CatalogId = myCatalog.Id);
        insert category3;
    
        // Create a ProductCategory
        ProductCategory category4 = new ProductCategory(Name = 'Test Category 4', ParentCategoryId = category3.Id, CatalogId = myCatalog.Id);
        insert category4;
    }
    @isTest
    private static void testLogic(){
        // Create a Product
        Product2 product = new Product2(
            Name = 'Test Product', 
            ProductCode = 'TEST1', 
            IsActive = true, 
            Tenant__c = '001'
        );
        insert product;
        ProductCategory category4 = [SELECT Id FROM ProductCategory WHERE Name = 'Test Category 4' LIMIT 1];
        Test.startTest();
            insert new ProductCategoryProduct(
                ProductCategoryId = category4.Id,
                ProductId = product.Id
            );
        Test.stopTest();
        List<ProductCategoryProduct> pcpList = [SELECT Id FROM ProductCategoryProduct];
        Assert.areEqual(pcpList.size(), 4);
    }
}