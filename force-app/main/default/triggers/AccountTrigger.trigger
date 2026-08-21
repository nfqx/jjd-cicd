trigger AccountTrigger on Account  (before insert, after insert, before update, after update, before delete, after delete) {
    if(Trigger.isInsert){
        if(Trigger.isBefore){
            AccountTriggerHandler.classify(Trigger.new, null);
        } else if(Trigger.isAfter){
            AccountTriggerHandler.handleAfterInsert(Trigger.newMap);
            AccountTriggerHandler.fanOut();
        }
    } else if(Trigger.isUpdate){
        if(Trigger.isBefore){
            AccountTriggerHandler.classify(Trigger.new, Trigger.oldMap);
        } else if(Trigger.isAfter){
            AccountTriggerHandler.handleAfterUpdate(Trigger.newMap, Trigger.oldMap);
            AccountTriggerHandler.fanOut();
        }
    } else if(Trigger.isDelete){
        if(Trigger.isBefore){
            AccountTriggerHandler.collectRelatedIds(Trigger.old);
        } else if(Trigger.isAfter){
            AccountTriggerHandler.fanOut();
        }
    }
}