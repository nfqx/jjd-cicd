/*
* Created by: Stanley Yin
* Created Date: June 2024
* Purpose: Batch Job to copy Standard into Custom Pricebook Entry records in the "Standard Price Book" Custom Price Book
*/

public without sharing class B2BProductPriceCopyStdChildBatch implements Database.Batchable<sObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {       
        return Database.getQueryLocator([SELECT Id,IsActive,Product2Id,ProductSellingModelId,UnitPrice,UseStandardPrice FROM PricebookEntry WHERE Pricebook2.IsStandard = TRUE AND Product2.ProductClass IN ('Variation')]);
    }
    
    // Execute method
    public void execute(Database.BatchableContext bc, List<PricebookEntry> scope)
    {
        List<Pricebook2> pb2s = [SELECT Id FROM Pricebook2 WHERE Name = : System.Label.WebshopDoNotTranslateInternalListpricePricebookName OR Pricebook2.Name = : System.Label.WebshopDoNotTranslateStandardPriceBookCopyForQuotes];
        //Pricebook2 pb2copy = [SELECT Id FROM Pricebook2 WHERE Name = : System.Label.WebshopDoNotTranslateInternalListpricePricebookName AND IsStandard = FALSE];

        List<String> involvedProdIds = CollectionUtils.generateStringListFromSObjectList(scope, 'Product2Id', true, true);
        List<ErrorLogging__c> errorLogs = new List<ErrorLogging__c>();
        try {
            Map<String, PricebookEntry> pricebookEntries = new Map<String, PricebookEntry>();
            for(Pricebook2 pb2 : pb2s){
                //Map<String, PricebookEntry> pricebookEntriesCopy = new Map<String, PricebookEntry>();

                for(PricebookEntry pbe : [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = : pb2.Id AND Product2Id IN : involvedProdIds]){
                    pricebookEntries.put(pbe.Product2Id, pbe);
                }
        
                for(PricebookEntry pbeold : scope){
                    PricebookEntry pbe = pricebookEntries.containsKey(pbeold.Product2Id) ? pricebookEntries.get(pbeold.Product2Id) : new PricebookEntry();
                    pbe.IsActive = pbeold.IsActive;
                    if(!pricebookEntries.containsKey(pbeold.Product2Id)){
                        pbe.Product2Id = pbeold.Product2Id;
                        pbe.Pricebook2Id = pb2.Id;
                        pbe.ProductSellingModelId = pbeold.ProductSellingModelId;
                        pbe.UseStandardPrice = pbeold.UseStandardPrice;
                    }
                    pbe.UnitPrice = pbeold.UnitPrice;
                    pricebookEntries.put(pbe.Product2Id, pbe);
                }
            }
            
            Integer i = 0;
            for (Database.UpsertResult result : Database.upsert(pricebookEntries.values(), false)) {
                if (!result.isSuccess()) {
                    for (Database.Error err : result.getErrors()) {
                        errorLogs.add(new ErrorLogging__c( Error__c = err.getStatusCode() + ': ' + err.getMessage() + ', Fields: ' + String.join(err.getFields(), ', '), RecordIDs__c = pricebookEntries.values()[i].Product2Id, ProcessName__c = 'B2BProductPriceCopyStdBatch.execute()' ));
                    }
                }
                i++;
            }
            i = 0;
            if(!errorLogs.isEmpty()){
                insert errorLogs;
            }
        }
        catch(Exception e){
            Database.insert(new ErrorLogging__c( Error__c = 'Failed to run B2BProductPriceCopyStdBatch: ' + e.getMessage() + ' - ' + e.getStackTraceString(), ProcessName__c = 'B2BProductPriceCopyStdBatch.execute()'));
        }
    }
    
    public void finish(Database.BatchableContext bc){ 
        // Database.executeBatch(new B2BProductPriceCopyStdChildBatch(), 100);
        // Do nothing
    }
        
}