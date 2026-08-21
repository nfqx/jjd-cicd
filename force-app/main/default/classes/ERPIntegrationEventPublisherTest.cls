@IsTest
public class ERPIntegrationEventPublisherTest {

    public static Integer newAccountEventsCount = 0;
    public static Integer contactChangedEventsCount = 0;
    public static Integer accountChangedEventsCount = 0;
    public static Integer bankAccountsCreated = 0;
    public static Integer bankAccountsUpdated = 0;
    public static Integer accountContactRelationEventsCount = 0;
    public static Integer accountContactRelationChangedEventsCount = 0;

    @TestSetup
    static void setup() {
        Account testAccount1 = new Account(
            Name = 'Test Account 1',
            ERPCustomerNumber__c = null,
            ERPLockStatus__c = 'Sanction List'
        );
        Account testAccount2 = new Account(
            Name = 'Test Account 2',
            ERPCustomerNumber__c = 'CUST123',
            ERPLockStatus__c = null
        );
        Account testAccount3 = new Account(
            Name = 'Test Account 3',
            ERPCustomerNumber__c = 'CUST1233',
            ERPLockStatus__c = 'Credit Rating'
        );
        insert new List<Account>{testAccount1, testAccount2, testAccount3};

        Contact testContact1 = new Contact(
            FirstName = 'Test',
            LastName = 'Contact 1',
            AccountId = testAccount1.Id
        );
        Contact testContact2 = new Contact(
            FirstName = 'Test',
            LastName = 'Contact 2',
            AccountId = testAccount2.Id
        );
        insert new List<Contact>{testContact1, testContact2};

        Opportunity testOpportunity1 = new Opportunity(
            Name = 'Test Opp 1',
            StageName = 'Qualifizierung',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount1.Id
        );
        Opportunity testOpportunity2 = new Opportunity(
            Name = 'Test Opp 2',
            StageName = 'Qualifizierung',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount2.Id
        );
        insert new List<Opportunity>{testOpportunity1, testOpportunity2};
    }

    public static void mockEventBusPublish(List<SObject> events) {
        if (events == null || events.isEmpty()) return;

        for (SObject event : events) {
            if (event instanceof NewAccount__e) {
                newAccountEventsCount++;
            } else if (event instanceof ContactChanged__e) {
                contactChangedEventsCount++;
            } else if (event instanceof AccountChanged__e) {
                accountChangedEventsCount++;
            } else if (event instanceof BankAccountCreated__e) {
                bankAccountsCreated++;
            } else if (event instanceof BankAccountUpdated__e) {
                bankAccountsUpdated++;
            } else if (event instanceof AccountContactRelationCreated__e) {
                accountContactRelationEventsCount++;
            } else if (event instanceof AccountContactRelationChanged__e) {
                accountContactRelationChangedEventsCount++;
            }
        }
    }

    @IsTest
    static void publishNewAccountEvent_WhenOpportunityStageChangesToQualified() {
        //Having
        Account testAccount = [SELECT Id FROM Account WHERE ERPCustomerNumber__c = null AND ERPLockStatus__c != 'Not Sanctioned' LIMIT 1];
        Opportunity testOpp = [SELECT Id, StageName, Name FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];

        //When
        Test.startTest();
        testOpp.StageName = 'Angebotsphase';
        update testOpp;
        Test.stopTest();

        //Then
        System.assertEquals(1, newAccountEventsCount, 'Should publish one NewAccount__e event');
        System.assertEquals(0, contactChangedEventsCount, 'Should not publish contact changed events');
        System.assertEquals(0, accountChangedEventsCount, 'Should not publish account changed events');
        System.assertEquals(0, bankAccountsCreated, 'Should not publish bank account created events');
        System.assertEquals(0, bankAccountsUpdated, 'Should not publish bank account updated events');
    }

    @IsTest
    static void returnValidAccounts_WhenGettingNewAccountsForERP() {
        //Having
        Account testAccount1 = [SELECT Id FROM Account WHERE ERPCustomerNumber__c = null AND ERPLockStatus__c != 'Credit Rating' LIMIT 1];
        Account testAccount3 = [SELECT Id FROM Account WHERE ERPLockStatus__c = 'Credit Rating' LIMIT 1];
        Set<Id> accountIds = new Set<Id>{testAccount1.Id, testAccount3.Id};

        //When
        Test.startTest();
        List<Account> result = ERPIntegrationEventPublisher.getNewAccountsForERP(accountIds);
        Test.stopTest();

        //Then
        System.assertEquals(1, result.size(), 'Should return exactly one account');
        System.assertEquals(testAccount1.Id, result[0].Id, 'Returned incorrect account');
    }

    @IsTest
    static void mapAllBankAccountFieldsWithoutERPInternalBankId_ShouldPublishBankAccountsCreated() {
        // Having
        Account testAccount = [SELECT Id, ERPCustomerNumber__c FROM Account WHERE ERPCustomerNumber__c != null LIMIT 1];

        // When
        Test.startTest();
        BankInfo__c bankAccount = new BankInfo__c(
            Account__c = testAccount.Id,
            ERPCustomerNumber__c = testAccount.ERPCustomerNumber__c,
            BankCountry__c = 'Germany',
            BankName__c = 'Test Bank',
            BankNumber__c = '12345678',
            SwiftCode__c = 'TESTDEFF',
            BankControlKey__c = '12',
            BankAccountHolderName__c = 'Test Holder',
            BankAccountName__c = 'Test Account',
            ValidFrom__c = Date.today(),
            ValidTo__c = Date.today().addYears(1),
            IBAN__c = 'DE89370400440532013000',
            IBANValidFrom__c = Date.today(),
            BankAccount__c = '1234567890',
            BankAccountReferenceText__c = 'Test Reference',
            DirectDebitAuthorization__c = true,
            City__c = 'Berlin'
        );
        insert bankAccount;
        Test.stopTest();

        // Then
        System.assertEquals(1, ERPIntegrationEventPublisherTest.bankAccountsCreated,
            'Should publish one BankAccountCreated__e event'
        );
    }

    @IsTest
    static void testSendNewAccountToERPOnOpportunityQualified_WithNullParameters() {
        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendNewAccountToERPOnOpportunityQualified(null, null);
        ERPIntegrationEventPublisher.sendNewAccountToERPOnOpportunityQualified(new Map<Id, Opportunity>(), null);
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle null parameters gracefully');
    }

    @IsTest
    static void testSendNewAccountToERPOnOpportunityQualified_WithEmptyMap() {
        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendNewAccountToERPOnOpportunityQualified(new Map<Id, Opportunity>(), null);
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle empty map gracefully');
    }

    @IsTest
    static void testSendNewAccountToERPOnOpportunityQualified_WithNonQualifiedStage() {
        // Having
        Opportunity testOpp = [SELECT Id, StageName, AccountId FROM Opportunity LIMIT 1];
        testOpp.StageName = 'Qualifizierung';
        update testOpp;

        Map<Id, Opportunity> newOpps = new Map<Id, Opportunity>{testOpp.Id => testOpp};
        Map<Id, Opportunity> oldOpps = new Map<Id, Opportunity>{testOpp.Id => testOpp.clone(true, true, false, false)};
        oldOpps.get(testOpp.Id).StageName = 'Prospecting';

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendNewAccountToERPOnOpportunityQualified(newOpps, oldOpps);
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle stage change to qualified gracefully');
    }

    @IsTest
    static void testSendAccountsToERP_WithNullParameters() {
        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendAccountsToERP(null, new Set<Id>());
        ERPIntegrationEventPublisher.sendAccountsToERP(new List<Account>(), new Set<Id>());
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle null parameters gracefully');
    }

    @IsTest
    static void testSendAccountsToERP_WithAccountsWithoutERPNumber() {
        // Having
        Account testAccount = [SELECT Id, ERPCustomerNumber__c FROM Account WHERE ERPCustomerNumber__c = null LIMIT 1];

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendAccountsToERP(new List<Account>{testAccount}, new Set<Id>());
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle accounts without ERP number gracefully');
    }

    // JJD-44 --------------------------------------------------------------------------------
    // The outbound event must fire only when a field the SAP update path actually reads has
    // changed. The trigger case that motivated this: a scheduled batch rewriting a local
    // Salesforce flag on every Account twice an hour, which used to publish one event per
    // record per run and exhausted the org's daily platform event allocation (JJD-54).

    // Every accessible field rather than an explicit list: the publisher reads roughly thirty
    // Account fields when it builds the event and the filter reads nineteen more, so naming them
    // here would break the test with SObjectException every time either list grows.
    // FIELDS(ALL) is not available in Apex, hence the describe.
    private static List<Account> queryAccountsWithRelevantFields() {
        List<String> fieldNames = new List<String>();
        for (Schema.SObjectField field : Schema.SObjectType.Account.fields.getMap().values()) {
            Schema.DescribeFieldResult described = field.getDescribe();
            if (described.isAccessible()) {
                fieldNames.add(described.getName());
            }
        }

        return (List<Account>) Database.query(
            'SELECT ' + String.join(fieldNames, ', ') +
            ' FROM Account WHERE ERPCustomerNumber__c != NULL ORDER BY ERPCustomerNumber__c LIMIT 200'
        );
    }

    @IsTest
    static void doNotPublish_WhenOnlyNonMappedFieldChanged() {
        // Having
        Account existing = queryAccountsWithRelevantFields()[0];
        Account oldRecord = existing.clone(true, true, true, true);
        Account newRecord = existing.clone(true, true, true, true);
        newRecord.Description = 'rewritten by an unrelated scheduled batch';
        accountChangedEventsCount = 0;

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendAccountsToERP(
            new List<Account>{newRecord},
            new Map<Id, Account>{oldRecord.Id => oldRecord},
            new Set<Id>()
        );
        Test.stopTest();

        // Then
        System.assertEquals(0, accountChangedEventsCount,
            'A change to a field the SAP update path never reads must not publish an event');
    }

    @IsTest
    static void publish_WhenMappedFieldChanged() {
        // Having - guards against a filter that simply never publishes, which would pass the
        // test above while silently killing the integration.
        Account existing = queryAccountsWithRelevantFields()[0];
        Account oldRecord = existing.clone(true, true, true, true);
        Account newRecord = existing.clone(true, true, true, true);
        newRecord.Name = existing.Name + ' (renamed)';
        accountChangedEventsCount = 0;

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendAccountsToERP(
            new List<Account>{newRecord},
            new Map<Id, Account>{oldRecord.Id => oldRecord},
            new Set<Id>()
        );
        Test.stopTest();

        // Then
        System.assertEquals(1, accountChangedEventsCount,
            'A change to a mapped field must still publish an event');
    }

    @IsTest
    static void publishOnlyChangedRecords_WhenBulkUpdateMixesRelevantAndIrrelevant() {
        // Having - catches a diff computed once and applied to the whole batch
        List<Account> existing = queryAccountsWithRelevantFields();
        System.assert(existing.size() >= 2, 'Test setup must provide at least two ERP-linked accounts');

        Map<Id, Account> oldRecordsMap = new Map<Id, Account>();
        List<Account> newRecords = new List<Account>();
        for (Integer i = 0; i < 2; i++) {
            Account oldRecord = existing[i].clone(true, true, true, true);
            Account newRecord = existing[i].clone(true, true, true, true);
            if (i == 0) {
                newRecord.Name = existing[i].Name + ' (renamed)';
            } else {
                newRecord.Description = 'rewritten by an unrelated scheduled batch';
            }
            oldRecordsMap.put(oldRecord.Id, oldRecord);
            newRecords.add(newRecord);
        }
        accountChangedEventsCount = 0;

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendAccountsToERP(newRecords, oldRecordsMap, new Set<Id>());
        Test.stopTest();

        // Then
        System.assertEquals(1, accountChangedEventsCount,
            'Only the record whose mapped field changed may be published');
    }

    @IsTest
    static void everyRelevantFieldExistsOnAccount() {
        // isAnyFieldChanged skips field names the SObject does not have, so a typo would silently
        // drop that field from the filter and the integration would stop reacting to it with no
        // error anywhere. Nothing else in the suite would catch that.
        Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
        List<String> unknown = new List<String>();

        for (ERPSyncRecursionPrevention.ERPFieldConfig config : ERPIntegrationEventPublisher.ACCOUNT_MAPPING_RELEVANT_FIELDS) {
            if (!accountFields.containsKey(config.fieldName)) {
                unknown.add(config.fieldName);
            }
        }

        System.assertEquals(new List<String>(), unknown,
            'ACCOUNT_MAPPING_RELEVANT_FIELDS names fields that do not exist on Account: ' + unknown);
    }

    @IsTest
    static void testSendContactsToERP_WithNullParameters() {
        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendContactsToERP(null, new Set<Id>(), true);
        ERPIntegrationEventPublisher.sendContactsToERP(new Map<Id, Contact>(), new Set<Id>(), true);
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle null parameters gracefully');
    }

    @IsTest
    static void testSendContactsToERP_WithContactsWithoutAccount() {
        // Having
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com'
        );
        insert testContact;

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendContactsToERP(new Map<Id, Contact>{testContact.Id => testContact}, new Set<Id>(), true);
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle contacts without account gracefully');
    }

    @IsTest
    static void testSendCustomAddressToERP_WithNullParameters() {
        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendCustomAddressToERP(null, new Set<Id>());
        ERPIntegrationEventPublisher.sendCustomAddressToERP(new List<CustomAddress__c>(), new Set<Id>());
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle null parameters gracefully');
    }

    @IsTest
    static void testFormatAddress_WithAllFields() {
        // When
        Test.startTest();
        String result = ERPIntegrationEventPublisher.formatAddress('Test Street', 'Test City', 'Test State', '12345', 'Test Country');
        Test.stopTest();

        // Then
        System.assertEquals('Test Street, Test City, Test State, 12345, Test Country', result, 'Should format address correctly');
    }

    @IsTest
    static void testFormatAddress_WithNullFields() {
        // When
        Test.startTest();
        String result = ERPIntegrationEventPublisher.formatAddress(null, 'Test City', null, '12345', 'Test Country');
        Test.stopTest();

        // Then
        System.assertEquals('Test City, 12345, Test Country', result, 'Should skip null fields');
    }

    @IsTest
    static void testFormatAddress_WithAllNullFields() {
        // When
        Test.startTest();
        String result = ERPIntegrationEventPublisher.formatAddress(null, null, null, null, null);
        Test.stopTest();

        // Then
        System.assertEquals(null, result, 'Should return null for all null fields');
    }

    @IsTest
    static void testSendNewAccountToERPOnOpportunityQualified_DirectCall() {
        // Given
        Account testAccount = [SELECT Id, ERPCustomerNumber__c FROM Account WHERE ERPCustomerNumber__c = null LIMIT 1];

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Angebotsphase',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testOpportunity;

        Map<Id, Opportunity> newOpportunities = new Map<Id, Opportunity>{testOpportunity.Id => testOpportunity};
        Map<Id, Opportunity> oldOpportunities = new Map<Id, Opportunity>{testOpportunity.Id => new Opportunity(Id = testOpportunity.Id, StageName = 'Prospecting')};

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendNewAccountToERPOnOpportunityQualified(newOpportunities, oldOpportunities);
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle direct method call without exception');
    }

    @IsTest
    static void testSendNewAccountToERPOnOpportunityQualified_NewQualifiedOpportunity() {
        // Given
        Account testAccount = [SELECT Id, ERPCustomerNumber__c FROM Account WHERE ERPCustomerNumber__c = null LIMIT 1];

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testOpportunity;

        Map<Id, Opportunity> newOpportunities = new Map<Id, Opportunity>{testOpportunity.Id => testOpportunity};
        Map<Id, Opportunity> oldOpportunities = null; // New opportunity

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendNewAccountToERPOnOpportunityQualified(newOpportunities, oldOpportunities);
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle new qualified opportunity without exception');
    }

    @IsTest
    static void testSendNewAccountToERPOnOpportunityQualified_EmptyMap() {
        // Given
        Map<Id, Opportunity> newOpportunities = new Map<Id, Opportunity>();
        Map<Id, Opportunity> oldOpportunities = new Map<Id, Opportunity>();

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendNewAccountToERPOnOpportunityQualified(newOpportunities, oldOpportunities);
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle empty map without exception');
    }

    @IsTest
    static void testSendNewAccountToERPOnOpportunityQualified_NullMap() {
        // Given
        Map<Id, Opportunity> newOpportunities = null;
        Map<Id, Opportunity> oldOpportunities = null;

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendNewAccountToERPOnOpportunityQualified(newOpportunities, oldOpportunities);
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle null map without exception');
    }

    @IsTest
    static void testSendAccountsToERP_EmptyList() {
        // Given
        List<Account> accounts = new List<Account>();
        Set<Id> erpUpdatedRecords = new Set<Id>();

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendAccountsToERP(accounts, erpUpdatedRecords);
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle empty list without exception');
    }

    @IsTest
    static void testSendAccountsToERP_NullList() {
        // Given
        List<Account> accounts = null;
        Set<Id> erpUpdatedRecords = new Set<Id>();

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendAccountsToERP(accounts, erpUpdatedRecords);
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle null list without exception');
    }

    @IsTest
    static void testSendAccountsToERP_AccountWithoutERPNumber() {
        // Given
        Account testAccount = [SELECT Id, ERPCustomerNumber__c FROM Account WHERE ERPCustomerNumber__c = null LIMIT 1];
        List<Account> accounts = new List<Account>{testAccount};
        Set<Id> erpUpdatedRecords = new Set<Id>();

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendAccountsToERP(accounts, erpUpdatedRecords);
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle account without ERP number without exception');
    }

    @IsTest
    static void testSendAccountsToERP_AccountInERPUpdatedRecords() {
        // Given
        Account testAccount = [SELECT Id, ERPCustomerNumber__c FROM Account WHERE ERPCustomerNumber__c = 'CUST123' LIMIT 1];
        List<Account> accounts = new List<Account>{testAccount};
        Set<Id> erpUpdatedRecords = new Set<Id>{testAccount.Id};

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendAccountsToERP(accounts, erpUpdatedRecords);
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle account in ERP updated records without exception');
    }

    @IsTest
    static void testSendContactsToERP_DirectCall() {
        // Given
        Contact testContact = [SELECT Id, AccountId FROM Contact LIMIT 1];
        Map<Id, Contact> contacts = new Map<Id, Contact>{testContact.Id => testContact};
        Set<Id> erpUpdatedRecords = new Set<Id>();
        Boolean isCreatedContact = false;

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendContactsToERP(contacts, erpUpdatedRecords, isCreatedContact);
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle direct method call without exception');
    }

    @IsTest
    static void testSendContactsToERP_EmptyMap() {
        // Given
        Map<Id, Contact> contacts = new Map<Id, Contact>();
        Set<Id> erpUpdatedRecords = new Set<Id>();
        Boolean isCreatedContact = false;

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendContactsToERP(contacts, erpUpdatedRecords, isCreatedContact);
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle empty map without exception');
    }

    @IsTest
    static void testSendContactsToERP_NullMap() {
        // Given
        Map<Id, Contact> contacts = null;
        Set<Id> erpUpdatedRecords = new Set<Id>();
        Boolean isCreatedContact = false;

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendContactsToERP(contacts, erpUpdatedRecords, isCreatedContact);
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle null map without exception');
    }

    @IsTest
    static void testSendContactsToERP_ContactWithoutAccount() {
        // Given
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact No Account'
        );
        insert testContact;
        Map<Id, Contact> contacts = new Map<Id, Contact>{testContact.Id => testContact};
        Set<Id> erpUpdatedRecords = new Set<Id>();
        Boolean isCreatedContact = true;

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendContactsToERP(contacts, erpUpdatedRecords, isCreatedContact);
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle contact without account without exception');
    }

    @IsTest
    static void testSendCustomAddressesToERP_DirectCall() {
        // Given
        Account testAccount = [SELECT Id, ERPCustomerNumber__c FROM Account WHERE ERPCustomerNumber__c = 'CUST123' LIMIT 1];
        CustomAddress__c testAddress = new CustomAddress__c(
            LookupType__c = 'Account',
            RelatedId__c = testAccount.Id,
            AddressType__c = 'Billing',
            ExternalID__c = 'EXT001',
            IsPrimary__c = true,
            ERPCustomerNumber__c = 'CUST123',
            Address__CountryCode__s = 'DE',
            Address__City__s = 'Berlin',
            Address__Street__s = 'Test Street',
            Address__PostalCode__s = '12345',
            Address__StateCode__s = 'BE'
        );
        insert testAddress;
        List<CustomAddress__c> addresses = new List<CustomAddress__c>{testAddress};
        Set<Id> erpUpdatedAddressed = new Set<Id>();

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendCustomAddressToERP(addresses, erpUpdatedAddressed);
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle direct method call without exception');
    }

    @IsTest
    static void testSendCustomAddressesToERP_EmptyList() {
        // Given
        List<CustomAddress__c> addresses = new List<CustomAddress__c>();
        Set<Id> erpUpdatedAddressed = new Set<Id>();

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendCustomAddressToERP(addresses, erpUpdatedAddressed);
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle empty list without exception');
    }

    @IsTest
    static void testSendCustomAddressesToERP_NullList() {
        // Given
        List<CustomAddress__c> addresses = null;
        Set<Id> erpUpdatedAddressed = new Set<Id>();

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendCustomAddressToERP(addresses, erpUpdatedAddressed);
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle null list without exception');
    }

    @IsTest
    static void testSendBankAccountsToERP_DirectCall() {
        // Given
        Account testAccount = [SELECT Id, ERPCustomerNumber__c FROM Account WHERE ERPCustomerNumber__c = 'CUST123' LIMIT 1];
        BankInfo__c testBankInfo = new BankInfo__c(
            Account__c = testAccount.Id,
            BankName__c = 'Test Bank',
            BankCountry__c = 'Germany',
            ERPCustomerNumber__c = 'CUST123',
            BankAccount__c = '1234567890',
            BankNumber__c = '12345678'
        );
        insert testBankInfo;
        List<BankInfo__c> bankAccounts = new List<BankInfo__c>{testBankInfo};
        Set<Id> erpUpdatedAddressed = new Set<Id>();

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendBankAccountToERP(bankAccounts, erpUpdatedAddressed);
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle direct method call without exception');
    }

    @IsTest
    static void testSendBankAccountsToERP_EmptyList() {
        // Given
        List<BankInfo__c> bankAccounts = new List<BankInfo__c>();
        Set<Id> erpUpdatedAddressed = new Set<Id>();

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendBankAccountToERP(bankAccounts, erpUpdatedAddressed);
        Test.stopTest();

        // Then - should not throw exception
        System.assert(true, 'Should handle empty list without exception');
    }

    @IsTest
    static void testGetNewAccountsForERP_DirectCall() {
        // Given
        Account testAccount = [SELECT Id FROM Account WHERE ERPCustomerNumber__c = null LIMIT 1];
        Set<Id> accountIds = new Set<Id>{testAccount.Id};

        // When
        Test.startTest();
        List<Account> result = ERPIntegrationEventPublisher.getNewAccountsForERP(accountIds);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should return one account');
        System.assertEquals(testAccount.Id, result[0].Id, 'Should return the correct account');
    }

    @IsTest
    static void testGetNewAccountsForERP_EmptySet() {
        // Given
        Set<Id> accountIds = new Set<Id>();

        // When
        Test.startTest();
        List<Account> result = ERPIntegrationEventPublisher.getNewAccountsForERP(accountIds);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty list for empty set');
    }

    @IsTest
    static void testGetNewAccountsForERP_NullSet() {
        // Given
        Set<Id> accountIds = null;

        // When
        Test.startTest();
        List<Account> result = ERPIntegrationEventPublisher.getNewAccountsForERP(accountIds);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty list for null set');
    }

    @IsTest
    static void testFormatAddress_DirectCall() {
        // Given
        String street = '123 Test Street';
        String city = 'Test City';
        String state = 'Test State';
        String postalCode = '12345';
        String country = 'Test Country';

        // When
        Test.startTest();
        String result = ERPIntegrationEventPublisher.formatAddress(street, city, state, postalCode, country);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains(street), 'Result should contain street');
        System.assert(result.contains(city), 'Result should contain city');
        System.assert(result.contains(state), 'Result should contain state');
        System.assert(result.contains(postalCode), 'Result should contain postal code');
        System.assert(result.contains(country), 'Result should contain country');
    }

    @IsTest
    static void testFormatAddress_WithNullValues() {
        // Given
        String street = '123 Test Street';
        String city = null;
        String state = 'Test State';
        String postalCode = null;
        String country = 'Test Country';

        // When
        Test.startTest();
        String result = ERPIntegrationEventPublisher.formatAddress(street, city, state, postalCode, country);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains(street), 'Result should contain street');
        System.assert(result.contains(state), 'Result should contain state');
        System.assert(result.contains(country), 'Result should contain country');
    }

    @IsTest
    static void testSendACREndDating_WithNullParameters() {
        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendAccountContactRelationEndDatingToERP(null, new Map<Id, Date>());
        ERPIntegrationEventPublisher.sendAccountContactRelationEndDatingToERP(new List<AccountContactRelation>(), new Map<Id, Date>());
        Test.stopTest();

        // Then
        System.assertEquals(0, accountContactRelationChangedEventsCount, 'Should not publish events for null/empty input');
    }

    @IsTest
    static void testSendACREndDating_PairAlreadyInSAP_ShouldPublishOneEvent() {
        // Having: account already in SAP + contact already in SAP -> the relationship can be end-dated.
        Account erpAccount = [SELECT Id FROM Account WHERE ERPCustomerNumber__c = 'CUST123' LIMIT 1];
        Contact erpContact = new Contact(
            FirstName = 'Test',
            LastName = 'ERP Contact',
            AccountId = erpAccount.Id,
            ERPContactNumber__c = 'KONT456'
        );
        insert erpContact; // auto-creates the direct AccountContactRelation

        AccountContactRelation relation = [
            SELECT Id, AccountId, ContactId
            FROM AccountContactRelation
            WHERE AccountId = :erpAccount.Id AND ContactId = :erpContact.Id
            LIMIT 1
        ];

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendAccountContactRelationEndDatingToERP(
            new List<AccountContactRelation>{relation},
            new Map<Id, Date>{relation.Id => Date.today()}
        );
        Test.stopTest();

        // Then
        System.assertEquals(1, accountContactRelationChangedEventsCount,
            'Should publish one AccountContactRelationChanged__e event for a pair already in SAP');
    }

    @IsTest
    static void testSendACREndDating_PairNotInSAP_ShouldPublishNoEvent() {
        // Having: account without ERP number + contact without ERP number -> nothing to end-date.
        Account noErpAccount = [SELECT Id FROM Account WHERE ERPCustomerNumber__c = null LIMIT 1];
        Contact noErpContact = new Contact(
            FirstName = 'Test',
            LastName = 'No ERP Contact',
            AccountId = noErpAccount.Id
        );
        insert noErpContact;

        AccountContactRelation relation = [
            SELECT Id, AccountId, ContactId
            FROM AccountContactRelation
            WHERE AccountId = :noErpAccount.Id AND ContactId = :noErpContact.Id
            LIMIT 1
        ];

        // When
        Test.startTest();
        ERPIntegrationEventPublisher.sendAccountContactRelationEndDatingToERP(
            new List<AccountContactRelation>{relation},
            new Map<Id, Date>{relation.Id => Date.today()}
        );
        Test.stopTest();

        // Then
        System.assertEquals(0, accountContactRelationChangedEventsCount,
            'Should not publish events when the pair is not in SAP');
    }

    @IsTest
    static void testFormatAddress_WithEmptyStrings() {
        // Given
        String street = '123 Test Street';
        String city = '';
        String state = 'Test State';
        String postalCode = '';
        String country = 'Test Country';

        // When
        Test.startTest();
        String result = ERPIntegrationEventPublisher.formatAddress(street, city, state, postalCode, country);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains(street), 'Result should contain street');
        System.assert(result.contains(state), 'Result should contain state');
        System.assert(result.contains(country), 'Result should contain country');
    }
}