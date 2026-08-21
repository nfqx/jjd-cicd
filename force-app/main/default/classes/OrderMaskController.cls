public with sharing class OrderMaskController {

    private static final Map<String, String> RELEASE_FIELD_BY_CHANNEL = new Map<String, String>{
        '10' => 'ReleasedForRetail__c',
        '20' => 'ReleasedForAHS__c',
        '30' => 'ReleasedForExport__c'
    };

    @AuraEnabled(cacheable=true)
    public static AccountContextWrapper getAccountContext(Id recordId, String objectApiName) {
        if (String.isBlank(recordId) || String.isBlank(objectApiName)) {
            return null; 
        }

        Id accountIdToQuery = null;

        if (objectApiName == 'Account') { 
            accountIdToQuery = recordId;
        } else if (objectApiName == 'Case') {
            List<Case> cases = [SELECT AccountId FROM Case WHERE Id = :recordId LIMIT 1];
            if (!cases.isEmpty()) {
                accountIdToQuery = cases[0].AccountId;
            }
        }
 
        if (accountIdToQuery != null) {
            Account acc = [
                SELECT Id, 
                    Name, 
                    AccountNumber, 
                    BillingStreet, 
                    BillingPostalCode, 
                    BillingCity,
                    ShippingStreet, 
                    ShippingPostalCode, 
                    ShippingCity, 
                    ShippingCountryCode, 
                    ERPCustomerNumber__c
                FROM Account
                WHERE Id = :accountIdToQuery
                LIMIT 1
            ];
            
            List<CustomAddress__c> customAddresses = new List<CustomAddress__c>();

            if (String.isNotBlank(acc.ERPCustomerNumber__c)) {
                customAddresses = [
                    SELECT Id, Address__c, 	AddressType__c, ERPCustomerNumber__c
                    FROM CustomAddress__c 
                    WHERE ERPCustomerNumber__c = :acc.ERPCustomerNumber__c
                ];
            }

            AccountContextWrapper wrapper = new AccountContextWrapper();
            wrapper.accountRecord = acc;
            wrapper.addresses = customAddresses;
            wrapper.isFirstOrder = [
                SELECT COUNT()
                FROM Order
                WHERE AccountId = :accountIdToQuery
                AND Status = 'Completed'
            ] == 0;
            
            return wrapper;
        }

        return null;
    } 

    @AuraEnabled(cacheable=false)
    public static List<ParentProductWrapper> searchProducts(String searchText, String accountId, String searchType) {
        List<ParentProductWrapper> products = new List<ParentProductWrapper>();
        Set<String> allowedProductIds = new Set<String>();
        if (String.isBlank(searchText) || String.isBlank(accountId) || String.isBlank(searchType)) {
            return products;
        }

        if(searchType == 'entitled'){
            allowedProductIds = WebshopDataController.retrieveAllowedProductIds(accountId, new Set<String>(), null);
            if (allowedProductIds.isEmpty()) {
                return products;
            }
        } else if(searchType == 'bought'){
            for(AggregateResult ar : [SELECT Product2Id FROM OrderItem WHERE Order.AccountId = : accountId GROUP BY Product2Id]){
                allowedProductIds.add((String)ar.get('Product2Id'));
            }
            if (allowedProductIds.isEmpty()) {
                return products;
            }
        }

        Account acc = [
            SELECT Id, DistributionChannel__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        String releaseField = RELEASE_FIELD_BY_CHANNEL.get(acc.DistributionChannel__c);
        String releaseFilter = String.isNotBlank(releaseField)
            ? ' AND ' + releaseField + ' = true'
            : '';

        String idFilter = (searchType == 'regular') ? '' : ' AND Id IN :allowedProductIds';

        String escapedSearch = String.escapeSingleQuotes(searchText.trim());
        String soslSearch = escapedSearch + '*';

        String fieldList = 'Id, Name, ProductCode, ProductClass, StockKeepingUnit, BaseProductCode__c, QuantityUnitOfMeasure, AvailableQuantity__c, CurrencyIsoCode';

        String whereClause = 'IsActive = true'
            + ' AND ProductClass IN (\'Variation\', \'Simple\')'
            + ' AND (NOT ProductCode LIKE \'OLD_%\')'
            + releaseFilter
            + idFilter;

        String soslQuery = 'FIND :soslSearch IN ALL FIELDS RETURNING Product2('
            + fieldList
            + ' WHERE ' + whereClause
            + ' LIMIT 50)';

        List<List<SObject>> searchResults = Search.query(soslQuery);

        if (!searchResults.isEmpty()) {
            Map<Id, List<Product2>> parentToChildrenMap = new Map<Id, List<Product2>>();
            Map<Id, Product2> childIdMap = new Map<Id, Product2>();
            Map<Id, Decimal> priceMap = new Map<Id, Decimal>();
            for (SObject sob : searchResults[0]) {
                Product2 prod2 = (Product2)sob;
                priceMap.put((Id)sob.get('Id'), null);
            }
            for(PricebookEntry pbe : [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Pricebook2.IsStandard = TRUE AND Product2Id IN : priceMap.keySet()]){
                priceMap.put(pbe.Product2Id, pbe.UnitPrice);
            }
            for(PricebookEntry pbe : [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Pricebook2.Account__c = : accountId AND Product2Id IN : priceMap.keySet()]){
                priceMap.put(pbe.Product2Id, pbe.UnitPrice);
            }
            for (SObject sob : searchResults[0]) {
                Product2 prod2 = (Product2)sob;
                if(prod2.ProductClass == 'Simple'){
                    products.add(new ParentProductWrapper(prod2.Name, prod2.ProductCode, prod2, new Map<Id, Decimal>{prod2.Id => priceMap.get(prod2.Id)}));
                } else {
                    childIdMap.put((Id)sob.get('Id'), prod2);
                }
            }
            for(ProductAttribute pa : [
                SELECT ProductId, VariantParentId
                FROM ProductAttribute
                WHERE ProductId IN :childIdMap.keySet()
            ]){
                List<Product2> innerList = parentToChildrenMap.containsKey(pa.VariantParentId) ? parentToChildrenMap.get(pa.VariantParentId) : new List<Product2>();
                innerList.add(childIdMap.get(pa.ProductId));
                parentToChildrenMap.put(pa.VariantParentId, innerList);
            }

            for(Product2 prod2 : [SELECT Id, Name, ProductCode FROM Product2 WHERE Id IN : parentToChildrenMap.keySet()]){
                Map<Id, Decimal> priceMapInner = new Map<Id, Decimal>();
                for(Product2 childProd : parentToChildrenMap.get(prod2.Id)){
                    priceMapInner.put(childProd.Id, priceMap.get(childProd.Id));
                }
                products.add(new ParentProductWrapper(prod2.Name, prod2.ProductCode, parentToChildrenMap.get(prod2.Id), priceMapInner));
            }
        }
        return products;
    }

    public class ParentProductWrapper{
        @AuraEnabled public List<Product2> variations {get; set;}
        @AuraEnabled public Boolean simpleProduct {get; set;}
        @AuraEnabled public String productName {get; set;}
        @AuraEnabled public String productCode {get; set;}
        @AuraEnabled public Boolean oneVariation {get; set;}
        @AuraEnabled public Product2 oneVariationProduct {get; set;}
        @AuraEnabled public Map<Id, Decimal> priceMap {get; set;}
        public ParentProductWrapper(String productName, String productCode, List<Product2> variations, Map<Id, Decimal> priceMap){
            this.productName = productName;
            this.productCode = productCode;
            this.simpleProduct = false;
            this.variations = variations;
            this.priceMap = priceMap;
            this.calculate();
        }
        public ParentProductWrapper(String productName, String productCode, Product2 simpleProduct, Map<Id, Decimal> priceMap){
            this.productName = productName;
            this.productCode = productCode;
            this.simpleProduct = true;
            this.variations = new List<Product2>{simpleProduct};
            this.priceMap = priceMap;
            this.calculate();
        }
        public void calculate(){
            this.oneVariation = this.variations.size() == 1;
            this.oneVariationProduct = this.oneVariation ? this.variations[0] : null;
        }
    }

    public static Map<String,Object> buildPayload(
        Map<Id, OrderItemWrapper> orderItemWrappers,
        String customerReferenceId,
        ERPIntegrationSettings__mdt cfg,
        Map<String,Object> orderDataMap
    ){
        Map<String,Object> root = new Map<String,Object>();
        
        // Order Items
        Integer lineNum = 1;    
        String isoCode = null;
        List<Map<String,Object>> orderItems = new List<Map<String,Object>>();    
        for(String wrapperKey : orderItemWrappers.keySet()){
            OrderItemWrapper wrapper = orderItemWrappers.get(wrapperKey);
            List<String> ciSplit = WebshopDataController.splitLastSuffix(wrapper.productCode);
            Map<String,Object> item = new Map<String,Object>();            
            item.put('Quantity', wrapper.quantity);
            item.put('CurrencyIsoCode', wrapper.currencyIsoCode);
            isoCode = wrapper.currencyIsoCode;
            item.put('LineNumber', lineNum++);            
            Map<String,Object> product = new Map<String,Object>();
            product.put('Id', wrapper.productId);
            /*
            if(!ciSplit.isEmpty() && ciSplit.size() > 1 && ciSplit[1].isAlpha()){
                product.put('ProductCode', ciSplit[0].replace('OLD_', ''));
            } else {
                product.put('ProductCode', wrapper.ProductCode.replace('OLD_', ''));
            }*/
            product.put('ProductCode', wrapper.productCode.replace('OLD_', ''));
            product.put('BaseProductCode__c', wrapper.baseProductCode.replace('OLD_', ''));
            product.put('Name', wrapper.productName);
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
        }        
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
        if (orderDataMap != null) {
            String shippingCondition = (String) orderDataMap.get('shippingCondition');
            if (String.isNotBlank(shippingCondition)) {
                root.put('PreferredShippingCondition__c', shippingCondition);
            }

            String requestedDeliveryDate = (String) orderDataMap.get('requestedDeliveryDate');
            if (String.isNotBlank(requestedDeliveryDate)) {
                root.put('RequestedDeliveryDate__c', requestedDeliveryDate);
            }
        }
        
        return root;
    }

    @AuraEnabled(cacheable=false)
    public static WebshopDataController.ERPResponseWrapper sendToOrderSimulation(Id accountId, Map<Id, OrderItemWrapper> orderItems, String orderData){
        try{
            // 1. Load data
            Account ac = [
                SELECT Id, ERPCustomerNumber__c
                FROM Account
                WHERE Id = :accountId
            ];

            ERPIntegrationSettings__mdt cfg = ERPIntegrationSettings__mdt.getInstance('Default');

            Map<String, Object> orderDataMap = String.isNotBlank(orderData)
            ? (Map<String, Object>) JSON.deserializeUntyped(orderData)
            : new Map<String, Object>();

            // 2. Build payload
            Map<String,Object> payload = buildPayload(orderItems, ac.ERPCustomerNumber__c, cfg, orderDataMap);
            String body = JSON.serialize(payload);
            // 3. Callout
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:ERP_API_NEW' + (cfg.EndpointPath__c ?? ''));
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(body);
            System.debug('ERP REQUEST: ' + body);

            Http http = new Http();
            HttpResponse res = http.send(req);
            

            if(res.getStatusCode() >= 300){
                throw new CalloutException(
                    'ERP Order failed: ' + res.getBody()
                );
            }
            System.debug(res.getBody());
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, WebshopDataController.ERPResponseInnerWrapper> successOrderItemsMap = new Map<String, WebshopDataController.ERPResponseInnerWrapper>();
            Set<String> failedOrderItemsSet = new Set<String>();
            if(data != null && data.containsKey('OrderItems')){
                for(Object oiObj : (List<Object>) data.get('OrderItems')){
                    Map<String, Object> oi = (Map<String, Object>) oiObj;
                    if(oi.containsKey('Product2')){
                        Map<String, Object> product2 = (Map<String, Object>) oi.get('Product2');
                        if(product2.containsKey('Id')){
                            String productId = (String) product2.get('Id');
                            if(String.isNotBlank(productId)){
                                if(orderItems.containsKey(productId)){
                                    successOrderItemsMap.put(productId, new WebshopDataController.ERPResponseInnerWrapper(oi));
                                }
                            }
                        }
                    } 
                }

            }
            return new WebshopDataController.ERPResponseWrapper(data, 0, successOrderItemsMap.values());
        } catch(Exception e){
            System.debug(e.getMessage());
            return null;
        }
    }

    @AuraEnabled(cacheable=false)
    public static OrderWrapper createOrder(Id accountId, String erpResponse, String orderData, Map<Id, LineDiscountWrapper> discounts){
        try {
            Map<String, Object> erpResponseMap = (Map<String, Object>) System.JSON.deserializeUntyped(erpResponse);
            Map<String, Object> orderDataMap = (Map<String, Object>) System.JSON.deserializeUntyped(orderData);
            Account acc = [SELECT Id, Name, BillingStreet, BillingCity, BillingPostalCode, BillingCOuntry, ShippingStreet, ShippingCity, ShippingPostalCode, ShippingCOuntry FROM Account WHERE Id = : accountId];
            String directShipmentName = (String) orderDataMap.get('shippingName');
            String shippingName = String.isNotBlank(directShipmentName)
                ? directShipmentName
                : (acc.Name + ', ' + (String.isNotBlank(UserInfo.getFirstName()) ? UserInfo.getFirstName() : '') + UserInfo.getLastName());
            
            String billingStreet = acc.BillingStreet;
            String billingCity = acc.BillingCity;
            String billingPostalCode = acc.BillingPostalCode;
            String billingCountry = acc.BillingCountry;
            
            //String shippingStreet = (String.isNotBlank(acc.BillingStreet) ? acc.BillingStreet : acc.ShippingStreet);
            //String shippingCity = (String.isNotBlank(acc.BillingCity) ? acc.BillingCity : acc.ShippingCity);
            //String shippingPostalCode = (String.isNotBlank(acc.BillingPostalCode) ? acc.BillingPostalCode : acc.ShippingPostalCode) ;
            //String shippingCountry = (String.isNotBlank(acc.BillingCountry) ? acc.BillingCountry : acc.ShippingCountry);
            String shippingStreet = (String) orderDataMap.get('shippingStreet');
            String shippingCity = (String) orderDataMap.get('shippingCity');
            String shippingPostalCode = (String) orderDataMap.get('shippingPostalCode');
            String shippingCountry = (String) orderDataMap.get('shippingCountry');
 
            Decimal shippingCosts = 0;
            if(String.isNotBlank(erpResponse) && erpResponseMap.containsKey('order')){
                Map<String, Object> orderMap = (Map<String, Object>) erpResponseMap.get('order');
                Object rawShippingCosts = orderMap.get('ShippingCosts__c');
                if(rawShippingCosts != null){
                    shippingCosts = Decimal.valueOf(String.valueOf(rawShippingCosts));
                }
            }

            if ('ZKLA'.equals((String) orderDataMap.get('type'))) {
                shippingCosts = 0;
            }

            Date effectiveDate = String.isNotBlank((String) orderDataMap.get('orderStartDate'))
                ? Date.valueOf((String) orderDataMap.get('orderStartDate'))
                : Date.today();
            Date requestedDeliveryDate = String.isNotBlank((String) orderDataMap.get('requestedDeliveryDate'))
                ? Date.valueOf((String) orderDataMap.get('requestedDeliveryDate'))
                : null;

            Order order = new Order(
                AccountId = accountId,
                SalesStoreId = System.Label.WebshopDoNotTranslateStoreID,
                //PoNumber = orderNumber,
                //WebshopPhone__c = phoneNumber,
                //Comment__c = comment,
                //ShippingName__c = shippingName, 
                //BillingStreet = shippingStreet,
                //ShippingStreet = shippingStreet,          
                //ShippingCosts__c = shippingCosts,
                //BillingCity = shippingCity,
                //ShippingCity = shippingCity,             
                //BillingPostalCode = shippingPostalCode,
                //ShippingPostalCode = shippingPostalCode,  
                //BillingCountry = shippingCountry,
                //ShippingCountry = shippingCountry, 
                ShippingName__c = shippingName,
                BillingStreet = billingStreet,
                BillingCity = billingCity,
                BillingPostalCode = billingPostalCode,
                BillingCountry = billingCountry,
                ShippingStreet = shippingStreet,
                ShippingCity = shippingCity,
                ShippingPostalCode = shippingPostalCode,
                ShippingCountryCode = shippingCountry,
                ShippingCosts__c = shippingCosts, 
                PreferredShippingCondition__c = (String) orderDataMap.get('shippingCondition'), 
                PlantLocation__c = (String) orderDataMap.get('pickupLocation'),    
                EffectiveDate = effectiveDate,
                OrderedDate = Date.today(),
                RequestedDeliveryDate__c = requestedDeliveryDate,
                OrderSource__c = (String) orderDataMap.get('source'),  
                Type = (String) orderDataMap.get('type'),     
                DeliveryText__c = (String) orderDataMap.get('deliveryText'),
                CarrierNote__c = (String) orderDataMap.get('carrierNote'),
                //AdditionalDeliveryAddressId__c = runningNumber,
                Status = 'Draft'
            );
            insert order;
    
            OrderDeliveryGroup orderDeliveryGroup = new OrderDeliveryGroup(
                DeliverToName = shippingName,
                DeliverToStreet = shippingStreet,
                DeliverToCity = shippingCity,
                DeliverToPostalCode = shippingPostalCode,
                DeliverToCountryCode = shippingCountry,
                OrderDeliveryMethodId = [SELECT Id FROM OrderDeliveryMethod ORDER BY CreatedDate LIMIT 1].Id,
                OrderId = order.Id
            );
            insert orderDeliveryGroup;    
            List<OrderItem> oil = new List<OrderItem>();
            if(String.isNotBlank(erpResponse) && erpResponseMap.containsKey('successfulItems')){
                List<Object> objectList = (List<Object>) erpResponseMap.get('successfulItems');
                for (Object innerObj : objectList) {
                    Map<String, Object> innerMap = (Map<String, Object>) innerObj;
                    if (innerMap.containsKey('orderItem')) {
                        Map<String, Object> orderItem = (Map<String, Object>) innerMap.get('orderItem');

                        Id product2Id = (Id) orderItem.get('Product2Id');
                        Decimal quantity = (Decimal) orderItem.get('Quantity');
                        Decimal listPrice = Decimal.valueOf(String.valueOf((Decimal) orderItem.get('UnitPrice'))).setScale(2);

                        Decimal unitPrice = listPrice;
                        Decimal discountPercent = null;
                        Decimal discountAbsolute = null;
                        Boolean isFreeItem = false;

                        if (discounts != null && discounts.containsKey(product2Id)) {
                            LineDiscountWrapper d = discounts.get(product2Id);
                            if (d.isFree == true) {
                                isFreeItem = true;
                                discountPercent = 100;
                                unitPrice = 0;
                            } else if (d.percent != null) {
                                discountPercent = d.percent;
                                unitPrice = (listPrice * (1 - d.percent / 100)).setScale(2);
                            } else if (d.absolute != null) {
                                discountAbsolute = d.absolute;
                                unitPrice = (listPrice - d.absolute).setScale(2);
                            }
                            if (unitPrice < 0) unitPrice = 0;
                        } else {
                            System.debug('No discount for ' + product2Id + ' | keys: ' +
                                (discounts == null ? 'NULL PARAM' : String.valueOf(discounts.keySet())));
                        }

                        OrderItem oi = new OrderItem(
                            Product2Id = product2Id,
                            Quantity = quantity,
                            ListPrice = listPrice,
                            UnitPrice = unitPrice,
                            TotalLineAmount = (quantity * unitPrice).setScale(2),
                            FreeItem__c = isFreeItem,
                            DiscountPercent__c = discountPercent,
                            DiscountAbsolute__c = discountAbsolute,
                            OrderId = order.Id,
                            OrderDeliveryGroupId = orderDeliveryGroup.Id,
                            LineNumber = (Integer) orderItem.get('LineNumber')
                        );
                        oil.add(oi);
                    }
                }
                if(!oil.isEmpty()){
                    insert oil;
                    Boolean needsApproval = orderDataMap.get('requiresApproval') == true;
                    order.Status = needsApproval ? 'In Approval' : 'Ready for Transmission to ERP';
                    update order;
                    if (!needsApproval) {
                        ConnectApi.OrderSummaryInputRepresentation osir = new ConnectApi.OrderSummaryInputRepresentation();
                        osir.orderId = order.Id;
                        osir.orderLifeCycleType = 'MANAGED';
                        if(!Test.isRunningTest()){
                            try {
                                ConnectApi.OrderSummaryOutputRepresentation osor = ConnectApi.OrderSummaryCreation.createOrderSummary(osir);
                            } catch(Exception e){
                                System.debug(e.getMessage());
                            }
                        }
                    }
                    return new OrderWrapper(true, order.Id, null);
                }
            }
            delete orderDeliveryGroup;
            delete order;
            return new OrderWrapper(false, null, System.Label.GeneralNoOrderItems);
        } catch(Exception e){
            System.debug(e);
            return new OrderWrapper(false, null, e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static OrderWrapper saveOrderDraft(Id accountId, String orderData, Map<Id, DraftOrderItemWrapper> orderItems, Map<Id, LineDiscountWrapper> discounts){
        try {
            Map<String, Object> orderDataMap = (Map<String, Object>) System.JSON.deserializeUntyped(orderData);

            Account acc = [
                SELECT Id, Name, BillingStreet, BillingCity, BillingPostalCode, BillingCountry,
                    ShippingStreet, ShippingCity, ShippingPostalCode, ShippingCountry
                FROM Account
                WHERE Id = :accountId
            ];

            String directShipmentName = (String) orderDataMap.get('shippingName');
            String shippingName = String.isNotBlank(directShipmentName)
                ? directShipmentName
                : (acc.Name + ', ' + (String.isNotBlank(UserInfo.getFirstName()) ? UserInfo.getFirstName() : '') + UserInfo.getLastName());
            
            String billingStreet = acc.BillingStreet;
            String billingCity = acc.BillingCity;
            String billingPostalCode = acc.BillingPostalCode;
            String billingCountry = acc.BillingCountry;
            /*
            String shippingStreet = (String.isNotBlank(acc.BillingStreet) ? acc.BillingStreet : acc.ShippingStreet);
            String shippingCity = (String.isNotBlank(acc.BillingCity) ? acc.BillingCity : acc.ShippingCity);
            String shippingPostalCode = (String.isNotBlank(acc.BillingPostalCode) ? acc.BillingPostalCode : acc.ShippingPostalCode);
            String shippingCountry = (String.isNotBlank(acc.BillingCountry) ? acc.BillingCountry : acc.ShippingCountry);
            */
            String shippingStreet = (String) orderDataMap.get('shippingStreet');
            String shippingCity = (String) orderDataMap.get('shippingCity');
            String shippingPostalCode = (String) orderDataMap.get('shippingPostalCode');
            String shippingCountry = (String) orderDataMap.get('shippingCountry');
            
            Date effectiveDate = String.isNotBlank((String) orderDataMap.get('orderStartDate'))
                ? Date.valueOf((String) orderDataMap.get('orderStartDate'))
                : Date.today();
            Date requestedDeliveryDate = String.isNotBlank((String) orderDataMap.get('requestedDeliveryDate'))
                ? Date.valueOf((String) orderDataMap.get('requestedDeliveryDate'))
                : null;

            Order order = new Order(
                AccountId = accountId,
                SalesStoreId = System.Label.WebshopDoNotTranslateStoreID,
                ShippingName__c = shippingName,
                //BillingStreet = shippingStreet,
                //BillingCity = shippingCity,
                //BillingPostalCode = shippingPostalCode,
                //BillingCountry = shippingCountry,
                BillingStreet = billingStreet,
                BillingCity = billingCity,
                BillingPostalCode = billingPostalCode,
                BillingCountry = billingCountry,
                ShippingStreet = shippingStreet,
                ShippingCity = shippingCity,
                ShippingPostalCode = shippingPostalCode,
                ShippingCountryCode = shippingCountry,
                PreferredShippingCondition__c = (String) orderDataMap.get('shippingCondition'),
                PlantLocation__c = (String) orderDataMap.get('pickupLocation'),
                EffectiveDate = effectiveDate,
                OrderedDate = Date.today(),
                RequestedDeliveryDate__c = requestedDeliveryDate,
                OrderSource__c = (String) orderDataMap.get('source'),
                Type = (String) orderDataMap.get('type'),
                DeliveryText__c = (String) orderDataMap.get('deliveryText'),
                CarrierNote__c = (String) orderDataMap.get('carrierNote'),
                Status = 'Draft'
            );
            insert order;

            OrderDeliveryGroup orderDeliveryGroup = new OrderDeliveryGroup(
                DeliverToName = shippingName,
                DeliverToStreet = shippingStreet,
                DeliverToCity = shippingCity,
                DeliverToPostalCode = shippingPostalCode,
                DeliverToCountryCode = shippingCountry,
                OrderDeliveryMethodId = [SELECT Id FROM OrderDeliveryMethod ORDER BY CreatedDate LIMIT 1].Id,
                OrderId = order.Id
            );
            insert orderDeliveryGroup;

            List<OrderItem> oil = new List<OrderItem>();
            Integer lineNum = 1;
            if (orderItems != null) {
                for (Id prodId : orderItems.keySet()) {
                    DraftOrderItemWrapper wrapper = orderItems.get(prodId);

                    Decimal listPrice = wrapper.maxPrice;
                    Decimal unitPrice = listPrice;
                    Decimal discountPercent = null;
                    Decimal discountAbsolute = null;
                    Boolean isFreeItem = false;

                    if (discounts != null && discounts.containsKey(prodId)) {
                        LineDiscountWrapper d = discounts.get(prodId);
                        if (d.isFree == true) {
                            isFreeItem = true;
                            discountPercent = 100;
                            unitPrice = 0;
                        } else if (d.percent != null) {
                            discountPercent = d.percent;
                            unitPrice = (listPrice * (1 - d.percent / 100)).setScale(2);
                        } else if (d.absolute != null) {
                            discountAbsolute = d.absolute;
                            unitPrice = (listPrice - d.absolute).setScale(2);
                        }
                        if (unitPrice < 0) unitPrice = 0;
                    }

                    oil.add(new OrderItem(
                        Product2Id = prodId,
                        Quantity = wrapper.quantity,
                        ListPrice = listPrice,
                        UnitPrice = unitPrice,
                        TotalLineAmount = wrapper.quantity * unitPrice,
                        MinPrice__c = wrapper.minPrice,
                        MaxPrice__c = wrapper.maxPrice,
                        FreeItem__c = isFreeItem,
                        DiscountPercent__c = discountPercent,
                        DiscountAbsolute__c = discountAbsolute,
                        OrderId = order.Id,
                        OrderDeliveryGroupId = orderDeliveryGroup.Id,
                        LineNumber = lineNum++
                    ));
                }
            }
            if (!oil.isEmpty()) {
                insert oil;
            }

            return new OrderWrapper(true, order.Id, null);
        } catch (Exception e) {
            System.debug(e);
            return new OrderWrapper(false, null, e.getMessage());
        }
    }

    public class DraftOrderItemWrapper {
        @AuraEnabled public Integer quantity { get; set; }
        @AuraEnabled public Id productId { get; set; }
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public String productCode { get; set; }
        @AuraEnabled public String currencyIsoCode { get; set; }
        @AuraEnabled public String quantityUnitOfMeasure { get; set; }
        @AuraEnabled public Decimal minPrice { get; set; }
        @AuraEnabled public Decimal maxPrice { get; set; }
    }

    public class OrderWrapper{
        @AuraEnabled public Boolean success;
        @AuraEnabled public Id orderId;
        @AuraEnabled public String errorText;
        public OrderWrapper(Boolean success, Id orderId, String errorText){
            this.success = success;
            this.orderId = orderId;
            this.errorText = errorText;
        }
    }

    public class OrderItemWrapper{
        @AuraEnabled public Integer quantity { get; set; }
        @AuraEnabled public Id productId { get; set; }
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public String productCode { get; set; }
        @AuraEnabled public String baseProductCode { get; set; }
        @AuraEnabled public String currencyIsoCode { get; set; }
        @AuraEnabled public String quantityUnitOfMeasure { get; set; }

        public OrderItemWrapper() {}

        public OrderItemWrapper(Integer quantity, Id productId, String productName, String productCode, String baseProductCode, String currencyIsoCode, String quantityUnitOfMeasure){
            this.quantity = quantity;
            this.productId = productId;
            this.productName = productName;
            this.productCode = productCode;
            this.baseProductCode = baseProductCode;
            this.currencyIsoCode = currencyIsoCode;
            this.quantityUnitOfMeasure = quantityUnitOfMeasure;
        }
    }

    public class AccountContextWrapper {
        @AuraEnabled public Account accountRecord { get; set; }
        @AuraEnabled public List<CustomAddress__c> addresses { get; set; }
        @AuraEnabled public Boolean isFirstOrder { get; set; }
    }

    public class LineDiscountWrapper {
        @AuraEnabled public Decimal percent { get; set; }
        @AuraEnabled public Decimal absolute { get; set; }
        @AuraEnabled public Boolean isFree { get; set; }
    }
}