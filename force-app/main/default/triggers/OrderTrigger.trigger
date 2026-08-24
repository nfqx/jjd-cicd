trigger OrderTrigger on Order (after insert, after update) {
    if(Trigger.isInsert){
        OrderTriggerHandler.handleERPAfterInsert(Trigger.new);
        OrderTriggerHandler.removeFromVoucherBuyerGroup(Trigger.new);
        OrderTriggerHandler.informAboutVIPCustomers(Trigger.new);
        OrderTriggerHandler.sendParentNotification(Trigger.new);
    } else if(Trigger.isUpdate){
        OrderTriggerHandler.handleERPAfterUpdate(Trigger.new);
        OrderTriggerHandler.checkLetterCampaignFreeItems(Trigger.new, Trigger.oldMap);
    }
}