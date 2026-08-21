trigger ProductCategoryProductTrigger on ProductCategoryProduct (before insert, after insert) {
    if(Trigger.isBefore){
        ProductCategoryProductTriggerHandler.populateUniqueKey(Trigger.new);
    } else if(Trigger.isAfter){
        ProductCategoryProductTriggerHandler.addHierarchyRecords(Trigger.new);
    }
}