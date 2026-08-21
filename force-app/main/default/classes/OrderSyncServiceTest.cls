@IsTest
private class OrderSyncServiceTest {

    @TestSetup
    static void setup() {
        Account testAccount = new Account(
            Name = 'Test Account',
            ERPCustomerNumber__c = 'TEST123'
        );
        insert testAccount;

        Account soldToAccount = new Account(
            Name = 'Sold To Account',
            ERPCustomerNumber__c = 'SOLD123'
        );
        insert soldToAccount;

        Account shipToAccount = new Account(
            Name = 'Ship To Account',
            ERPCustomerNumber__c = 'SHIP123'
        );
        insert shipToAccount;

        Account billToAccount = new Account(
            Name = 'Bill To Account',
            ERPCustomerNumber__c = 'BILL123'
        );
        insert billToAccount;

        Account payerAccount = new Account(
            Name = 'Payer Account',
            ERPCustomerNumber__c = 'PAY123'
        );
        insert payerAccount;

        Product2 product = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST-PROD',
            BaseProductCode__c = 'BASE-PROD',
            IsActive = true,
            QuantityUnitOfMeasure = 'EA'
        );
        insert product;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        Order testOrder = new Order(
            AccountId = testAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId(),
            SalesOrganization__c = '1100',
            DistributionChannel__c = '10',
            OrganizationDivision__c = '00',
            RequestedDeliveryDate__c = Date.today().addDays(30),
            Type = 'Standard',
            PaymentTerms__c = 'D046',
            SoldTo__c = soldToAccount.Id,
            ShipTo__c = shipToAccount.Id,
            BillTo__c = billToAccount.Id,
            Payer__c = payerAccount.Id
        );
        insert testOrder;

        OrderItem item = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 5,
            UnitPrice = 100
        );
        insert item;
    }

    @IsTest
    static void testPushOrders_ShouldSendRequestSuccessfully() {
        // HAVING
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        OrderSyncService.isTestEnvironment = true;
        OrderSyncService.testEndpoint = 'https://test.mulesoft.com/api';
        OrderSyncService.capturedRequests.clear();

        // WHEN
        Test.startTest();
        OrderSyncService.pushOrders(new Set<Id>{testOrder.Id});
        Test.stopTest();

        // THEN
        System.assertEquals(1, OrderSyncService.capturedRequests.size(), 'Should have captured 1 request');
        HttpRequest req = OrderSyncService.capturedRequests[0];
        System.assertEquals('POST', req.getMethod(), 'Should be POST request');
        System.assertEquals('https://test.mulesoft.com/api', req.getEndpoint(), 'Should use test endpoint');
        System.assertEquals('application/json', req.getHeader('Content-Type'), 'Should have correct content type');
        System.assert(req.getBody().contains(testOrder.Id), 'Request should contain order ID');
        System.assert(req.getBody().contains('"data":['), 'Request should contain data array');
    }

    @IsTest
    static void testPushOrders_WithEmptySet_ShouldNotSendRequest() {
        // WHEN
        Test.startTest();
        OrderSyncService.pushOrders(new Set<Id>());
        Test.stopTest();

        // THEN
        System.assertEquals(0, OrderSyncService.capturedRequests.size(), 'Should not send request for empty set');
    }

    @IsTest
    static void testCreateOrderPayload_ShouldMatchAllFields() {
        // HAVING
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        testOrder = OrderSyncService.getOrdersWithItems(new Set<Id>{testOrder.Id})[0];

        // WHEN
        Test.startTest();
        String payload = OrderSyncService.createOrderPayload(testOrder);
        Test.stopTest();

        // THEN
        Map<String, Object> payloadMap = (Map<String, Object>)JSON.deserializeUntyped(payload);

        System.assertEquals(testOrder.Id, payloadMap.get('id'), 'Should contain order ID');
        System.assertEquals(testOrder.OrderNumber, payloadMap.get('orderNumber'), 'Should contain order number');
        System.assertEquals(testOrder.Type, payloadMap.get('orderType'), 'Should contain order type');
        System.assertEquals(testOrder.SalesOrganization__c, payloadMap.get('salesOrganization'), 'Should contain sales organization');
        System.assertEquals(testOrder.DistributionChannel__c, payloadMap.get('distributionChannel'), 'Should contain distribution channel');
        System.assertEquals(testOrder.OrganizationDivision__c, payloadMap.get('organizationDivision'), 'Should contain organization division');
        System.assertEquals(testOrder.CurrencyIsoCode, payloadMap.get('currencyIsoCode'), 'Should contain currency');
        System.assertEquals(testOrder.Account.ERPCustomerNumber__c, payloadMap.get('erpCustomerNumber'), 'Should contain ERP customer number');
        System.assertEquals(testOrder.PaymentTerms__c, payloadMap.get('paymentTerms'), 'Should contain payment terms');
        System.assertNotEquals(null, payloadMap.get('createdDate'), 'Should contain created date');
        System.assertNotEquals(null, payloadMap.get('requestedDeliveryDate'), 'Should contain requested delivery date');

        System.assertEquals(testOrder.SoldTo__r.ERPCustomerNumber__c, payloadMap.get('soldToPartner'), 'Should contain sold to partner');
        System.assertEquals(testOrder.ShipTo__r.ERPCustomerNumber__c, payloadMap.get('shipToPartner'), 'Should contain ship to partner');
        System.assertEquals(testOrder.BillTo__r.ERPCustomerNumber__c, payloadMap.get('billToPartner'), 'Should contain bill to partner');
        System.assertEquals(testOrder.Payer__r.ERPCustomerNumber__c, payloadMap.get('payerPartner'), 'Should contain payer partner');

        List<Object> items = (List<Object>)payloadMap.get('orderItems');
        System.assertEquals(1, items.size(), 'Should have 1 order item');

        Map<String, Object> itemMap = (Map<String, Object>)items[0];
        System.assertNotEquals(null, itemMap.get('id'), 'Item should have ID');
        System.assertEquals(5, itemMap.get('quantity'), 'Item should have correct quantity');
        System.assertEquals('EUR', itemMap.get('itemCurrencyIsoCode'), 'Item should have correct currency');
        System.assertEquals('TEST-PROD', itemMap.get('productCode'), 'Item should have correct product code');
        System.assertEquals('BASE-PROD', itemMap.get('baseProductCode'), 'Item should have correct base product code');
        System.assertEquals('EA', itemMap.get('baseUnitCode'), 'Item should have correct base unit code');
        System.assertNotEquals(null, itemMap.get('createdDate'), 'Item should have created date');
        System.assertEquals(null, itemMap.get('orderItemPos'), 'Item should have null orderItemPos');
    }

    @IsTest
    static void testCreateOrderPayload_WithNullValues_ShouldHandleGracefully() {
        // HAVING
        Account testAccount = new Account(Name = 'Test Account 2');
        insert testAccount;

        Product2 product = new Product2(
            Name = 'Test Product 2',
            ProductCode = 'TEST2',
            IsActive = true
        );
        insert product;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 50,
            IsActive = true
        );
        insert pbe;

        Order testOrder = new Order(
            AccountId = testAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testOrder;

        OrderItem item = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = 50
        );
        insert item;

        testOrder = OrderSyncService.getOrdersWithItems(new Set<Id>{testOrder.Id})[0];

        // WHEN
        Test.startTest();
        String payload = OrderSyncService.createOrderPayload(testOrder);
        Test.stopTest();

        // THEN
        Map<String, Object> payloadMap = (Map<String, Object>)JSON.deserializeUntyped(payload);
        System.assertEquals('1100', payloadMap.get('salesOrganization'), 'Should handle null sales organization');
        System.assertEquals('20', payloadMap.get('distributionChannel'), 'DistributionChannel__c defaults to 20 on insert, same as SalesOrganization__c (1100) and OrganizationDivision__c (10)');
        System.assertEquals('10', payloadMap.get('organizationDivision'), 'Should handle null organization division');
        System.assertEquals(null, payloadMap.get('requestedDeliveryDate'), 'Should handle null requested delivery date');
        System.assertEquals('D046', payloadMap.get('paymentTerms'), 'PaymentTerms__c defaults to D046 on insert');
        System.assertEquals(null, payloadMap.get('soldToPartner'), 'Should handle null sold to partner');
        System.assertEquals(null, payloadMap.get('shipToPartner'), 'Should handle null ship to partner');
        System.assertEquals(null, payloadMap.get('billToPartner'), 'Should handle null bill to partner');
        System.assertEquals(null, payloadMap.get('payerPartner'), 'Should handle null payer partner');
    }

    @IsTest
    static void testGetOrdersWithItems_ShouldReturnOrdersWithItems() {
        // HAVING
        Order testOrder = [SELECT Id FROM Order LIMIT 1];

        // WHEN
        Test.startTest();
        List<Order> orders = OrderSyncService.getOrdersWithItems(new Set<Id>{testOrder.Id});
        Test.stopTest();

        // THEN
        System.assertEquals(1, orders.size(), 'Should return 1 order');
        System.assertEquals(1, orders[0].OrderItems.size(), 'Should have 1 order item');
        System.assertNotEquals(null, orders[0].Account, 'Should have account relationship');
        System.assertNotEquals(null, orders[0].OrderItems[0].Product2, 'Should have product relationship');
    }
}