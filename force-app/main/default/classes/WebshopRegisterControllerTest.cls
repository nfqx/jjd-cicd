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
}