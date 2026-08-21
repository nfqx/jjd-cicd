@IsTest
public class AccountContactRelationTriggerHandlerTest {

    @TestSetup
    static void setup() {
        Account primaryAccount = new Account(
            Name = 'Primary Account ACR Test',
            ERPCustomerNumber__c = 'CUST_ACR_001'
        );
        Account secondaryAccount = new Account(
            Name = 'Secondary Account ACR Test',
            ERPCustomerNumber__c = 'CUST_ACR_002'
        );
        Account noErpAccount = new Account(
            Name = 'No ERP Account ACR Test'
        );
        insert new List<Account>{ primaryAccount, secondaryAccount, noErpAccount };

        Contact testContact1 = new Contact(
            FirstName = 'ACR',
            LastName = 'Contact One',
            AccountId = primaryAccount.Id
        );
        Contact testContact2 = new Contact(
            FirstName = 'ACR',
            LastName = 'Contact Two',
            AccountId = secondaryAccount.Id
        );
        insert new List<Contact>{ testContact1, testContact2 };
    }

    // ---- Unit tests: direct method calls, no trigger firing ----
    // Use uninserted AccountContactRelation objects so the trigger does not fire.
    // The SOQL inside sendAccountContactRelationsToERP uses ContactId / AccountId to query
    // the database, so the referenced records must exist (created in @TestSetup).

    @IsTest
    static void sendAccountContactRelationsToERP_NullList_ShouldNotPublish() {
        //When
        Test.startTest();
        ERPIntegrationEventPublisher.sendAccountContactRelationsToERP(null);
        Test.stopTest();

        //Then
        System.assertEquals(0, ERPIntegrationEventPublisherTest.accountContactRelationEventsCount,
            'No event should be published for null input');
    }

    @IsTest
    static void sendAccountContactRelationsToERP_EmptyList_ShouldNotPublish() {
        //When
        Test.startTest();
        ERPIntegrationEventPublisher.sendAccountContactRelationsToERP(new List<AccountContactRelation>());
        Test.stopTest();

        //Then
        System.assertEquals(0, ERPIntegrationEventPublisherTest.accountContactRelationEventsCount,
            'No event should be published for empty list');
    }

    @IsTest
    static void sendAccountContactRelationsToERP_AccountWithoutERPNumber_ShouldNotPublish() {
        //Having
        Account noErpAccount = [SELECT Id FROM Account WHERE ERPCustomerNumber__c = null LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];

        AccountContactRelation acr = new AccountContactRelation();
        acr.ContactId = testContact.Id;
        acr.AccountId = noErpAccount.Id;

        //When
        Test.startTest();
        ERPIntegrationEventPublisher.sendAccountContactRelationsToERP(new List<AccountContactRelation>{ acr });
        Test.stopTest();

        //Then
        System.assertEquals(0, ERPIntegrationEventPublisherTest.accountContactRelationEventsCount,
            'No event should be published when account has no ERP number');
    }

    @IsTest
    static void sendAccountContactRelationsToERP_ValidRelation_ShouldPublishOneEvent() {
        //Having
        Account erpAccount = [SELECT Id FROM Account WHERE ERPCustomerNumber__c = 'CUST_ACR_001' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :erpAccount.Id LIMIT 1];

        AccountContactRelation acr = new AccountContactRelation();
        acr.ContactId = testContact.Id;
        acr.AccountId = erpAccount.Id;

        //When
        Test.startTest();
        ERPIntegrationEventPublisher.sendAccountContactRelationsToERP(new List<AccountContactRelation>{ acr });
        Test.stopTest();

        //Then
        System.assertEquals(1, ERPIntegrationEventPublisherTest.accountContactRelationEventsCount,
            'One AccountContactRelationCreated__e should be published for a valid relation');
    }

    @IsTest
    static void sendAccountContactRelationsToERP_MultipleValidRelations_ShouldPublishMultipleEvents() {
        //Having
        Account acc1 = [SELECT Id FROM Account WHERE ERPCustomerNumber__c = 'CUST_ACR_001' LIMIT 1];
        Account acc2 = [SELECT Id FROM Account WHERE ERPCustomerNumber__c = 'CUST_ACR_002' LIMIT 1];
        Contact c1 = [SELECT Id FROM Contact WHERE AccountId = :acc1.Id LIMIT 1];
        Contact c2 = [SELECT Id FROM Contact WHERE AccountId = :acc2.Id LIMIT 1];

        AccountContactRelation acr1 = new AccountContactRelation();
        acr1.ContactId = c1.Id;
        acr1.AccountId = acc2.Id;

        AccountContactRelation acr2 = new AccountContactRelation();
        acr2.ContactId = c2.Id;
        acr2.AccountId = acc1.Id;

        //When
        Test.startTest();
        ERPIntegrationEventPublisher.sendAccountContactRelationsToERP(new List<AccountContactRelation>{ acr1, acr2 });
        Test.stopTest();

        //Then
        System.assertEquals(2, ERPIntegrationEventPublisherTest.accountContactRelationEventsCount,
            'Two AccountContactRelationCreated__e events should be published for two valid relations');
    }

    // ---- Trigger integration tests ----

    @IsTest
    static void trigger_DirectRelation_ShouldNotPublishEvent() {
        //Having — insert a Contact whose primary account has ERP number; Salesforce auto-creates IsDirect=true ACR
        Account primaryAccount = [SELECT Id FROM Account WHERE ERPCustomerNumber__c = 'CUST_ACR_001' LIMIT 1];
        Contact newContact = new Contact(
            FirstName = 'Direct',
            LastName = 'Trigger Contact',
            AccountId = primaryAccount.Id
        );

        //When
        Test.startTest();
        insert newContact;
        Test.stopTest();

        //Then — handler filters IsDirect=true, so no event
        System.assertEquals(0, ERPIntegrationEventPublisherTest.accountContactRelationEventsCount,
            'IsDirect=true AccountContactRelation must not publish AccountContactRelationCreated__e');
    }

    @IsTest
    static void trigger_IndirectRelation_WithERPAccount_ShouldPublishEvent() {
        //Having — testContact1 belongs to primaryAccount; linking it to secondaryAccount creates IsDirect=false
        Account secondaryAccount = [SELECT Id FROM Account WHERE ERPCustomerNumber__c = 'CUST_ACR_002' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE Account.ERPCustomerNumber__c = 'CUST_ACR_001' LIMIT 1];

        //When
        Test.startTest();
        insert new AccountContactRelation(AccountId = secondaryAccount.Id, ContactId = testContact.Id);
        Test.stopTest();

        //Then
        System.assertEquals(1, ERPIntegrationEventPublisherTest.accountContactRelationEventsCount,
            'IsDirect=false AccountContactRelation to an ERP account should publish one AccountContactRelationCreated__e');
    }

    @IsTest
    static void trigger_IndirectRelation_WithoutERPAccount_ShouldNotPublishEvent() {
        //Having — linking testContact1 to noErpAccount creates IsDirect=false, but account is not in SAP
        Account noErpAccount = [SELECT Id FROM Account WHERE ERPCustomerNumber__c = null LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE Account.ERPCustomerNumber__c = 'CUST_ACR_001' LIMIT 1];

        //When
        Test.startTest();
        insert new AccountContactRelation(AccountId = noErpAccount.Id, ContactId = testContact.Id);
        Test.stopTest();

        //Then
        System.assertEquals(0, ERPIntegrationEventPublisherTest.accountContactRelationEventsCount,
            'IsDirect=false AccountContactRelation to a non-ERP account must not publish any events');
    }
}