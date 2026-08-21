trigger AccountBrandAssignmentTrigger on AccountBrandAssignment__c (before insert, after insert, after delete) {
    if(Trigger.isInsert){
        if(Trigger.isBefore){
            AccountBrandAssignmentHandler.populateUniqueIdentifier(Trigger.new);
        } else if(Trigger.isAfter){
            AccountBrandAssignmentHandler.assignBuyerGroups(Trigger.new);
        }
    } else if(Trigger.isDelete){
        AccountBrandAssignmentHandler.unassignBuyerGroups(Trigger.old);
    }
}