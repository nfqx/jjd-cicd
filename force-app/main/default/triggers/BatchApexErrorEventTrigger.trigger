trigger BatchApexErrorEventTrigger on BatchApexErrorEvent (after insert) {
    if(Trigger.isInsert){
        BatchApexErrorEventTriggerHandler.handleAfterInsert(Trigger.new);
    } 
}