trigger UserTrigger on User (after insert, before update, after update)
{
	if(Trigger.isUpdate){
		if(Trigger.isBefore){
			UserTriggerHandler.unsetActivationRequired(Trigger.new, Trigger.oldMap);
		} else if(Trigger.isAfter){
    		UserTriggerHandler.handleWebshopSync(Trigger.new, Trigger.oldMap);
		}
	} else if(Trigger.isInsert){
		UserTriggerHandler.handleWebshopSync(Trigger.new, null);
	}
}