@IsTest
private class BatchAutomateBrandAssortmentExtTest {

    @TestSetup
    static void setup() {

        WebStore webStore = new WebStore(
            Name=System.Label.WebshopDoNotTranslateStoreName
        );
        insert webStore;

        ProductCatalog myCatalog = new ProductCatalog(Name = 'test');
        insert myCatalog;

        Pricebook2 internalPB = new Pricebook2(Name = 'Internal Listprices Quote', IsActive = true);
        insert internalPB;

        // Brand
        WebshopBrand__c brand = new WebshopBrand__c(
            Name = 'Lavazza',
            AssortmentExtensionEnabled__c = true
        );
        insert brand;

        // BuyerGroup
        BuyerGroup bg = new BuyerGroup(
            Name = 'Lavazza Coffee'
        );
        insert bg;

        // BuyerGroup
        BuyerGroup bg2 = new BuyerGroup(
            Name = 'Lavazza Sortimentserweiterung',
            Brand__c = brand.Id
        );
        insert bg2;

        // Account
        Account acct = new Account(
            Name = 'Test Account'
        );
        insert acct;

        BuyerAccount buyerAccount = new BuyerAccount(
            BuyerId = acct.Id,
            Name = 'Test Buyer Account',
            IsActive = true
        );
        insert buyerAccount;

        // Static BuyerGroupMember
        insert new BuyerGroupMember(
            BuyerGroupId = bg.Id,
            BuyerId = acct.Id,
            Dynamic__c = false
        );

        // WebStoreBuyerGroup

        insert new WebStoreBuyerGroup(
            BuyerGroupId = bg.Id,
            WebStoreId = webStore.Id
        );

        // Policy

        CommerceEntitlementPolicy policy =
            new CommerceEntitlementPolicy(
                Name='Policy'
            );
        insert policy;

        insert new CommerceEntitlementBuyerGroup(
            BuyerGroupId = bg.Id,
            PolicyId = policy.Id
        );

        Product2 product = new Product2(
            Name='Coffee Beans',
            IsActive=true,
            Tenant__c = '001',
            BrandWebshop__c = brand.Id
        );

        insert product;

        insert new CommerceEntitlementProduct(
            PolicyId = policy.Id,
            ProductId = product.Id
        );

        ProductCategory coffee =
            new ProductCategory(
                Name='KAFFEE',
                CatalogId = myCatalog.Id
            );

        insert coffee;

        insert new ProductCategoryProduct(
            ProductId = product.Id,
            ProductCategoryId = coffee.Id
        );
    }

    @IsTest
    static void testCreatesDynamicMembership() {

        Test.startTest();

        Database.executeBatch(
            new BatchAutomateBrandAssortmentExtension(),
            1
        );

        Test.stopTest();

        List<BuyerGroupMember> dynamicMembers = [

            SELECT BuyerId,
                   BuyerGroupId,
                   Dynamic__c

            FROM BuyerGroupMember

            WHERE Dynamic__c = TRUE
        ];

        System.assertEquals(
            1,
            dynamicMembers.size()
        );

        System.assert(dynamicMembers[0].Dynamic__c);
    }

    @IsTest
    static void testDisabledBrandProducesNothing() {

        WebshopBrand__c brand = [
            SELECT Id,
                   AssortmentExtensionEnabled__c
            FROM WebshopBrand__c
            LIMIT 1
        ];

        brand.AssortmentExtensionEnabled__c = false;
        update brand;

        Test.startTest();

        Database.executeBatch(
            new BatchAutomateBrandAssortmentExtension(),
            1
        );

        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT()
             FROM BuyerGroupMember
             WHERE Dynamic__c = TRUE]
        );
    }

}