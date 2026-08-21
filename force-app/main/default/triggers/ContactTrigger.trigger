trigger ContactTrigger on Contact (after insert, after update) {
    if(Trigger.isInsert){
        ContactTriggerHandler.handleAfterInsert(Trigger.newMap);
    } else if(Trigger.isUpdate){
        ContactTriggerHandler.handleAfterUpdate(Trigger.newMap, Trigger.oldMap);
    } 
}