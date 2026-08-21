trigger OpportunityTrigger on Opportunity (after insert, after update) {
    if(Trigger.isInsert){
        OpportunityTriggerHandler.handleAfterInsert(Trigger.newMap);
    } else if(Trigger.isUpdate){
        OpportunityTriggerHandler.handleAfterUpdate(Trigger.newMap, Trigger.oldMap);
    } 
}