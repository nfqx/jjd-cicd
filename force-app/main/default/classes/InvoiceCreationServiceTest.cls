@IsTest
private class InvoiceCreationServiceTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(
            Name = 'Test Billing Account',
            ERPCustomerNumber__c = '0000641200'
        );
        insert acc;
    }

    @IsTest
    static void createInvoiceFromSap_WithMissingAccount_ThrowsException() {
        // HAVING
        Map<String, Object> invoiceData = new Map<String, Object>{
            'BillingAccountId' => 'NONEXISTENT',
            'CurrencyIsoCode' => 'EUR',
            'InvoiceDate' => '2025-08-04',
            'ReferenceEntityId' => 'CH_9898765'
        };
        List<Object> lines = new List<Object>{
            new Map<String, Object>{
                'ProductNumber__c' => '319001-6-01',
                'Name' => 'Test Product',
                'Quantity' => '270.000',
                'ChargeAmount' => '12749.40'
            }
        };

        // WHEN
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            InvoiceCreationService.createInvoiceFromSap(invoiceData, lines);
        } catch (InvoiceCreationService.InvoiceCreationException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Account not found'), 'Should mention account not found');
        }
        Test.stopTest();

        // THEN
        System.assert(exceptionThrown, 'Should throw InvoiceCreationException');
    }

    @IsTest
    static void createInvoiceFromSap_WithNullInvoiceData_ThrowsException() {
        // HAVING
        List<Object> lines = new List<Object>{
            new Map<String, Object>{ 'ProductNumber__c' => 'P1', 'Quantity' => '1', 'ChargeAmount' => '100' }
        };

        // WHEN
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            InvoiceCreationService.createInvoiceFromSap(null, lines);
        } catch (InvoiceCreationService.InvoiceCreationException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        // THEN
        System.assert(exceptionThrown, 'Should throw when invoice data is null');
    }

    @IsTest
    static void createInvoiceFromSap_WithEmptyLines_ThrowsException() {
        // HAVING
        Map<String, Object> invoiceData = new Map<String, Object>{
            'BillingAccountId' => '0000641200',
            'CurrencyIsoCode' => 'EUR'
        };

        // WHEN
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            InvoiceCreationService.createInvoiceFromSap(invoiceData, new List<Object>());
        } catch (InvoiceCreationService.InvoiceCreationException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        // THEN
        System.assert(exceptionThrown, 'Should throw when invoice lines are empty');
    }

    @IsTest
    static void createInvoiceFromSap_WithBlankBillingAccountId_ThrowsException() {
        // HAVING
        Map<String, Object> invoiceData = new Map<String, Object>{
            'BillingAccountId' => '',
            'CurrencyIsoCode' => 'EUR'
        };
        List<Object> lines = new List<Object>{
            new Map<String, Object>{ 'ProductNumber__c' => 'P1', 'Quantity' => '1', 'ChargeAmount' => '100' }
        };

        // WHEN
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            InvoiceCreationService.createInvoiceFromSap(invoiceData, lines);
        } catch (InvoiceCreationService.InvoiceCreationException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        // THEN
        System.assert(exceptionThrown, 'Should throw when BillingAccountId is blank');
    }
}