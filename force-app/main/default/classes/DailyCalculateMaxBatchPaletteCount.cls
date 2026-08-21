/*
* Created by: Stanley Yin
* Created Date: 05-11-2025
* Purpose: Batch Job to calculate BoxCount__c and PaletteCount__c
*/

public without sharing class DailyCalculateMaxBatchPaletteCount implements Schedulable, Database.Batchable<sObject> {
    // Start method: Retrieve Custom ErrorLogging__c records
    public static void execute(SchedulableContext sc) {
        Database.executeBatch(new DailyCalculateMaxBatchPaletteCount(), 100);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id FROM Product2 WHERE IsActive = TRUE AND ProductClass = 'VariationParent']);
    }
    
    public void execute(Database.BatchableContext bc, List<Product2> scope){
        Map<Id, Product2> productsToUpdate = new Map<Id, Product2>();
        Map<Id, List<Product2>> parentToPieceMap = new Map<Id, List<Product2>>();
        Map<Id, List<Product2>> parentToBoxMap = new Map<Id, List<Product2>>();
        Map<Id, Map<String, Integer>> perUnitMap = new Map<Id, Map<String, Integer>>();
        for(ProductAttribute att : [SELECT Unit__c, ProductId, Product.Factor__c, VariantParentId FROM ProductAttribute WHERE VariantParentId IN :scope]){
            if(att.Unit__c == 'STUECK'){
                List<Product2> innerList = parentToPieceMap.containsKey(att.VariantParentId) ? parentToPieceMap.get(att.VariantParentId) : new List<Product2>();
                innerList.add(att.Product);
                parentToPieceMap.put(att.VariantParentId, innerList);
            } else if(att.Unit__c == 'KARTON'){
                List<Product2> innerList = parentToBoxMap.containsKey(att.VariantParentId) ? parentToBoxMap.get(att.VariantParentId) : new List<Product2>();
                innerList.add(att.Product);
                parentToBoxMap.put(att.VariantParentId, innerList);
                if(att.Product.Factor__c != null){
                    Map<String, Integer> innerMap = perUnitMap.containsKey(att.VariantParentId) ? perUnitMap.get(att.VariantParentId) : new Map<String, Integer>();
                    innerMap.put('box', Integer.valueOf(att.Product.Factor__c));
                    perUnitMap.put(att.VariantParentId, innerMap);
                }
            } else if(att.Unit__c == 'PALETTE'){
                if(att.Product.Factor__c != null){
                    Map<String, Integer> innerMap = perUnitMap.containsKey(att.VariantParentId) ? perUnitMap.get(att.VariantParentId) : new Map<String, Integer>();
                    innerMap.put('palette', Integer.valueOf(att.Product.Factor__c));
                    perUnitMap.put(att.VariantParentId, innerMap);
                }
            }
        }
        for(Id variationParentId : parentToPieceMap.keySet()){
            for(Product2 prodToUpdate : parentToPieceMap.get(variationParentId)){
                prodToUpdate.BoxCount__c = perUnitMap.containsKey(variationParentId) && perUnitMap.get(variationParentId).containsKey('box') ? perUnitMap.get(variationParentId).get('box') : null;
                prodToUpdate.PaletteCount__c = perUnitMap.containsKey(variationParentId) && perUnitMap.get(variationParentId).containsKey('palette') ? perUnitMap.get(variationParentId).get('palette') : null;
                productsToUpdate.put(prodToUpdate.Id, prodToUpdate);
            }
        }
        for(Id variationParentId : parentToBoxMap.keySet()){
            for(Product2 prodToUpdate : parentToBoxMap.get(variationParentId)){
                prodToUpdate.BoxCount__c = null;
                prodToUpdate.PaletteCount__c = prodToUpdate.Factor__c != null && perUnitMap.containsKey(variationParentId) && perUnitMap.get(variationParentId).containsKey('palette') && Math.mod(perUnitMap.get(variationParentId).get('palette'), Integer.valueOf(prodToUpdate.Factor__c)) == 0 ?
                    Integer.valueOf(perUnitMap.get(variationParentId).get('palette') / prodToUpdate.Factor__c) : null;
                productsToUpdate.put(prodToUpdate.Id, prodToUpdate);
            }
        }
        if(!productsToUpdate.isEmpty()){
            update productsToUpdate.values();
        }
    }

    public void finish(Database.BatchableContext bc){
        // Do nothing
    }
        
}