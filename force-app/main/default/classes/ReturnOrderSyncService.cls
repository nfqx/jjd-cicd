public with sharing class ReturnOrderSyncService {
    private static final String MULESOFT_MDT_NOT_FOUND_ENDPOINT = 'No MuleSoft endpoint configuration found for environment: ';
    private static final String PROD_LABEL = 'Production';
    private static final String SB_LABEL = 'Sandbox';

    @TestVisible
    private static Boolean isTestEnvironment = false;
    @TestVisible
    private static String testEndpoint;
    @TestVisible
    private static List<HttpRequest> capturedRequests = new List<HttpRequest>();

    // JJD-28 — Create ReturnOrder in SAP. Triggered on afterInsert when ERPReturnOrderNumber__c is blank.
    // POSTs the full return payload to MuleSoft, which creates A_CustomerReturn via OData.
    public static void pushReturnOrderCreate(Set<Id> returnOrderIds) {
        if (returnOrderIds == null || returnOrderIds.isEmpty()) {
            return;
        }

        List<String> payloads = new List<String>();
        for (ReturnOrder ro : getReturnOrdersForCreate(returnOrderIds)) {
            // Guard: SAP requires SoldToParty (maps from soldToParty → Account fallback).
            // If neither resolves, the callout will fail with S4HANA:INVALID_ENTITY — skip it.
            if (String.isBlank(ro.SoldTo__r?.ERPCustomerNumber__c)
                    && String.isBlank(ro.Account?.ERPCustomerNumber__c)) {
                continue;
            }
            payloads.add(createReturnOrderCreatePayload(ro));
        }

        if (payloads.isEmpty()) {
            return;
        }

        sendToMuleSoft('{"data":[' + String.join(payloads, ', ') + ']}', getMulesoftEndpoint(), 'POST');
    }

    // JJD-26 — Credit Memo / Billing Release. Triggered when BillingBlocked__c changes true -> false.
    // Pushes the release to MuleSoft, which removes the billing block on the SAP CustomerReturn
    // (PATCH A_CustomerReturn, identified by ERPReturnOrderNumber__c). Mirrors OrderSyncService.
    public static void pushBillingReleases(Set<Id> returnOrderIds) {
        if (returnOrderIds == null || returnOrderIds.isEmpty()) {
            return;
        }

        List<String> payloads = new List<String>();
        for (ReturnOrder ro : getReturnOrders(returnOrderIds)) {
            payloads.add(createReturnOrderPayload(ro));
        }

        if (payloads.isEmpty()) {
            return;
        }

        // Billing release is an update -> PATCH; create (JJD-28) uses POST to the same resource.
        sendToMuleSoft('{"data":[' + String.join(payloads, ', ') + ']}', getMulesoftEndpoint(), 'PATCH');
    }

    private static String getMulesoftEndpoint() {
        if (isTestEnvironment && testEndpoint != null) {
            return testEndpoint;
        }

        String endpointLabel = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox ? SB_LABEL : PROD_LABEL;
        MuleSoftReturnEndpoints__mdt endpointConfig = [
            SELECT Endpoint__c
            FROM MuleSoftReturnEndpoints__mdt
            WHERE MasterLabel = :endpointLabel
            LIMIT 1
        ];

        if (endpointConfig == null) {
            throw new CalloutException(MULESOFT_MDT_NOT_FOUND_ENDPOINT + endpointLabel);
        }

        return endpointConfig.Endpoint__c;
    }

    @TestVisible
    private static List<ReturnOrder> getReturnOrders(Set<Id> returnOrderIds) {
        return [
            SELECT Id, ReturnOrderNumber, ERPReturnOrderNumber__c, BillingBlocked__c
            FROM ReturnOrder
            WHERE Id IN :returnOrderIds
        ];
    }

    @TestVisible
    private static List<ReturnOrder> getReturnOrdersForCreate(Set<Id> returnOrderIds) {
        return [
            SELECT Id,
                   SalesOrganization__c, DistributionChannel__c, OrganizationDivision__c,
                   ReturnReason__c, ReturnOrderType__c, PurchaseOrderbyCustomer__c,
                   CurrencyIsoCode, RequestedPickupDate__c,
                   // Fallback anchor for partner roles (JJD-28 "always populated") — the
                   // ReturnOrder's own Account ERP number, mirrors OrderSyncService.
                   Account.ERPCustomerNumber__c,
                   // ReferenceSDDocument is filled from the linked Order or Invoice (mapping JJD-28),
                   // not from a dedicated field. Only one of the two lookups is populated in SF.
                   Order.ERP_Order_Number__c,
                   LegacyInvoice__r.ERPInvoiceNumber__c,
                   SoldTo__r.ERPCustomerNumber__c,
                   ShipTo__r.ERPCustomerNumber__c,
                   BillTo__r.ERPCustomerNumber__c,
                   Payer__r.ERPCustomerNumber__c,
                   (SELECT Product2.ProductCode, Product2.BaseProductCode__c,
                           Product2.QuantityUnitOfMeasure,
                           QuantityExpected, QuantityUnitOfMeasure, CurrencyIsoCode
                    FROM ReturnOrderLineItems)
            FROM ReturnOrder
            WHERE Id IN :returnOrderIds
        ];
    }

    @TestVisible
    private static String createReturnOrderCreatePayload(ReturnOrder ro) {
        Map<String, Object> partners = new Map<String, Object>{
            'soldTo' => ro.SoldTo__r  != null ? ro.SoldTo__r.ERPCustomerNumber__c  : null,
            'shipTo' => ro.ShipTo__r != null ? ro.ShipTo__r.ERPCustomerNumber__c : null,
            'billTo' => ro.BillTo__r != null ? ro.BillTo__r.ERPCustomerNumber__c : null,
            'payer'  => ro.Payer__r  != null ? ro.Payer__r.ERPCustomerNumber__c   : null
        };

        List<Map<String, Object>> lineItems = new List<Map<String, Object>>();
        if (ro.ReturnOrderLineItems != null) {
            for (ReturnOrderLineItem item : ro.ReturnOrderLineItems) {
                lineItems.add(new Map<String, Object>{
                    'material'             => item.Product2 == null ? null : (String.isNotBlank(item.Product2.BaseProductCode__c) ? item.Product2.BaseProductCode__c : item.Product2.ProductCode),
                    'requestedQuantity'    => item.QuantityExpected,
                    'requestedQuantityUnit'=> item.Product2 != null && String.isNotBlank(item.Product2.QuantityUnitOfMeasure) ? item.Product2.QuantityUnitOfMeasure : item.QuantityUnitOfMeasure,
                    'transactionCurrency'  => item.CurrencyIsoCode
                });
            }
        }

        Map<String, Object> payload = new Map<String, Object>{
            // SF ReturnOrder Id — used by Mule to write ERPReturnOrderNumber__c back after SAP create.
            'id'                   => ro.Id,
            // Account ERP number — fallback for any unfilled partner role (mirrors Order integration).
            'erpCustomerNumber'    => ro.Account != null ? ro.Account.ERPCustomerNumber__c : null,
            'salesOrganization'    => ro.SalesOrganization__c,
            'distributionChannel'  => ro.DistributionChannel__c,
            'organizationDivision' => ro.OrganizationDivision__c,
            'returnReason'         => ro.ReturnReason__c,
            'purchaseOrderByCustomer' => ro.PurchaseOrderbyCustomer__c,
            'referenceSDDocument'  => ro.Order != null            ? ro.Order.ERP_Order_Number__c
                                    : ro.LegacyInvoice__r != null ? ro.LegacyInvoice__r.ERPInvoiceNumber__c
                                    : null,
            'returnOrderType'      => ro.ReturnOrderType__c,
            'transactionCurrency'  => ro.CurrencyIsoCode,
            'requestedPickupDate'  => formatDate(ro.RequestedPickupDate__c),
            'soldToParty'          => ro.SoldTo__r != null ? ro.SoldTo__r.ERPCustomerNumber__c : null,
            'partners'             => partners,
            'returnOrderLineItems' => lineItems
        };

        return JSON.serialize(payload);
    }

    @TestVisible
    private static String createReturnOrderPayload(ReturnOrder returnOrder) {
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('id', returnOrder.Id);
        payload.put('returnOrderNumber', returnOrder.ReturnOrderNumber);
        // Key for identifying the SAP CustomerReturn (= CustomerReturn / BELNR).
        payload.put('erpReturnOrderNumber', returnOrder.ERPReturnOrderNumber__c);
        payload.put('billingBlocked', returnOrder.BillingBlocked__c);
        return JSON.serialize(payload);
    }

    // Mirrors OrderSyncService.formatDate — SAP/OData expect ISO 8601 (yyyy-MM-dd'T'HH:mm:ss'Z'),
    // not the space-separated default of String.valueOf(Datetime).
    private static String formatDate(Datetime dt) {
        if (dt == null) {
            return null;
        }
        return dt.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    }

    @future(callout=true)
    private static void sendToMuleSoft(String payload, String endpoint, String method) {
        if (isTestEnvironment) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod(method);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(payload);
            capturedRequests.add(req);

            return;
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(payload);

        Http http = new Http();
        HttpResponse res = http.send(req);
    }
}