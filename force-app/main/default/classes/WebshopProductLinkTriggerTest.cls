@isTest
private class WebshopProductLinkTriggerTest {
    @isTest
    static void testLogic() {
        Product2 product = new Product2();
        product.ExternalId = 'TestProduct';
        product.Name = 'MyTestCoffee';
        product.Tenant__c = '001';
        product.Type = 'Base';
        product.IsActive = true;
        insert product;
        Product2 product2 = new Product2();
        product2.ExternalId = 'TestProduct2';
        product2.Name = 'MyTestCoffee2';
        product2.Tenant__c = '001';
        product2.Type = 'Base';
        product2.IsActive = true;
        insert product2;
        WebshopProductLink__c link = new WebshopProductLink__c(
            Product1__c = product.Id,
            Product2__c = product2.Id
        );
        insert link;
    }
}