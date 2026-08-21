public with sharing class OrderSyncService {
    private static final String MULESOFT_MDT_NOT_FOUND_ENDPOINT = 'No Mulesoft endpoint configuration found for environment: ';
    private static final String MULESOFT_RESPONSE_ERROR = 'MuleSoft API call failed with status: ';
    private static final String PROD_LABEL = 'Production';
    private static final String SB_LABEL = 'Sandbox';

    @TestVisible
    private static Boolean isTestEnvironment = false;
    @TestVisible
    private static String testEndpoint;
    @TestVisible
    private static HttpResponse testResponse;
    @TestVisible
    private static List<HttpRequest> capturedRequests = new List<HttpRequest>();

    public static void pushOrders(Set<Id> orderIds) {
        if (orderIds == null || orderIds.isEmpty()) {
            return;
        }

        List<String> payloads = new List<String>();
        for (Order ord : getOrdersWithItems(orderIds)) {
            payloads.add(createOrderPayload(ord));
        }

        sendToMuleSoft('{"data":[' + String.join(payloads, ', ') + ']}', getMulesoftEndpoint());
    }

    private static String getMulesoftEndpoint() {
        if (isTestEnvironment && testEndpoint != null) {
            return testEndpoint;
        }

        String endpointLabel = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox ? SB_LABEL : PROD_LABEL;
        MuleSoftOrderEndpoints__mdt endpointConfig = [
            SELECT Endpoint__c
            FROM MuleSoftOrderEndpoints__mdt
            WHERE MasterLabel = :endpointLabel
            LIMIT 1
        ];

        if (endpointConfig == null) {
            throw new CalloutException(MULESOFT_MDT_NOT_FOUND_ENDPOINT + endpointLabel);
        }

        return endpointConfig.Endpoint__c;
    }

    @TestVisible
    private static List<Order> getOrdersWithItems(Set<Id> orderIds) {
        return [
            SELECT Id, OrderNumber, OrderReferenceNumber, Type, CreatedDate, Account.ERPCustomerNumber__c,
            SalesOrganization__c, DistributionChannel__c, OrganizationDivision__c,
            CurrencyIsoCode, RequestedDeliveryDate__c, PreferredShippingCondition__c,
            PaymentTerms__c,
            SoldTo__r.ERPCustomerNumber__c,
            ShipTo__r.ERPCustomerNumber__c, BillTo__r.ERPCustomerNumber__c, Payer__r.ERPCustomerNumber__c,
                (
                    SELECT Id, Quantity, Product2.ProductCode, Product2.BaseProductCode__c,
                    Product2.BaseUnitCode__c, TotalPrice, UnitPrice, CreatedDate,
                    Product2.QuantityUnitOfMeasure, CurrencyIsoCode
                    FROM OrderItems
                    ORDER BY CreatedDate ASC
                )
            FROM Order
            WHERE Id IN :orderIds
        ];
    }

    @TestVisible
    private static String createOrderPayload(Order order) {
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('salesOrganization', order.SalesOrganization__c);
        payload.put('organizationDivision', order.OrganizationDivision__c);
        payload.put('currencyIsoCode', order.CurrencyIsoCode);
        payload.put('distributionChannel', order.DistributionChannel__c);
        payload.put('requestedDeliveryDate', formatDate(order.RequestedDeliveryDate__c));
        payload.put('erpCustomerNumber', order.Account?.ERPCustomerNumber__c);
        payload.put('createdDate', formatDate(order.CreatedDate));
        payload.put('orderType', order.Type);
        payload.put('orderNumber', order.OrderNumber);
        payload.put('orderReferenceNumber', order.OrderReferenceNumber);
        payload.put('preferredShippingCondition', order.PreferredShippingCondition__c);
        payload.put('paymentTerms', order.PaymentTerms__c);
        payload.put('id', order.Id);
        payload.put('soldToPartner', order.SoldTo__r.ERPCustomerNumber__c);
        payload.put('shipToPartner', order.ShipTo__r.ERPCustomerNumber__c);
        payload.put('billToPartner', order.BillTo__r.ERPCustomerNumber__c);
        payload.put('payerPartner', order.Payer__r.ERPCustomerNumber__c);

        List<Map<String, Object>> orderItems = new List<Map<String, Object>>();
        for (OrderItem item : order.OrderItems) {
            Map<String, Object> itemMap = new Map<String, Object>();
            itemMap.put('createdDate', formatDate(item.CreatedDate));
            itemMap.put('itemCurrencyIsoCode', item.CurrencyIsoCode);
            itemMap.put('unitPrice', item.UnitPrice);
            itemMap.put('totalPrice', item.TotalPrice);
            itemMap.put('baseUnitCode', item.Product2?.QuantityUnitOfMeasure);
            itemMap.put('productCode', item.Product2?.ProductCode);
            // SAP material number; the ERP leg sends this as Material and falls back to productCode.
            itemMap.put('baseProductCode', item.Product2?.BaseProductCode__c);
            itemMap.put('quantity', item.Quantity);
            itemMap.put('orderItemPos', null);
            itemMap.put('id', item.Id);

            orderItems.add(itemMap);
        }

        payload.put('orderItems', orderItems);

        return JSON.serialize(payload);
    }

    private static String formatDate(Datetime dt) {
        if (dt == null) return null;
        return dt.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    }

    private static String formatDate(Date d) {
        if (d == null) return null;
        return Datetime.newInstance(
            d.year(), d.month(), d.day()).format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''
        );
    }

    @future(callout=true)
    private static void sendToMuleSoft(String payload, String endpoint) {
        if (isTestEnvironment) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(payload);
            capturedRequests.add(req);

            return;
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(payload);

        Http http = new Http();
        HttpResponse res = http.send(req);
    }
}