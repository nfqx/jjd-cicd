trigger ReturnOrderTrigger on ReturnOrder (after insert, after update) {
    if(Trigger.isInsert){
        ReturnOrderTriggerHandler.handleAfterInsert(Trigger.new);
    } else if(Trigger.isUpdate){
        ReturnOrderTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}