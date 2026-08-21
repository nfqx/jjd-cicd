trigger AccountContactRelationTrigger on AccountContactRelation (after insert, after update, after delete) {
    if(Trigger.isInsert){
        AccountContactRelationTriggerHandler.handleAfterInsert(Trigger.new);
    } else if(Trigger.isUpdate){
        AccountContactRelationTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    } else if(Trigger.isDelete){
        AccountContactRelationTriggerHandler.handleAfterDelete(Trigger.old);
    }
}