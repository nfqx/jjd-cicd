@IsTest
public class AccountTriggerHandlerTest {

    @IsTest
    static void handleAfterInsert_shouldPublishNewAccountEvent_whenAccountHasNoERPNumber() {
        //Having
        Account account = new Account(Name = 'New Account Without ERP Number');

        //When
        Test.startTest();
        insert account;
        Test.stopTest();

        //Then
        System.assertEquals(1, ERPIntegrationEventPublisherTest.newAccountEventsCount,
            'A newly created Account without an ERP number must be sent to SAP once');
    }

    @IsTest
    static void handleAfterInsert_shouldNotPublishNewAccountEvent_whenAccountHasERPNumber() {
        //Having
        Account account = new Account(
            Name = 'New Account With ERP Number',
            ERPCustomerNumber__c = 'CUST_ATH_001'
        );

        //When
        Test.startTest();
        insert account;
        Test.stopTest();

        //Then
        System.assertEquals(0, ERPIntegrationEventPublisherTest.newAccountEventsCount,
            'An Account that already carries an ERP number exists in SAP and must not be created again');
    }

    @IsTest
    static void handleAfterInsert_shouldPublishOneEventPerAccount_whenAccountsInsertedInBulk() {
        //Having
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(Name = 'Bulk Account ' + i));
        }
        accounts[0].ERPCustomerNumber__c = 'CUST_ATH_BULK';

        //When
        Test.startTest();
        insert accounts;
        Test.stopTest();

        //Then
        System.assertEquals(199, ERPIntegrationEventPublisherTest.newAccountEventsCount,
            'Every inserted Account without an ERP number must be sent to SAP exactly once');
    }

    private static Integer countChainHeadBatchJobs() {
        return [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'BatchApex' AND ApexClass.Name = 'ChainHeadCalculationBatch'];
    }

    @IsTest
    static void calculateChainHead_shouldNotStartBatch_whenNoChainFieldChanged() {
        //Having
        Account account = new Account(Name = 'Account Without Chain Change');
        insert account;

        Account oldAccount = account.clone(true, true, false, false);
        Account newAccount = account.clone(true, true, false, false);
        newAccount.Description = 'unrelated change';

        //When
        Test.startTest();
        AccountTriggerHandler.calculateChainHead(new List<Account>{ newAccount }, new Map<Id, Account>{ oldAccount.Id => oldAccount });
        Test.stopTest();

        //Then
        System.assertEquals(0, countChainHeadBatchJobs(),
            'A change that touches no chain field must not start the chain head calculation');
    }

    @IsTest
    static void calculateChainHead_shouldNotStartBatch_whenRecalculationIsSuppressed() {
        //Having
        Account parent = new Account(Name = 'Chain Parent');
        insert parent;
        Account child = new Account(Name = 'Chain Child', ConditionChainParent__c = parent.Id);
        AccountTriggerHandler.suppressRecalcHead = true;

        //When
        Test.startTest();
        AccountTriggerHandler.calculateChainHead(new List<Account>{ child }, null);
        Test.stopTest();

        //Then
        System.assertEquals(0, countChainHeadBatchJobs(),
            'Suppressed recalculation must not start the chain head calculation');
    }
}