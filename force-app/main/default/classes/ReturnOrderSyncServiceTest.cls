@IsTest
private class ReturnOrderSyncServiceTest {

    @TestSetup
    static void setup() {
        Account account = new Account(
            Name = 'Return Test Account',
            ERPCustomerNumber__c = 'RET123'
        );
        insert account;

        ReturnOrder returnOrder = new ReturnOrder(
            AccountId = account.Id,
            Status = 'Draft',
            ERPReturnOrderNumber__c = '5000000123',
            BillingBlocked__c = true
        );
        insert returnOrder;
    }

    @IsTest
    static void testPushBillingReleases_ShouldSendRequestSuccessfully() {
        // HAVING
        ReturnOrder returnOrder = [SELECT Id FROM ReturnOrder LIMIT 1];
        ReturnOrderSyncService.isTestEnvironment = true;
        ReturnOrderSyncService.testEndpoint = 'https://test.mulesoft.com/api';
        ReturnOrderSyncService.capturedRequests.clear();

        // WHEN
        Test.startTest();
        ReturnOrderSyncService.pushBillingReleases(new Set<Id>{ returnOrder.Id });
        Test.stopTest();

        // THEN
        System.assertEquals(1, ReturnOrderSyncService.capturedRequests.size(), 'Should have captured 1 request');
        HttpRequest req = ReturnOrderSyncService.capturedRequests[0];
        System.assertEquals('PATCH', req.getMethod(), 'Billing release should be a PATCH (update) request');
        System.assertEquals('https://test.mulesoft.com/api', req.getEndpoint(), 'Should use test endpoint');
        System.assertEquals('application/json', req.getHeader('Content-Type'), 'Should have correct content type');
        System.assert(req.getBody().contains('"data":['), 'Request should contain data array');
        System.assert(req.getBody().contains('5000000123'), 'Request should contain ERP return order number');
    }

    @IsTest
    static void testPushBillingReleases_WithEmptySet_ShouldNotSendRequest() {
        // WHEN
        Test.startTest();
        ReturnOrderSyncService.pushBillingReleases(new Set<Id>());
        Test.stopTest();

        // THEN
        System.assertEquals(0, ReturnOrderSyncService.capturedRequests.size(), 'Should not send request for empty set');
    }

    @IsTest
    static void testCreateReturnOrderPayload_ShouldMatchAllFields() {
        // HAVING
        ReturnOrder returnOrder = ReturnOrderSyncService.getReturnOrders(
            new Set<Id>{ [SELECT Id FROM ReturnOrder LIMIT 1].Id }
        )[0];

        // WHEN
        Test.startTest();
        String payload = ReturnOrderSyncService.createReturnOrderPayload(returnOrder);
        Test.stopTest();

        // THEN
        Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(payload);
        System.assertEquals(returnOrder.Id, payloadMap.get('id'), 'Should contain return order ID');
        System.assertEquals(returnOrder.ERPReturnOrderNumber__c, payloadMap.get('erpReturnOrderNumber'), 'Should contain ERP return order number');
        System.assertEquals(returnOrder.BillingBlocked__c, payloadMap.get('billingBlocked'), 'Should contain billing blocked flag');
    }

    @IsTest
    static void testBillingRelease_TriggersOutboundIntegration() {
        // HAVING — billing block is currently true (from setup)
        ReturnOrder returnOrder = [SELECT Id, BillingBlocked__c FROM ReturnOrder LIMIT 1];
        ReturnOrderSyncService.isTestEnvironment = true;
        ReturnOrderSyncService.testEndpoint = 'https://test.mulesoft.com/api';
        ReturnOrderSyncService.capturedRequests.clear();

        // WHEN — release the billing block (true -> false)
        Test.startTest();
        returnOrder.BillingBlocked__c = false;
        update returnOrder;
        Test.stopTest();

        // THEN — the trigger/handler pushed exactly one release to MuleSoft
        System.assertEquals(1, ReturnOrderSyncService.capturedRequests.size(), 'Billing release should trigger one outbound call');
        System.assert(ReturnOrderSyncService.capturedRequests[0].getBody().contains('5000000123'), 'Outbound call should reference the SAP return number');
    }

    @IsTest
    static void testNonReleaseUpdate_DoesNotTrigger() {
        // HAVING
        ReturnOrder returnOrder = [SELECT Id FROM ReturnOrder LIMIT 1];
        ReturnOrderSyncService.isTestEnvironment = true;
        ReturnOrderSyncService.testEndpoint = 'https://test.mulesoft.com/api';
        ReturnOrderSyncService.capturedRequests.clear();

        // WHEN — update an unrelated field without releasing the billing block
        Test.startTest();
        returnOrder.Description = 'No billing change';
        update returnOrder;
        Test.stopTest();

        // THEN
        System.assertEquals(0, ReturnOrderSyncService.capturedRequests.size(), 'Non-release update must not trigger an outbound call');
    }

    @IsTest
    static void testPushReturnOrderCreate_ShouldSendPostRequest() {
        // HAVING — a ReturnOrder without ERPReturnOrderNumber__c (not yet in SAP)
        Account account = [SELECT Id, ERPCustomerNumber__c FROM Account LIMIT 1];
        ReturnOrder newRo = new ReturnOrder(
            AccountId    = account.Id,
            Status       = 'Draft',
            SoldTo__c    = account.Id,
            ReturnOrderType__c = 'ZRE',
            CurrencyIsoCode    = 'EUR'
        );
        insert newRo;

        ReturnOrderSyncService.isTestEnvironment = true;
        ReturnOrderSyncService.testEndpoint = 'https://test.mulesoft.com/api';
        ReturnOrderSyncService.capturedRequests.clear();

        // WHEN
        Test.startTest();
        ReturnOrderSyncService.pushReturnOrderCreate(new Set<Id>{ newRo.Id });
        Test.stopTest();

        // THEN
        System.assertEquals(1, ReturnOrderSyncService.capturedRequests.size(), 'Should have captured 1 POST request');
        HttpRequest req = ReturnOrderSyncService.capturedRequests[0];
        System.assertEquals('POST', req.getMethod(), 'Return order create should be a POST request');
        System.assert(req.getBody().contains('"data":['), 'Request should contain data array');
    }

    @IsTest
    static void testCreateReturnOrderCreatePayload_ShouldContainExpectedFields() {
        // HAVING
        Account account = [SELECT Id, ERPCustomerNumber__c FROM Account LIMIT 1];
        ReturnOrder ro = new ReturnOrder(
            AccountId          = account.Id,
            Status             = 'Draft',
            SoldTo__c          = account.Id,
            ReturnOrderType__c = 'ZREA',
            CurrencyIsoCode    = 'EUR',
            SalesOrganization__c   = '1100',
            DistributionChannel__c = '20'
        );
        insert ro;

        // WHEN
        Test.startTest();
        ReturnOrder fetched = ReturnOrderSyncService.getReturnOrdersForCreate(new Set<Id>{ ro.Id })[0];
        String payload = ReturnOrderSyncService.createReturnOrderCreatePayload(fetched);
        Test.stopTest();

        // THEN
        Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(payload);
        System.assertEquals('ZREA', payloadMap.get('returnOrderType'), 'Should contain return order type');
        System.assertEquals('EUR', payloadMap.get('transactionCurrency'), 'Should contain currency');
        System.assertEquals('1100', payloadMap.get('salesOrganization'), 'Should contain sales org');
        System.assertNotEquals(null, payloadMap.get('partners'), 'Should contain partners map');
        System.assertNotEquals(null, payloadMap.get('returnOrderLineItems'), 'Should contain line items array');
    }

    @IsTest
    static void testReturnOrderInsert_WithReadyStatus_TriggersCreate() {
        // HAVING
        Account account = [SELECT Id FROM Account LIMIT 1];
        ReturnOrderSyncService.isTestEnvironment = true;
        ReturnOrderSyncService.testEndpoint = 'https://test.mulesoft.com/api';
        ReturnOrderSyncService.capturedRequests.clear();

        // WHEN — inserted already in the "ready to send" status (Gesendet)
        Test.startTest();
        insert new ReturnOrder(AccountId = account.Id, Status = 'Gesendet', SoldTo__c = account.Id);
        Test.stopTest();

        // THEN — trigger pushed exactly one create to MuleSoft
        System.assertEquals(1, ReturnOrderSyncService.capturedRequests.size(), 'Ready-status insert should trigger one outbound POST');
        System.assertEquals('POST', ReturnOrderSyncService.capturedRequests[0].getMethod(), 'Should be POST');
    }

    @IsTest
    static void testReturnOrderInsert_DraftStatus_DoesNotTrigger() {
        // HAVING
        Account account = [SELECT Id FROM Account LIMIT 1];
        ReturnOrderSyncService.isTestEnvironment = true;
        ReturnOrderSyncService.testEndpoint = 'https://test.mulesoft.com/api';
        ReturnOrderSyncService.capturedRequests.clear();

        // WHEN — still a draft (not ready to send) → must stay silent
        Test.startTest();
        insert new ReturnOrder(AccountId = account.Id, Status = 'Entwurf', SoldTo__c = account.Id);
        Test.stopTest();

        // THEN
        System.assertEquals(0, ReturnOrderSyncService.capturedRequests.size(), 'Draft insert must not trigger outbound');
    }

    @IsTest
    static void testReturnOrderStatusTransition_TriggersCreate() {
        // HAVING — draft first, gated out, no callout
        Account account = [SELECT Id FROM Account LIMIT 1];
        ReturnOrderSyncService.isTestEnvironment = true;
        ReturnOrderSyncService.testEndpoint = 'https://test.mulesoft.com/api';

        ReturnOrder ro = new ReturnOrder(AccountId = account.Id, Status = 'Entwurf', SoldTo__c = account.Id);
        insert ro;
        ReturnOrderSyncService.capturedRequests.clear();

        // WHEN — user completes the return and moves it to Gesendet
        Test.startTest();
        ro.Status = 'Gesendet';
        update ro;
        Test.stopTest();

        // THEN — transition into the ready status triggers exactly one create
        System.assertEquals(1, ReturnOrderSyncService.capturedRequests.size(), 'Transition to ready status should trigger one outbound POST');
    }
}