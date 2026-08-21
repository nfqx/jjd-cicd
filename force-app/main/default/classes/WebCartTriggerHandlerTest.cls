@isTest
public class WebCartTriggerHandlerTest {
    private static CartItem createCartItemBelow() {
        WebCart cart = [SELECT Id FROM WebCart LIMIT 1];
        CartDeliveryGroup cdg = [SELECT Id FROM CartDeliveryGroup LIMIT 1];
        Product2 prod = new Product2(
        	Name='Test Product',
            Tenant__c = '001',
            ProductCode = 'TEST1'
        );
        insert prod;
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.ID,
            Pricebook2Id = Test.getStandardPricebookId(),
            UnitPrice = WebCartTriggerHandler.SHIPPING_FREE_THRESHOLD - 1
        );
        insert pbe;
        CartItem ciClone = new CartItem();
        ciClone.Name = 'Test';
        ciClone.Product2Id = prod.Id;
        ciClone.cartDeliveryGroupId = cdg.Id;
        ciClone.Quantity = 1;
        ciClone.UnitAdjustedPrice = WebCartTriggerHandler.SHIPPING_FREE_THRESHOLD - 1;
        ciClone.SalesPrice = WebCartTriggerHandler.SHIPPING_FREE_THRESHOLD - 1;
        ciClone.TotalPrice = WebCartTriggerHandler.SHIPPING_FREE_THRESHOLD - 1;
        ciClone.TotalPriceAfterAllAdjustments = WebCartTriggerHandler.SHIPPING_FREE_THRESHOLD - 1;
        ciClone.TotalLineAmount = WebCartTriggerHandler.SHIPPING_FREE_THRESHOLD - 1;
        ciClone.CartId = cart.Id;
        insert ciClone;
        return ciClone;
    }
    private static CartItem createCartItemAbove() {
        WebCart cart = [SELECT Id FROM WebCart LIMIT 1];
        CartDeliveryGroup cdg = [SELECT Id FROM CartDeliveryGroup LIMIT 1];
        Product2 prod = new Product2(
        	Name='Test Product',
            Tenant__c = '001',
            ProductCode = 'TEST1'
        );
        insert prod;
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.ID,
            Pricebook2Id = Test.getStandardPricebookId(),
            UnitPrice = WebCartTriggerHandler.SHIPPING_FREE_THRESHOLD + 1
        );
        insert pbe;
        CartItem ciClone = new CartItem();
        ciClone.Name = 'Test';
        ciClone.Product2Id = prod.Id;
        ciClone.cartDeliveryGroupId = cdg.Id;
        ciClone.Quantity = 1;
        ciClone.UnitAdjustedPrice = WebCartTriggerHandler.SHIPPING_FREE_THRESHOLD + 1;
        ciClone.SalesPrice = WebCartTriggerHandler.SHIPPING_FREE_THRESHOLD + 1;
        ciClone.TotalPrice = WebCartTriggerHandler.SHIPPING_FREE_THRESHOLD + 1;
        ciClone.TotalPriceAfterAllAdjustments = WebCartTriggerHandler.SHIPPING_FREE_THRESHOLD + 1;
        ciClone.TotalLineAmount = WebCartTriggerHandler.SHIPPING_FREE_THRESHOLD + 1;
        ciClone.CartId = cart.Id;
        insert ciClone;
        return ciClone;
    }

    @isTest
    static void testShippingCostCalcBelow() {
        WebStore webstore = new WebStore(Name = System.Label.WebshopDoNotTranslateStoreName);
        insert webstore;
        Product2 prod = new Product2(
        	Name='Shipping',
            Tenant__c = '001',
            ProductCode = WebCartTriggerHandler.SHIPPING_PRODUCT_CODES[0]
        );
        insert prod;
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.ID,
            Pricebook2Id = Test.getStandardPricebookId(),
            UnitPrice = 1
        );
        insert pbe;
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
        // Create test WebCart records before and simulate an update that triggers the logic
        WebCart cart = new WebCart(Name = 'Cart', WebStoreId = webstore.Id, AccountId=account.Id);
        insert cart;
        CartDeliveryGroup cdg = new CartDeliveryGroup(Name = 'test', CartId = cart.Id);
        insert cdg;
        Test.startTest();
            CartItem itemAbove = createCartItemBelow();
        Test.stopTest();
        
        List<CartItem> shippingItems = [SELECT Id, TotalPrice FROM CartItem WHERE Product2.ProductCode IN : WebCartTriggerHandler.SHIPPING_PRODUCT_CODES];
        Assert.areEqual(shippingItems.size(), 1);
        Assert.areEqual(shippingItems[0].TotalPrice, WebCartTriggerHandler.SHIPPING_COST);
    }

    @isTest
    static void testShippingCostCalcAbove() {
        WebStore webstore = new WebStore(Name = System.Label.WebshopDoNotTranslateStoreName);
        insert webstore;
        Product2 prod = new Product2(
        	Name='Shipping',
            Tenant__c = '001',
            ProductCode = WebCartTriggerHandler.SHIPPING_PRODUCT_CODES[0]
        );
        insert prod;
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.ID,
            Pricebook2Id = Test.getStandardPricebookId(),
            UnitPrice = 1
        );
        insert pbe;
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
        // Create test WebCart records before and simulate an update that triggers the logic
        WebCart cart = new WebCart(Name = 'Cart', WebStoreId = webstore.Id, AccountId=account.Id);
        insert cart;
        CartDeliveryGroup cdg = new CartDeliveryGroup(Name = 'test', CartId = cart.Id);
        insert cdg;
        Test.startTest();
            CartItem itemAbove = createCartItemAbove();
        Test.stopTest();
        
        List<CartItem> shippingItems = [SELECT Id, TotalPrice FROM CartItem WHERE Product2.ProductCode IN : WebCartTriggerHandler.SHIPPING_PRODUCT_CODES];
        Assert.areEqual(shippingItems.size(), 1);
        Assert.areEqual(shippingItems[0].TotalPrice, 0);
    }

    static testMethod void testWebCartUpdateTrigger() {
        WebStore testWebStore = new WebStore(Name = System.Label.WebshopDoNotTranslateStoreName);
        insert testWebStore;
        // Insert test products corresponding to the labels
        Product2 firstStageProduct = new Product2(Name = 'test1', Tenant__c = '001', ProductCode = System.Label.LetterCampaignBonusFirstStageItemCode);
        Product2 secondStageProduct = new Product2(Name = 'test2', Tenant__c = '001', ProductCode = System.Label.LetterCampaignBonusSecondStageItemCode);
        Decimal productPrice = (Decimal.valueOf(System.Label.LetterCampaignBonusFirstStageThreshold) + Decimal.valueOf(System.Label.LetterCampaignBonusSecondStageThreshold)) / 4;
        Product2 myProduct = new Product2(Name = 'test3', Tenant__c = '001', ProductCode = '123');
        insert new List<Product2>{ firstStageProduct, secondStageProduct, myProduct };

        Account account = WebCartTriggerHandlerTest.generateAccount(true, false);
        account.LetterCampaignActivated__c = true;
        account.LetterCampaignBonusUsed__c = false;
        account.LetterCampaignFreeItem__c = firstStageProduct.Id;
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
        // Create test WebCart records before and simulate an update that triggers the logic
        WebCart cart = new WebCart(Name = 'Cart', WebStoreId = testWebStore.Id, AccountId=account.Id);
        insert cart;
        CartDeliveryGroup cdg = new CartDeliveryGroup(Name = 'test', CartId = cart.Id);
        insert cdg;
        CartItem ci = new CartItem(CartId = cart.Id, Product2Id = myProduct.Id, Quantity = 1, CartDeliveryGroupId = cdg.Id, Name = 'myitem', SalesPrice = productPrice, TotalPrice = productPrice, TotalLineAmount = productPrice);
        insert ci;
        Test.startTest();
            ci.Quantity = 2;
            ci.SalesPrice = productPrice * 2;
            ci.TotalPrice = productPrice * 2;
            ci.TotalLineAmount = productPrice * 2;
            update ci;
        Test.stopTest();

        // Check results
        // Fetch CartItems to verify that a new free item was inserted correctly
        List<CartItem> cartItems = [SELECT Product2Id, LetterCampaignFreeItem__c FROM CartItem WHERE CartId = :cart.Id AND LetterCampaignFreeItem__c = true];
        System.assertEquals(1, cartItems.size(), 'There should be one free item added to the cart.');
        System.assertEquals(firstStageProduct.Id, cartItems[0].Product2Id, 'The free item should be the first stage product.');
    }

    public static Account generateAccount(Boolean buyerAccount, Boolean persist){
        return generateAccount(buyerAccount, persist, false);
    }
    public static Account generateAccount(Boolean buyerAccount, Boolean persist, Boolean puk){
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
        
        //Webstore needs to be created for test, otherwise flow will not run. 
        WebStore webStore = new WebStore(
            Name='J.J. Darboven Webshop'
        );
    
        insert webStore;
        WebStore webStore2 = new WebStore(
            Name='J.J. Darboven LWR Shop'
        );
    
        insert webStore2;
        WebStore webStore3 = new WebStore(
            Name='Test Store'
        );
    
        insert webStore3;

        Account acc = new Account(
        	Name='Test Account (' + guid + ')',
            CustomerReferenceID__c=guid
            //Verwendet_neues_Preismodell__c = puk
        );
        
        if(persist){
            insert acc;
        }
        
        if(buyerAccount) {
            BuyerAccount bacc = new BuyerAccount(
                BuyerId = acc.Id,
                Name = acc.Name,
                isActive = true
            );

            if(persist) {
                insert bacc;
            }
        }

        return acc;
    }
}