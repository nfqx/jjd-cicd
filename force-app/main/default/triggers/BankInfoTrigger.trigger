trigger BankInfoTrigger on BankInfo__c (before insert, before update, after insert, after update) {
    if(Trigger.isInsert){
        if(Trigger.isBefore){
            BankInfoTriggerHandler.handleBeforeInsert(Trigger.new);
        } else if(Trigger.isAfter){
            BankInfoTriggerHandler.handleAfterInsert(Trigger.new);
        }
    } else if(Trigger.isUpdate){
        if(Trigger.isBefore){
            BankInfoTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        } else if(Trigger.isAfter){
            BankInfoTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}