public class OneTimeBatchPopulateChildOldAccNr implements Database.Batchable<sObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, ProductId, VariantParentId, VariantParent.OldProductNumber__c FROM ProductAttribute WHERE VariantParent.OldProductNumber__c != NULL');
    }
    
    public void execute(Database.BatchableContext bc, List<ProductAttribute> scope) {
        Map<Id, Product2> productMap = new Map<Id, Product2>();
        for(ProductAttribute pa : scope){
            productMap.put(pa.ProductId, new Product2(Id = pa.ProductId, OldProductNumber__c = pa.VariantParent.OldProductNumber__c));
        }
        update productMap.values();
    }

    public void finish(Database.BatchableContext bc){
        
    }
}