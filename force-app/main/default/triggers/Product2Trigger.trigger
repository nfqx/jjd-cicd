trigger Product2Trigger on Product2 (before insert, after insert, before update, after update) {
    if(Trigger.isInsert){
        if(Trigger.isBefore){
            Product2TriggerHandler.brandAutoFill(Trigger.new);
        } else if(Trigger.isAfter){
            Product2TriggerHandler.setMachinePrice(Trigger.new, null);
        }
    } else if(Trigger.isUpdate){
        if(Trigger.isBefore){
            Product2TriggerHandler.setAlternativeName(Trigger.new, Trigger.oldMap);
        } else if(Trigger.isAfter){
            Product2TriggerHandler.setMachinePrice(Trigger.new, Trigger.oldMap);
        }
    }
    
}