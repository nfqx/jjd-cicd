@IsTest
private class AccountAllProductsControllerTest {

    @testSetup
    static void setupData() {

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

        Account acc = new Account();
        acc.Name = 'TestAccount';
        acc.AssortmentExtended__c = true;
        acc.CustomerReferenceID__c = '001-001';
        insert acc;

        BuyerGroup buyerGroup = new BuyerGroup();
        buyerGroup.Account__c = acc.Id;
        buyerGroup.Name = 'TestGroup';
        insert buyerGroup;

        CommerceEntitlementPolicy policy = new CommerceEntitlementPolicy();
        policy.Account__c = acc.Id;
        policy.Name = 'TestPolicy';
        insert policy;

        WebStoreBuyerGroup wsb = new WebStoreBuyerGroup(
            BuyerGroupId = buyerGroup.Id,
            WebStoreId = webStore2.Id
        );
        insert wsb;

        CommerceEntitlementPolicy policyOwn = new CommerceEntitlementPolicy(
            Name = 'Own Policy',
            Account__c = acc.Id
        );
        insert policyOwn;

        CommerceEntitlementPolicy policyGroup = new CommerceEntitlementPolicy(
            Name = 'Group Policy'
        );
        insert policyGroup;

        CommerceEntitlementBuyerGroup cebg = new CommerceEntitlementBuyerGroup(
            BuyerGroupId = buyerGroup.Id,
            PolicyId = policyGroup.Id
        );
        insert cebg;

        // Create Internal Listprices Quote Pricebook
        Pricebook2 internalPB = new Pricebook2(Name = System.Label.WebshopDoNotTranslateInternalListpricePricebookName, IsActive = true);
        insert internalPB;        

        Product2 product = new Product2(
            Name = 'Test Product',
            IsActive = true,
            tenant__c = '001'
        );
        insert product;

        CommerceEntitlementProduct ep1 = new CommerceEntitlementProduct(
            PolicyId = policyOwn.Id,
            ProductId = product.Id
        );

        CommerceEntitlementProduct ep2 = new CommerceEntitlementProduct(
            PolicyId = policyGroup.Id,
            ProductId = product.Id
        );

        insert new List<CommerceEntitlementProduct>{ep1, ep2};

        PricebookEntry stdEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert stdEntry;

        Pricebook2 accountPb = new Pricebook2(
            Name = 'Account Pricebook',
            IsActive = true,
            Account__c = acc.Id
        );
        insert accountPb;

        PricebookEntry accEntry = new PricebookEntry(
            Pricebook2Id = accountPb.Id,
            Product2Id = product.Id,
            UnitPrice = 80,
            IsActive = true
        );
        insert accEntry;
    }

    @IsTest
    static void testGetAccountProducts() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Map<String,Object> result =
            AccountAllProductsController.getAccountProducts(acc.Id);
        Test.stopTest();

        System.assert(result.containsKey('rows'));
        System.assert(result.containsKey('assortmentExtended'));

        List<AccountAllProductsController.ProductRowDTO> rows =
            (List<AccountAllProductsController.ProductRowDTO>)result.get('rows');

        System.assert(rows.size() > 0);

        AccountAllProductsController.ProductRowDTO row = rows[0];

        System.assertNotEquals(null, row.productId);
        System.assertEquals(true, row.isOwnAssortment);
        System.assertEquals(100, row.listPrice);
        System.assertEquals(80, row.ownPrice);
    }

    @IsTest
    static void testNoAccountPricebook() {

        Account acc = new Account(
            Name = 'Account Without Pricebook',
            AssortmentExtended__c = false
        );
        insert acc;

        Test.startTest();
        Map<String,Object> result =
            AccountAllProductsController.getAccountProducts(acc.Id);
        Test.stopTest();

        System.assert(result.containsKey('rows'));
        System.assertEquals(false, result.get('assortmentExtended'));
    }
}