public with sharing class InvoiceCreationService {
    private static final String ERR_ACCOUNT_NOT_FOUND = 'Account not found for BillingAccountId (ERPCustomerNumber): ';
    private static final String ERR_INVALID_PAYLOAD = 'Invalid payload: invoice and invoiceLines are required';
    private static final String ERR_BILLING_ACCOUNT_REQUIRED = 'BillingAccountId is required';
    private static final String DEFAULT_CURRENCY = 'EUR';
    private static final String STATUS_CODE_DRAFT = 'Draft';
    private static final String STATUS_CODE_ACTIVATED = 'Activated';
    private static final String DEFAULT_FULFILLMENT_STATUS = 'Draft';
    private static final String LOCATION_TYPE_WAREHOUSE = 'Warehouse';
    private static final String PREFIX_LOCATION = 'Loc ';
    private static final String PREFIX_ORDER_DELIVERY_METHOD = 'ODM ';

    private static final String KEY_BILLING_ACCOUNT_ID = 'BillingAccountId';
    private static final String KEY_CURRENCY_ISO_CODE = 'CurrencyIsoCode';
    private static final String KEY_REFERENCE_ENTITY_ID = 'ReferenceEntityId';
    private static final String KEY_INVOICE_DATE = 'InvoiceDate';
    private static final String KEY_PRODUCT_NUMBER = 'ProductNumber__c';
    private static final String KEY_QUANTITY = 'Quantity';
    private static final String KEY_CHARGE_AMOUNT = 'ChargeAmount';
    private static final String KEY_NAME = 'Name';
    private static final String KEY_ERP_INVOICE_NUMBER = 'ERPInvoiceNumber__c';

    /** Status values that mean the Invoice is Posted; these fields cannot be updated. */
    private static final Set<String> STATUSES_POSTED = new Set<String>{ 'Posted', 'Post' };
    /** Fields that Salesforce does not allow updating on Posted invoices. */
    private static final Set<String> INVOICE_FIELDS_LOCKED_WHEN_POSTED = new Set<String>{
        'InvoiceDate', 'DueDate', 'BillingAccountId', 'ReferenceEntityId'
    };

    private static final Set<String> INVOICE_STRING_FIELDS = new Set<String>{
        'AccountingArea__c', 'OrganizationDivision__c', 'DistributionChannel__c', 'SalesOrganization__c',
        'InvoiceType__c', 'SalesOffice__c', 'SalesDocumentType__c', 'CurrencyIsoCode', 'CorporateCurrencyIsoCode',
        'PaymentTerms__c', 'ERPInvoiceNumber__c', 'BillingType__c', 'WeightUnit__c', 'ERPReferenceEntityId__c',
        'IncotermsCodeMandatory__c', 'DescriptionIncotermsMandatory__c', 'IncotermsCodeOptional__c',
        'DescriptionIncotermsOptional__c', 'DiscountNote__c', 'PaymentDueDateNote__c', 'PaymenTermText__c', 'TaxLocaleType'
    };
    private static final Set<String> INVOICE_DATE_FIELDS = new Set<String>{
        'ERPReferenceEntityIdDate__c', 'DeliveryNoteDate__c', 'DeliveryDate__c', 'OrderDate__c', 'ValueDate__c',
        'DiscountPeriod__c', 'PaymentDueDate__c', 'InvoiceDate', 'DueDate'
    };
    private static final Set<String> INVOICE_DATE_FIELDS_SKIP_ON_EXISTING = new Set<String>{
        'InvoiceDate', 'DueDate'
    };
    private static final Set<String> INVOICE_DECIMAL_FIELDS = new Set<String>{
        'ExchangeRate__c', 'NetWeight__c', 'GrossWeight__c', 'DiscountPercentage__c', 'DiscountForTimelyPayment__c'
    };
    private static final Map<String, String> INVOICE_FIELD_ALIASES = new Map<String, String>{
        'Delivery_Note_Number__c' => 'DeliveryNoteNumber__c'
    };

    private static final Set<String> INVOICE_LINE_STRING_FIELDS = new Set<String>{
        'PositionNumber__c', 'Unit__c', 'ProductNumber__c', 'EAN__c', 'WeightUnit__c', 'Factory__c',
        'InternalInvoiceNumber__c', 'PriorDocumentNumber__c'
    };
    private static final Set<String> INVOICE_LINE_DATE_FIELDS = new Set<String>{
        'OrderCreationDate__c', 'DeliveryDate__c', 'PriceDate__c', 'OrderDate__c'
    };
    private static final Set<String> INVOICE_LINE_DECIMAL_FIELDS = new Set<String>{
        'Quantity', 'NetWeight__c', 'GrossWeight__c', 'ChargeAmount', 'GrossUnitPrice', 'EligibleForDiscount__c'
    };
    private static final Map<String, String> INVOICE_LINE_FIELD_ALIASES = new Map<String, String>{
        'Name' => 'Description'
    };

    /** True when the last createInvoiceFromSap call updated an existing invoice; false when it created a new one. */
    public static Boolean lastOperationWasUpdate { get; set; }

    private static Order findExistingOrder(String referenceNumber, Id accountId) {
        if (String.isBlank(referenceNumber)) {
            return null;
        }

        List<Order> orders = [
            SELECT Id, Status
            FROM Order
            WHERE OrderNumber = :referenceNumber
            AND AccountId = :accountId
            LIMIT 1
        ];

        return orders.isEmpty() ? null : orders[0];
    }

    public static Id createInvoiceFromSap(Map<String, Object> invoiceData, List<Object> invoiceLines) {
        validateInput(invoiceData, invoiceLines);
        String billingAccountId = (String) getField(invoiceData, KEY_BILLING_ACCOUNT_ID);
        if (String.isBlank(billingAccountId)) {
            throw new InvoiceCreationException(ERR_BILLING_ACCOUNT_REQUIRED);
        }

        Account account = requireAccountByErpNumber(billingAccountId);
        List<Map<String, Object>> lines = castToMapList(invoiceLines);
        String erpInvoiceNumber = (String) getField(invoiceData, KEY_ERP_INVOICE_NUMBER);

        Invoice existingInvoice = findExistingInvoiceByErpNumber(account.Id, erpInvoiceNumber);
        if (existingInvoice != null) {
            lastOperationWasUpdate = true;
            updateInvoiceFromPayload(existingInvoice.Id, invoiceData, account.Id, existingInvoice.ReferenceEntityId, true);
            updateInvoiceLineItemsFromPayload(existingInvoice.Id, lines);

            return existingInvoice.Id;
        }

        lastOperationWasUpdate = false;
        InvoiceContext context = buildInvoiceContext(invoiceData, lines);


        String orderReference = (String) getField(invoiceData, KEY_REFERENCE_ENTITY_ID);
        Order order = findExistingOrder(orderReference, account.Id);

        Id orderId;
        Id orderSummaryId;

        if (order != null) {

            orderId = order.Id;
            List<OrderSummary> summaries = [SELECT Id FROM OrderSummary WHERE OriginalOrderId = :orderId LIMIT 1];

            if (!summaries.isEmpty()) {
                orderSummaryId = summaries[0].Id;
            } else {
                if (order.Status != context.activatedStatus) {
                    activateOrder(order, context.activatedStatus);
                }
                orderSummaryId = createOrderSummary(orderId);
            }
        } else {

            order = createOrderWithItems(account, invoiceData, lines, context);
            activateOrder(order, context.activatedStatus);
            orderId = order.Id;
            orderSummaryId = createOrderSummary(orderId);
        }

        Id invoiceId = createInvoiceViaConnectApi(account, orderSummaryId, context);
        updateInvoiceFromPayload(invoiceId, invoiceData, account.Id, orderId, false);
        updateInvoiceLineItemsFromPayload(invoiceId, lines);

        return invoiceId;
    }

    private static Invoice findExistingInvoiceByErpNumber(Id billingAccountId, String erpInvoiceNumber) {
        if (String.isBlank(erpInvoiceNumber)) {
            return null;
        }

        List<Invoice> invoices = [
            SELECT Id, ReferenceEntityId
            FROM Invoice
            WHERE BillingAccountId = :billingAccountId
            AND ERPInvoiceNumber__c = :erpInvoiceNumber
            LIMIT 1
        ];

        return invoices.isEmpty() ? null : invoices[0];
    }

    private static void validateInput(Map<String, Object> invoiceData, List<Object> invoiceLines) {
        if (invoiceData == null || invoiceLines == null || invoiceLines.isEmpty()) {
            throw new InvoiceCreationException(ERR_INVALID_PAYLOAD);
        }
    }

    private static Account requireAccountByErpNumber(String erpNumber) {
        Account account = findAccountByErpNumber(erpNumber);
        if (account == null) {
            throw new InvoiceCreationException(ERR_ACCOUNT_NOT_FOUND + erpNumber);
        }

        return account;
    }

    private static List<Map<String, Object>> castToMapList(List<Object> invoiceLines) {
        List<Map<String, Object>> lines = new List<Map<String, Object>>();
        for (Object item : invoiceLines) {
            lines.add((Map<String, Object>) item);
        }

        return lines;
    }

    private static InvoiceContext buildInvoiceContext(Map<String, Object> invoiceData, List<Map<String, Object>> lines) {
        Id pricebookId = Test.isRunningTest()
            ? Test.getStandardPricebookId()
            : [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
        String currencyCode = (String) getField(invoiceData, KEY_CURRENCY_ISO_CODE);
        if (String.isBlank(currencyCode)) {
            currencyCode = DEFAULT_CURRENCY;
        }

        Map<String, Id> productIdByErpNumber = resolveProducts(lines, pricebookId, currencyCode);

        InvoiceContext context = new InvoiceContext();
        context.pricebookId = pricebookId;
        context.currencyCode = currencyCode;
        context.productIdByErpNumber = productIdByErpNumber;
        context.location = createLocation();
        context.orderDeliveryMethod = createOrderDeliveryMethod();
        context.draftStatus = getOrderStatusApiName(STATUS_CODE_DRAFT);
        context.activatedStatus = getOrderStatusApiName(STATUS_CODE_ACTIVATED);
        context.deliverToName = (String) getField(invoiceData, KEY_REFERENCE_ENTITY_ID);

        return context;
    }

    private static Order createOrderWithItems(
        Account account,
        Map<String, Object> invoiceData,
        List<Map<String, Object>> lines,
        InvoiceContext context
    ) {
        if (String.isBlank(context.deliverToName)) {
            context.deliverToName = account.Name;
        }

        Order order = createDraftOrder(account, invoiceData, context);
        insert order;

        OrderDeliveryGroup orderDeliveryGroup = new OrderDeliveryGroup(
            OrderId = order.Id,
            OrderDeliveryMethodId = context.orderDeliveryMethod.Id,
            DeliverToName = context.deliverToName
        );

        insert orderDeliveryGroup;

        insertOrderItems(order.Id, orderDeliveryGroup.Id, lines, context);
        return order;
    }

    private static Order createDraftOrder(Account account, Map<String, Object> invoiceData, InvoiceContext context) {
        return new Order(
            AccountId = account.Id,
            EffectiveDate = parseDate(getField(invoiceData, KEY_INVOICE_DATE), Date.today()),
            Status = context.draftStatus,
            Pricebook2Id = context.pricebookId,
            CurrencyIsoCode = context.currencyCode
        );
    }

    private static void insertOrderItems(Id orderId, Id orderDeliveryGroupId, List<Map<String, Object>> lines, InvoiceContext context) {
        for (Map<String, Object> line : lines) {
            Id productId = context.productIdByErpNumber.get((String) getField(line, KEY_PRODUCT_NUMBER));
            if (productId == null) {
                continue;
            }

            Decimal quantity = parseDecimal(getField(line, KEY_QUANTITY));
            if (quantity == null || quantity <= 0) {
                quantity = 1;
            }

            Decimal chargeAmount = parseDecimal(getField(line, KEY_CHARGE_AMOUNT));
            if (chargeAmount == null) {
                chargeAmount = 0;
            }

            Decimal unitPrice = quantity > 0 ? chargeAmount / quantity : chargeAmount;
            Id pricebookEntryId = getOrUpdatePricebookEntry(
                context.pricebookId, productId, unitPrice, context.currencyCode
            );

            OrderItem orderItem = new OrderItem(
                OrderId = orderId,
                PricebookEntryId = pricebookEntryId,
                OrderDeliveryGroupId = orderDeliveryGroupId,
                Quantity = quantity,
                UnitPrice = unitPrice,
                ListPrice = unitPrice,
                TotalLineAmount = chargeAmount
            );

            insert orderItem;
        }
    }

    private static void activateOrder(Order order, String activatedStatus) {
        order.Status = activatedStatus;
        update order;
    }

    private static Id createOrderSummary(Id orderId) {
        ConnectApi.OrderSummaryInputRepresentation orderSummaryInput = new ConnectApi.OrderSummaryInputRepresentation();
        orderSummaryInput.orderId = orderId;
        ConnectApi.OrderSummaryOutputRepresentation orderSummaryOutput = ConnectApi.OrderSummaryCreation.createOrderSummary(orderSummaryInput);
        return orderSummaryOutput.orderSummaryId;
    }

    private static Id createInvoiceViaConnectApi(Account account, Id orderSummaryId, InvoiceContext context) {
        String fulfillmentOrderStatus = getFirstActiveFulfillmentOrderStatus();
        FulfillmentOrder fulfillmentOrder = new FulfillmentOrder(
            AccountId = account.Id,
            OrderSummaryId = orderSummaryId,
            FulfilledFromLocationId = context.location.Id,
            DeliveryMethodId = context.orderDeliveryMethod.Id,
            Status = fulfillmentOrderStatus,
            FulfilledToName = context.deliverToName
        );

        insert fulfillmentOrder;

        insertFulfillmentOrderLineItems(fulfillmentOrder.Id, orderSummaryId);

        ConnectApi.FulfillmentOrderInvoiceInputRepresentation invoiceInput = new ConnectApi.FulfillmentOrderInvoiceInputRepresentation();
        ConnectApi.FulfillmentOrderInvoiceOutputRepresentation result = ConnectApi.FulfillmentOrder.createInvoice(fulfillmentOrder.Id, invoiceInput);
        return result.invoiceId;
    }

    private static void insertFulfillmentOrderLineItems(Id fulfillmentOrderId, Id orderSummaryId) {
        List<OrderItemSummary> orderItemSummaries = [
            SELECT Id, Product2Id, Quantity, UnitPrice, TotalLineAmount, Type, TypeCode
            FROM OrderItemSummary
            WHERE OrderSummaryId = :orderSummaryId
        ];

        if (orderItemSummaries.isEmpty()) {
            return;
        }

        String defaultType = getFirstActivePicklistValue(FulfillmentOrderLineItem.Type.getDescribe());
        String defaultTypeCode = getFirstActivePicklistValue(FulfillmentOrderLineItem.TypeCode.getDescribe());

        List<FulfillmentOrderLineItem> lineItems = new List<FulfillmentOrderLineItem>();
        for (OrderItemSummary orderItemSummary : orderItemSummaries) {
            lineItems.add(new FulfillmentOrderLineItem(
                FulfillmentOrderId = fulfillmentOrderId,
                OrderItemSummaryId = orderItemSummary.Id,
                Quantity = orderItemSummary.Quantity,
                OriginalQuantity = orderItemSummary.Quantity != null ? orderItemSummary.Quantity : 0,
                Type = orderItemSummary.Type != null ? orderItemSummary.Type : defaultType,
                TypeCode = orderItemSummary.TypeCode != null ? orderItemSummary.TypeCode : defaultTypeCode,
                UnitPrice = orderItemSummary.UnitPrice,
                TotalLineAmount = orderItemSummary.TotalLineAmount
            ));
        }

        insert lineItems;
    }

    private static String getFirstActivePicklistValue(Schema.DescribeFieldResult fieldDescribe) {
        for (Schema.PicklistEntry picklistEntry : fieldDescribe.getPicklistValues()) {
            if (picklistEntry.isActive()) {
                return picklistEntry.getValue();
            }
        }

        return null;
    }

    private static void updateInvoiceFromPayload(Id invoiceId, Map<String, Object> invoiceData, Id accountId, Id orderId, Boolean skipLockedFields) {
        List<Invoice> existing = [SELECT Id, Status FROM Invoice WHERE Id = :invoiceId LIMIT 1];
        Boolean isPosted = !existing.isEmpty() && existing[0].Status != null && STATUSES_POSTED.contains(existing[0].Status);

        Invoice invoice = new Invoice(Id = invoiceId);
        if (!isPosted) {
            invoice.BillingAccountId = accountId;
            invoice.ReferenceEntityId = orderId;
        }

        for (String fieldName : INVOICE_STRING_FIELDS) {
            if (isPosted && INVOICE_FIELDS_LOCKED_WHEN_POSTED.contains(fieldName)) {
                continue;
            }

            Object value = getField(invoiceData, fieldName);
            if (value != null && String.isNotBlank(String.valueOf(value))) {
                invoice.put(fieldName, (String) value);
            }
        }

        for (String fieldName : INVOICE_DATE_FIELDS) {
            if (isPosted && INVOICE_FIELDS_LOCKED_WHEN_POSTED.contains(fieldName)) {
                continue;
            }

            if (skipLockedFields && INVOICE_DATE_FIELDS_SKIP_ON_EXISTING.contains(fieldName)) {
                continue;
            }

            Date value = parseDate(getField(invoiceData, fieldName), null);
            if (value != null) {
                invoice.put(fieldName, value);
            }
        }

        for (String fieldName : INVOICE_DECIMAL_FIELDS) {
            if (isPosted && INVOICE_FIELDS_LOCKED_WHEN_POSTED.contains(fieldName)) {
                continue;
            }

            Decimal value = parseDecimal(getField(invoiceData, fieldName));
            if (value != null) {
                invoice.put(fieldName, value);
            }
        }

        for (String payloadKey : INVOICE_FIELD_ALIASES.keySet()) {
            String targetField = INVOICE_FIELD_ALIASES.get(payloadKey);
            if (isPosted && targetField != null && INVOICE_FIELDS_LOCKED_WHEN_POSTED.contains(targetField)) {
                continue;
            }

            Object value = getField(invoiceData, payloadKey);
            if (value != null && String.isNotBlank(String.valueOf(value))) {
                invoice.put(targetField, (String) value);
            }
        }

        update invoice;
    }

    private static void updateInvoiceLineItemsFromPayload(Id invoiceId, List<Map<String, Object>> lines) {
        List<InvoiceLine> invoiceLines = [
            SELECT Id, Product2Id
            FROM InvoiceLine
            WHERE InvoiceId = :invoiceId
            ORDER BY CreatedDate ASC
        ];

        if (invoiceLines.isEmpty() || lines.isEmpty()) {
            return;
        }

        Integer lineCount = Math.min(invoiceLines.size(), lines.size());
        List<InvoiceLine> toUpdate = new List<InvoiceLine>();
        for (Integer index = 0; index < lineCount; index++) {
            Map<String, Object> line = lines[index];
            InvoiceLine invoiceLine = invoiceLines[index];

            for (String fieldName : INVOICE_LINE_STRING_FIELDS) {
                Object value = getField(line, fieldName);
                if (value != null && String.isNotBlank(String.valueOf(value))) {
                    invoiceLine.put(fieldName, (String) value);
                }
            }

            for (String fieldName : INVOICE_LINE_DATE_FIELDS) {
                Date value = parseDate(getField(line, fieldName), null);
                if (value != null) {
                    invoiceLine.put(fieldName, value);
                }
            }

            for (String fieldName : INVOICE_LINE_DECIMAL_FIELDS) {
                Decimal value = parseDecimal(getField(line, fieldName));
                if (value != null) {
                    invoiceLine.put(fieldName, value);
                }
            }

            Date serviceProvisionDate = parseCompactDate(getField(line, 'ServiceProvisionDate__c'));
            if (serviceProvisionDate != null) {
                invoiceLine.put('ServiceProvisionDate__c', serviceProvisionDate);
            }

            Object product2IdValue = getField(line, 'Product2Id');
            if (product2IdValue != null && String.isNotBlank(String.valueOf(product2IdValue))) {
                invoiceLine.Product2Id = (Id) String.valueOf(product2IdValue);
            }

            for (String payloadKey : INVOICE_LINE_FIELD_ALIASES.keySet()) {
                Object value = getField(line, payloadKey);
                if (value != null && String.isNotBlank(String.valueOf(value))) {
                    invoiceLine.put(INVOICE_LINE_FIELD_ALIASES.get(payloadKey), (String) value);
                }
            }

            toUpdate.add(invoiceLine);
        }

        update toUpdate;
    }

    private static Account findAccountByErpNumber(String erpNumber) {
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE ERPCustomerNumber__c = :erpNumber LIMIT 1];
        return accounts.isEmpty() ? null : accounts[0];
    }

    private static Map<String, Id> resolveProducts(List<Map<String, Object>> lines, Id pricebookId, String currencyCode) {
        Set<String> productNumbers = extractProductNumbersFromLines(lines);
        Map<String, Id> productIdByErpNumber = loadExistingProductsByErpNumber(productNumbers);
        Set<String> missingNumbers = getMissingProductNumbers(productNumbers, productIdByErpNumber);

        if (!missingNumbers.isEmpty()) {
            Map<String, Id> newProductIds = createAndInsertProducts(missingNumbers, lines);
            productIdByErpNumber.putAll(newProductIds);
        }

        return productIdByErpNumber;
    }

    private static Set<String> extractProductNumbersFromLines(List<Map<String, Object>> lines) {
        Set<String> productNumbers = new Set<String>();
        for (Map<String, Object> line : lines) {
            String productNumber = (String) getField(line, KEY_PRODUCT_NUMBER);
            if (String.isNotBlank(productNumber)) {
                productNumbers.add(productNumber);
            }
        }

        return productNumbers;
    }

    private static Map<String, Id> loadExistingProductsByErpNumber(Set<String> productNumbers) {
        Map<String, Id> productIdByErpNumber = new Map<String, Id>();
        for (Product2 product : [SELECT Id, ERPProductNumber__c FROM Product2 WHERE ERPProductNumber__c IN :productNumbers]) {
            productIdByErpNumber.put(product.ERPProductNumber__c, product.Id);
        }

        return productIdByErpNumber;
    }

    private static Set<String> getMissingProductNumbers(Set<String> productNumbers, Map<String, Id> existingByErpNumber) {
        Set<String> missing = new Set<String>();
        for (String productNumber : productNumbers) {
            if (!existingByErpNumber.containsKey(productNumber)) {
                missing.add(productNumber);
            }
        }

        return missing;
    }

    private static Map<String, Id> createAndInsertProducts(Set<String> productNumbers, List<Map<String, Object>> lines) {
        List<Product2> newProducts = new List<Product2>();
        for (String productNumber : productNumbers) {
            String productName = findProductNameInLines(productNumber, lines);
            newProducts.add(
                new Product2(
                    Name = productName,
                    ERPProductNumber__c = productNumber,
                    IsActive = true
                )
            );
        }

        insert newProducts;

        Map<String, Id> result = new Map<String, Id>();
        for (Product2 product : newProducts) {
            result.put(product.ERPProductNumber__c, product.Id);
        }

        return result;
    }

    private static String findProductNameInLines(String productNumber, List<Map<String, Object>> lines) {
        for (Map<String, Object> line : lines) {
            if (!productNumber.equals(getField(line, KEY_PRODUCT_NUMBER))) {
                continue;
            }

            Object nameValue = getField(line, KEY_NAME);
            if (nameValue != null && String.isNotBlank((String) nameValue)) {
                return (String) nameValue;
            }

            break;
        }

        return productNumber;
    }

    private static Id getOrUpdatePricebookEntry(Id pricebookId, Id productId, Decimal unitPrice, String currencyCode) {
        List<PricebookEntry> pricebookEntries = [
            SELECT Id, UnitPrice FROM PricebookEntry
            WHERE Pricebook2Id = :pricebookId
            AND Product2Id = :productId AND IsActive = true
            LIMIT 1
        ];

        if (!pricebookEntries.isEmpty()) {
            PricebookEntry pricebookEntry = pricebookEntries[0];
            if (pricebookEntry.UnitPrice != unitPrice) {
                pricebookEntry.UnitPrice = unitPrice;
                update pricebookEntry;
            }

            return pricebookEntry.Id;
        }

        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = productId,
            UnitPrice = unitPrice,
            IsActive = true
        );

        insert pricebookEntry;
        return pricebookEntry.Id;
    }

    private static Schema.Location createLocation() {
        String timestamp = String.valueOf(DateTime.now().getTime());
        Schema.Location location = new Schema.Location(
            Name = PREFIX_LOCATION + timestamp,
            LocationType = LOCATION_TYPE_WAREHOUSE,
            IsInventoryLocation = true
        );

        insert location;
        return location;
    }

    private static OrderDeliveryMethod createOrderDeliveryMethod() {
        String timestamp = String.valueOf(DateTime.now().getTime());
        OrderDeliveryMethod orderDeliveryMethod = new OrderDeliveryMethod(
            Name = PREFIX_ORDER_DELIVERY_METHOD + timestamp,
            IsActive = true
        );

        insert orderDeliveryMethod;
        return orderDeliveryMethod;
    }

    private static String getOrderStatusApiName(String statusCode) {
        List<OrderStatus> statuses = [SELECT ApiName FROM OrderStatus WHERE StatusCode = :statusCode LIMIT 1];
        return statuses.isEmpty() ? statusCode : statuses[0].ApiName;
    }

    private static String getFirstActiveFulfillmentOrderStatus() {
        for (Schema.PicklistEntry picklistEntry : FulfillmentOrder.Status.getDescribe().getPicklistValues()) {
            if (picklistEntry.isActive()) {
                return picklistEntry.getValue();
            }
        }

        return DEFAULT_FULFILLMENT_STATUS;
    }

    private static Object getField(Map<String, Object> recordMap, String key) {
        return recordMap == null ? null : recordMap.get(key);
    }

    private static Date parseDate(Object value, Date defaultVal) {
        if (value == null) {
            return defaultVal;
        }

        String stringValue = String.valueOf(value);
        if (String.isBlank(stringValue)) {
            return defaultVal;
        }

        Date compactDate = parseCompactDate(value);
        if (compactDate != null) {
            return compactDate;
        }

        try {
            return Date.valueOf(stringValue);
        } catch (Exception parseException) {
            return defaultVal;
        }
    }

    private static Date parseCompactDate(Object value) {
        if (value == null) {
            return null;
        }

        String stringValue = String.valueOf(value).trim();
        if (stringValue.length() != 8) {
            return null;
        }

        try {
            Integer year = Integer.valueOf(stringValue.substring(0, 4));
            Integer month = Integer.valueOf(stringValue.substring(4, 6));
            Integer day = Integer.valueOf(stringValue.substring(6, 8));
            return Date.newInstance(year, month, day);
        } catch (Exception parseException) {
            return null;
        }
    }

    private static Decimal parseDecimal(Object value) {
        if (value == null) {
            return null;
        }

        if (value instanceof Decimal) {
            return (Decimal) value;
        }

        if (value instanceof Integer) {
            return Decimal.valueOf((Integer) value);
        }

        String stringValue = String.valueOf(value);
        if (String.isBlank(stringValue)) {
            return null;
        }

        try {
            return Decimal.valueOf(stringValue.trim().replace(',', '.'));
        } catch (Exception parseException) {
            return null;
        }
    }

    private class InvoiceContext {
        Id pricebookId;
        String currencyCode;
        Map<String, Id> productIdByErpNumber;
        Schema.Location location;
        OrderDeliveryMethod orderDeliveryMethod;
        String draftStatus;
        String activatedStatus;
        String deliverToName;
    }

    public class InvoiceCreationException extends Exception {}
}