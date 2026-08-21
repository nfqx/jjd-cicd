@isTest
private class BatchAutomateAssortmentExtensionTest {

    @testSetup
    static void setupTestData() {
        //Webstore needs to be created for test, otherwise flow will not run.     
        WebStore webStore2 = new WebStore(
            Name='J.J. Darboven LWR Shop'
        );
        insert webstore2;

        // Create Buyer Group
        BuyerGroup buyerGroup = new BuyerGroup(
            Name = System.Label.WebshopDoNotTranslateTeaAndCocayaEntPolicy
        );
        insert buyerGroup;

        // Account NOT in chain
        Account standaloneAcc = new Account(
            Name = 'Standalone Account'
        );
        insert standaloneAcc;

        BuyerAccount bacc1 = new BuyerAccount(
            BuyerId = standaloneAcc.Id,
            Name = standaloneAcc.Name,
            isActive = true
        );

        insert bacc1;
    }

    @isTest
    static void testBatchExecute() {
        Test.startTest();

            Database.executeBatch(new BatchAutomateAssortmentExtension(), 100);

        Test.stopTest();

        Account standalone = [SELECT Id,
                    Name,
                    AssortmentExtended__c,
                    WebshopFrontpageWarning__c
             FROM Account
             WHERE Name IN ('Standalone Account')];
        System.assertEquals(true, standalone.AssortmentExtended__c);
        System.assertEquals(System.Label.WebshopDoNotTranslateAssortmentExtensionBG, standalone.WebshopFrontpageWarning__c);


        // Verify BuyerGroupMember created for chained account
        List<BuyerGroupMember> members = [
            SELECT Id, BuyerId, BuyerGroupId
            FROM BuyerGroupMember
            WHERE BuyerId = :standalone.Id
        ];

        System.assertEquals(1, members.size());
    }

    @isTest
    static void testSchedulableExecute() {
        Test.startTest();

        String cronExp = '0 0 0 1 1 ? 2099';
        System.schedule(
            'Test BatchAutomateAssortmentExtension Schedule',
            cronExp,
            new BatchAutomateAssortmentExtension()
        );

        Test.stopTest();

        // If no exception is thrown, schedulable path works
        System.assert(true);
    }
}