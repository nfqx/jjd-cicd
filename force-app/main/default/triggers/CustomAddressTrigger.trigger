trigger CustomAddressTrigger on CustomAddress__c (before insert, after insert, after update) {
    if(Trigger.isInsert){
        if(Trigger.isBefore){
            CustomAddressTriggerHandler.handleBeforeInsert(Trigger.new);
        } else if(Trigger.isAfter){
            CustomAddressTriggerHandler.handleAfterInsert(Trigger.new);
        }
    } else if(Trigger.isUpdate){
        CustomAddressTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}