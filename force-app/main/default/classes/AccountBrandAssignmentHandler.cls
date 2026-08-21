public without sharing class AccountBrandAssignmentHandler {
    public static void populateUniqueIdentifier(List<AccountBrandAssignment__c> newRecords){
        for(AccountBrandAssignment__c newRec : newRecords){
            newRec.UniqueIdentifier__c = newRec.Account__c + '' + newRec.Brand__c;
        }
    }
    public static void assignBuyerGroups(List<AccountBrandAssignment__c> newRecords){
        Set<Id> brandSet = new Set<Id>();
        Set<Id> accSet = new Set<Id>();
        for(AccountBrandAssignment__c newRec : newRecords){
            brandSet.add(newRec.Brand__c);
            accSet.add(newRec.Account__c);
        }
        Map<Id, Id> brandToBuyerGroupMap = new Map<Id, Id>();
        for(BuyerGroup bg : [SELECT Id, Brand__c FROM BuyerGroup WHERE Brand__c IN : brandSet]){
            brandToBuyerGroupMap.put(bg.Brand__c, bg.Id);
        }
        Set<Id> activeAccounts = new Set<Id>();
        for(BuyerAccount bacc : [SELECT Id, BuyerId FROM BuyerAccount WHERE BuyerId IN : accSet AND IsActive = TRUE]){
            activeAccounts.add(bacc.BuyerId);
        }
        List<BuyerGroupMember> bgmToInsert = new List<BuyerGroupMember>();
        for(AccountBrandAssignment__c newRec : newRecords){
            if(brandToBuyerGroupMap.containsKey(newRec.Brand__c) && activeAccounts.contains(newRec.Account__c)){
                bgmToInsert.add(new BuyerGroupMember(
                    BuyerId = newRec.Account__c,
                    BuyerGroupId = brandToBuyerGroupMap.get(newRec.Brand__c)
                ));
            }
        }
        if(!bgmToInsert.isEmpty()){
            Database.insert(bgmToInsert, false);
        }
    }
    public static void unassignBuyerGroups(List<AccountBrandAssignment__c> newRecords){
        Map<Id, Set<Id>> deletedRelationMap = new Map<Id, Set<Id>>();
        Set<Id> deletedBrandSet = new Set<Id>();
        for(AccountBrandAssignment__c newRec : newRecords){
            deletedBrandSet.add(newRec.Brand__c);
            Set<Id> innerSet = deletedRelationMap.containsKey(newRec.Account__c) ? deletedRelationMap.get(newRec.Account__c) : new Set<Id>();
            innerSet.add(newRec.Brand__c);
            deletedRelationMap.put(newRec.Account__c, innerSet);
        }
        List<BuyerGroupMember> bgmToDelete = new List<BuyerGroupMember>();
        for(BuyerGroupMember bgm : [SELECT Id, BuyerGroup.Brand__c, BuyerId FROM BuyerGroupMember WHERE BuyerId IN : deletedRelationMap.keySet() AND BuyerGroup.Brand__c IN : deletedBrandSet]){
            if(deletedRelationMap.containsKey(bgm.BuyerId) && deletedRelationMap.get(bgm.BuyerId).contains(bgm.BuyerGroup.Brand__c)){
                bgmToDelete.add(bgm);
            }
        }
        if(!bgmToDelete.isEmpty()){
            delete bgmToDelete;
        }
    }
}