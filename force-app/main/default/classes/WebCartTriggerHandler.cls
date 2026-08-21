public without sharing class WebCartTriggerHandler {
    private static final WebStore LWR_STORE = [SELECT Id, Name FROM WebStore WHERE Name = : System.Label.WebshopDoNotTranslateStoreName LIMIT 1];
    @TestVisible
    private static final Decimal SHIPPING_COST = Decimal.valueOf(System.Label.WebshopDoNotTranslateShippingCost);
    @TestVisible
    private static final Decimal SHIPPING_FREE_THRESHOLD = Decimal.valueOf(System.Label.WebshopDoNotTranslateShippingFreeThreshold);
    @TestVisible
    private static final List<String> SHIPPING_PRODUCT_CODES = System.Label.ShippingProductCodes.split(',');
    @TestVisible
    private static final Decimal FIRST_STAGE_VAL = Decimal.valueOf(System.Label.LetterCampaignBonusFirstStageThreshold);
    @TestVisible
    private static final Decimal SECOND_STAGE_VAL = Decimal.valueOf(System.Label.LetterCampaignBonusSecondStageThreshold);
    
    @AuraEnabled 
    public static Boolean checkLetterCustomer(){
        User u = [SELECT Contact.AccountId, Contact.Account.LetterCampaignActivated__c, Contact.Account.LetterCampaignBonusUsed__c FROM user WHERE id = : UserInfo.getUserId()];
        return u.Contact.Account.LetterCampaignActivated__c && !u.Contact.Account.LetterCampaignBonusUsed__c;
    }
    public static void checkLetterCampaignFreeItemsAndShippingCosts(List<WebCart> newRecords){
        CartItemTriggerHandler.hasTriggerRan = true;    
        List<CartItem> itemsToInsertList = new List<CartItem>();
        List<CartItem> itemToDeleteList = new List<CartItem>();
        Map<Id, CartItem> itemToUpdateMap = new Map<Id, CartItem>();
        // Letter Campaign Processing
        List<String> allAccIds = CollectionUtils.generateStringListFromSObjectList(newRecords, 'AccountId', true, true);
        Map<Id, Account> accountsWithAttributes = new Map<Id, Account>([SELECT Id, LetterCampaignActivated__c, LetterCampaignBonusUsed__c, LetterCampaignFreeItem__c, LetterCampaignFreeItem2__c, LetterCampaignFreeItem__r.ProductCode, LetterCampaignFreeItem__r.Name, LetterCampaignFreeItem2__r.ProductCode, LetterCampaignFreeItem2__r.Name  FROM Account WHERE Id IN : allAccIds]);            
        Map<Id, Id> cartDeliveryGroupMap = new Map<Id, Id>();
        Set<Id> freeItemFirstLevelSet = new Set<Id>();
        Map<Id, CartItem> freeItems = new Map<Id, CartItem>();
        Map<Id, CartItem> freeItems2 = new Map<Id, CartItem>();
        for(CartItem ci : [SELECT Id, LetterCampaignFreeItem__c, LetterCampaignFreeItem2__c, Cart.AccountId, CartDeliveryGroupId, Product2.ProductCode, CartId FROM CartItem WHERE CartId IN : newRecords]){
            if(ci.LetterCampaignFreeItem__c){
                if(ci.LetterCampaignFreeItem2__c){
                    freeItems2.put(ci.CartId, ci);
                } else {
                    freeItems.put(ci.CartId, ci);
                }
            } else if(ci.CartDeliveryGroupId != null){
                cartDeliveryGroupMap.put(ci.CartId, ci.CartDeliveryGroupId);
            }
        }
        // Shipping Cost Processing
        Map<Id, Product2> shippingProductMap = new Map<Id, Product2>([SELECT Id FROM Product2 WHERE ProductCode IN : SHIPPING_PRODUCT_CODES]);
        Map<Id, PricebookEntry> shippingPricebookEntryMap = new Map<Id, PricebookEntry>();
        if(Test.isRunningTest()){
            for(PricebookEntry pbe : [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2.ProductCode IN : SHIPPING_PRODUCT_CODES AND Pricebook2ID =: Test.getStandardPricebookId()]){
                shippingPricebookEntryMap.put(pbe.Product2Id, pbe);
            }
        } else {
            for(PricebookEntry pbe : [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2.ProductCode IN : SHIPPING_PRODUCT_CODES AND Pricebook2.IsStandard = TRUE]){
                shippingPricebookEntryMap.put(pbe.Product2Id, pbe);
            }
        }
        for(CartItem ci : [SELECT Id, CartId FROM CartItem WHERE CartId IN : newRecords AND Product2.ProductCode IN : SHIPPING_PRODUCT_CODES]){
            itemToUpdateMap.put(ci.CartId, ci);
        }
        for(WebCart cart : newRecords){
            System.debug(cart.TotalAmount__c);
            Account acc = accountsWithAttributes.get(cart.AccountId);
            if(acc != null && acc.LetterCampaignActivated__c && !acc.LetterCampaignBonusUsed__c){
                if(cart.TotalAmount__c < FIRST_STAGE_VAL){
                    if(freeItems.containsKey(cart.Id)){
                        itemToDeleteList.add(freeItems.get(cart.Id));
                    }
                    if(freeItems2.containsKey(cart.Id)){
                        itemToDeleteList.add(freeItems2.get(cart.Id));
                    }
                } 
                if(acc.LetterCampaignFreeItem__c != null && cart.TotalAmount__c >= FIRST_STAGE_VAL){
                    CartItem ci = createFreeItem(cart.Id, acc.LetterCampaignFreeItem__c, acc.LetterCampaignFreeItem__r.Name, cartDeliveryGroupMap.get(cart.Id), false);
                    if(ci != null){
                        if(!freeItems.containsKey(cart.Id)){
                            itemsToInsertList.add(ci);
                        }
                    }
                    if(cart.TotalAmount__c < SECOND_STAGE_VAL){
                        if(freeItems2.containsKey(cart.Id)){
                            itemToDeleteList.add(freeItems2.get(cart.Id));
                        }
                    }
                } 
                if(acc.LetterCampaignFreeItem2__c != null && cart.TotalAmount__c >= SECOND_STAGE_VAL){
                    CartItem ci2 = createFreeItem(cart.Id, acc.LetterCampaignFreeItem2__c, acc.LetterCampaignFreeItem2__r.Name, cartDeliveryGroupMap.get(cart.Id), true);
                    if(ci2 != null){
                        if(!freeItems2.containsKey(cart.Id)){
                            itemsToInsertList.add(ci2);
                        }
                    }
                }
            }
            if(cart.WebStoreId == LWR_STORE.Id){
                // Free Shipping if no products or above threshold
                /*if(cart.TotalAmount__c == 0 || cart.TotalAmount__c > SHIPPING_FREE_THRESHOLD){
                    if(itemToUpdateMap.containsKey(cart.Id)){
                        itemToUpdateMap.get(cart.Id).Quantity = 1;
                        itemToUpdateMap.get(cart.Id).UnitAdjustedPrice = 0;
                        itemToUpdateMap.get(cart.Id).SalesPrice = 0;
                        itemToUpdateMap.get(cart.Id).TotalPrice = 0;
                        itemToUpdateMap.get(cart.Id).TotalPriceAfterAllAdjustments = 0;
                        itemToUpdateMap.get(cart.Id).TotalLineAmount = 0;
                        itemToUpdateMap.get(cart.Id).Type = 'Charge';
                    } else {
                        // Create Shipping Order Item   
                        if(!shippingProductMap.isEmpty() && shippingPricebookEntryMap.containsKey(shippingProductMap.values()[0].Id)){  
                            CartItem ci = createShippingItem(cart.Id, cartDeliveryGroupMap.get(cart.Id), shippingProductMap.values()[0].Id, true);
                            if(ci != null){
                                itemsToInsertList.add(ci);
                            }
                        }   
                    }
                } else {
                    if(itemToUpdateMap.containsKey(cart.Id)){
                        itemToUpdateMap.get(cart.Id).Quantity = 1;
                        itemToUpdateMap.get(cart.Id).UnitAdjustedPrice = SHIPPING_COST;
                        itemToUpdateMap.get(cart.Id).SalesPrice = SHIPPING_COST;
                        itemToUpdateMap.get(cart.Id).TotalPrice = SHIPPING_COST;
                        itemToUpdateMap.get(cart.Id).TotalPriceAfterAllAdjustments = SHIPPING_COST;
                        itemToUpdateMap.get(cart.Id).TotalLineAmount = SHIPPING_COST;
                        itemToUpdateMap.get(cart.Id).Type = 'Charge';
                    } else {
                        // Create Shipping Order Item   
                        if(!shippingProductMap.isEmpty() && shippingPricebookEntryMap.containsKey(shippingProductMap.values()[0].Id)){   
                            CartItem ci = createShippingItem(cart.Id, cartDeliveryGroupMap.get(cart.Id), shippingProductMap.values()[0].Id, false);
                            if(ci != null){
                                itemsToInsertList.add(ci);
                            }
                        }
                    }
                }*/
            }
        }

        if(!itemToUpdateMap.isEmpty()){
            update itemToUpdateMap.values();
        }
        if(!itemsToInsertList.isEmpty()){
            insert itemsToInsertList;
        }
        if(!itemToDeleteList.isEmpty()){
            delete itemToDeleteList;
        }
    }

    /*private static CartItem createShippingItem(Id cartId, Id cartDeliveryGroupId, Id productId, Boolean isFree){
        if(cartDeliveryGroupId != null){
            CartItem ciClone = new CartItem();
            ciClone.Name = 'Versandkosten';
            ciClone.Product2Id = productId;
            ciClone.cartDeliveryGroupId = cartDeliveryGroupId;
            ciClone.Quantity = 1;
            if(isFree){
                ciClone.UnitAdjustedPrice = 0;
                ciClone.SalesPrice = 0;
                ciClone.TotalPrice = 0;
                ciClone.TotalPriceAfterAllAdjustments = 0;
                ciClone.TotalLineAmount = 0;
            } else {
                ciClone.UnitAdjustedPrice = SHIPPING_COST;
                ciClone.SalesPrice = SHIPPING_COST;
                ciClone.TotalPrice = SHIPPING_COST;
                ciClone.TotalPriceAfterAllAdjustments = SHIPPING_COST;
                ciClone.TotalLineAmount = SHIPPING_COST;
            }
            ciClone.CartId = cartId;
            ciClone.Type = 'Charge';
            return ciClone;
        }
        return null;
    }*/
    private static CartItem createFreeItem(Id cartId, Id productId, String productName, Id cartDeliveryGroupId, Boolean secondLevel){
        if(cartDeliveryGroupId != null){
            CartItem ciClone = new CartItem();
            ciClone.Name = 'Gratisartikel für Neukunden: ' + productName;
            ciClone.Product2Id = productId;
            ciClone.cartDeliveryGroupId = cartDeliveryGroupId;
            ciClone.Quantity = 1;
            ciClone.UnitAdjustedPrice = 0;
            ciClone.SalesPrice = 0;
            ciClone.TotalPrice = 0;
            ciClone.TotalPriceAfterAllAdjustments = 0;
            ciClone.AdjustmentAmount = 0;
            ciClone.UnitAdjustmentAmount = 0;
            ciClone.TotalAdjustmentAmount = 0;
            ciClone.TotalLineAmount = 0;
            ciClone.LetterCampaignFreeItem__c = true;
            ciClone.LetterCampaignFreeItem2__c = secondLevel;
            ciClone.CartId = cartId;
            return ciClone;
        }
        return null;
    }
}