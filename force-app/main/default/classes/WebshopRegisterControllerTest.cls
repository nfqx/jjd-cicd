@isTest 
private without sharing class WebshopRegisterControllerTest {
    @testSetup
    static void setup() {
        WebStore webstore = new WebStore(Name = System.Label.WebshopDoNotTranslateStoreName);
        insert webstore;
        // Create mock Accounts
        Account activeAccount = new Account(Name = 'Active Account', WebshopRegistrationActivated__c = true, BillingPostalCode = '12345');
        Account inactiveAccount = new Account(Name = 'Inactive Account', WebshopRegistrationActivated__c = false, ShippingPostalCode = '67890');
        insert new List<Account>{activeAccount, inactiveAccount};
    }

    /*
    @isTest
    static void testActivateAccountForRegistration() {
        Account account = [SELECT Id, WebshopRegistrationActivated__c FROM Account WHERE WebshopRegistrationActivated__c = false LIMIT 1];

        Test.startTest();
        Boolean result = WebshopRegisterController.activateAccountForRegistration(account.Id);
        Test.stopTest();

        System.assertEquals(true, result, 'Account should be activated successfully');
        Account updatedAccount = [SELECT Id, WebshopRegistrationActivated__c FROM Account WHERE Id = :account.Id];
        System.assertEquals(true, updatedAccount.WebshopRegistrationActivated__c, 'Account should have WebshopRegistrationActivated__c set to true');
    }

    @isTest
    static void testVerifyRegistrationActivationSuccess() {
        Account account = [SELECT Id FROM Account WHERE WebshopRegistrationActivated__c = true LIMIT 1];

        Test.startTest();
        Boolean result = WebshopRegisterController.verifyRegistrationActivation(account.Id);
        Test.stopTest();

        System.assertEquals(true, result, 'Registration activation should be verified and deactivated successfully');
        Account updatedAccount = [SELECT Id, WebshopRegistrationActivated__c FROM Account WHERE Id = :account.Id];
        System.assertEquals(false, updatedAccount.WebshopRegistrationActivated__c, 'Account should have WebshopRegistrationActivated__c set to false');
    }
    */

    @isTest
    static void testVerifyRegistrationActivationFailure() {
        Account account = [SELECT Id FROM Account WHERE WebshopRegistrationActivated__c = false LIMIT 1];

        Test.startTest();
        Boolean result = WebshopRegisterController.verifyRegistrationActivation(account.Id);
        Test.stopTest();

        System.assertEquals(false, result, 'Verification should fail for inactive accounts');
    }

    @isTest
    static void testVerifyAccount() {
        Account account = [SELECT Id, BillingPostalCode FROM Account WHERE BillingPostalCode != null LIMIT 1];

        Test.startTest();
        Boolean result = WebshopRegisterController.verifyAccount(account.BillingPostalCode, account.Id);
        Test.stopTest();

        System.assertEquals(true, result, 'Account verification should succeed with correct postal code');
    }

    @isTest
    static void testVerifyAccountFalse() {
        Account account = [SELECT Id, BillingPostalCode FROM Account WHERE BillingPostalCode != null LIMIT 1];

        Test.startTest();
        Boolean falseResult = WebshopRegisterController.verifyAccount('99999', account.Id);
        Test.stopTest();

        System.assertEquals(false, falseResult, 'Account verification should fail with incorrect postal code');
    }

    /*
    @isTest
    static void testCheckAccountNumberNotFound() {
        // Setup test data
        String accountNumber = '12345';
        String email = 'test@example.com';
        String baseUrl = 'https://example.com';

        // Create a test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            ERPCustomerNumber__c = '001-' + accountNumber,
            WebshopRegistrationActivated__c = false
        );
        insert testAccount;

        // Test case: Account not found
        Test.startTest();
        String resultNotFound = WebshopRegisterController.checkAccountNumber('99999', email, baseUrl);
        Test.stopTest();

        System.assertEquals('not_found', resultNotFound, 'Result should be not_found.');
    }

    @isTest
    static void testCheckAccountNumberSuccess() {
        // Setup test data
        String accountNumber = '12345';
        String email = 'test@example.com';
        String baseUrl = 'https://example.com';

        // Create a test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            ERPCustomerNumber__c = '001-' + accountNumber,
            WebshopRegistrationActivated__c = false
        );
        insert testAccount;

        // Test case: Account is found and not already active
        Test.startTest();
        String resultSuccess = WebshopRegisterController.checkAccountNumber(accountNumber, email, baseUrl);
        Test.stopTest();

        // Verify the account was updated
        Account updatedAccount = [SELECT WebshopRegistrationActivated__c FROM Account WHERE Id = :testAccount.Id];
        System.assert(updatedAccount.WebshopRegistrationActivated__c, 'Account should be marked as active.');

        // Verify method result
        System.assertEquals('success', resultSuccess, 'Result should be success.');
    }

    @isTest
    static void testCheckShowGLPage_UserHasPermissionSet() {
        User testUser = [SELECT Id FROM User WHERE Id = : UserInfo.getUserId()];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = :System.Label.WebshopDoNotTranslatePermissionSetName LIMIT 1];

        if (ps == null) {
            ps = new PermissionSet(Name = System.Label.WebshopDoNotTranslatePermissionSetName);
            insert ps;
        }

        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = ps.Id
        );
        insert psa;

        Test.startTest();
        Boolean result = WebshopRegisterController.checkShowGLPage();
        Test.stopTest();

        System.assertEquals(true, result, 'Expected checkShowGLPage to return true when user has permission set.');
    }
    */

    @isTest
    static void testCheckShowGLPage_UserWithoutPermissionSet() {
        Test.startTest();
        Boolean result = WebshopRegisterController.checkShowGLPage();
        Test.stopTest();

        System.assertEquals(false, result, 'Expected checkShowGLPage to return false when user does not have permission set.');
    }

    @isTest
    static void testCheckRegisterUser_NoAccountFound() {
        Test.startTest();
        String result = WebshopRegisterController.checkRegisterUser(
            'Alice',
            'Brown',
            'alicebrown@gmail.com',
            '1231231234',
            'nonexistentAccountId',
            true
        );
        Test.stopTest();

        System.assertEquals('no_account_found', result, 'Expected checkRegisterUser to return no_account_found.');
    }

    @isTest
    static void testCheckRegisterUser_NotActivated() {
        Account inactiveAccount = [SELECT Id FROM Account WHERE Name = 'Inactive Account' LIMIT 1];
        Contact contact = new Contact(
            FirstName = 'In2active',
            LastName = 'Us2er',
            AccountId = inactiveAccount.Id,
            Email = UserInfo.getUserEmail(),
            WebshopCustomer__c = false
        );
        insert contact;

        Test.startTest();
        String result = WebshopRegisterController.checkRegisterUser(
            'Inactive',
            'User',
            UserInfo.getUserEmail(),
            '6666666666',
            inactiveAccount.Id,
            true
        );
        Test.stopTest();

        System.assertEquals('no_contact_or_not_webshop_customer', result, 'Expected checkRegisterUser to return no_contact_or_not_webshop_customer.');
    }
}