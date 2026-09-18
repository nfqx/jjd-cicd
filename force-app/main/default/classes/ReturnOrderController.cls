public with sharing class ReturnOrderController {
    private static final String CASE_PREFIX = Schema.getGlobalDescribe().get('Case').getDescribe().getKeyPrefix();
    private static final String ACCOUNT_PREFIX = Schema.getGlobalDescribe().get('Account').getDescribe().getKeyPrefix();
    private static final String DEFAULT_RETURN_REASON = 'R18';
    private static final Integer MAX_ITEM_COUNT = 3;

    @AuraEnabled(cacheable=false)
    public static AddressPricebookWrapper reselectAddressesAndPricebook(String recordId){
        Map<String, Decimal> pricebookMap = new Map<String, Decimal>();
        for(PricebookEntry pbe : [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2.ProductClass IN ('Simple', 'Variation') AND Pricebook2.Account__c = : recordId]){
            pricebookMap.put(pbe.Product2Id, pbe.UnitPrice);
        }
        List<CustomAddress__c> customAddresses = [SELECT Id, Name FROM CustomAddress__c WHERE Account__c = : recordId AND AddressType__c = 'Shipping' AND IsPrimary__c = TRUE AND IsValid__c = TRUE ORDER BY CreatedDate];
        Set<String> customerListingProductIds = WebshopDataController.retrieveAllowedProductIds(recordId);
        Set<String> coreAssortmentProductIds = WebshopDataController.retrieveOwnProductIds(recordId);

        List<ProductWrapper> coreAssortmentProducts = transformToProductWrappers(coreAssortmentProductIds);
        List<ProductWrapper> listedAssortmentProducts = transformToProductWrappers(customerListingProductIds);
        
        return !customAddresses.isEmpty() ? 
            new AddressPricebookWrapper(pricebookMap, customAddresses[0], customerListingProductIds, coreAssortmentProducts, listedAssortmentProducts) : 
            new AddressPricebookWrapper(pricebookMap, null, customerListingProductIds, coreAssortmentProducts, listedAssortmentProducts);
    }

    @AuraEnabled(cacheable=false)
    public static PrefillWrapper retrievePrefill(String recordId){
        if(String.isNotBlank(recordId)){
            if(recordId.startsWith(CASE_PREFIX)){
                Case c = [SELECT Id, ReturnOrder__c, ReturnOrder__r.Id, ReturnOrder__r.ReturnOrderType__c, ReturnOrder__r.CreditIssuance__c, ReturnOrder__r.ReferenceType__c, 
                    ReturnOrder__r.LegacyInvoice__c, ReturnOrder__r.NoDocumentReason__c, ReturnOrder__r.ShippingCondition__c, ReturnOrder__r.RequestedPickupDate__c,
                    ReturnOrder__r.AccountId, ReturnOrder__r.Account.Name, ReturnOrder__r.OrderId, ReturnOrder__r.Order.Id, ReturnOrder__r.Order.OrderNumber, ReturnOrder__r.Order.CreatedDate, 
                    ReturnOrder__r.Order.Status, ReturnOrder__r.Order.TotalAmount, ReturnOrder__r.Order.Invoice__c, ReturnOrder__r.LegacyInvoice__r.DocumentNumber, ReturnOrder__r.Account.SoldToParty__c, ReturnOrder__r.Account.ShipToParty__c,
                    ReturnOrder__r.LegacyInvoice__r.CreatedDate, ReturnOrder__r.LegacyInvoice__r.Status, ReturnOrder__r.LegacyInvoice__r.InvoiceType__c, ReturnOrder__r.LegacyInvoice__r.TotalAmount, ReturnOrder__r.LegacyInvoice__r.Id, 
                    ReturnOrder__r.Address__c, ReturnOrder__r.Address__r.Id, ReturnOrder__r.Address__r.Name, Invoice__r.InvoiceType__c,
                    AccountId, Account.Name, Order__c, Order__r.Id, Order__r.OrderNumber, Order__r.CreatedDate, Order__r.Status, Order__r.TotalAmount, Order__r.Invoice__c,
                    Invoice__r.CreatedDate, Invoice__r.Status, Invoice__r.TotalAmount, Invoice__r.Id, Invoice__r.DocumentNumber, Account.SoldToParty__c, Account.ShipToParty__c FROM Case WHERE Id = : recordId];
                CustomAddress__c addressPrefill = c.ReturnOrder__r?.Address__c != null ? c.ReturnOrder__r.Address__r : null;
                Invoice inv = c.ReturnOrder__r?.LegacyInvoice__c != null ? c.ReturnOrder__r.LegacyInvoice__r : (c.Invoice__c != null ? c.Invoice__r : null);
                Order order = c.ReturnOrder__r?.OrderId != null ? c.ReturnOrder__r.Order : (c.Order__c != null ? c.Order__r : null);
                ReturnOrder returnOrder = c.ReturnOrder__c != null ? c.ReturnOrder__r : null;
                List<ProductWrapper> orderPositions = null;
                List<ProductWrapper> invoicePositions = null; 
                List<ProductWrapper> returnOrderItems = null; 
                String invoiceSubtext = null;
                String orderSubtext = null;
                List<Order> invoiceOrders = new List<Order>();
                Set<String> customerListingProductIds = new Set<String>();
                Set<String> coreAssortmentProductIds = new Set<String>();
                Map<String, Decimal> pricebookMap = new Map<String, Decimal>();
                Set<String> productIds = new Set<String>();
                List<ProductWrapper> coreAssortmentProducts = new List<ProductWrapper>();
                List<ProductWrapper> listedAssortmentProducts = new List<ProductWrapper>();
                if(c.AccountId != null){
                    if(addressPrefill == null){
                        List<CustomAddress__c> addresses = [SELECT Id, Name FROM CustomAddress__c WHERE Account__c = : c.AccountId AND AddressType__c = 'Shipping' AND IsPrimary__c = TRUE AND IsValid__c = TRUE ORDER BY CreatedDate];
                        addressPrefill = !addresses.isEmpty() ? addresses[0] : null;
                    }
                    for(PricebookEntry pbe : [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2.ProductClass IN ('Simple', 'Variation') AND Pricebook2.Account__c = : c.AccountId]){
                        pricebookMap.put(pbe.Product2Id, pbe.UnitPrice);
                    }
                    customerListingProductIds = WebshopDataController.retrieveAllowedProductIds(c.AccountId);
                    coreAssortmentProductIds = WebshopDataController.retrieveOwnProductIds(c.AccountId);
                    
                    coreAssortmentProducts = transformToProductWrappers(coreAssortmentProductIds);
                    listedAssortmentProducts = transformToProductWrappers(customerListingProductIds);
                }
                if(order != null){
                    orderPositions = new List<ProductWrapper>();
                    Integer extraCount = 0;
                    Set<String> uniqueProductNames = new Set<String>();
                    for(OrderItem oi : [SELECT Id, Product2.Name, Product2.ProductCode, Product2.QuantityUnitOfMeasure, Product2.CurrencyIsoCode, Product2.Factor__c, Product2.BaseProductCode__c, Product2Id, Product2.Id, Quantity, UnitPrice FROM OrderItem WHERE OrderId = : order.Id AND Product2Id != NULL]){
                        orderPositions.add(new ProductWrapper(oi.Product2, oi.Quantity, oi.UnitPrice));
                        productIds.add(oi.Product2Id);
                        if(uniqueProductNames.size() <= MAX_ITEM_COUNT){
                            uniqueProductNames.add(oi.Product2.Name);
                        } else {
                            extraCount++;
                        }
                    }
                    orderSubtext = String.join(uniqueProductNames, ', ') + (extraCount > 0 ? (' ' + String.format(System.Label.ReturnOrderMaskAndXMore, new List<String>{String.valueOf(extraCount)})) : '');
                    orderPositions = !orderPositions.isEmpty() ? orderPositions : null;
                }
                if(inv != null){
                    invoicePositions = new List<ProductWrapper>();
                    for(InvoiceLine il : [SELECT Id, Product2.Name, Product2.ProductCode, Product2.QuantityUnitOfMeasure, Product2.CurrencyIsoCode, Product2.Factor__c, Product2.BaseProductCode__c, Product2Id, Product2.Id, Quantity, UnitPrice FROM InvoiceLine WHERE InvoiceId = : inv.Id AND Product2Id != NULL]){
                        invoicePositions.add(new ProductWrapper(il.Product2, il.Quantity, il.UnitPrice));
                        productIds.add(il.Product2Id);
                    }
                    invoicePositions = !invoicePositions.isEmpty() ? invoicePositions : null;
                    invoiceOrders = [SELECT Id, CurrencyIsoCode, OrderNumber, CreatedDate, Status, TotalAmount, (SELECT Id, Product2.Name, Product2.ProductCode, Product2.CurrencyIsoCode, Product2.BaseProductCode__c, Product2.QuantityUnitOfMeasure, Quantity, UnitPrice, TotalPrice FROM OrderItems) FROM Order WHERE Invoice__c = : inv.Id];
                    invoiceSubtext = invoiceOrders.isEmpty() ? System.Label.ReturnOrderMaskNoOrdersInInvoice : (
                        invoiceOrders.size() == 1 ? (System.Label.ReturnOrderMaskInvoiceFor + ' ' + invoiceOrders[0].OrderNumber) : (System.Label.ReturnOrderMaskCollectiveInvoiceFor + ' ' + String.valueOf(invoiceOrders.size()) + ' ' + System.Label.ReturnOrderMaskInvoices)
                    );
                }
                if(c.ReturnOrder__c != null){
                    returnOrderItems  = new List<ProductWrapper>();
                    for(ReturnOrderLineItem roi : [SELECT Id, Product2.Name, Product2.ProductCode, QuantityUnitOfMeasure, Product2.CurrencyIsoCode, Product2.Factor__c, Product2.BaseProductCode__c, Product2Id, Product2.Id, CreditIssuance__c, ReturnReason__c, UnitPrice, Description, QuantityExpected FROM ReturnOrderLineItem WHERE ReturnOrderId = : c.ReturnOrder__c AND Product2Id != NULL]){
                        returnOrderItems.add(new ProductWrapper(roi));
                        productIds.add(roi.Product2Id);
                    }
                }
                if(!productIds.isEmpty()){
                    Map<String, List<Map<String, String>>> productToVariationsMap = getProductVariations(new List<String>(productIds));
                    if(orderPositions != null){
                        for(ProductWrapper wrapper : orderPositions){
                            if(productToVariationsMap.containsKey(wrapper.productId)){
                                wrapper.variations = productToVariationsMap.get(wrapper.productId);
                            }
                        }
                    }
                    if(invoicePositions != null){
                        for(ProductWrapper wrapper : invoicePositions){
                            if(productToVariationsMap.containsKey(wrapper.productId)){
                                wrapper.variations = productToVariationsMap.get(wrapper.productId);
                            }
                        }
                    }
                    if(returnOrderItems != null){
                        for(ProductWrapper wrapper : returnOrderItems){
                            if(productToVariationsMap.containsKey(wrapper.productId)){
                                wrapper.variations = productToVariationsMap.get(wrapper.productId);
                            }
                        }
                    }
                }
                
                return new PrefillWrapper(c.Account, addressPrefill, inv, order, orderPositions, invoicePositions, invoiceOrders, orderSubtext, invoiceSubtext, pricebookMap, returnOrder, returnOrderItems, customerListingProductIds, coreAssortmentProducts, listedAssortmentProducts);
            } else if(recordId.startsWith(ACCOUNT_PREFIX)){
                Map<String, Decimal> pricebookMap = new Map<String, Decimal>();
                Account ac = [SELECT Id, Name, SoldToParty__c, ShipToParty__c, (SELECT Id, Name FROM CustomAddresses__r WHERE AddressType__c = 'Shipping' AND IsPrimary__c = TRUE AND IsValid__c = TRUE ORDER BY CreatedDate) FROM Account WHERE Id = : recordId];
                CustomAddress__c addressPrefill = !ac.CustomAddresses__r.isEmpty() ? ac.CustomAddresses__r[0] : null;                
                for(PricebookEntry pbe : [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2.ProductClass IN ('Simple', 'Variation') AND Pricebook2.Account__c = : recordId]){
                    pricebookMap.put(pbe.Product2Id, pbe.UnitPrice);
                }
                Set<String> customerListingProductIds = WebshopDataController.retrieveAllowedProductIds(ac.Id);
                Set<String> coreAssortmentProductIds = WebshopDataController.retrieveOwnProductIds(ac.Id);

                List<ProductWrapper> coreAssortmentProducts = transformToProductWrappers(coreAssortmentProductIds);
                List<ProductWrapper> listedAssortmentProducts = transformToProductWrappers(customerListingProductIds);
                return new PrefillWrapper(ac, addressPrefill, null, null, null, null, null, null, null, pricebookMap, null, null, customerListingProductIds, coreAssortmentProducts, listedAssortmentProducts);
            }
        }
        return new PrefillWrapper();
    }

    public static List<ProductWrapper> transformToProductWrappers(Set<String> recordIds){
        List<ProductWrapper> wrappers = new List<ProductWrapper>();
        for(Product2 prod : [SELECT Id, Name, ProductCode, QuantityUnitOfMeasure, CurrencyIsoCode, Factor__c, BaseProductCode__c FROM Product2 WHERE Id IN : recordIds]){
            wrappers.add(new ProductWrapper(prod, 1, null));
        }
        return wrappers;
    }

    private static Map<String,Object> buildPayload(
        ProductWrapper wrapper,
        String customerReferenceId,
        ERPIntegrationSettings__mdt cfg
    ){
        Map<String,Object> root = new Map<String,Object>();
        
        // Order Items
        Integer lineNum = 1;    
        String isoCode = null;
        List<Map<String,Object>> orderItems = new List<Map<String,Object>>();   
        // Build item
        List<String> ciSplit = WebshopDataController.splitLastSuffix(wrapper.productCode);
        Map<String,Object> item = new Map<String,Object>();            
        item.put('Quantity', wrapper.quantity);
        item.put('CurrencyIsoCode', wrapper.currencyIsoCode);
        isoCode = wrapper.currencyIsoCode;
        item.put('LineNumber', lineNum++);            
        Map<String,Object> product = new Map<String,Object>();
        product.put('Id', wrapper.productId);
        product.put('ProductCode', wrapper.productCode.replace('OLD_', ''));
        product.put('BaseProductCode__c', wrapper.baseProductCode.replace('OLD_', ''));
        product.put('Name', wrapper.name);
        if(String.isNotBlank(wrapper.quantityUnitOfMeasure)){
            product.put('QuantityUnitOfMeasure', wrapper.quantityUnitOfMeasure);  
        } else {
            if(!ciSplit.isEmpty() && ciSplit.size() > 1 && ciSplit[1].isAlpha()){
                product.put('QuantityUnitOfMeasure', ciSplit[1]);
            }
        }
        item.put('Product2', product);
        item.put('Product2Id', wrapper.productId);
        orderItems.add(item);
        root.put('OrderItems', orderItems);        
        // Partner Roles
        Map<String,Object> partner = new Map<String,Object>{
            'ERPCustomerNumber__c' => customerReferenceId
        };
        
        root.put('Account', partner);
        root.put('SoldTo__r', partner);
        root.put('BillTo__r', partner);
        root.put('ShipTo__r', partner);
        root.put('Payer__r', partner);
        
        // Order Header
        root.put('Type', cfg.OrderType__c);
        //root.put('OrderReferenceNumber', 'Test');
        root.put('CurrencyIsoCode', isoCode);
        root.put('SalesOrganization__c', cfg.SalesOrg__c);
        root.put('DistributionChannel__c', cfg.DistChannel__c);
        root.put('OrganizationDivision__c', cfg.Division__c);        
        return root;
    }

    @AuraEnabled(cacheable=false)
    public static Decimal getSinglePriceByOrderSimulation(String productStr, String accountId){
        try {
            // 1. Load data
            if(String.isNotBlank(productStr)){
                ProductWrapper productObj = (ProductWrapper) System.JSON.deserialize(productStr, ProductWrapper.class);
                Account ac = [SELECT Id, ERPCustomerNumber__c FROM Account WHERE Id = :accountId];
                ERPIntegrationSettings__mdt cfg = ERPIntegrationSettings__mdt.getInstance('Default');

                // 2. Build payload
                Map<String,Object> payload = buildPayload(productObj, ac.ERPCustomerNumber__c, cfg);
                String body = JSON.serialize(payload);
                OrderSimulationController.ReturnWrapper simulationResponse = OrderSimulationController.sendToOrderSimulation(body, cfg);
                if(simulationResponse.isSuccess == false){
                    return null;
                }
                Map<String, Object> data = simulationResponse.data;
                if(data != null && data.containsKey('OrderItems')){
                    for(Object oiObj : (List<Object>) data.get('OrderItems')){
                        Map<String, Object> oi = (Map<String, Object>) oiObj;
                        if(oi.containsKey('Product2')){
                            Map<String, Object> product2 = (Map<String, Object>) oi.get('Product2');
                            if(product2.containsKey('Id')){
                                String productId = (String) product2.get('Id');
                                if(String.isNotBlank(productId) && productId == productObj.productId){
                                    if(oi.containsKey('UnitPrice')){
                                        return (Decimal) oi.get('UnitPrice');
                                    }
                                }
                            }
                        } 
                    }
                }
            }
        } catch(Exception e){
            System.debug(e.getMessage());
        }
        return null;
    }
    
    @AuraEnabled(cacheable=false)
    public static Map<String, List<Map<String, String>>> getProductVariations(List<String> productIds){
        Map<String, List<Map<String, String>>> returnMap = new Map<String, List<Map<String, String>>>();
        Map<Id, Product2> productMap = new Map<Id, Product2>([SELECT Id, ProductCode, Name, Factor__c, CurrencyIsoCode, QuantityUnitOfMeasure, BaseProductCode__c FROM Product2 WHERE Id IN : productIds]);
        Map<Id, Id> childParentMap = new Map<Id, Id>();
        for(ProductAttribute pa : [SELECT Id, VariantParentId, ProductId FROM ProductAttribute WHERE ProductId IN : productMap.keySet()]){
            childParentMap.put(pa.ProductId, pa.VariantParentId);
        }
        Map<Id, List<Product2>> parentToOtherChildrenMap = new Map<Id, List<Product2>>();
        for(ProductAttribute pa : [SELECT Id, VariantParentId, ProductId, Product.Id, Product.ProductCode, Product.Name, Product.Factor__c, Product.CurrencyIsoCode, Product.QuantityUnitOfMeasure, Product.BaseProductCode__c FROM ProductAttribute WHERE Product.IsActive = TRUE AND VariantParentId IN : childParentMap.values()
            AND ProductId NOT IN :productMap.keySet() ]){
            List<Product2> innerList = parentToOtherChildrenMap.containsKey(pa.VariantParentId) ? parentToOtherChildrenMap.get(pa.VariantParentId) : new List<Product2>();
            innerList.add(pa.Product);
            parentToOtherChildrenMap.put(pa.VariantParentId, innerList);
        }
        for(Id product2Id : productMap.keySet()){
            Product2 product = productMap.get(product2Id);
            List<Map<String, String>> innerList = new List<Map<String, String>>();
            innerList.add(buildPicklistExtendedMap(product));
            if(childParentMap.containsKey(product2Id)){
                Id parentId = childParentMap.get(product2Id);
                if(parentToOtherChildrenMap.containsKey(parentId)){
                    for(Product2 relatedProd : parentToOtherChildrenMap.get(parentId)){
                        innerList.add(buildPicklistExtendedMap(relatedProd));
                    }
                }
            }
            returnMap.put(product2Id, innerList);
        }
        return returnMap;
    }

    private static Map<String, String> buildPicklistExtendedMap(Product2 prod){
        Map<String, String> returnMap = new Map<String, String>();
        returnMap.put('value', prod.Id);
        returnMap.put('label', prod.QuantityUnitOfMeasure);
        returnMap.put('name', prod.Name);
        returnMap.put('productCode', prod.ProductCode);
        returnMap.put('factor', String.valueOf(prod.Factor__c ?? 1));
        returnMap.put('currencyIsoCode', prod.CurrencyIsoCode);
        returnMap.put('baseProductCode', prod.BaseProductCode__c);
        return returnMap;
    }

    @AuraEnabled(cacheable=false)
    public static ProductSuperiorWrapper reselectPositionsFromOrder(String recordId){
        List<ProductWrapper> positions = new List<ProductWrapper>();
        Integer extraCount = 0;
        Set<String> uniqueProductNames = new Set<String>();
        Set<String> productIds = new Set<String>();
        for(OrderItem oi : [SELECT Id, Product2.Name, Product2.ProductCode, Product2.QuantityUnitOfMeasure, Product2.CurrencyIsoCode, Product2.Factor__c, Product2.BaseProductCode__c, Product2Id, Product2.Id, Quantity, UnitPrice FROM OrderItem WHERE OrderId = : recordId AND Product2Id != NULL]){
            positions.add(new ProductWrapper(oi.Product2, oi.Quantity, oi.UnitPrice));
            productIds.add(oi.Product2Id);
        }        
        if(!productIds.isEmpty()){
            Map<String, List<Map<String, String>>> productToVariationsMap = getProductVariations(new List<String>(productIds));
            if(positions != null){
                for(ProductWrapper wrapper : positions){
                    if(productToVariationsMap.containsKey(wrapper.productId)){
                        wrapper.variations = productToVariationsMap.get(wrapper.productId);
                    }
                }
            }
        }
        String orderSubtext = String.join(uniqueProductNames, ', ') + (extraCount > 0 ? (' ' + String.format(System.Label.ReturnOrderMaskAndXMore, new List<String>{String.valueOf(extraCount)})) : '' );
        return new ProductSuperiorWrapper(positions, orderSubtext, null, new List<Order>());
    }

    @AuraEnabled(cacheable=false)
    public static ProductSuperiorWrapper reselectPositionsFromInvoice(String recordId){
        List<ProductWrapper> positions = new List<ProductWrapper>();
        Set<String> productIds = new Set<String>();
        for(InvoiceLine il : [SELECT Id, Product2.Name, Product2.ProductCode, Product2.QuantityUnitOfMeasure, Product2.CurrencyIsoCode, Product2.Factor__c, Product2.BaseProductCode__c, Product2Id, Product2.Id, Quantity, UnitPrice FROM InvoiceLine WHERE InvoiceId = : recordId AND Product2Id != NULL]){
            positions.add(new ProductWrapper(il.Product2, il.Quantity, il.UnitPrice));
            productIds.add(il.Product2Id);
        }
        if(!productIds.isEmpty()){
            Map<String, List<Map<String, String>>> productToVariationsMap = getProductVariations(new List<String>(productIds));
            if(positions != null){
                for(ProductWrapper wrapper : positions){
                    if(productToVariationsMap.containsKey(wrapper.productId)){
                        wrapper.variations = productToVariationsMap.get(wrapper.productId);
                    }
                }
            }
        }
        List<Order> invoiceOrders = [SELECT Id, CurrencyIsoCode, OrderNumber, CreatedDate, Status, TotalAmount, (SELECT Id, Product2.Name, Product2.ProductCode, Product2.CurrencyIsoCode, Product2.Factor__c, Product2.BaseProductCode__c, Product2.QuantityUnitOfMeasure, Quantity, UnitPrice, TotalPrice FROM OrderItems) FROM Order WHERE Invoice__c = : recordId];
        String invoiceSubtext = invoiceOrders.isEmpty() ? System.Label.ReturnOrderMaskNoOrdersInInvoice : (
            invoiceOrders.size() == 1 ? (System.Label.ReturnOrderMaskInvoiceFor + ' ' + invoiceOrders[0].OrderNumber) : (System.Label.ReturnOrderMaskCollectiveInvoiceFor + ' ' + String.valueOf(invoiceOrders.size()) + ' ' + System.Label.ReturnOrderMaskInvoices)
        );
        return new ProductSuperiorWrapper(positions, null, invoiceSubtext, invoiceOrders);
    }

    @AuraEnabled(cacheable=false)
    public static ReturnOrderResultWrapper createReturnOrder(
        Id recordId,
        Id existingReturnOrderId,
        Id accountId,
        Id orderId,
        Id invoiceId,
        Id addressId,
        String positions,
        Map<String, String> params
    ){
        try {
            if(String.isNotBlank(accountId)){
                Account ac = [SELECT Id, SoldToParty__c, ShipToParty__c, InvoiceRecipient__c, CentralRegulator__c FROM Account WHERE Id = : accountId];
                ReturnOrder rto = new ReturnOrder();
                if(String.isNotBlank(existingReturnOrderId)){
                    rto.Id = existingReturnOrderId;
                }
                rto.AccountId = accountId;
                rto.SoldTo__c = ac.SoldToParty__c;
                rto.ShipTo__c = ac.ShipToParty__c;
                rto.BillTo__c = ac.InvoiceRecipient__c;
                rto.Payer__c = ac.CentralRegulator__c;
                rto.Address__c = addressId;
                rto.ReturnOrderType__c = params.get('caseType');
                rto.CreditIssuance__c = params.get('refund') == 'true' ? 'WITH' : 'WITHOUT';
                rto.ReferenceType__c = params.get('reference');
                rto.OrderId = orderId;
                rto.LegacyInvoice__c = invoiceId;
                rto.NoDocumentReason__c = params.get('reasonNoReference');
                rto.ShippingCondition__c = params.get('shippingMethod');
                rto.RequestedPickupDate__c = params.get('arrivalDate') != null ? Date.valueOf(params.get('arrivalDate')) : null;
                upsert rto;
                if(String.isNotBlank(existingReturnOrderId)){
                    delete [SELECT Id FROM ReturnOrderLineItem WHERE ReturnOrderId = : existingReturnOrderId];
                }
                List<ReturnOrderLineItem> lineItemsToInsert = new List<ReturnOrderLineItem>();
                List<ProductWrapper> positionObjList = String.isNotBlank(positions) ? (List<ProductWrapper>) System.JSON.deserialize(positions, List<ProductWrapper>.class) : new List<ProductWrapper>();
                for(ProductWrapper wrapper : positionObjList){
                    lineItemsToInsert.add(new ReturnOrderLineItem(
                        ReturnOrderId = rto.Id,
                        Product2Id = wrapper.productId,
                        QuantityExpected = wrapper.quantity,
                        QuantityUnitOfMeasure = wrapper.QuantityUnitOfMeasure,
                        ReturnReason__c = wrapper.returnReason,
                        UnitPrice = wrapper.price,
                        CreditIssuance__c = wrapper.creditIssuance ? 'WITH' : 'WITHOUT',
                        Description = params.get('internalNote')
                    ));
                }
                if(!lineItemsToInsert.isEmpty()){
                    insert lineItemsToInsert;
                }
                if(String.valueOf(recordId).startsWith(CASE_PREFIX)){
                    Case c = new Case(Id = recordId, ReturnOrder__c =  rto.Id);
                    update c;
                }
                return new ReturnOrderResultWrapper(true, null, '/' + rto.Id);
            } else {
                return new ReturnOrderResultWrapper(false, 'Account ID invalid', null);
            }
        } catch(Exception e){
            return new ReturnOrderResultWrapper(false, e.getMessage(), null);
        }
    }

    public class ReturnOrderResultWrapper{
        @AuraEnabled public Boolean success;
        @AuraEnabled public String error;
        @AuraEnabled public String recordId;
        public ReturnOrderResultWrapper(Boolean success, String error, String recordId){
            this.success = success;
            this.error = error;
            this.recordId = recordId;
        }
    }

    public class AddressPricebookWrapper{
        @AuraEnabled public Map<String, Decimal> pricebookMap;
        @AuraEnabled public CustomAddress__c address;
        @AuraEnabled public List<String> customerListingProductIds;
        @AuraEnabled public List<ProductWrapper> coreAssortmentProducts;
        @AuraEnabled public List<ProductWrapper> listedProducts;
        public AddressPricebookWrapper(Map<String, Decimal> pricebookMap, CustomAddress__c address, Set<String> customerListingProductIds, List<ProductWrapper> coreAssortmentProducts, List<ProductWrapper> listedProducts){
            this.pricebookMap = pricebookMap;
            this.address = address;
            this.customerListingProductIds = new List<String>(customerListingProductIds);
            this.coreAssortmentProducts = coreAssortmentProducts;
            this.listedProducts = listedProducts;
        }
    }

    public class PrefillWrapper{
        @AuraEnabled public Order prefillOrder;
        @AuraEnabled public Invoice prefillInvoice;
        @AuraEnabled public Account prefillAccount; 
        @AuraEnabled public CustomAddress__c prefillAddress; 
        @AuraEnabled public List<ProductWrapper> orderPositions; 
        @AuraEnabled public List<ProductWrapper> invoicePositions; 
        @AuraEnabled public List<Order> invoiceOrders;
        @AuraEnabled public List<String> customerListingProductIds;
        @AuraEnabled public Boolean differentAddresses; 
        @AuraEnabled public String orderSubtext; 
        @AuraEnabled public String invoiceSubtext; 
        @AuraEnabled public Map<String, Decimal> pricebookMap;
        @AuraEnabled public ReturnOrder returnOrder; 
        @AuraEnabled public List<ProductWrapper> returnOrderItems;
        @AuraEnabled public List<ProductWrapper> coreAssortmentProducts;
        @AuraEnabled public List<ProductWrapper> listedProducts;
        public PrefillWrapper(){
            this.prefillOrder = null;
            this.prefillInvoice = null;
            this.prefillAccount = null;
            this.prefillAddress = null;
            this.orderPositions = null;
            this.invoicePositions = null;
            this.differentAddresses = false;
            this.orderSubtext = null;
            this.invoiceSubtext = null;
            this.pricebookMap = null;
            this.customerListingProductIds = new List<String>();
            this.coreAssortmentProducts = new List<ProductWrapper>();
            this.listedProducts = new List<ProductWrapper>();
            this.invoiceOrders = new List<Order>();
        }
        public PrefillWrapper(Account ac, CustomAddress__c address, 
        Invoice inv, Order order, List<ProductWrapper> orderPositions, List<ProductWrapper> invoicePositions, List<Order> invoiceOrders, String orderSubtext, 
        String invoiceSubtext, Map<String, Decimal> pricebookMap, ReturnOrder returnOrder, List<ProductWrapper> returnOrderItems, Set<String> customerListingProductIds,
        List<ProductWrapper> coreAssortmentProducts, List<ProductWrapper> listedProducts){
            this.prefillOrder = order;
            this.prefillInvoice = inv;
            this.prefillAccount = ac;
            this.prefillAddress = address;
            this.orderPositions = orderPositions;
            this.invoicePositions = invoicePositions;
            this.differentAddresses = ac.SoldToParty__c != ac.ShipToParty__c;
            this.orderSubtext = orderSubtext;
            this.invoiceSubtext = invoiceSubtext;
            this.pricebookMap = pricebookMap;
            this.returnOrder = returnOrder;
            this.returnOrderItems = returnOrderItems;
            this.customerListingProductIds = new List<String>(customerListingProductIds);
            this.coreAssortmentProducts = coreAssortmentProducts;
            this.listedProducts = listedProducts;
            this.invoiceOrders = invoiceOrders;
        }
    }
    public class ProductSuperiorWrapper{
        @AuraEnabled public List<ProductWrapper> positions;
        @AuraEnabled public String orderSubtext; 
        @AuraEnabled public String invoiceSubtext; 
        @AuraEnabled public List<Order> invoiceOrders; 
        public ProductSuperiorWrapper(List<ProductWrapper> positions, String orderSubtext, String invoiceSubtext, List<Order> invoiceOrders){
            this.positions = positions;
            this.orderSubtext = orderSubtext;
            this.invoiceSubtext = invoiceSubtext;
            this.invoiceOrders = invoiceOrders;
        }
    }
    public class ProductWrapper{
        @AuraEnabled public Id productId;
        @AuraEnabled public String name; 
        @AuraEnabled public Decimal factor; 
        @AuraEnabled public String description; 
        @AuraEnabled public String productCode; 
        @AuraEnabled public String baseProductCode; 
        @AuraEnabled public String quantityUnitOfMeasure; 
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal price;
        @AuraEnabled public Decimal totalPrice;
        @AuraEnabled public String priceDisplay;
        @AuraEnabled public String totalPriceDisplay;
        @AuraEnabled public String currencyIsoCode; 
        @AuraEnabled public String returnReason; 
        @AuraEnabled public String returnReasonLong; 
        @AuraEnabled public Boolean creditIssuance; 
        @AuraEnabled public String creditIssuanceVal; 
        @AuraEnabled public String creditIssuanceDisplay; 
        @AuraEnabled public String status; 
        @AuraEnabled public List<Map<String, String>> variations; 
        //@AuraEnabled public String batch; 
        //@AuraEnabled public Date bestBeforeDate; 
        public ProductWrapper(Product2 product, Decimal quantity, Decimal price){
            this.productId = product.Id;
            this.name = product.Name;
            this.factor = product.Factor__c;
            this.baseProductCode = product.BaseProductCode__c;
            this.productCode = product.ProductCode;
            this.description = product.ProductCode;
            this.quantityUnitOfMeasure = product.QuantityUnitOfMeasure;
            this.quantity = quantity;
            this.price = price;
            this.currencyIsoCode = product.CurrencyIsoCode;
            this.totalPrice = (quantity ?? 0) * (price ?? 0);
            this.priceDisplay = (price != null ? String.valueOf(price.setScale(2)) : '0.00') + ' ' + product.CurrencyIsoCode;
            this.totalPriceDisplay = (totalPrice != null ? String.valueOf(totalPrice.setScale(2)) : '0.00') + ' ' + product.CurrencyIsoCode;
            this.returnReason = DEFAULT_RETURN_REASON;
            this.returnReasonLong = null;
            this.creditIssuance = false;
            this.creditIssuanceVal = 'WITHOUT';
            this.creditIssuanceDisplay = this.creditIssuance ? System.Label.ReturnOrderMaskRefundYes : System.Label.ReturnOrderMaskRefundNo;
            this.status = 'pristine';
            this.variations = new List<Map<String, String>>();
        }
        public ProductWrapper(ReturnOrderLineItem roi){
            this.productId = roi.Product2Id;
            this.name = roi.Product2.Name;
            this.factor = roi.Product2.Factor__c;
            this.baseProductCode = roi.Product2.BaseProductCode__c;
            this.productCode = roi.Product2.ProductCode;
            this.description = roi.Product2.ProductCode;
            this.quantityUnitOfMeasure = roi.QuantityUnitOfMeasure;
            this.quantity = roi.QuantityExpected;
            this.price = roi.UnitPrice;
            this.currencyIsoCode = roi.Product2.CurrencyIsoCode;
            this.totalPrice = (roi.QuantityExpected ?? 0) * (roi.UnitPrice ?? 0);
            this.priceDisplay = (this.price != null ? String.valueOf(price.setScale(2)) : '0.00') + ' ' + roi.Product2.CurrencyIsoCode;
            this.totalPriceDisplay = (this.totalPrice != null ? String.valueOf(totalPrice.setScale(2)) : '0.00') + ' ' + roi.Product2.CurrencyIsoCode;
            this.returnReason = roi.ReturnReason__c;
            this.returnReasonLong = null;
            this.creditIssuance = roi.CreditIssuance__c == 'WITH';
            this.creditIssuanceVal = roi.CreditIssuance__c;
            this.creditIssuanceDisplay = this.creditIssuance ? System.Label.ReturnOrderMaskRefundYes : System.Label.ReturnOrderMaskRefundNo;
            this.status = 'pristine';
            this.variations = new List<Map<String, String>>();
        }
    }
}