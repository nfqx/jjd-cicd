@isTest 
public without sharing class BatchPopulateFirstContactActivationTest {
    @testSetup
    private static void setupTestData() {
        // Create test accounts
        Account account = new Account(Name = 'Test Account'); //, SalesClassification__c = '1-Customer');
        insert account;

        // Create test contacts and users
        List<Contact> contacts = new List<Contact>();
        List<User> users = new List<User>();
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = account.Id);
        contacts.add(con);
        insert contacts;
        
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User'];
        insert new User(Username = 'testuser' + con.Id + '@test.com',
                            LastName = 'Test',
                            Email = 'testuser' + con.Id + '@test.com',
                            Alias = 'test',
                            TimeZoneSidKey = 'America/Los_Angeles',
                            LocaleSidKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            ProfileId = profiles[0].Id,
                            LanguageLocaleKey = 'en_US',
                            ContactId = con.Id,
                            IsActive = true);
    }

    @isTest 
    private static void testLogic(){
        SchedulableContext sc = null;
        Test.startTest();
            BatchPopulateFirstContactActivationDate.execute(sc);
        Test.stopTest();
        Account acc = [SELECT Id, WebshopFirstContactActivationDate__c FROM Account LIMIT 1];
        Assert.areEqual(acc.WebshopFirstContactActivationDate__c, Date.today());
    }
}