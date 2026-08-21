@isTest
public with sharing class WebshopBatchCreateActivateBuyerAccTest {
    @isTest 
    private static void testLogic(){
        BuyerGroup bg = new BuyerGroup(Name = 'Standard');
        insert bg;
        WebStore webStore2 = new WebStore(
            Name='J.J. Darboven LWR Shop'
        );
        insert webStore2;
        // Create mock CommerceEntitlementProduct and Account records
        Account acc1 = new Account(Name = 'Test Account 1', ERPCustomerNumber__c = 'CUST001', CreateOrActivateBuyerAccount__c = TRUE);
        insert acc1;
        Test.startTest();
            System.enqueueJob(new WebshopQueueCreateActivateBuyerAccount());
        Test.stopTest();
        Assert.areEqual([SELECT Id FROM BuyerAccount].size(), 1);
    }
}