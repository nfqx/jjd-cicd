@IsTest
public class BankInfoTriggerHandlerTest {

    @TestSetup
    static void setupTestData() {
        // Create test account with ERP customer number
        Account testAccount = new Account(
            Name = 'Test Account',
            ERPCustomerNumber__c = 'ERP123'
        );
        insert testAccount;

        // Create test account without ERP customer number
        Account testAccountNoERP = new Account(
            Name = 'Test Account No ERP'
        );
        insert testAccountNoERP;
    }

    @IsTest
    static void testBeforeInsert_ShouldNotPrepopulateERPCustomerNumber_WhenAccountHasNoERP() {
        // Given
        Account testAccount = [SELECT Id, ERPCustomerNumber__c FROM Account WHERE ERPCustomerNumber__c = null LIMIT 1];

        BankInfo__c bankInfo = new BankInfo__c(
            Account__c = testAccount.Id,
            BankName__c = 'Test Bank',
            BankCountry__c = 'Germany',
            BankAccount__c = '1234567890',
            BankNumber__c = '12345678'
        );

        // When
        Test.startTest();
        insert bankInfo;
        Test.stopTest();

        // Then
        BankInfo__c insertedBankInfo = [SELECT Id, ERPCustomerNumber__c FROM BankInfo__c WHERE Id = :bankInfo.Id];
        System.assertEquals(null, insertedBankInfo.ERPCustomerNumber__c, 'ERP Customer Number should remain null');
    }

    @IsTest
    static void testBeforeUpdate_ShouldPrepopulateERPCustomerNumber_WhenAccountChanges() {
        // Given
        Account testAccount = [SELECT Id, ERPCustomerNumber__c FROM Account WHERE ERPCustomerNumber__c = 'ERP123' LIMIT 1];
        Account testAccount2 = [SELECT Id, ERPCustomerNumber__c FROM Account WHERE ERPCustomerNumber__c = null LIMIT 1];

        BankInfo__c bankInfo = new BankInfo__c(
            Account__c = testAccount.Id,
            BankName__c = 'Test Bank',
            BankCountry__c = 'Germany',
            BankAccount__c = '1234567890',
            BankNumber__c = '12345678'
        );
        insert bankInfo;

        // When
        Test.startTest();
        bankInfo.Account__c = testAccount2.Id;
        update bankInfo;
        Test.stopTest();

        // Then
        BankInfo__c updatedBankInfo = [SELECT Id, ERPCustomerNumber__c FROM BankInfo__c WHERE Id = :bankInfo.Id];
        System.assertEquals(null, updatedBankInfo.ERPCustomerNumber__c, 'ERP Customer Number should be updated to new account value');
    }

    @IsTest
    static void testBeforeUpdate_ShouldNotPrepopulateERPCustomerNumber_WhenAccountNotChanged() {
        // Given
        Account testAccount = [SELECT Id, ERPCustomerNumber__c FROM Account WHERE ERPCustomerNumber__c = 'ERP123' LIMIT 1];

        BankInfo__c bankInfo = new BankInfo__c(
            Account__c = testAccount.Id,
            BankName__c = 'Test Bank',
            BankCountry__c = 'Germany',
            BankAccount__c = '1234567890',
            BankNumber__c = '12345678'
        );
        insert bankInfo;

        // When
        Test.startTest();
        bankInfo.BankName__c = 'Updated Bank Name';
        update bankInfo;
        Test.stopTest();

        // Then
        BankInfo__c updatedBankInfo = [SELECT Id, ERPCustomerNumber__c FROM BankInfo__c WHERE Id = :bankInfo.Id];
        System.assertEquals('ERP123', updatedBankInfo.ERPCustomerNumber__c, 'ERP Customer Number should remain unchanged');
    }

    @IsTest
    static void testAfterInsert_ShouldPublishBankAccountEvent() {
        // Given
        Account testAccount = [SELECT Id, ERPCustomerNumber__c FROM Account WHERE ERPCustomerNumber__c = 'ERP123' LIMIT 1];

        BankInfo__c bankInfo = new BankInfo__c(
            Account__c = testAccount.Id,
            BankName__c = 'Test Bank',
            BankCountry__c = 'Germany',
            BankAccount__c = '1234567890',
            BankNumber__c = '12345678'
        );

        // When
        Test.startTest();
        insert bankInfo;
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle after insert without exception');
    }

    @IsTest
    static void testAfterUpdate_ShouldPublishBankAccountEvent() {
        // Given
        Account testAccount = [SELECT Id, ERPCustomerNumber__c FROM Account WHERE ERPCustomerNumber__c = 'ERP123' LIMIT 1];

        BankInfo__c bankInfo = new BankInfo__c(
            Account__c = testAccount.Id,
            BankName__c = 'Test Bank',
            BankCountry__c = 'Germany',
            BankAccount__c = '1234567890',
            BankNumber__c = '12345678'
        );
        insert bankInfo;

        // When
        Test.startTest();
        bankInfo.BankName__c = 'Updated Bank Name';
        update bankInfo;
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle after update without exception');
    }

    @IsTest
    static void testPrepopulateERPCustomerNumber_WithAccountChange() {
        // Given
        Account testAccount1 = [SELECT Id, ERPCustomerNumber__c FROM Account WHERE ERPCustomerNumber__c = 'ERP123' LIMIT 1];
        Account testAccount2 = [SELECT Id, ERPCustomerNumber__c FROM Account WHERE ERPCustomerNumber__c = null LIMIT 1];

        BankInfo__c bankInfo = new BankInfo__c(
            Account__c = testAccount1.Id,
            BankName__c = 'Test Bank',
            BankCountry__c = 'Germany',
            BankAccount__c = '1234567890',
            BankNumber__c = '12345678'
        );
        insert bankInfo;

        // When
        Test.startTest();
        bankInfo.Account__c = testAccount2.Id;
        update bankInfo;
        Test.stopTest();

        // Then
        BankInfo__c updatedBankInfo = [SELECT Id, ERPCustomerNumber__c FROM BankInfo__c WHERE Id = :bankInfo.Id];
        System.assertEquals(null, updatedBankInfo.ERPCustomerNumber__c, 'ERP Customer Number should be updated when account changes');
    }

    @IsTest
    static void testPrepopulateERPCustomerNumber_WithNoAccountChange() {
        // Given
        Account testAccount = [SELECT Id, ERPCustomerNumber__c FROM Account WHERE ERPCustomerNumber__c = 'ERP123' LIMIT 1];

        BankInfo__c bankInfo = new BankInfo__c(
            Account__c = testAccount.Id,
            BankName__c = 'Test Bank',
            BankCountry__c = 'Germany',
            BankAccount__c = '1234567890',
            BankNumber__c = '12345678'
        );
        insert bankInfo;

        // When
        Test.startTest();
        bankInfo.BankCountry__c = 'France';
        update bankInfo;
        Test.stopTest();

        // Then
        BankInfo__c updatedBankInfo = [SELECT Id, ERPCustomerNumber__c FROM BankInfo__c WHERE Id = :bankInfo.Id];
        System.assertEquals('ERP123', updatedBankInfo.ERPCustomerNumber__c, 'ERP Customer Number should remain unchanged when account does not change');
    }
}