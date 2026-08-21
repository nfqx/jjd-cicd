@IsTest
public class UserTriggerTest {

    @testSetup
    static void setupData() {

        // Create Account + Contact
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(
            LastName = 'Test Contact',
            AccountId = acc.Id,
            ActiveWebshopUser__c = false
        );
        insert con;

        // Get required profile
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User' LIMIT 1];

        // Create User (inactive first)
        User u = new User(
            Username = 'testuser' + System.currentTimeMillis() + '@test.com',
            Email = 'test@test.com',
            LastName = 'Test User',
            Alias = 'tuser',
            TimeZoneSidKey = 'Europe/Berlin',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            IsActive = true,
            ContactId = con.Id
        );
        insert u;
    }

    @IsTest
    static void testActivateUser_setsContactAndFutureUserUpdate() {

        User u = [SELECT Id, IsActive, ContactId FROM User WHERE EMail = 'test@test.com' LIMIT 1];
        Contact c = [SELECT Id, ActiveWebshopUser__c FROM Contact LIMIT 1];

        Test.startTest();

        u.ContactId = c.Id;
        update u;

        Test.stopTest(); // executes @future

        Contact updatedContact = [SELECT Id, ActiveWebshopUser__c FROM Contact WHERE Id = :c.Id];
        User updatedUser = [SELECT Id, ContactId FROM User WHERE Id = :u.Id];

        System.assertEquals(true, updatedContact.ActiveWebshopUser__c,
            'Contact should be activated when User is activated');

        System.assertEquals(c.Id, updatedUser.ContactId,
            'User should store ContactId after activation');
    }

    @IsTest
    static void testDeactivateUser_setsContactFalse() {

        User u = [SELECT Id FROM User WHERE EMail = 'test@test.com' LIMIT 1];
        Contact c = [SELECT Id, ActiveWebshopUser__c FROM Contact LIMIT 1];

        Test.startTest();
            // Now deactivate
            u.IsActive = false;
            u.ContactId = c.Id;
            update u;
        Test.stopTest();

        Contact updatedContact = [SELECT ActiveWebshopUser__c FROM Contact WHERE Id = :c.Id];

        System.assertEquals(false, updatedContact.ActiveWebshopUser__c,
            'Contact should be deactivated when User is deactivated');
    }
    
    @IsTest
    static void testInsertPath_runsSync() {

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User' LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Contact con = new Contact(
            LastName = 'Insert Contact',
            AccountId = acc.Id,
            ActiveWebshopUser__c = false
        );
        insert con;

        Test.startTest();

        User u = new User(
            Username = 'insert' + System.currentTimeMillis() + '@test.com',
            Email = 'insert@test.com',
            LastName = 'Insert User',
            Alias = 'insu',
            TimeZoneSidKey = 'Europe/Berlin',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            IsActive = true,
            ContactId = con.Id
        );

        insert u;

        Test.stopTest();

        Contact updated = [SELECT ActiveWebshopUser__c FROM Contact WHERE Id = :con.Id];

        System.assertEquals(true, updated.ActiveWebshopUser__c,
            'Insert should also trigger Contact update logic');
    }
}