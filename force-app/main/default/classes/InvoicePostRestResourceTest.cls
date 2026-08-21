@IsTest
private class InvoicePostRestResourceTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(
            Name = 'Test Billing Account',
            ERPCustomerNumber__c = '0000641200'
        );
        insert acc;
    }

    @IsTest
    static void doPost_WithEmptyBody_Returns400() {
        // HAVING
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // WHEN
        Test.startTest();
        InvoicePostRestResource.ResponseWrapper result = InvoicePostRestResource.doPost();
        Test.stopTest();

        // THEN
        System.assertEquals(false, result.success, 'Should not succeed');
        System.assertEquals(400, result.statusCode, 'Should return 400');
        System.assert(result.message.contains('body'), 'Message should mention request body');
    }

    @IsTest
    static void doPost_WithInvalidPayload_Returns400() {
        // HAVING
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{"foo": "bar"}');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // WHEN
        Test.startTest();
        InvoicePostRestResource.ResponseWrapper result = InvoicePostRestResource.doPost();
        Test.stopTest();

        // THEN
        System.assertEquals(false, result.success, 'Should not succeed');
        System.assertEquals(400, result.statusCode, 'Should return 400');
    }

    @IsTest
    static void doPost_WithRecordsFormat_MissingAccount_Returns400() {
        // HAVING
        Map<String, Object> payload = new Map<String, Object>{
            'records' => new List<Object>{
                new Map<String, Object>{
                    'attributes' => new Map<String, Object>{ 'type' => 'Invoice' },
                    'BillingAccountId' => 'NONEXISTENT',
                    'CurrencyIsoCode' => 'EUR'
                },
                new Map<String, Object>{
                    'attributes' => new Map<String, Object>{ 'type' => 'InvoiceLine' },
                    'ProductNumber__c' => 'P1',
                    'Quantity' => '1',
                    'ChargeAmount' => '100'
                }
            }
        };

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // WHEN
        Test.startTest();
        InvoicePostRestResource.ResponseWrapper result = InvoicePostRestResource.doPost();
        Test.stopTest();

        // THEN
        System.assertEquals(false, result.success, 'Should not succeed');
        System.assertEquals(400, result.statusCode, 'Should return 400');
        System.assert(result.message.contains('Account not found') || result.message.contains('NONEXISTENT'), 'Should mention account');
    }

    @IsTest
    static void doPost_WithInvoiceFormat_InvalidPayload_Returns400() {
        // HAVING
        Map<String, Object> payload = new Map<String, Object>{
            'invoice' => new Map<String, Object>{ 'BillingAccountId' => '0000641200' },
            'invoiceLines' => new List<Object>()
        };

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // WHEN
        Test.startTest();
        InvoicePostRestResource.ResponseWrapper result = InvoicePostRestResource.doPost();
        Test.stopTest();

        // THEN
        System.assertEquals(false, result.success, 'Should not succeed with empty lines');
        System.assertEquals(400, result.statusCode, 'Should return 400');
    }
}