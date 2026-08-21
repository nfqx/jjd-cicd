/*
* Created by: Stanley Yin
* Created Date: 24.02.2025
* Purpose: Batch Job to populate ExternalId on Product2 where missing
*/

public without sharing class BatchPopulateWebshopProductImage implements Schedulable, Database.Batchable<sObject>, Database.Stateful {
    private static final String CURRENT_STORE_ID = System.Label.WebshopDoNotTranslateStoreID;
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchPopulateWebshopProductImage(), 20);
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Set<Id> allowedProductIds = new Set<Id>();
        String DUMMY_ACCOUNT_ID = [SELECT Id FROM Account WHERE Name = : System.Label.WebshopDoNotTranslateTestCustomerName LIMIT 1].Id;
        for(CommerceEntitlementProduct entitlement : [SELECT Id, ProductId FROM CommerceEntitlementProduct WHERE (Product.ProductClass = 'Variation' OR Product.ProductClass = 'Simple') AND Policy.Account__c = : DUMMY_ACCOUNT_ID]){
            allowedProductIds.add(entitlement.ProductId);
        }
        return Database.getQueryLocator('SELECT Id FROM Product2 WHERE Id IN : allowedProductIds');
    }
    
    public void execute(Database.BatchableContext bc, List<Product2> scope) {
        Map<Id, Product2> productsMap = new Map<Id, Product2>(scope);
        String DUMMY_ACCOUNT_ID = [SELECT Id FROM Account WHERE Name = : System.Label.WebshopDoNotTranslateTestCustomerName LIMIT 1].Id;
        ConnectApi.ProductOverviewCollection productObjectdata = ConnectApi.CommerceCatalog.getProducts(CURRENT_STORE_ID, DUMMY_ACCOUNT_ID, new List<String>((Set<String>)JSON.deserialize(JSON.serialize(productsMap.keySet()), Set<String>.class)), null, new List<String>{'Id'}, false, false);
        // get the ConnectApi.ProductOverview objects from the collection
        for (ConnectApi.ProductOverview product: productObjectdata.products) {
            if(product.defaultImage != null && product.id  != null && product.defaultImage.url  != null){
                productsMap.get(product.id).WebshopImageURL__c = product.defaultImage.url;
            }
        }
        update productsMap.values();
    }

public void finish(Database.BatchableContext bc){ /* DO nothing */ }
}