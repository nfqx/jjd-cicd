@isTest
public with sharing class AccountBrandAssignmentTest {

    @testSetup
    static void setupData() {
        // Create Account
        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;

        // Create Brand
        WebshopBrand__c brand = new WebshopBrand__c(
            Name = 'Test Brand',
            AssortmentExtensionEnabled__c = true
        );
        insert brand;

        // Create Buyer Group linked to Brand
        BuyerGroup bg = new BuyerGroup(
            Name = 'Test Buyer Group',
            Brand__c = brand.Id
        );
        insert bg;
    }

    @isTest
    static void testPopulateUniqueIdentifier() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        WebshopBrand__c brand = [SELECT Id FROM WebshopBrand__c LIMIT 1];
        AccountBrandAssignment__c aba = new AccountBrandAssignment__c(
            Account__c = acc.Id,
            Brand__c = brand.Id
        );

        Test.startTest();
            insert aba;
        Test.stopTest();

        aba = [SELECT Id, UniqueIdentifier__c FROM AccountBrandAssignment__c LIMIT 1];
        System.assertEquals(
            acc.Id + '' + brand.Id,
            aba.UniqueIdentifier__c,
            'UniqueIdentifier should concatenate Account and Brand Ids'
        );
    }

    @isTest
    static void testAssignBuyerGroups() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        WebshopBrand__c brand = [SELECT Id FROM WebshopBrand__c LIMIT 1];
        BuyerAccount buyerAccount = new BuyerAccount(
            BuyerId = acc.Id,
            Name = 'Test Buyer Account',
            IsActive = true
        );
        insert buyerAccount;

        AccountBrandAssignment__c aba = new AccountBrandAssignment__c(
            Account__c = acc.Id,
            Brand__c = brand.Id
        );

        Test.startTest();
            insert aba;
        Test.stopTest();

        List<BuyerGroupMember> members = [
            SELECT Id, BuyerId, BuyerGroupId
            FROM BuyerGroupMember
            WHERE BuyerId = :acc.Id
        ];

        System.assertEquals(1, members.size(), 'BuyerGroupMember should be created');
    }

    @isTest
    static void testUnassignBuyerGroups() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        WebshopBrand__c brand = [SELECT Id FROM WebshopBrand__c LIMIT 1];
        BuyerGroup bg = [SELECT Id FROM BuyerGroup LIMIT 1];
        BuyerAccount buyerAccount = new BuyerAccount(
            BuyerId = acc.Id,
            Name = 'Test Buyer Account',
            IsActive = true
        );
        insert buyerAccount;
        // Insert BuyerGroupMember first
        BuyerGroupMember bgm = new BuyerGroupMember(
            BuyerId = acc.Id,
            BuyerGroupId = bg.Id
        );
        insert bgm;

        AccountBrandAssignment__c aba = new AccountBrandAssignment__c(
            Account__c = acc.Id,
            Brand__c = brand.Id
        );
        insert aba;

        Test.startTest();
            delete aba;
        Test.stopTest();

        List<BuyerGroupMember> members = [
            SELECT Id
            FROM BuyerGroupMember
            WHERE Id = :bgm.Id
        ];

        System.assertEquals(0, members.size(), 'BuyerGroupMember should be deleted');
    }
}