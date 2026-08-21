trigger CartItemTrigger on CartItem (before insert, after insert, before update, after update, after delete) {
    if(Trigger.isInsert){
        if(Trigger.isBefore){
            CartItemTriggerHandler.checkTriggerRun(Trigger.new);
        } else {
            CartItemTriggerHandler.triggerCarts(Trigger.new);
        }
    } else if(Trigger.isUpdate){
        if(Trigger.isBefore){
            List<CartItem> cartItemQuantityChanged = new List<CartItem>();
            for(CartItem ci : Trigger.new){
                if(Trigger.oldMap.get(ci.Id).Quantity != ci.Quantity){
                    cartItemQuantityChanged.add(ci);
                }
            }
            if(!cartItemQuantityChanged.isEmpty()){
                CartItemTriggerHandler.checkTriggerRun(cartItemQuantityChanged);
            }
        } else {
            CartItemTriggerHandler.triggerCarts(Trigger.new);
        }
    } else if(Trigger.isDelete){
        //CartItemTriggerHandler.deleteRelatedFreeItems(Trigger.old);
        if(!CartItemTriggerHandler.hasTriggerRan){
            CartItemTriggerHandler.triggerCarts(Trigger.old);
        }
    } 
}