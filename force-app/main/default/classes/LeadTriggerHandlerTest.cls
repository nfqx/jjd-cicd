@IsTest
public class LeadTriggerHandlerTest {

    // Accounts are created here rather than in the test methods: an Account insert already sends
    // the Account to SAP and marks it as sent for the rest of the transaction, which would hide
    // what the Lead conversion itself does.
    @TestSetup
    static void setup() {
        Account accountWithoutERPNumber = new Account(Name = 'Existing Account Without ERP Number');
        Account accountWithERPNumber = new Account(
            Name = 'Existing Account With ERP Number',
            ERPCustomerNumber__c = 'CUST_LTH_001'
        );
        insert new List<Account>{ accountWithoutERPNumber, accountWithERPNumber };
    }

    private static Lead insertLead(String company) {
        Lead lead = new Lead(
            LastName = 'Conversion Test',
            Company = company
        );
        insert lead;
        return lead;
    }

    private static Database.LeadConvert buildConversion(Id leadId, Id existingAccountId) {
        Database.LeadConvert conversion = new Database.LeadConvert();
        conversion.setLeadId(leadId);
        conversion.setConvertedStatus([SELECT ApiName FROM LeadStatus WHERE IsConverted = true LIMIT 1].ApiName);
        conversion.setDoNotCreateOpportunity(true);
        if (existingAccountId != null) {
            conversion.setAccountId(existingAccountId);
        }
        return conversion;
    }

    @IsTest
    static void afterUpdate_shouldPublishOneNewAccountEvent_whenLeadConvertedIntoNewAccount() {
        //Having
        Lead lead = insertLead('Lead Into New Account');
        Database.LeadConvert conversion = buildConversion(lead.Id, null);

        //When
        Test.startTest();
        Database.LeadConvertResult result = Database.convertLead(conversion);
        Test.stopTest();

        //Then
        System.assert(result.isSuccess(), 'Lead conversion should succeed: ' + result.getErrors());
        System.assertEquals(1, ERPIntegrationEventPublisherTest.newAccountEventsCount,
            'The Account and Lead triggers both see the new Account, but SAP must receive a single create request');
    }

    @IsTest
    static void afterUpdate_shouldPublishNewAccountEvent_whenLeadConvertedIntoExistingAccountWithoutERPNumber() {
        //Having
        Account existingAccount = [SELECT Id FROM Account WHERE ERPCustomerNumber__c = null LIMIT 1];
        Lead lead = insertLead('Lead Into Existing Account Without ERP Number');
        Database.LeadConvert conversion = buildConversion(lead.Id, existingAccount.Id);

        //When
        Test.startTest();
        Database.LeadConvertResult result = Database.convertLead(conversion);
        Test.stopTest();

        //Then
        System.assert(result.isSuccess(), 'Lead conversion should succeed: ' + result.getErrors());
        System.assertEquals(existingAccount.Id, result.getAccountId(), 'Lead should be converted into the existing Account');
        System.assertEquals(1, ERPIntegrationEventPublisherTest.newAccountEventsCount,
            'An existing Account that is not yet in SAP must be sent to SAP when a Lead is converted into it');
    }

    @IsTest
    static void afterUpdate_shouldNotPublishNewAccountEvent_whenLeadConvertedIntoExistingAccountWithERPNumber() {
        //Having
        Account existingAccount = [SELECT Id FROM Account WHERE ERPCustomerNumber__c = 'CUST_LTH_001' LIMIT 1];
        Lead lead = insertLead('Lead Into Existing Account With ERP Number');
        Database.LeadConvert conversion = buildConversion(lead.Id, existingAccount.Id);

        //When
        Test.startTest();
        Database.LeadConvertResult result = Database.convertLead(conversion);
        Test.stopTest();

        //Then
        System.assert(result.isSuccess(), 'Lead conversion should succeed: ' + result.getErrors());
        System.assertEquals(0, ERPIntegrationEventPublisherTest.newAccountEventsCount,
            'An Account that already exists in SAP must not be created again');
    }

    @IsTest
    static void afterUpdate_shouldNotPublishNewAccountEvent_whenLeadUpdatedWithoutConversion() {
        //Having
        Lead lead = insertLead('Lead Without Conversion');

        //When
        Test.startTest();
        lead.Company = 'Lead Without Conversion (renamed)';
        update lead;
        Test.stopTest();

        //Then
        System.assertEquals(0, ERPIntegrationEventPublisherTest.newAccountEventsCount,
            'A Lead update that is not a conversion must not send anything to SAP');
    }
}