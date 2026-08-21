public without sharing class CartItemTriggerHandler {
    @TestVisible
    private static final List<String> SHIPPING_PRODUCT_CODES = System.Label.ShippingProductCodes.split(',');
    public static Boolean hasTriggerRan = false;

    public static void triggerCarts(List<CartItem> newRecords){
        Boolean run = false;
        for(CartItem ci : newRecords){
            if(!ci.LetterCampaignFreeItem__c && !ci.FreeItem__c && !ci.CartFreeItem__c){
                run = true;
            }
        }
        // Only run if we have neither free items nor letter campaign free items
        if(run){
            List<String> allCartIds = new List<String>();
            for(CartItem ci : newRecords){
                if(!ci.FreeItem__c && !ci.LetterCampaignFreeItem__c && !SHIPPING_PRODUCT_CODES.contains(ci.ProductCode__c)){
                    allCartIds.add(ci.CartId);
                }
            }
            if(!allCartIds.isEmpty()){
                List<WebCart> carts = [SELECT Id, AccountId, WebStoreId, (SELECT Id, CartDeliveryGroupId FROM CartItems WHERE FreeItem__c = FALSE AND CartFreeItem__c = FALSE AND LetterCampaignFreeItem__c = FALSE) FROM WebCart WHERE Id IN : allCartIds];

                Map<Id, CartItem> hasCartFreeItems = new Map<Id, CartItem>();
                for(CartItem ci : [SELECT Id, CartId FROM CartItem WHERE CartId IN : carts AND CartFreeItem__c = TRUE]){
                    hasCartFreeItems.put(ci.CartId, ci);
                }

                Map<Id, Decimal> sumMap = new Map<Id, Decimal>();
                for(AggregateResult ar : [SELECT SUM(TotalLineAmount) sumVal, CartId FROM CartItem WHERE Product2.ProductCode NOT IN :SHIPPING_PRODUCT_CODES AND CartId IN : allCartIDs GROUP BY CartId]){
                    sumMap.put(String.valueOf(ar.get('CartId')), (Decimal)ar.get('sumVal'));
                }
                List<CartItem> cartItemsToDelete = new List<CartItem>();
                for(WebCart cart : carts){
                    cart.TotalAmount__c = sumMap.containsKey(cart.Id) ? sumMap.get(cart.Id) : 0;
                    if(hasCartFreeItems.containsKey(cart.Id)){
                        cartItemsToDelete.add(hasCartFreeItems.get(cart.Id));
                    }

                }
                if(!cartItemsToDelete.isEmpty()){
                    delete cartItemsToDelete;
                }
                WebCartTriggerHandler.checkLetterCampaignFreeItemsAndShippingCosts(carts);
            }
        }
    }

    public static void checkTriggerRun(List<CartItem> newRecords){
        Boolean run = false;
        for(CartItem ci : newRecords){
            if(!ci.LetterCampaignFreeItem__c && !ci.FreeItem__c && !ci.CartFreeItem__c){
                hasTriggerRan = true;
            }
        }
    }
}