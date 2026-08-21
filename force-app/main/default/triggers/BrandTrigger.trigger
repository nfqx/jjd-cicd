trigger BrandTrigger on WebshopBrand__c (after insert, after update, after delete, after undelete) {
    if(Trigger.isInsert){
        BrandTriggerHandler.createDeleteBuyerGroupEntitlementPolicies(Trigger.new, null, false);
    } else if(Trigger.isUpdate){
        BrandTriggerHandler.createDeleteBuyerGroupEntitlementPolicies(Trigger.new, Trigger.oldMap, false);
    } else if(Trigger.isDelete){
        BrandTriggerHandler.createDeleteBuyerGroupEntitlementPolicies(Trigger.old, null, true);
    } else if(Trigger.isUndelete){
        BrandTriggerHandler.createDeleteBuyerGroupEntitlementPolicies(Trigger.new, null, false);
    } 
}