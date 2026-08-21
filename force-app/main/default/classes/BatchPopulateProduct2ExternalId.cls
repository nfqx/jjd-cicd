/*
* Created by: Stanley Yin
* Created Date: 06-04-2024
* Purpose: Batch Job to populate ExternalId on Product2 where missing
*/

public without sharing class BatchPopulateProduct2ExternalId implements Schedulable, Database.Batchable<sObject>, Database.Stateful {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchPopulateProduct2ExternalId(), 100);
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, ProductCode, Tenant__c FROM Product2 WHERE ExternalId = null AND ProductCode != NULL AND Tenant__c != NULL');
    }
    
    public void execute(Database.BatchableContext bc, List<Product2> scope) {
        for(Product2 prod : scope){
            prod.ExternalId = prod.Tenant__c + prod.ProductCode;
        }
        update scope;
    }

public void finish(Database.BatchableContext bc){ /* DO nothing */ }
}