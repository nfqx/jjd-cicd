/*
* Created by: Stanley Yin
* Created Date: 15-11-2024
* Purpose: Batch Job to populate ExternalId on Product2 where missing
*/

public without sharing class BatchPopulateCountSales implements Schedulable, Database.Batchable<sObject>, Database.Stateful {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchPopulateCountSales(), 100);
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id FROM Product2');
    }
    
    public void execute(Database.BatchableContext bc, List<Product2> scope) {
        Map<String, Integer> salesCount = new Map<String, Integer>();
        for(AggregateResult ar : [SELECT Count(Id) cnt, Product2Id FROM OrderItem WHERE Order.Status != 'Draft' AND Order.CreatedDate = LAST_N_MONTHS:12 AND Product2Id IN : scope GROUP BY Product2Id]){
            salesCount.put(String.valueOf(ar.get('Product2Id')), Integer.valueOf(ar.get('cnt')));
        }
        for(Product2 p : scope){
            p.CountSales__c = salesCount.containsKey(p.Id) ? salesCount.get(p.Id) : 0;
        }
        update scope;
    }

public void finish(Database.BatchableContext bc){ /* DO nothing */ }
}