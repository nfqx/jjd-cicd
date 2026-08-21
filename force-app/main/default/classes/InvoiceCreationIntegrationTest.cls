/**
 * Integration tests for Invoice creation via ConnectAPI.
 * Requires @IsTest(SeeAllData=true) because ConnectApi methods are not supported in data siloed tests.
 * Separate from InvoiceCreationServiceTest to avoid conflict with @TestSetup.
 */
@IsTest(SeeAllData=true)
private class InvoiceCreationIntegrationTest {

    @IsTest
    static void createInvoiceFromSap_WithValidData_CreatesInvoice() {
        Account acc = new Account(
            Name = 'Integration Test Billing Account',
            ERPCustomerNumber__c = 'INTTEST001'
        );
        insert acc;

        Map<String, Object> invoiceData = new Map<String, Object>{
            'BillingAccountId' => 'INTTEST001',
            'CurrencyIsoCode' => 'EUR',
            'InvoiceDate' => '2025-08-04',
            'ReferenceEntityId' => 'CH_9898765'
        };
        List<Object> lines = new List<Object>{
            new Map<String, Object>{
                'ProductNumber__c' => '319001-6-01',
                'Name' => 'Alfredo Caffè 1000g Bohne VB/S',
                'Quantity' => '270.000',
                'ChargeAmount' => '12749.40'
            }
        };

        Test.startTest();
        Id invoiceId = InvoiceCreationService.createInvoiceFromSap(invoiceData, lines);
        Test.stopTest();

        System.assertNotEquals(null, invoiceId, 'Invoice ID should be returned');
        System.assert(invoiceId.getSobjectType().getDescribe().getName() == 'Invoice', 'Should be Invoice type');
    }
}