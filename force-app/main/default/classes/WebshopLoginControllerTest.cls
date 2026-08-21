@isTest 
private without sharing class WebshopLoginControllerTest {
    // Helper method to create a test user
    private static User createTestUser(String username) {
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = username,
            Username = username,
            Alias = 'tuser',
            CommunityNickname = 'testuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        return testUser;
    }

    // Test for the login method
    @isTest
    static void testLogin() {
        // Set up test data
        String username = 'testuser@test.com.darboventest';
        String password = 'password123';
        String expectedReturnUrl = Url.getOrgDomainUrl().toExternalForm().replace('.salesforce.', '.site.') + '/' + System.Label.WebshopLoginReturnURL;

        // Create a test user
        User testUser = createTestUser(username);
        WebshopLoginController.login(username, password);
    }

    // Test for the forgotPassword method
    /*
    @isTest
    static void testForgotPassword() {
        // Set up test data
        String username = 'testforgotpassword@test.com';

        // Create a test user
        User testUser = createTestUser(username);

        // Test the forgotPassword method
        Test.startTest();
        Boolean result = WebshopLoginController.forgotPassword(username);
        Test.stopTest();

        // Assertions
        System.assert(result, 'The forgotPassword method should return true for a valid user');
    }
    */

    // Test for forgotPassword method when user is not found
    @isTest
    static void testForgotPasswordUserNotFound() {
        // Set up test data
        String invalidUsername = 'nonexistentuser@test.com';

        // Test the forgotPassword method for a non-existent user
        Test.startTest();
        Boolean result = WebshopLoginController.forgotPassword(invalidUsername);
        Test.stopTest();

        // Assertions
        System.assert(!result, 'The forgotPassword method should return false when the user is not found');
    }

    // Test for login method when login fails
    @isTest
    static void testLoginFailure() {
        // Set up test data
        String invalidUsername = 'invaliduser@test.com';
        String invalidPassword = 'wrongpassword';
        
        // Test the login method with invalid credentials
        Test.startTest();
        Map<String, String> loginResult = WebshopLoginController.login(invalidUsername, invalidPassword);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(System.Label.WebshopLoginErrorMessage, loginResult.get('error'), 'The login method should return the error message for invalid login');
    }

    @isTest
    static void testSetPassword() {
        Test.startTest();
            Boolean result = WebshopLoginController.setPassword('NewSecurePassword123');
        Test.stopTest();
        System.assertEquals(true, result, 'Password should be updated successfully');
    }
}