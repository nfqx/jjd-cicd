/**
* Test for WebshopActiveCustomerCheckBatch
* @author: Stanley Yin (stanley.yin@nfq-x.com), Dec 17, 2023
*
*/

@isTest
private class WebshopActiveCustomerCheckTest {
    @TestSetup
    static void makeData(){        
        Account ac1 = new Account(Name = 'Acc1');
        Account ac2 = new Account(Name = 'Acc2');
        insert new List<Account>{ac1, ac2};
        Contact con = new Contact(AccountId = ac1.Id, Lastname = 'Test', ActiveWebshopUser__c = true);
        insert con;
    }
    @isTest
    private static void testLogic() {      
        Test.startTest();
            Database.executeBatch(new WebshopActiveCustomerCheckBatch(), 2);
        Test.stopTest();
        Account ac1 = [SELECT Id, HasActiveCustomer__c FROM Account WHERE Name = 'Acc1' LIMIT 1];
        Assert.areEqual(ac1.HasActiveCustomer__c, true);
        Account ac2 = [SELECT Id, HasActiveCustomer__c FROM Account WHERE Name = 'Acc2' LIMIT 1];
        Assert.areEqual(ac2.HasActiveCustomer__c, false);
    }
}