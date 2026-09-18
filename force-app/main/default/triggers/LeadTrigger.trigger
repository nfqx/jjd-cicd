trigger LeadTrigger on Lead (after update) {
    if(Trigger.isUpdate){
        LeadTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}