@IsTest
private class ERPSyncRecursionPreventionTest {

    @TestSetup
    static void setupTestData() {
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                ERPCustomerNumber__c = 'ERP' + i,
                ERPLastSyncAt__c = Datetime.now().addDays(-1)
            ));
        }
        insert testAccounts;
    }

    @IsTest
    static void testCheckERPFieldOnlyUpdate_OnlyERPFieldUpdated() {
        // Given
        List<Account> accounts = [
            SELECT Id, Name, ERPCustomerNumber__c, ERPLastSyncAt__c, LastModifiedById
            FROM Account LIMIT 2
        ];

        List<Account> accountsToUpdate = new List<Account>();
        Map<Id, Account> oldAccountsMap = new Map<Id, Account>();

        for (Account acc : accounts) {
            Account updatedAcc = acc.clone(true, true, false, false);
            updatedAcc.ERPLastSyncAt__c = Datetime.now();
            accountsToUpdate.add(updatedAcc);
            oldAccountsMap.put(acc.Id, acc);
        }

        // When
        Test.startTest();
        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
            accountsToUpdate, oldAccountsMap
        );
        Test.stopTest();

        // Then
        System.assertEquals(2, erpUpdatedRecords.size(), 'Should be 2 records with updated ERP fields');
        System.assert(erpUpdatedRecords.contains(accounts[0].Id), 'Should contain first account');
        System.assert(erpUpdatedRecords.contains(accounts[1].Id), 'Should contain second account');
    }

    @IsTest
    static void testCheckERPFieldOnlyUpdate_OtherFieldsUpdated() {
        // Given
        Account account = [
            SELECT Id, Name, ERPCustomerNumber__c, ERPLastSyncAt__c, LastModifiedById
            FROM Account LIMIT 1
        ];

        Account accountToUpdate = account.clone(true, true, false, false);
        accountToUpdate.ERPLastSyncAt__c = Datetime.now();
        accountToUpdate.Name = 'Updated Name';

        Map<Id, Account> oldAccountsMap = new Map<Id, Account>{account.Id => account};

        // When
        Test.startTest();
        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
            new List<Account>{accountToUpdate}, oldAccountsMap
        );
        Test.stopTest();

        // Then
        System.assertEquals(1, erpUpdatedRecords.size(), 'Should be 1 record with updated ERP field');
        System.assert(erpUpdatedRecords.contains(account.Id), 'Should contain account');
    }

    @IsTest
    static void testCheckERPFieldOnlyUpdate_NoERPFieldUpdate() {
        // Given
        Account account = [
            SELECT Id, Name, ERPCustomerNumber__c, ERPLastSyncAt__c, LastModifiedById
            FROM Account LIMIT 1
        ];

        Account accountToUpdate = account.clone(true, true, false, false);
        accountToUpdate.Name = 'Updated Name';

        Map<Id, Account> oldAccountsMap = new Map<Id, Account>{account.Id => account};

        // When
        Test.startTest();
        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
            new List<Account>{accountToUpdate}, oldAccountsMap
        );
        Test.stopTest();

        // Then
        System.assertEquals(0, erpUpdatedRecords.size(), 'Should not be any records with updated ERP fields');
    }

    @IsTest
    static void testCheckERPFieldOnlyUpdate_ERPFieldNotChanged() {
        // Given
        Account account = [
            SELECT Id, Name, ERPCustomerNumber__c, ERPLastSyncAt__c, LastModifiedById
            FROM Account LIMIT 1
        ];

        Account accountToUpdate = account.clone(true, true, false, false);

        Map<Id, Account> oldAccountsMap = new Map<Id, Account>{account.Id => account};

        // When
        Test.startTest();
        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
            new List<Account>{accountToUpdate}, oldAccountsMap
        );
        Test.stopTest();

        // Then
        System.assertEquals(0, erpUpdatedRecords.size(), 'Should not be any records with updated ERP fields');
    }

    @IsTest
    static void testCheckERPFieldOnlyUpdate_NullParameters() {
        // Given
        // When
        Test.startTest();
        Set<Id> result1 = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(null, null);
        Set<Id> result2 = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(new List<Account>(), null);
        Set<Id> result3 = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(null, new Map<Id, Account>());
        Test.stopTest();

        // Then
        System.assertEquals(0, result1.size(), 'Result with null parameters should be empty');
        System.assertEquals(0, result2.size(), 'Result with null oldRecordsMap should be empty');
        System.assertEquals(0, result3.size(), 'Result with null newRecords should be empty');
    }

    @IsTest
    static void testCheckERPFieldOnlyUpdate_EmptyCollections() {
        // Given
        List<Account> emptyAccounts = new List<Account>();
        Map<Id, Account> emptyMap = new Map<Id, Account>();

        // When
        Test.startTest();
        Set<Id> result = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(emptyAccounts, emptyMap);
        Test.stopTest();

        // Then
        System.assertEquals(0, result.size(), 'Result with empty collections should be empty');
    }

    @IsTest
    static void testCheckERPFieldOnlyUpdate_RecordWithoutERPField() {
        // Given
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com'
        );
        insert testContact;

        Contact contactToUpdate = testContact.clone(true, true, false, false);
        contactToUpdate.FirstName = 'Updated';

        Map<Id, Contact> oldContactsMap = new Map<Id, Contact>{testContact.Id => testContact};

        // When
        Test.startTest();
        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
            new List<Contact>{contactToUpdate}, oldContactsMap
        );
        Test.stopTest();

        // Then
        System.assertEquals(0, erpUpdatedRecords.size(), 'Should not be any records with updated ERP fields');
    }

    @IsTest
    static void testCheckERPFieldOnlyUpdate_MixedUpdates() {
        // Given
        List<Account> accounts = [
            SELECT Id, Name, ERPCustomerNumber__c, ERPLastSyncAt__c, LastModifiedById
            FROM Account LIMIT 2
        ];

        List<Account> accountsToUpdate = new List<Account>();
        Map<Id, Account> oldAccountsMap = new Map<Id, Account>();

        Account acc1 = accounts[0].clone(true, true, false, false);
        acc1.ERPLastSyncAt__c = Datetime.now();
        accountsToUpdate.add(acc1);
        oldAccountsMap.put(accounts[0].Id, accounts[0]);

        Account acc2 = accounts[1].clone(true, true, false, false);
        acc2.ERPLastSyncAt__c = Datetime.now();
        acc2.Name = 'Updated Name';
        accountsToUpdate.add(acc2);
        oldAccountsMap.put(accounts[1].Id, accounts[1]);

        // When
        Test.startTest();
        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
            accountsToUpdate, oldAccountsMap
        );
        Test.stopTest();

        // Then
        System.assertEquals(2, erpUpdatedRecords.size(), 'Should be 2 records with updated ERP fields');
        System.assert(erpUpdatedRecords.contains(accounts[0].Id), 'Should contain first account');
        System.assert(erpUpdatedRecords.contains(accounts[1].Id), 'Should contain second account');
    }

    @IsTest
    static void testCheckERPFieldOnlyUpdate_DatetimeFieldComparison() {
        // Given
        Account account = [
            SELECT Id, Name, ERPCustomerNumber__c, ERPLastSyncAt__c, LastModifiedById
            FROM Account LIMIT 1
        ];

        Account accountToUpdate = account.clone(true, true, false, false);
        accountToUpdate.ERPLastSyncAt__c = Datetime.now().addHours(1);

        Map<Id, Account> oldAccountsMap = new Map<Id, Account>{account.Id => account};

        // When
        Test.startTest();
        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
            new List<Account>{accountToUpdate}, oldAccountsMap
        );
        Test.stopTest();

        // Then
        System.assertEquals(1, erpUpdatedRecords.size(), 'Should be 1 record with updated ERP field');
        System.assert(erpUpdatedRecords.contains(account.Id), 'Should contain account');
    }

    @IsTest
    static void testCheckERPFieldOnlyUpdate_ERPFieldFromNullToValue() {
        // Given
        Account account = [
            SELECT Id, Name, ERPCustomerNumber__c, ERPLastSyncAt__c, LastModifiedById
            FROM Account LIMIT 1
        ];

        account.ERPLastSyncAt__c = null;
        update account;

        Account accountToUpdate = account.clone(true, true, false, false);
        accountToUpdate.ERPLastSyncAt__c = Datetime.now();

        Map<Id, Account> oldAccountsMap = new Map<Id, Account>{account.Id => account};

        // When
        Test.startTest();
        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
            new List<Account>{accountToUpdate}, oldAccountsMap
        );
        Test.stopTest();

        // Then
        System.assertEquals(1, erpUpdatedRecords.size(), 'Should be 1 record with updated ERP field');
        System.assert(erpUpdatedRecords.contains(account.Id), 'Should contain account');
    }

    @IsTest
    static void testCheckERPFieldOnlyUpdate_ERPFieldFromValueToNull() {
        // Given
        Account account = [
            SELECT Id, Name, ERPCustomerNumber__c, ERPLastSyncAt__c, LastModifiedById
            FROM Account LIMIT 1
        ];

        Account accountToUpdate = account.clone(true, true, false, false);
        accountToUpdate.ERPLastSyncAt__c = null;

        Map<Id, Account> oldAccountsMap = new Map<Id, Account>{account.Id => account};

        // When
        Test.startTest();
        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
            new List<Account>{accountToUpdate}, oldAccountsMap
        );
        Test.stopTest();

        // Then
        System.assertEquals(1, erpUpdatedRecords.size(), 'Should be 1 record with updated ERP field');
        System.assert(erpUpdatedRecords.contains(account.Id), 'Should contain account');
    }

    @IsTest
    static void testCheckERPFieldOnlyUpdate_OnlyERPFieldsNoOtherChanges() {
        // Given
        Account account = [
            SELECT Id, Name, ERPCustomerNumber__c, ERPLastSyncAt__c, LastModifiedById
            FROM Account LIMIT 1
        ];

        Account accountToUpdate = account.clone(true, true, false, false);
        accountToUpdate.ERPLastSyncAt__c = Datetime.now();

        System.assertEquals(account.Name, accountToUpdate.Name, 'Name should not change');
        System.assertEquals(account.ERPCustomerNumber__c, accountToUpdate.ERPCustomerNumber__c, 'ERPCustomerNumber__c should not change');

        Map<Id, Account> oldAccountsMap = new Map<Id, Account>{account.Id => account};

        // When
        Test.startTest();
        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
            new List<Account>{accountToUpdate}, oldAccountsMap
        );
        Test.stopTest();

        // Then
        System.assertEquals(1, erpUpdatedRecords.size(), 'Should be 1 record with updated ERP field');
        System.assert(erpUpdatedRecords.contains(account.Id), 'Should contain account');

        System.assertNotEquals(account.ERPLastSyncAt__c, accountToUpdate.ERPLastSyncAt__c, 'ERP field should change');
    }

    @IsTest
    static void testCheckERPFieldOnlyUpdate_RecordNotFoundInOldMap() {
        // Given
        Account account = [
            SELECT Id, Name, ERPCustomerNumber__c, ERPLastSyncAt__c, LastModifiedById
            FROM Account LIMIT 1
        ];

        Account accountToUpdate = account.clone(true, true, false, false);
        accountToUpdate.ERPLastSyncAt__c = Datetime.now();

        Map<Id, Account> oldAccountsMap = new Map<Id, Account>();

        // When
        Test.startTest();
        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
            new List<Account>{accountToUpdate}, oldAccountsMap
        );
        Test.stopTest();

        // Then
        System.assertEquals(0, erpUpdatedRecords.size(), 'Should not be any records with updated ERP fields when old record not found');
    }

    @IsTest
    static void testERPFieldConfig_Constructor() {
        // When
        Test.startTest();
        ERPSyncRecursionPrevention.ERPFieldConfig config = new ERPSyncRecursionPrevention.ERPFieldConfig('TestField', Schema.DisplayType.STRING);
        Test.stopTest();

        // Then
        System.assertEquals('TestField', config.fieldName, 'Field name should be set correctly');
        System.assertEquals(Schema.DisplayType.STRING, config.fieldType, 'Field type should be set correctly');
    }

    @IsTest
    static void testFieldValueChanged_WithNullValues() {
        // Given
        Account account = [
            SELECT Id, Name, ERPCustomerNumber__c, ERPLastSyncAt__c, LastModifiedById
            FROM Account LIMIT 1
        ];

        Account accountToUpdate = account.clone(true, true, false, false);
        accountToUpdate.ERPLastSyncAt__c = null;

        Map<Id, Account> oldAccountsMap = new Map<Id, Account>{account.Id => account};

        // When
        Test.startTest();
        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
            new List<Account>{accountToUpdate}, oldAccountsMap
        );
        Test.stopTest();

        // Then
        System.assertEquals(1, erpUpdatedRecords.size(), 'Should detect change from value to null');
    }

    @IsTest
    static void testFieldValueChanged_WithSameValues() {
        // Given
        Account account = [
            SELECT Id, Name, ERPCustomerNumber__c, ERPLastSyncAt__c, LastModifiedById
            FROM Account LIMIT 1
        ];

        Account accountToUpdate = account.clone(true, true, false, false);
        // Keep same value
        accountToUpdate.ERPLastSyncAt__c = account.ERPLastSyncAt__c;

        Map<Id, Account> oldAccountsMap = new Map<Id, Account>{account.Id => account};

        // When
        Test.startTest();
        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
            new List<Account>{accountToUpdate}, oldAccountsMap
        );
        Test.stopTest();

        // Then
        System.assertEquals(0, erpUpdatedRecords.size(), 'Should not detect change when values are the same');
    }

    @IsTest
    static void testCheckERPFieldOnlyUpdate_WithDifferentFieldTypes() {
        // Given
        Account oldAccount = new Account(
            Id = '001000000000001',
            Name = 'Old Account',
            BillingCity = 'Old City',
            BillingStreet = 'Old Street',
            BillingPostalCode = '12345',
            BillingCountry = 'Old Country',
            ERPCustomerNumber__c = 'ERP123',
            ERPLockStatus__c = 'Old Status'
        );

        Account newAccount = new Account(
            Id = '001000000000001',
            Name = 'New Account',
            BillingCity = 'New City',
            BillingStreet = 'New Street',
            BillingPostalCode = '67890',
            BillingCountry = 'New Country',
            ERPCustomerNumber__c = 'ERP456',
            ERPLockStatus__c = 'New Status'
        );

        List<SObject> newRecords = new List<SObject>{newAccount};
        Map<Id, SObject> oldRecordsMap = new Map<Id, SObject>{oldAccount.Id => oldAccount};

        // When
        Test.startTest();
        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(newRecords, oldRecordsMap);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, erpUpdatedRecords, 'Result should not be null');
        System.assertEquals(0, erpUpdatedRecords.size(), 'Should not detect ERP field changes when no ERP fields defined for this object type');
    }

    @IsTest
    static void testCheckERPFieldOnlyUpdate_WithMixedFieldChanges() {
        // Given
        Account oldAccount = new Account(
            Id = '001000000000001',
            Name = 'Old Account',
            BillingCity = 'Old City',
            ERPCustomerNumber__c = 'ERP123'
        );

        Account newAccount = new Account(
            Id = '001000000000001',
            Name = 'New Account', // Non-ERP field changed
            BillingCity = 'New City', // Non-ERP field changed
            ERPCustomerNumber__c = 'ERP123' // ERP field unchanged
        );

        List<SObject> newRecords = new List<SObject>{newAccount};
        Map<Id, SObject> oldRecordsMap = new Map<Id, SObject>{oldAccount.Id => oldAccount};

        // When
        Test.startTest();
        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(newRecords, oldRecordsMap);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, erpUpdatedRecords, 'Result should not be null');
        System.assertEquals(0, erpUpdatedRecords.size(), 'Should not detect ERP field only update when other fields changed');
    }

    @IsTest
    static void testCheckERPFieldOnlyUpdate_WithSingleERPFieldChange() {
        // Given
        Account oldAccount = new Account(
            Id = '001000000000001',
            Name = 'Test Account',
            BillingCity = 'Test City',
            ERPCustomerNumber__c = 'ERP123'
        );

        Account newAccount = new Account(
            Id = '001000000000001',
            Name = 'Test Account', // Unchanged
            BillingCity = 'Test City', // Unchanged
            ERPCustomerNumber__c = 'ERP456' // Only ERP field changed
        );

        List<SObject> newRecords = new List<SObject>{newAccount};
        Map<Id, SObject> oldRecordsMap = new Map<Id, SObject>{oldAccount.Id => oldAccount};

        // When
        Test.startTest();
        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(newRecords, oldRecordsMap);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, erpUpdatedRecords, 'Result should not be null');
        System.assertEquals(0, erpUpdatedRecords.size(), 'Should not detect ERP field changes when no ERP fields defined for this object type');
    }

    @IsTest
    static void testCheckERPFieldOnlyUpdate_WithNoERPFields() {
        // Given
        Account oldAccount = new Account(
            Id = '001000000000001',
            Name = 'Old Account',
            BillingCity = 'Old City'
        );

        Account newAccount = new Account(
            Id = '001000000000001',
            Name = 'New Account',
            BillingCity = 'New City'
        );

        List<SObject> newRecords = new List<SObject>{newAccount};
        Map<Id, SObject> oldRecordsMap = new Map<Id, SObject>{oldAccount.Id => oldAccount};

        // When
        Test.startTest();
        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(newRecords, oldRecordsMap);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, erpUpdatedRecords, 'Result should not be null');
        System.assertEquals(0, erpUpdatedRecords.size(), 'Should return empty set when no ERP fields defined');
    }

    @IsTest
    static void testCheckERPFieldOnlyUpdate_WithNullERPFields() {
        // Given
        Account oldAccount = new Account(
            Id = '001000000000001',
            Name = 'Old Account',
            BillingCity = 'Old City'
        );

        Account newAccount = new Account(
            Id = '001000000000001',
            Name = 'New Account',
            BillingCity = 'New City'
        );

        List<SObject> newRecords = new List<SObject>{newAccount};
        Map<Id, SObject> oldRecordsMap = new Map<Id, SObject>{oldAccount.Id => oldAccount};

        // When
        Test.startTest();
        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(newRecords, oldRecordsMap);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, erpUpdatedRecords, 'Result should not be null');
        System.assertEquals(0, erpUpdatedRecords.size(), 'Should return empty set when ERP fields is null');
    }

    @IsTest
    static void testCheckERPFieldOnlyUpdate_WithDifferentSObjectTypes() {
        // Given
        Contact oldContact = new Contact(
            Id = '003000000000001',
            FirstName = 'Old',
            LastName = 'Contact',
            Email = 'old@test.com'
        );

        Contact newContact = new Contact(
            Id = '003000000000001',
            FirstName = 'New',
            LastName = 'Contact',
            Email = 'new@test.com'
        );

        List<SObject> newRecords = new List<SObject>{newContact};
        Map<Id, SObject> oldRecordsMap = new Map<Id, SObject>{oldContact.Id => oldContact};

        // When
        Test.startTest();
        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(newRecords, oldRecordsMap);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, erpUpdatedRecords, 'Result should not be null');
        System.assertEquals(0, erpUpdatedRecords.size(), 'Should not detect ERP field changes when no ERP fields defined for Contact object');
    }

    @IsTest
    static void testIntegrationUserUpdate_SuppressedWithoutERPFieldChange() {
        //Having
        Account account = [
            SELECT Id, ERPCustomerNumber__c, ERPLastSyncAt__c, LastModifiedById
            FROM Account LIMIT 1
        ];
        Map<Id, Account> oldAccountsMap = new Map<Id, Account>{account.Id => account};

        // Simulate account-link PATCH: only non-ERP fields updated, ERPLastSyncAt__c unchanged
        update new Account(Id = account.Id, ParentId = null);

        Account updatedAccount = [
            SELECT Id, ERPCustomerNumber__c, ERPLastSyncAt__c, LastModifiedById
            FROM Account WHERE Id = :account.Id
        ];
        ERPSyncRecursionPrevention.testIntegrationUsername = UserInfo.getUserName();

        //When
        Test.startTest();
        Set<Id> result = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
            new List<Account>{updatedAccount}, oldAccountsMap
        );
        Test.stopTest();

        //Then
        System.assertEquals(1, result.size(), 'Integration user update should be suppressed even without ERPLastSyncAt__c change');
        System.assert(result.contains(account.Id), 'Should contain account updated by integration user');
    }

    @IsTest
    static void testNonIntegrationUserUpdate_NotSuppressedWithoutERPFieldChange() {
        //Having
        Account account = [
            SELECT Id, ERPCustomerNumber__c, ERPLastSyncAt__c, LastModifiedById
            FROM Account LIMIT 1
        ];
        Map<Id, Account> oldAccountsMap = new Map<Id, Account>{account.Id => account};

        update new Account(Id = account.Id, ParentId = null);

        Account updatedAccount = [
            SELECT Id, ERPCustomerNumber__c, ERPLastSyncAt__c, LastModifiedById
            FROM Account WHERE Id = :account.Id
        ];
        ERPSyncRecursionPrevention.testIntegrationUsername = 'nonexistent.integration@darboven.example.com';

        //When
        Test.startTest();
        Set<Id> result = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
            new List<Account>{updatedAccount}, oldAccountsMap
        );
        Test.stopTest();

        //Then
        System.assertEquals(0, result.size(), 'Non-integration user update without ERP field change must not be suppressed');
    }

    // Insert context (oldRecordsMap == null). Before this was handled, checkERPFieldOnlyUpdate
    // returned an empty set for every insert, so nothing created by the integration - records
    // arriving from SAP, and everything written by an initial data migration - was ever
    // suppressed, and each one published a platform event straight back to the ERP.

    @IsTest
    static void testInsert_SuppressedForIntegrationUser() {
        //Having
        List<Account> accounts = [
            SELECT Id, ERPCustomerNumber__c, ERPLastSyncAt__c, LastModifiedById
            FROM Account LIMIT 2
        ];
        ERPSyncRecursionPrevention.testIntegrationUsername = UserInfo.getUserName();

        //When
        Test.startTest();
        Set<Id> result = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(accounts, null);
        Test.stopTest();

        //Then
        System.assertEquals(2, result.size(), 'Records inserted by the integration user must be suppressed on insert');
        System.assert(result.contains(accounts[0].Id), 'Should contain first inserted account');
        System.assert(result.contains(accounts[1].Id), 'Should contain second inserted account');
    }

    @IsTest
    static void testInsert_SuppressedByERPSyncMarker() {
        //Having
        // @TestSetup populates ERPLastSyncAt__c, which is the marker of ERP origin when there
        // is no old record to diff against.
        Account account = [
            SELECT Id, ERPCustomerNumber__c, ERPLastSyncAt__c, LastModifiedById
            FROM Account LIMIT 1
        ];
        System.assertNotEquals(null, account.ERPLastSyncAt__c, 'Precondition: ERPLastSyncAt__c must be populated');
        ERPSyncRecursionPrevention.testIntegrationUsername = 'nonexistent.integration@darboven.example.com';

        //When
        Test.startTest();
        Set<Id> result = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
            new List<Account>{account}, null
        );
        Test.stopTest();

        //Then
        System.assertEquals(1, result.size(), 'A populated ERPLastSyncAt__c should suppress on insert regardless of who created the record');
        System.assert(result.contains(account.Id), 'Should contain the ERP-originated account');
    }

    @IsTest
    static void testInsert_NotSuppressedForUserCreatedRecord() {
        //Having
        // The record a person creates in the UI: no ERP sync marker, not the integration user.
        // This is what must keep reaching the ERP - if this test ever fails, the recursion
        // guard has started swallowing genuine Salesforce-to-ERP events.
        Account userCreated = new Account(
            Name = 'User Created Account',
            ERPCustomerNumber__c = 'ERP-USER-1',
            ERPLastSyncAt__c = null
        );
        insert userCreated;

        Account inserted = [
            SELECT Id, ERPCustomerNumber__c, ERPLastSyncAt__c, LastModifiedById
            FROM Account WHERE Id = :userCreated.Id
        ];
        ERPSyncRecursionPrevention.testIntegrationUsername = 'nonexistent.integration@darboven.example.com';

        //When
        Test.startTest();
        Set<Id> result = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
            new List<Account>{inserted}, null
        );
        Test.stopTest();

        //Then
        System.assertEquals(0, result.size(), 'A record created by a user without an ERP sync marker must still be published to the ERP');
    }

    @IsTest
    static void testNonIntegrationUserUpdate_SuppressedByERPFieldChange() {
        //Having
        Account account = [
            SELECT Id, ERPCustomerNumber__c, ERPLastSyncAt__c, LastModifiedById
            FROM Account LIMIT 1
        ];

        Account updatedAccount = account.clone(true, true, true, false);
        updatedAccount.ERPLastSyncAt__c = Datetime.now();

        Map<Id, Account> oldAccountsMap = new Map<Id, Account>{account.Id => account};
        ERPSyncRecursionPrevention.testIntegrationUsername = 'nonexistent.integration@darboven.example.com';

        //When
        Test.startTest();
        Set<Id> result = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
            new List<Account>{updatedAccount}, oldAccountsMap
        );
        Test.stopTest();

        //Then
        System.assertEquals(1, result.size(), 'ERPLastSyncAt__c change should suppress regardless of who modified the record');
        System.assert(result.contains(account.Id), 'Should contain account with changed ERPLastSyncAt__c');
    }
}