@isTest
private class AbandonedCartCheckoutDeleteTest {
    @testSetup
    static void setup() {
        
        // Insert test products corresponding to the labels
        Product2 firstStageProduct = new Product2(Name = 'test1', Tenant__c = '001', ProductCode = System.Label.LetterCampaignBonusFirstStageItemCode);
        Product2 secondStageProduct = new Product2(Name = 'test2', Tenant__c = '001', ProductCode = System.Label.LetterCampaignBonusSecondStageItemCode);
        Decimal productPrice = (Decimal.valueOf(System.Label.LetterCampaignBonusFirstStageThreshold) + Decimal.valueOf(System.Label.LetterCampaignBonusSecondStageThreshold)) / 4;
        Product2 myProduct = new Product2(Name = 'test3', Tenant__c = '001', ProductCode = '123');
        insert new List<Product2>{ firstStageProduct, secondStageProduct, myProduct };
    
        Account account = WebCartTriggerHandlerTest.generateAccount(true, false);
        account.LetterCampaignActivated__c = true;
        account.LetterCampaignBonusUsed__c = false;
        insert account;

        Pricebook2 buyersbook = new Pricebook2();
        buyersbook.Name = 'BuyerBook1';
        buyersbook.isActive = true;
        buyersbook.Account__c = account.Id;
        insert buyersbook;

        PricebookEntry entryForProduct = new PricebookEntry();
        entryForProduct.Pricebook2Id = Test.getStandardPricebookId();
        entryForProduct.Product2Id = myProduct.Id;
        entryForProduct.UnitPrice = productPrice;
        entryForProduct.IsActive = TRUE;
        insert entryForProduct;

        PricebookEntry cstEntryForProduct = new PricebookEntry();
        cstEntryForProduct.Pricebook2Id = buyersbook.Id;
        cstEntryForProduct.Product2Id = myProduct.Id;
        cstEntryForProduct.UnitPrice = productPrice;
        cstEntryForProduct.IsActive = TRUE;
        insert cstEntryForProduct;
        // Insert test account

        WebStore testWebStore = new WebStore(Name='TestWebStore');
        insert testWebStore;
        // Create test WebCart records before and simulate an update that triggers the logic
        WebCart cart = new WebCart(Name = 'Cart', WebStoreId = testWebStore.Id, AccountId=account.Id, Status = 'Checkout', CreatedDate = Datetime.now().addDays(-30), LastModifiedDate = Datetime.now().addDays(-30));
        insert cart;
    }

    @isTest
    static void testBatch() {
        // Test the Batchable execute method
        Test.startTest();
            Database.executeBatch(new AbandonedCartCheckoutDeleteBatch(), 1);
        Test.stopTest();

        // Verify the outcome
        List<WebCart> updatedCarts = [SELECT Id FROM WebCart];
        System.assertEquals(0, updatedCarts.size());
    }
}