public with sharing class FTPOrderProcessingBatch implements Database.Batchable<FTPOrderGroup>, Database.AllowsCallouts {
    private List<FTPOrderGroup> orderGroups;
    public FTPOrderProcessingBatch(List<FTPOrderGroup> orderGroups) {
        this.orderGroups = orderGroups;
    }
    public Iterable<FTPOrderGroup> start(Database.BatchableContext bc) {
        return orderGroups;
    }    

    public void execute(Database.BatchableContext bc, List<FTPOrderGroup> scope) {
        for (FTPOrderGroup orderGroup : scope) {
            String headAccountNumber = orderGroup.headAccountNumber;
            Account acc = [SELECT Id, Name, BillingStreet, BillingCity, BillingPostalCode, BillingCOuntry, ShippingStreet, ShippingCity, ShippingPostalCode, ShippingCountry FROM Account WHERE Id = : headAccountNumber];

            List<FTPOrderLine> lines = orderGroup.lines;
            
            // 1. Populate Basic Data
            Set<String> childAccountNumbers = new Set<String>();
            Set<String> productSkus = new Set<String>();
            for (FTPOrderLine line : lines) {
                childAccountNumbers.add(line.childAccountNumber);
                productSkus.add(line.productSku);
            }
            Map<String, Account> accountsByCustomerReference = new Map<String, Account>();
            for (Account runningAcc : [SELECT Id, Name, ERPCustomerNumber__c FROM Account WHERE ERPCustomerNumber__c IN :childAccountNumbers]) {
                accountsByCustomerReference.put(runningAcc.ERPCustomerNumber__c, runningAcc);
            }
            Map<String, Product2> productsBySku = new Map<String, Product2>();
            for (Product2 product : [SELECT Id, Name, ProductCode FROM Product2  WHERE ProductCode IN :productSkus AND ProductClass IN ('Variation', 'Simple')]) {
                productsBySku.put(product.StockKeepingUnit, product);
            }
            // Order Simulation
            try{
                ERPIntegrationSettings__mdt cfg = ERPIntegrationSettings__mdt.getInstance('Default');

                // 2. Build payload
                Map<String,Object> payload = buildPayload(lines, productsBySku, acc.ERPCustomerNumber__c, cfg);
                String body = JSON.serialize(payload);

                // 3. Callout
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:ERP_API_NEW' + (cfg.EndpointPath__c ?? ''));
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                req.setBody(body);

                Http http = new Http();
                HttpResponse res = http.send(req);
                

                if(res.getStatusCode() >= 300){
                    throw new CalloutException(
                        'ERP Order failed: ' + res.getBody()
                    );
                }
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
                                    successOrderItemsMap.put(productId, new WebshopDataController.ERPResponseInnerWrapper(oi));
                                }
                            }
                        } 
                    }
                }
                WebshopDataController.ERPResponseWrapper erpResponse = new WebshopDataController.ERPResponseWrapper(data, 0, successOrderItemsMap.values());
                String shippingName = (acc.Name + ', ' + (String.isNotBlank(UserInfo.getFirstName()) ? UserInfo.getFirstName() : '') + UserInfo.getLastName());
                String shippingStreet = (String.isNotBlank(acc.BillingStreet) ? acc.BillingStreet : acc.ShippingStreet);
                String shippingCity = (String.isNotBlank(acc.BillingCity) ? acc.BillingCity : acc.ShippingCity);
                String shippingPostalCode = (String.isNotBlank(acc.BillingPostalCode) ? acc.BillingPostalCode : acc.ShippingPostalCode) ;
                String shippingCountry = (String.isNotBlank(acc.BillingCountry) ? acc.BillingCountry : acc.ShippingCountry);
                Decimal shippingCosts = 0;
                if(erpResponse.order != null){
                    Map<String, Object> orderMap = erpResponse.order;
                    if(orderMap.containsKey('ShippingCosts__c')){
                        shippingCosts = (Decimal) orderMap.get('ListPrice');
                    }
                }
                Order order = new Order(
                    AccountId = acc.Id,
                    SalesStoreId = System.Label.WebshopDoNotTranslateStoreID,
                    //PoNumber = orderNumber,
                    //WebshopPhone__c = phoneNumber,
                    //Comment__c = comment,
                    ShippingName__c = shippingName, 
                    BillingStreet = shippingStreet,
                    ShippingCosts__c = shippingCosts,
                    BillingCity = shippingCity,
                    BillingPostalCode = shippingPostalCode,
                    BillingCountry = shippingCountry,
                    EffectiveDate = Date.today(),
                    OrderedDate = Date.today(),
                    //AdditionalDeliveryAddressId__c = runningNumber,
                    Status = 'Draft'
                );
                insert order;
        
                OrderDeliveryGroup orderDeliveryGroup = new OrderDeliveryGroup(
                    DeliverToName = shippingName,
                    DeliverToStreet = shippingStreet,
                    DeliverToCity = shippingCity,
                    DeliverToPostalCode = shippingPostalCode,
                    DeliverToCountry = shippingCountry,
                    OrderDeliveryMethodId = [SELECT Id FROM OrderDeliveryMethod ORDER BY CreatedDate LIMIT 1].Id,
                    OrderId = order.Id
                );
                insert orderDeliveryGroup;    
                List<OrderItem> oil = new List<OrderItem>();
                if(erpResponse.successfulItems != null){
                    for(WebshopDataController.ERPResponseInnerWrapper successfulItem : erpResponse.successfulItems){
                        if (successfulItem.orderItem != null 
                            && successfulItem.orderItem.containsKey('Product2Id')
                            && successfulItem.orderItem.containsKey('Quantity')
                            && successfulItem.orderItem.containsKey('UnitPrice')
                            && successfulItem.orderItem.containsKey('LineNumber')
                        ) {
                            OrderItem oi = new OrderItem(
                                Product2Id = (String) successfulItem.orderItem.get('Product2Id'),
                                Quantity = (Decimal) successfulItem.orderItem.get('Quantity'),
                                UnitPrice = Decimal.valueOf(String.valueOf(successfulItem.orderItem.get('UnitPrice'))).setScale(2),
                                OrderId = order.Id,
                                OrderDeliveryGroupId = orderDeliveryGroup.Id,
                                LineNumber = (Integer) successfulItem.orderItem.get('LineNumber')
                            );
                            oil.add(oi);
                        }
                    }
                    if(!oil.isEmpty()){
                        insert oil;    
                        order.Status = 'Ready for Transmission to ERP';
                        update order;
                        ConnectApi.OrderSummaryInputRepresentation osir = new ConnectApi.OrderSummaryInputRepresentation();
                        osir.orderId = order.Id;
                        osir.orderLifeCycleType = 'MANAGED';
                        if(!Test.isRunningTest()){    
                            ConnectApi.OrderSummaryOutputRepresentation osor = ConnectApi.OrderSummaryCreation.createOrderSummary(osir);
                        }
                    } else {
                        delete orderDeliveryGroup;
                        delete order;
                    }
                } else {
                    delete orderDeliveryGroup;
                    delete order;
                }
            } catch(Exception e){
                System.debug(e);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('FTPOrderProcessingBatch processed.' );
    }

    public class OrderItemWrapper{
        @AuraEnabled public Integer quantity;
        @AuraEnabled public Id productId;
        @AuraEnabled public String productName;
        @AuraEnabled public String productCode;
        @AuraEnabled public String currencyIsoCode;
        @AuraEnabled public String quantityUnitOfMeasure;
        public OrderItemWrapper(Integer quantity, Id productId, String productName, String productCode, String currencyIsoCode, String quantityUnitOfMeasure){
            this.quantity = quantity;
            this.productId = productId;
            this.productName = productName;
            this.productCode = productCode;
            this.currencyIsoCode = currencyIsoCode;
            this.quantityUnitOfMeasure = quantityUnitOfMeasure;
        }
    }
    
    public static Map<String,Object> buildPayload(
        List<FTPOrderLine> orderLines,
        Map<String, Product2> productsBySku,
        String erpCustomerNumber,
        ERPIntegrationSettings__mdt cfg
    ){
        Map<String,Object> root = new Map<String,Object>();
        
        // Order Items
        Integer lineNum = 1;    
        List<Map<String,Object>> orderItems = new List<Map<String,Object>>();    
        for(FTPOrderLine orderLine : orderLines){
            if(productsBySku.containsKey(orderLine.productSku)){
                List<String> productCodeSplit = WebshopDataController.splitLastSuffix(orderLine.productSku);
                Map<String,Object> item = new Map<String,Object>();            
                item.put('Quantity', orderLine.quantity);
                item.put('CurrencyIsoCode', 'EUR');
                item.put('LineNumber', lineNum++);            
                Map<String,Object> product = new Map<String,Object>();
                product.put('Id', productsBySku.get(orderLine.productSku));
                if(!productCodeSplit.isEmpty() && productCodeSplit.size() > 1 && productCodeSplit[1].isAlpha()){
                    product.put('ProductCode', productCodeSplit[0].replace('OLD_', ''));
                }       
                item.put('Product2', product);
                item.put('Product2Id', productsBySku.get(orderLine.productSku));
                orderItems.add(item);
            }
        }        
        root.put('OrderItems', orderItems);        
        // Partner Roles
        Map<String,Object> partner = new Map<String,Object>{
            'ERPCustomerNumber__c' => erpCustomerNumber
        };
        
        root.put('Account', partner);
        root.put('SoldTo__r', partner);
        root.put('BillTo__r', partner);
        root.put('ShipTo__r', partner);
        root.put('Payer__r', partner);
        
        // Order Header
        root.put('Type', cfg.OrderType__c);
        //root.put('OrderReferenceNumber', 'Test');
        root.put('CurrencyIsoCode', 'EUR');
        root.put('SalesOrganization__c', cfg.SalesOrg__c);
        root.put('DistributionChannel__c', cfg.DistChannel__c);
        root.put('OrganizationDivision__c', cfg.Division__c);
        root.put('RequestedDeliveryDate__c', String.valueOf(Date.today().addDays(7)));
        root.put('ConfirmedDeliveryDate__c', Date.today());
        root.put('ShippingCondition__c', '-');
        
        return root;
    }

}