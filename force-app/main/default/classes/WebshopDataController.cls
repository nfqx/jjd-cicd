/** BUILT BY NFQ-X **/

public without sharing class WebshopDataController {

    private static final List<String> PRODUCT_FIELDS = new List<String>{'Id','Name','BrandId__c','BrandName__c','StockKeepingUnit','ProductCode','PackageUnit__c',
        'Allergens__c', 'NutritionalValue__c', 'Ingredients__c', // CRM-1557
        'BoxCount__c', 'PaletteCount__c', 'CountSales__c', // CRM-1595
        'AvailableQuantity__c', // JJDSF-448
        'CurrencyIsoCode','Description','QuantityUnitOfMeasure','ProductSubtitle__c','ProductSlider__c','WebshopImageURL__c', 'BrandStaticSlider__c'};
    private static final String CURRENT_STORE_ID = System.Label.WebshopDoNotTranslateStoreID;
    private static final Integer RECORDS_PER_PAGE = Integer.valueOf(System.Label.WebshopSliderPerPage);
    private static final List<String> EXCLUDE_PRODUCTS = System.Label.ShippingProductCodes.split(',');
    private static final String WISHLIST_ITEM_PREFIX = Schema.getGlobalDescribe().get('WishlistItem').getDescribe().getKeyPrefix();
    private static final String ORDER_ITEM_PREFIX = Schema.getGlobalDescribe().get('OrderItem').getDescribe().getKeyPrefix();
    private static final String PRODUCT_PREFIX = Schema.getGlobalDescribe().get('Product2').getDescribe().getKeyPrefix();
    private static final Integer YELLOW_GREEN_THRESHOLD = (Integer) WebshopConfigurations__mdt.getAll().get('General').AvailabilityYellowGreenThreshold__c;
    //private static final Id CASE_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ZKS_Cases').getRecordTypeId();

    
    //private static final String CHANNEL_ID = ConnectApi.ManagedContentDelivery.getChannels(0, 250).channels[1].id;

    /********
     * 
     * CART AND WISHLIST
     * 
     ********/

     @AuraEnabled(cacheable=true)
     public static List<String> getProductImageDataById(String accountId, String productId){
        try {
            String productCode = [SELECT Id , ProductCode FROM Product2 WHERE Id = : productId LIMIT 1].ProductCode;
            Set<String> contentIds = new Set<String>();
            Set<String> returnSet = new Set<String>();
            for(ProductMedia pm : [
                SELECT Id, ElectronicMediaId
                FROM ProductMedia
                WHERE Product.ProductCode = : productCode
                ORDER BY CreatedDate
              ]){
                contentIds.add(pm.ElectronicMediaId);
            }
            if(!contentIds.isEmpty()){
                for(ManagedContent__c mc : [SELECT ManagedContentId__c, ContentKey__c FROM ManagedContent__c WHERE ManagedContentId__c IN : contentIds]){
                    returnSet.add(mc.ContentKey__c);
                }
            }
            return new List<String>(returnSet);
        } catch(Exception e){
            System.debug(e);
            return null;
        }
     }

     @AuraEnabled(cacheable=false)
     public static Integer getWishlistCount(String accountId){
        try{
            return [SELECT Id FROM WishlistItem WHERE Wishlist.WebstoreId = : CURRENT_STORE_ID AND Wishlist.OwnerId = : UserInfo.getUserId() AND Wishlist.AccountId = : accountId].size();
        } catch(Exception e){
            System.debug(e);
            return null;
        }
     }

     @AuraEnabled(cacheable=false)
     public static Boolean removeFromWishlist(String accountId, String productId){
        try{
            delete [SELECT Id, Product2Id FROM WishlistItem WHERE Wishlist.WebstoreId = : CURRENT_STORE_ID AND Wishlist.AccountId = : accountId AND Wishlist.OwnerId = : UserInfo.getUserId() AND Product2Id = : productId];
            return true;
        } catch(Exception e){
            System.debug(e);
            return false;
        }
     }

     @AuraEnabled(cacheable=false)
     public static List<WishlistItem> getWishlistItems(String accountId){
        try{
            return [SELECT Id, Product2Id, Product2.Name FROM WishlistItem WHERE Wishlist.WebstoreId = : CURRENT_STORE_ID AND Wishlist.AccountId = : accountId AND Wishlist.OwnerId = : UserInfo.getUserId() ];
        } catch(Exception e){
            System.debug(e);
            return null;
        }
     }

     @AuraEnabled(cacheable=false)
     public static Boolean addProductToWishlist(String accountId, String productId){
        try{
            Wishlist wishlist = null;
            List<Wishlist> wishlistList = [SELECT Id FROM Wishlist WHERE WebstoreId = : CURRENT_STORE_ID AND AccountId = : accountId AND OwnerId = : UserInfo.getUserId()];
            if(wishlistList.isEmpty()){
                wishlist = new Wishlist();
                wishlist.Name = UserInfo.getFirstName() + '\'s wishlist';
                wishlist.WebStoreId = CURRENT_STORE_ID;
                wishlist.AccountId = accountId;
                insert wishlist;
            } else {
                wishlist = wishlistList[0];
            }
            WishlistItem item = new WishlistItem(WishlistId = wishlist.Id, Product2Id = productId, Name = [SELECT Id, Name FROM Product2 WHERE id = : productId LIMIT 1].Name);
            System.debug(Database.insert(item, false));
            return true;
        } catch(Exception e){
            System.debug(e);
            return false;
        }
     }

     

     @AuraEnabled(cacheable=false)
     public static Integer countItemsInCart(String accountId, String cartId){
        try {
            if(String.isBlank(cartId)){
                cartId = getCartSummaryOrCreateCart(accountId);
            }
            if([SELECT Id FROM CartItem WHERE CartId = : cartId].isEmpty()){
                return 0;
            }
            return Integer.valueOf([SELECT SUM(Quantity) quantitySum FROM CartItem WHERE CartId = : cartId AND Product2.ProductCode NOT IN : EXCLUDE_PRODUCTS][0].get('quantitySum'));
        } catch(Exception e){
            System.debug(e);
            return null;
        }
     }

     @AuraEnabled(cacheable=false)
     public static String getCartSummaryOrCreateCart(String accountId){
        try {
            return Test.isRunningTest() ? [SELECT Id FROM WebCart LIMIT 1].Id : ConnectApi.CommerceCart.getOrCreateActiveCartSummary(CURRENT_STORE_ID, accountId, 'current').cartId;
        } catch(Exception e){
            System.debug(e);
            return null;
        }
     }

     @AuraEnabled(cacheable=false)
     public static List<CartItemWrapper> getCartItems(String accountId, String cartId){
        try{
            if(String.isBlank(cartId)){
                cartId = getCartSummaryOrCreateCart(accountId);
            }
            List<CartItemWrapper> dataList = new List<CartItemWrapper>();
            Set<String> allowedProductIds = retrieveAllowedProductIds(accountId);
            if(!allowedProductIds.isEmpty()){
                List<String> wishlistItems = new List<String>();
                for(WishlistItem wi : [SELECT Id, Product2Id FROM WishlistItem WHERE Wishlist.WebstoreId = : CURRENT_STORE_ID AND Wishlist.AccountId = : accountId AND Wishlist.OwnerId = : UserInfo.getUserId() AND Product2Id IN : allowedProductIds]){
                    wishlistItems.add(wi.Product2Id);
                }
                String queryString = 'SELECT Id, CurrencyIsoCode, Product2Id, Quantity, TotalAmount, TotalLineAmount, TotalPromoAdjustmentAmount, Product2.' + String.join(PRODUCT_FIELDS, ', Product2.') + ', CartId, Type, CartFreeItem__c, LetterCampaignFreeItem__c, FreeItem__c FROM CartItem WHERE CartId = : cartId AND Product2Id IN : allowedProductIds';
                for(CartItem ci : Database.query(queryString)){
                    dataList.add(new CartItemWrapper(ci, wishlistItems.contains(ci.Product2Id)));
                }
            }
            System.debug(dataList);
            return dataList;
        } catch(Exception e){
            System.debug(e);
            return null;
        }
     }

     @AuraEnabled(cacheable=false)
     public static Boolean removeItemFromCart(String cartId, String accountId, String productId){
        try{
            if(String.isBlank(cartId)){
                cartId = getCartSummaryOrCreateCart(accountId);
            }
            List<CartItem> cartItems = [SELECT Id FROM CartItem WHERE CartId = : cartId AND Product2Id = : productId];
            if(!cartItems.isEmpty()){
                for(Database.DeleteResult deleteResult: Database.delete(cartItems, false)){
                    if(!deleteResult.isSuccess()){
                        return false;
                    }
                }
            }
            return true;
        } catch(Exception e){
            System.debug(e);
            return false;
        }
     }
     @AuraEnabled(cacheable=false)
     public static Boolean changeCartQuantity(String cartId, String accountId, String productId, Integer quantity){
        try{
            if(String.isBlank(cartId)){
                cartId = getCartSummaryOrCreateCart(accountId);
            }
            List<CartItem> cartItems = [SELECT Id, UnitAdjustedPrice FROM CartItem WHERE CartId = : cartId AND Product2Id = : productId AND FreeItem__c = FALSE AND CartFreeItem__c = FALSE AND LetterCampaignFreeItem__c = FALSE];
            if(!cartItems.isEmpty()){
                CartItem cartItem = cartItems[0];
                if(quantity > 0){
                    //final ConnectApi.CartItemInput input = new ConnectApi.CartItemInput();
                    //input.productId = productId;
                    //input.quantity = String.valueOf(quantity);
                    //input.type = ConnectApi.CartItemType.Product; 
                    //if(Test.isRunningTest()){
                    cartItem.Quantity = quantity;
                    Decimal resultingPrice = (cartItem.UnitAdjustedPrice ?? 0) * (cartItem.Quantity ?? 0);
                    cartItem.SalesPrice = resultingPrice;
                    cartItem.TotalPrice = resultingPrice;
                    cartItem.TotalPriceAfterAllAdjustments = resultingPrice;
                    cartItem.TotalLineAmount = resultingPrice;
                    update cartItem;
                    //} else {
                    //    ConnectApi.CartItem itemResult = ConnectApi.CommerceCart.updateCartItem(CURRENT_STORE_ID, accountId, cartId, cartItem.Id, input);
                    //}
                    return true;
                } else {
                    //if(Test.isRunningTest()){
                    //      delete cartItem;
                    //} else {
                    //      ConnectApi.CommerceCart.deleteCartItem(CURRENT_STORE_ID, accountId, cartId, cartItem.Id);
                    delete [SELECT Id FROM CartItem WHERE CartId = : cartId AND Product2Id = : productId];
                    //}
                    return true;
                }
            }
        } catch(Exception e){
            System.debug(e);
        }
        return false;
     }
     
     /********
      * 
      * SLIDER PROCESSING
      * 
      ********/

     private static Set<String> retrieveAllowedProductIds(Id accountId){
        return retrieveAllowedProductIds(accountId, null, null);
     }

     public static Set<String> retrieveAllowedProductIds(Id accountId, Set<String> productCodes, String excludeId){
        Set<String> allowedProductIds = new Set<String>();
        Set<Id> allBuyerGroupIds = new Set<Id>();
        Set<Id> allPolicyIds = new Set<Id>();
        Boolean assortmentExtended = checkIfCustomerAssortmentExtended(accountId);
        if(assortmentExtended){
            for(BuyerGroupMember bgm : [SELECT Id, BuyerGroupId FROM BuyerGroupMember WHERE BuyerId = : accountId]){
                allBuyerGroupIds.add(bgm.BuyerGroupId);
            }
            for(WebStoreBuyerGroup wsb : [SELECT Id, BuyerGroupId FROM WebStoreBuyerGroup WHERE BuyerGroupId IN : allBuyerGroupIds AND WebStoreId = : CURRENT_STORE_ID]){
                allBuyerGroupIds.add(wsb.BuyerGroupId);
            }
            for(CommerceEntitlementBuyerGroup cebg : [SELECT Id, PolicyId FROM CommerceEntitlementBuyerGroup WHERE BuyerGroupId IN : allBuyerGroupIds]){
                allPolicyIds.add(cebg.PolicyId);
            }
        } else {
            for(CommerceEntitlementPolicy policy : [SELECT Id FROM CommerceEntitlementPolicy WHERE Account__c = : accountId]){
                allPolicyIds.add(policy.Id);
            }
        }
        if(productCodes != null && !productCodes.isEmpty()){
            if(excludeId != null){
                for(CommerceEntitlementProduct entitlement : [SELECT Id, ProductId FROM CommerceEntitlementProduct  WHERE ProductId != : excludeId AND Product.ProductCode IN : productCodes AND (Product.ProductClass = 'Variation' OR Product.ProductClass = 'Simple') AND PolicyId IN : allPolicyIds]){
                    allowedProductIds.add(entitlement.ProductId);
                }
            } else {
                for(CommerceEntitlementProduct entitlement : [SELECT Id, ProductId FROM CommerceEntitlementProduct  WHERE Product.ProductCode IN : productCodes AND (Product.ProductClass = 'Variation' OR Product.ProductClass = 'Simple') AND PolicyId IN : allPolicyIds]){
                    allowedProductIds.add(entitlement.ProductId);
                }
            }
        } else {
            if(excludeId != null){
                for(CommerceEntitlementProduct entitlement : [SELECT Id, ProductId FROM CommerceEntitlementProduct  WHERE ProductId != : excludeId AND (Product.ProductClass = 'Variation' OR Product.ProductClass = 'Simple') AND PolicyId IN : allPolicyIds]){
                    allowedProductIds.add(entitlement.ProductId);
                }
            } else {
                for(CommerceEntitlementProduct entitlement : [SELECT Id, ProductId FROM CommerceEntitlementProduct  WHERE (Product.ProductClass = 'Variation' OR Product.ProductClass = 'Simple') AND PolicyId IN : allPolicyIds]){
                    allowedProductIds.add(entitlement.ProductId);
                }
            }
        }
        return allowedProductIds;
    }

     @AuraEnabled(cacheable=true)
     public static WebshopProductSuperiorWrapper getSliderDataById(String sliderId, String accountId, Integer offset, String filter, List<String> categoryFilter, String sorting, Boolean multiRows){
        try{
            Set<String> allowedProductIds = retrieveAllowedProductIds(accountId);
            Id userId = UserInfo.getUserId();
            Set<String> productIds = new Set<String>();
            for(WebshopProductSlider__c slider : [SELECT Id, Query__c, Category__c, Type__c FROM WebshopProductSlider__c WHERE Id = : sliderId]){
                if(slider.Type__c == 'List'){
                    for(WebshopProductSliderItem__c sliderItem : [SELECT Id, Product__c FROM WebshopProductSliderItem__c WHERE WebshopProductSlider__c  = : slider.Id AND Product__c IN : allowedProductIds ORDER BY Order__c]){
                        productIds.add(sliderItem.Product__c);
                    }
                } else if(slider.Type__c == 'Query' && String.isNotBlank(slider.Query__c)){
                    for(sObject sobj : Database.query(slider.Query__c)){
                        String objId = String.valueOf(sobj.get('Id'));
                        if(objId.startsWith(ORDER_ITEM_PREFIX) || objId.startsWith(WISHLIST_ITEM_PREFIX)){
                            if(allowedProductIds.contains(String.valueOf(sobj.get('Product2Id')))){
                                productIds.add(String.valueOf(sobj.get('Product2Id')));
                            }
                        } else if(objId.startsWith(PRODUCT_PREFIX)){
                            if(allowedProductIds.contains(objId)){
                                productIds.add(objId);
                            }
                        } 
                    }
                }
            }
            return getSliderDetails(accountId, offset, filter, categoryFilter, productIds, sorting, multiRows, null);
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }
    @AuraEnabled(cacheable=true)
    public static WebshopProductSuperiorWrapper getSliderDataByName(String sliderName, String accountId, Integer offset, String filter, List<String> categoryFilter, String sorting, Boolean multiRows){
        try{
            Set<String> allowedProductIds = retrieveAllowedProductIds(accountId);
            Id userId = UserInfo.getUserId();
            Set<String> productIds = new Set<String>();
            for(WebshopProductSlider__c slider : [SELECT Id, Query__c, Category__c, Type__c FROM WebshopProductSlider__c WHERE Name = : sliderName]){
                if(slider.Type__c == 'List'){
                    for(WebshopProductSliderItem__c sliderItem : [SELECT Id, Product__c FROM WebshopProductSliderItem__c WHERE WebshopProductSlider__c  = : slider.Id AND Product__c IN : allowedProductIds ORDER BY Order__c]){
                        productIds.add(sliderItem.Product__c);
                    }
                } else if(slider.Type__c == 'Query' && String.isNotBlank(slider.Query__c)){
                    for(sObject sobj : Database.query(slider.Query__c)){
                        String objId = String.valueOf(sobj.get('Id'));
                        if(objId.startsWith(ORDER_ITEM_PREFIX) || objId.startsWith(WISHLIST_ITEM_PREFIX)){
                            if(allowedProductIds.contains(String.valueOf(sobj.get('Product2Id')))){
                                productIds.add(String.valueOf(sobj.get('Product2Id')));
                            }
                        } else if(objId.startsWith(PRODUCT_PREFIX)){
                            if(allowedProductIds.contains(objId)){
                                productIds.add(objId);
                            }
                        } 
                    }
                }
            }
            return getSliderDetails(accountId, offset, filter, categoryFilter, productIds, sorting, multiRows, null);
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }

    @AuraEnabled(cacheable=true)    
    public static WebshopProductSuperiorWrapper getSliderDataByBrand(String brandId, String accountId, Integer offset, String filter, List<String> categoryFilter, String sorting, Boolean multiRows, String currentProductId, Boolean brandAccessories){
        try{
            Set<String> productIdsAllowed = retrieveAllowedProductIds(accountId);
            Set<String> productIds = new Set<String>();
            String filteredQuery = String.isNotBlank(filter) ? 
                ('SELECT Id FROM Product2 WHERE (ProductClass = \'Variation\' OR ProductClass = \'Simple\') AND Id IN : productIdsAllowed AND BrandWebshop__c = : brandId ' + filter) : 
                 'SELECT Id FROM Product2 WHERE (ProductClass = \'Variation\' OR ProductClass = \'Simple\') AND Id IN : productIdsAllowed AND BrandWebshop__c = : brandId';
            for(Product2 prod : Database.query(filteredQuery)){
                productIds.add(prod.Id);
            }
            if(brandAccessories) {
                Set<String> productIdsAlt = new Set<String>();                
                for(WebshopProductLink__c wpl : [SELECT Id, Product1__c, Product2__c FROM WebshopProductLink__c WHERE (Product1__c IN : productIds AND Product2__c IN  : productIdsAllowed) OR (Product2__c IN : productIds AND Product1__c IN : productIdsAllowed)]){
                    if(!productIds.contains(wpl.Product1__c)){
                        productIdsAlt.add(wpl.Product1__c);
                    }
                    if(!productIds.contains(wpl.Product2__c)){
                        productIdsAlt.add(wpl.Product2__c);
                    }
                }
                //Adds all accessories that are linked with the brand from WebshopBrandLink on the brand page
                for (WebshopBrandLink__c wbl : [SELECT Product__c FROM WebshopBrandLink__c WHERE Brand__c = :brandId]) {
                    if (productIdsAllowed.contains(wbl.Product__c)) {
                        productIdsAlt.add(wbl.Product__c); 
                    }
                }
                return getSliderDetails(accountId, offset, filter, categoryFilter, productIdsAlt, sorting, multiRows, null);
            } else {
                return getSliderDetails(accountId, offset, filter, categoryFilter, productIds, sorting, multiRows, null);
            }
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }

    @AuraEnabled(cacheable=false)    
    public static WebshopProductSuperiorWrapper getSliderDataByMyProducts(String accountId, Integer offset, String filter, List<String> categoryFilter, String sorting, Boolean multiRows, Boolean withPreselection){
        try{
            Set<String> productIds = new Set<String>();
            if(!withPreselection){
                productIds = retrieveAllowedProductIds(accountId);
            } else {
                for(CommerceEntitlementProduct entitlement : [SELECT Id, ProductId FROM CommerceEntitlementProduct  WHERE (Product.ProductClass = 'Simple' OR Product.ProductClass = 'Variation') AND Policy.Account__c = : accountId]){
                    productIds.add(entitlement.ProductId);
                }
            }
            // store the Product2 object fields to be retrieved via ConnectApi
            return getSliderDetails(accountId, offset, filter, categoryFilter, productIds, sorting, multiRows, null);
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }

    @AuraEnabled(cacheable=true)    
    public static WebshopProductSuperiorWrapper getSliderDataByCategory(String categoryId, String accountId, Integer offset, String filter, List<String> categoryFilter, String sorting, Boolean multiRows, String currentProductId, String categoryType, Boolean onlyMyItems){
        try{
            Set<String> productCodes = new Set<String>();
            Set<String> productIds = new Set<String>();
            if(categoryId != null){
                for(ProductCategoryProduct pcp : [SELECT Id, ProductId, Product.ProductCode FROM ProductCategoryProduct WHERE ProductId != : currentProductId AND (ProductCategoryId = : categoryId OR ProductCategory.ParentCategoryId = : categoryId OR ProductCategory.ParentCategory.ParentCategoryId = : categoryId OR ProductCategory.ParentCategory.ParentCategory.ParentCategoryId = : categoryId) ORDER BY CreatedDate DESC]){
                    productCodes.add(pcp.Product.ProductCode);
                }
                Set<String> productIdsPre = new Set<String>();
                if(onlyMyItems == false){
                    productIdsPre = retrieveAllowedProductIds(accountId, productCodes, null);
                } else {
                    for(CommerceEntitlementProduct entitlement : [SELECT Id, ProductId FROM CommerceEntitlementProduct  WHERE (Product.ProductClass = 'Variation' OR Product.ProductClass = 'Simple') AND Policy.Account__c = : accountId]){
                        productIdsPre.add(entitlement.ProductId);
                    }
                }
                if(categoryType == 'new'){ 
                    for(CommerceEntitlementProduct entitlement : [SELECT Id, ProductId FROM CommerceEntitlementProduct  WHERE Product.CreatedDate = LAST_N_MONTHS:3 AND Product.ProductCode IN : productCodes AND (Product.ProductClass = 'Variation' OR Product.ProductClass = 'Simple') AND ProductId IN : productIdsPre ORDER BY Product.CreatedDate]){
                        productIds.add(entitlement.ProductId);
                    }
                } else if(categoryType == 'featured'){
                    for(CommerceEntitlementProduct entitlement : [SELECT Id, ProductId FROM CommerceEntitlementProduct  WHERE Product.Featured__c = TRUE AND Product.ProductCode IN : productCodes AND (Product.ProductClass = 'Variation' OR Product.ProductClass = 'Simple') AND ProductId IN : productIdsPre]){
                        productIds.add(entitlement.ProductId);
                    }
                } else {
                    for(CommerceEntitlementProduct entitlement : [SELECT Id, ProductId FROM CommerceEntitlementProduct  WHERE Product.ProductCode IN : productCodes AND (Product.ProductClass = 'Variation' OR Product.ProductClass = 'Simple') AND ProductId IN : productIdsPre]){
                        productIds.add(entitlement.ProductId);
                    }
                }
                // store the Product2 object fields to be retrieved via ConnectApi
                return getSliderDetails(accountId, offset, filter, categoryFilter, productIds, sorting, multiRows, categoryId);
            }
            return new WebshopProductSuperiorWrapper();
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }

    @AuraEnabled(cacheable=false)
    public static WebshopProductSuperiorWrapper getSliderDataByRecommendation(String accountId){
        String cartId = getCartSummaryOrCreateCart(accountId);
        try{
            Set<String> productCodesPreFinal = new Set<String>();
            Set<String> existingProductIds = new Set<String>();
            for(CartItem ci : [SELECT Id, Product2Id FROM CartItem WHERE CartId = : cartId AND Product2.ProductCode NOT IN : EXCLUDE_PRODUCTS]){
                existingProductIds.add(ci.Product2Id);
            }
            String sorting = ' ORDER BY CountSales__c DESC ';
            for(WebshopProductLink__c wpl : [SELECT Id, Product1__r.ProductCode, Product2__r.ProductCode FROM WebshopProductLink__c WHERE Product1__c IN  : existingProductIds OR Product2__c IN : existingProductIds]){
                if(!existingProductIds.contains(wpl.Product1__c)){
                    productCodesPreFinal.add(wpl.Product1__r.ProductCode);
                }
                if(!existingProductIds.contains(wpl.Product2__c)){
                    productCodesPreFinal.add(wpl.Product2__r.ProductCode);
                }
            }
            
            if(!productCodesPreFinal.isEmpty()){
                Set<String> productIdsPre = retrieveAllowedProductIds(accountId, productCodesPreFinal, null);
                return getSliderDetails(accountId, 0, '', new List<String>(), productIdsPre, sorting, false, null, true);
            }
            return new WebshopProductSuperiorWrapper();
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static WebshopProductSuperiorWrapper getSliderDataByProduct(String productId, String productCode, String productSlider, String brandId, String accountId, Integer offset, String filter, List<String> categoryFilter, String sorting, Boolean multiRows, Boolean getBrandInstead){
        try{
            Set<String> productCodesPreFinal = new Set<String>();
            for(WebshopProductLink__c wpl : [SELECT Id, Product1__r.ProductCode, Product2__r.ProductCode FROM WebshopProductLink__c WHERE Product1__c = : productId OR Product2__c = : productId]){
                if(wpl.Product1__c != productId){
                    productCodesPreFinal.add(wpl.Product1__r.ProductCode);
                }
                if(wpl.Product2__c != productId){
                    productCodesPreFinal.add(wpl.Product2__r.ProductCode);
                }
            }
            
            for (WebshopBrandLink__c wbl : [SELECT Product__r.ProductCode FROM WebshopBrandLink__c WHERE Brand__c = :brandId]) {
                productCodesPreFinal.add(wbl.Product__r.ProductCode);
            }
            
            if(!productCodesPreFinal.isEmpty()){
                Set<String> productIdsPre = retrieveAllowedProductIds(accountId, productCodesPreFinal, productId);
                return getSliderDetails(accountId, offset, filter, categoryFilter, productIdsPre, sorting, multiRows, null);
            } else {
                if(String.isNotBlank(productSlider) && productSlider != 'undefined'){
                    return getSliderDataById(productSlider, accountId, offset, filter, categoryFilter, sorting, multiRows);
                } else if(getBrandInstead && String.isNotBlank(brandId) && brandId != 'undefined') {
                    return getSliderDataByBrand(brandId, accountId, offset, filter, categoryFilter, sorting, multiRows, productId, false);
                }
            }
            return new WebshopProductSuperiorWrapper();
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static WebshopProductSuperiorWrapper getSliderDataBySearchTerm(String searchTerm, String accountId, Integer offset, String filter, List<String> categoryFilter, String sorting, Boolean multiRows){
        try{
            Set<String> productCodes = new Set<String>();
            Set<String> numVals = new Set<String>();
            Set<String> stringVals = new Set<String>();
            
            List<String> searchTermSplit = searchTerm.split(' ', 5);
            for(String s : searchTermSplit){
                String sExact = s.trim();
                String sWildc = '%' + sExact + '%';
                if(sExact.length() >= 4){
                    if(sExact.isNumeric()){
                        numVals.add(sExact);
                    } else {
                        stringVals.add(sWildc);
                    }
                }
            }
            if(!numVals.isEmpty()){
                for(Product2 prod : [SELECT Id, ProductCode FROM Product2 WHERE EAN__c IN : numVals OR ProductCode IN : numVals OR ExternalId IN : numVals]){
                    productCodes.add(prod.ProductCode);
                }
            }
            if(!stringVals.isEmpty()){
                String fuzzyQuery = 'SELECT Id, Product.ProductCode FROM ProductCategoryProduct WHERE '
                    + (' (Product.Name LIKE \'' + String.join(stringVals, '\' OR Product.Name LIKE \'') + '\') OR ')
                    + (' (Product.BrandName__c LIKE \'' + String.join(stringVals, '\' OR Product.BrandName__c LIKE \'') + '\') OR ')
                    + (' (Product.ProductSubtitle__c LIKE \'' + String.join(stringVals, '\' OR Product.ProductSubtitle__c LIKE \'') + '\') OR ')
                    + (' (Product.Description__c LIKE \'' + String.join(stringVals, '\' OR Product.Description__c LIKE \'') + '\') OR ')
                    + (' (Product.Description2__c LIKE \'' + String.join(stringVals, '\' OR Product.Description2__c LIKE \'') + '\') OR ')
                    + (' (ProductCategory.Name LIKE \'' + String.join(stringVals, '\' OR ProductCategory.Name LIKE \'') + '\') ');
                System.debug(fuzzyQuery);
                for(ProductCategoryProduct pcp : Database.Query(fuzzyQuery)){
                    productCodes.add(pcp.Product.ProductCode);
                }
            }

            Set<String> productIds = retrieveAllowedProductIds(accountId, productCodes, null);
            return getSliderDetails(accountId, offset, filter, categoryFilter, productIds, sorting, multiRows, null);
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }
    private static WebshopProductSuperiorWrapper getSliderDetails(String accountId,  Integer offset, String filter, List<String> categoryFilter, Set<String> productIds, String sorting, Boolean multiRows, String categoryId){
        return getSliderDetails(accountId, offset, filter, categoryFilter, productIds, sorting, multiRows, categoryId, false);
    }

    private static WebshopProductSuperiorWrapper getSliderDetails(String accountId,  Integer offset, String filter, List<String> categoryFilter, Set<String> productIds, String sorting, Boolean multiRows, String categoryId, Boolean isRecommendations){
        Integer totalCount = 0;
        List<WebshopProductWrapper> productData = new List<WebshopProductWrapper>();
        String sortingString = '';
        Boolean hasPriceAscSort = false;
        Boolean hasPriceDescSort = false;
        Set<String> allRecordIds = new Set<String>();
        Set<String> allowedProductCodesByCategory = new Set<String>();
        Set<String> productIdsPreWithPricesKeys = new Set<String>();
        Map<String, WebshopSliderFilterWrapper> filters = new Map<String, WebshopSliderFilterWrapper>();
        if(categoryFilter != null && !categoryFilter.isEmpty()){
            for(ProductCategoryProduct pcp : [SELECT Id, Product.ProductCode FROM ProductCategoryProduct WHERE ProductCategory.Name IN : categoryFilter]){
                allowedProductCodesByCategory.add(pcp.Product.ProductCode);
            }
        }

        List<String> wishlistItems = new List<String>();
        for(WishlistItem wi : [SELECT Id, Product2Id FROM WishlistItem WHERE Wishlist.WebstoreId = : CURRENT_STORE_ID AND Wishlist.AccountId = : accountId AND Wishlist.OwnerId = : UserInfo.getUserId() ]){
            wishlistItems.add(wi.Product2Id);
        }

        // Handle Sorting
        if(String.isNotBlank(sorting)){
            if(sorting == 'nameAsc'){
                sortingString = ' ORDER BY Name';
            } else if(sorting == 'nameDesc'){
                sortingString = ' ORDER BY Name DESC';
            } else if(sorting == 'priceAsc'){
                hasPriceAscSort = true;
            } else if(sorting == 'priceDesc'){
                hasPriceDescSort = true;
            }
        }
        sortingString += (isRecommendations ? ' LIMIT 4 ' : (multiRows ? ' LIMIT 500' : ' LIMIT 20')); // PricingInput max limit
        List<WebshopProductWrapper> productDataPre = new List<WebshopProductWrapper>();
        Set<String> productIdsForCount = new Set<String>();
        Map<String, String> productIdsPreWithPrices = new Map<String, String>();
        Map<String, String> productIdsFinalWithPrices = new Map<String, String>();
        String filteredQuery = 'SELECT ' + String.join(PRODUCT_FIELDS, ', ') + ' FROM Product2 WHERE Id IN : productIds ' + filter + sortingString;
        Map<Id, Product2> allProducts = new Map<Id, Product2>((List<Product2>)Database.query(filteredQuery));
        if(!allProducts.isEmpty()){
            ConnectApi.PricingInput input = new ConnectApi.PricingInput();
            input.pricingLineItems = new List<ConnectApi.PricingLineItemInput>();
            for(Id prodId : allProducts.keySet()){
                ConnectApi.PricingLineItemInput newItem = new ConnectApi.PricingLineItemInput();
                newItem.productId = prodId;
                input.pricingLineItems.add(newItem);
            }
            if(!Test.isRunningTest()){
                ConnectApi.PricingResult pricingResult = ConnectApi.CommerceStorePricing.getProductPrices(CURRENT_STORE_ID, accountId, input);
                System.debug(pricingResult);
                for(ConnectApi.PricingResultLineItem result : pricingResult.pricingLineItemResults){
                    if(String.isNotBlank(result.unitPrice) && result.unitPrice != 'null'){
                        productIdsPreWithPrices.put(result.productId, result.unitPrice);
                    }
                }
            }
            productIdsPreWithPricesKeys = productIdsPreWithPrices.keySet();
            
            for(Id prodId : allProducts.keySet()){
                if(productIdsPreWithPrices.containsKey(prodId)){
                    if(categoryFilter.isEmpty() || allowedProductCodesByCategory.contains(allProducts.get(prodId).ProductCode)){
                        if(productIdsPreWithPrices.get(prodId) != null){
                            Decimal price = Decimal.valueOf(productIdsPreWithPrices.get(prodId));
                            totalCount++;
                            productDataPre.add(new WebshopProductWrapper(prodId, price));
                        }
                    }
                }
            }
            if(hasPriceAscSort || hasPriceDescSort){
                productDataPre.sort();
            }            

            if(hasPriceDescSort){
                Integer i = 0;
                for(Integer j = productDataPre.size() - 1; j >= 0; j--){
                    allRecordIds.add(productDataPre[j].productId);
                    if(i >= offset){
                        if(i < (offset + RECORDS_PER_PAGE)){
                            productData.add(new WebshopProductWrapper(allProducts.get(productDataPre[j].productId), productDataPre[j].price, wishlistItems.contains(productDataPre[j].productId)));
                        } else {
                            break;
                        }
                    }
                    i++;
                }
            } else {
                Integer i = 0;
                for(WebshopProductWrapper wrapper : productDataPre){
                    allRecordIds.add(wrapper.productId);
                    if(i >= offset){
                        if(i < (offset + RECORDS_PER_PAGE)){
                            productData.add(new WebshopProductWrapper(allProducts.get(wrapper.productId), wrapper.price, wishlistItems.contains(wrapper.productId)));
                        } else {
                            break;
                        }
                    }
                    i++;
                }
            }
        }

        WebshopProductSuperiorWrapper wrapper = new WebshopProductSuperiorWrapper(productData, totalCount, offset, allRecordIds, productIdsPreWithPricesKeys);
        return wrapper;
    }

    @AuraEnabled(cacheable=true)
    public static List<WebshopSliderFilterWrapper> getSliderFilters(List<String> productIdsPreWithPrices, String categoryId){
        Map<String, WebshopSliderFilterWrapper> filters = new Map<String, WebshopSliderFilterWrapper>();
        // Prepare Filters
        if(!productIdsPreWithPrices.isEmpty()){
            List<String> fieldList = new List<String>();
            Set<String> productCodesForCategory = new Set<String>();
            for(WebshopFilter__mdt availableFilter : Test.isRunningTest() ? new List<WebshopFilter__mdt>{new WebshopFilter__mdt(Type__c = 'Values', Order__c = 1, FilteredObject__c = 'Product2', FilteredField__c = 'BrandName__c')} : [SELECT Id, Type__c, Order__c, FilteredField__r.MasterLabel, FilteredField__r.QualifiedApiName FROM WebshopFilter__mdt WHERE Active__c = TRUE ORDER BY Order__c]){
                String filterName = /*availableFilter.Type__c == 'Price' ? System.Label.GeneralPrice : */ (availableFilter.Type__c == 'Category' ? System.Label.WebshopCategory : availableFilter.FilteredField__r.QualifiedApiName);
                if(/*availableFilter.Type__c != 'Price' && */availableFilter.Type__c != 'Category'){
                    fieldList.add(availableFilter.FilteredField__r.QualifiedApiName);
                }
                filters.put(
                    filterName,
                    new WebshopSliderFilterWrapper(
                        /*availableFilter.Type__c == 'Price' ? System.Label.GeneralPrice :*/ (availableFilter.Type__c == 'Category' ? System.Label.WebshopCategory : availableFilter.FilteredField__r.MasterLabel),
                        filterName, 
                        availableFilter.Type__c == 'Values',
                        availableFilter.Type__c == 'Range',
                        availableFilter.Type__c == 'Boolean',
                        false, //availableFilter.Type__c == 'Price',
                        availableFilter.Type__c == 'Category',
                        Integer.valueOf(availableFilter.Order__c)
                    )
                );
            }
            WebshopSliderFilterWrapper categoryWrapper = filters.get(System.Label.WebshopCategory);
            for(Product2 prod : Database.query('SELECT Id, ProductCode, ' + String.join(fieldList, ',') + ' FROM Product2 WHERE Id IN : productIdsPreWithPrices')){
                productCodesForCategory.add(prod.ProductCode);
                for(String fieldName : filters.keySet()){
                    WebshopSliderFilterWrapper filterWrapper = filters.get(fieldName);
                    if(filterWrapper.isRangeType){
                        Decimal val = (Decimal) prod.get(fieldName);
                        if(val != null){
                            if(filterWrapper.minVal == null || filterWrapper.minVal > val){
                                filterWrapper.minVal = val;
                            }
                            if(filterWrapper.maxVal == null || filterWrapper.maxVal > val){
                                filterWrapper.maxVal = val;
                            }
                        }
                    } else if(filterWrapper.isMultiselectType){
                        String val = String.valueOf(prod.get(fieldName));
                        if(String.isNotBlank(val) && !filterWrapper.availableOptions.contains(val)){
                            filterWrapper.availableOptions.add(val);
                        }
                    } else if(filterWrapper.isBooleanType){
                        Boolean val = Boolean.valueOf(prod.get(fieldName));
                        if(val == true){
                            filterWrapper.hasTrueVal = true;
                        }
                    }
                }
            }
            // Populating categories
            Map<String, CategoryOptionWrapper> optionWrapperMap = new Map<String, CategoryOptionWrapper>();
            if(String.isBlank(categoryId)){
                for(ProductCategoryProduct pcp : [SELECT Id, ProductCategoryId, ProductCategory.Name, ProductCategory.ParentCategoryId, ProductCategory.ParentCategory.ParentCategoryId, ProductCategory.ParentCategory.ParentCategory.ParentCategoryId, ProductCategory.ParentCategory.ParentCategory.ParentCategory.ParentCategoryId FROM ProductCategoryProduct WHERE ProductCategory.ParentCategoryId != NULL AND Product.ProductCode IN : productCodesForCategory AND ProductCategory.Name != : System.Label.WebshopDoNotTranslateMyItems ORDER BY ProductCategory.Name]){
                    if(!optionWrapperMap.containsKey(pcp.ProductCategoryId)){
                        optionWrapperMap.put(pcp.ProductCategoryId, new CategoryOptionWrapper(pcp.ProductCategoryId, pcp.ProductCategory.Name, pcp.ProductCategory.ParentCategoryId, pcp.ProductCategory.ParentCategory.ParentCategoryId, pcp.ProductCategory.ParentCategory.ParentCategory.ParentCategoryId, pcp.ProductCategory.ParentCategory.ParentCategory.ParentCategory.ParentCategoryId, 1));
                    } else {
                        optionWrapperMap.get(pcp.ProductCategoryId).count++;
                    }
                }
            } else {
                for(ProductCategoryProduct pcp : [SELECT Id, ProductCategoryId, ProductCategory.Name, ProductCategory.ParentCategoryId, ProductCategory.ParentCategory.ParentCategoryId, ProductCategory.ParentCategory.ParentCategory.ParentCategoryId, ProductCategory.ParentCategory.ParentCategory.ParentCategory.ParentCategoryId FROM ProductCategoryProduct 
                WHERE ProductCategory.ParentCategoryId != NULL 
                AND (ProductCategoryId = : categoryId OR ProductCategory.ParentCategoryId  = : categoryId OR ProductCategory.ParentCategory.ParentCategoryId  = : categoryId OR ProductCategory.ParentCategory.ParentCategory.ParentCategoryId  = : categoryId)
                AND Product.ProductCode IN : productCodesForCategory AND ProductCategory.Name != : System.Label.WebshopDoNotTranslateMyItems ORDER BY ProductCategory.Name]){
                    if(!optionWrapperMap.containsKey(pcp.ProductCategoryId)){
                        optionWrapperMap.put(pcp.ProductCategoryId, new CategoryOptionWrapper(pcp.ProductCategoryId, pcp.ProductCategory.Name, pcp.ProductCategory.ParentCategoryId, pcp.ProductCategory.ParentCategory.ParentCategoryId, pcp.ProductCategory.ParentCategory.ParentCategory.ParentCategoryId, pcp.ProductCategory.ParentCategory.ParentCategory.ParentCategory.ParentCategoryId, 1));
                    } else {
                        optionWrapperMap.get(pcp.ProductCategoryId).count++;
                    }
                }
            }
            for(String categoryIdWrapper : optionWrapperMap.keySet()){
                CategoryOptionWrapper optionWrapper = optionWrapperMap.get(categoryIdWrapper);
                if(String.isNotBlank(optionWrapper.parentParentParentParentId)){ // 4th level processing
                    if(optionWrapperMap.containsKey(optionWrapper.parentId)){
                        optionWrapperMap.get(optionWrapper.parentId).children.add(optionWrapper);
                        optionWrapperMap.remove(categoryIdWrapper);
                    }
                }
            }
            for(String categoryIdWrapper : optionWrapperMap.keySet()){
                CategoryOptionWrapper optionWrapper = optionWrapperMap.get(categoryIdWrapper);
                if(String.isNotBlank(optionWrapper.parentParentParentId)){ // 3rd level processing
                    if(optionWrapperMap.containsKey(optionWrapper.parentId)){
                        optionWrapperMap.get(optionWrapper.parentId).children.add(optionWrapper);
                        optionWrapperMap.remove(categoryIdWrapper);
                    }
                }
            }
            for(String categoryIdWrapper : optionWrapperMap.keySet()){
                CategoryOptionWrapper optionWrapper = optionWrapperMap.get(categoryIdWrapper);
                if(String.isNotBlank(optionWrapper.parentParentId)){ // 2nd level processing
                    if(optionWrapperMap.containsKey(optionWrapper.parentId)){
                        optionWrapperMap.get(optionWrapper.parentId).children.add(optionWrapper);
                        optionWrapperMap.remove(categoryIdWrapper);
                    }
                }
            }
            categoryWrapper.availableCategoryOptions = optionWrapperMap.values();
            for(WebshopSliderFilterWrapper filterWrapper : filters.values()){
                filterWrapper.availableOptions.sort();
            }
        }
        return filters.values();
    }
     
    /********
     * 
     * PRODUCTS AND PRODUCT TAXONOMY
     * 
     ********/

    @AuraEnabled(cacheable=true)
    public static WebshopProductWrapper getProductDataById(String productId, String accountId){
        try{
            List<String> wishlistItems = new List<String>();
            for(WishlistItem wi : [SELECT Id, Product2Id FROM WishlistItem WHERE Wishlist.WebstoreId = : CURRENT_STORE_ID AND Wishlist.AccountId = : accountId AND Wishlist.OwnerId = : Userinfo.getUserId()]){
                wishlistItems.add(wi.Product2Id);
            }
            String productQuery = 'SELECT ' + String.join(PRODUCT_FIELDS, ', ') + ' FROM Product2 WHERE Id = : productId';
            for(Product2 product: Database.Query(productQuery)) {
                return Test.isRunningTest() ? 
                    new WebshopProductWrapper(product, 0, wishlistItems.contains(product.Id)) :
                    new WebshopProductWrapper(product, Decimal.valueOf(ConnectApi.CommerceStorePricing.getProductPrice(CURRENT_STORE_ID, product.Id, accountId).unitPrice), wishlistItems.contains(product.Id));
            }
            return null;
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static WebshopCategoryWrapper getCategoryById(String categoryId){
        try{
            List<ProductCategory> returnList = [SELECT Id, Name, Subheader__c, ParentCategoryId, ParentCategory.Name, ParentCategory.ParentCategoryId, ParentCategory.ParentCategory.Name, 
                ParentCategory.ParentCategory.ParentCategoryId, ParentCategory.ParentCategory.ParentCategory.Name FROM ProductCategory WHERE Id = : categoryId];
            if(returnList.isEmpty()){
                return new WebshopCategoryWrapper(new ProductCategory(), new List<WebshopBreadcrumbWrapper>());
            } else {
                ProductCategory category = returnList[0];
                List<WebshopBreadcrumbWrapper> wrappers = new List<WebshopBreadcrumbWrapper>();
                if(String.isNotBlank(category.ParentCategory.ParentCategory.ParentCategoryId)){
                    wrappers.add(new WebshopBreadcrumbWrapper(category.ParentCategory.ParentCategory.ParentCategoryId, category.ParentCategory.ParentCategory.ParentCategory.Name, 'Category'));
                }
                if(String.isNotBlank(category.ParentCategory.ParentCategoryId)){
                    wrappers.add(new WebshopBreadcrumbWrapper(category.ParentCategory.ParentCategoryId, category.ParentCategory.ParentCategory.Name, 'Category'));
                }
                if(String.isNotBlank(category.ParentCategoryId)){
                    wrappers.add(new WebshopBreadcrumbWrapper(category.ParentCategoryId, category.ParentCategory.Name, 'Category'));
                }
                return new WebshopCategoryWrapper(category, wrappers);
            }
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }   

    @AuraEnabled(cacheable=true)
    public static WebshopBrand__c getBrandData(String recordId){
        try{
            return [SELECT Id, Name, BrandLogo__c, BrandText__c, WebshopStaticSlider__c, WebshopFeaturedAd__c, WebshopFeaturedAd__r.Name FROM WebshopBrand__c WHERE Id = : recordId LIMIT 1];
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }  

    @AuraEnabled(cacheable=true)
    public static List<WebshopBrand__c> getActiveBrands(String accountId){
        try{
            Set<Id> activeBrandIds = new Set<Id>();
            for(CommerceEntitlementProduct entitlement : [SELECT Id, Product.BrandWebshop__c, Product.BrandWebshop__r.Name FROM CommerceEntitlementProduct  WHERE (Product.ProductClass = 'Variation' OR Product.ProductClass = 'Simple') AND Policy.Account__c = : accountId ORDER BY Product.BrandWebshop__r.Name]){
                if(!activeBrandIds.contains(entitlement.Product.BrandWebshop__c)){
                    activeBrandIds.add(entitlement.Product.BrandWebshop__c);
                }
            }
            return [
            SELECT Id, Name, BrandLogo__c 
            FROM WebshopBrand__c 
            WHERE Id IN :activeBrandIds
            ];
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    } 
     
    /********
     * 
     * ORDERS
     * 
     ********/  

     @AuraEnabled(cacheable=false)
     public static Decimal getCartPromoValue(String cartId){
        return [SELECT TotalPromoAdjustmentAmount FROM WebCart WHERE Id = : cartId].TotalPromoAdjustmentAmount ?? 0;
     }

     @AuraEnabled(cacheable=false)
     public static Map<String, String> createOrder(
        String accountId, 
        String orderNumber, 
        String comment, 
        Boolean setNewsletter, 
        String externalAddressId, 
        String cartId, 
        String erpResponse
    ){
        try {
            Map<String, Object> erpResponseMap = (Map<String, Object>) System.JSON.deserializeUntyped(erpResponse);
            if(String.isBlank(cartId)){
                cartId = getCartSummaryOrCreateCart(accountId);
            }
            WebCart cart = [SELECT AccountId, OwnerId, WebStoreId FROM WebCart WHERE Id = : cartId];
            List<CartItem> cartItems = [SELECT Id,Type,Product2Id,Quantity,ListPrice,CurrencyIsoCode,SalesPrice,TotalPrice,TotalAmount,TotalLineAmount,TotalPromoAdjustmentAmount,FreeItem__c,CartFreeItem__c,LetterCampaignFreeItem__c FROM CartItem WHERE CartId = : cartId];
            if(cartItems.isEmpty()){
                return new Map<String, String>{'error' => System.Label.WebshopOrderNoProductsError};
            }
            Account acc = [SELECT Id, Name, BillingStreet, BillingCity, BillingPostalCode, BillingCOuntry, ShippingStreet, ShippingCity, ShippingPostalCode, ShippingCOuntry FROM Account WHERE Id = : accountId];
            CustomAddress__c add = null;
            if(String.isNotBlank(externalAddressId)){
                add = [SELECT Id, ExternalID__c, Address__CountryCode__s, Address__Street__s, Address__PostalCode__s, Address__City__s FROM CustomAddress__c WHERE Id = : externalAddressId];
            }

            String externalId = add != null ? String.valueOf(Integer.valueOf(add.ExternalID__c)) : null; // currently not used
            String shippingName = acc.Name + ', ' + (String.isNotBlank(UserInfo.getFirstName()) ? UserInfo.getFirstName() : '') + UserInfo.getLastName();
            String shippingStreet = add != null ? add.Address__Street__s : (String.isNotBlank(acc.BillingStreet) ? acc.BillingStreet : acc.ShippingStreet);
            String shippingCity = add != null ? add.Address__City__s : (String.isNotBlank(acc.BillingCity) ? acc.BillingCity : acc.ShippingCity);
            String shippingPostalCode = add != null ? add.Address__PostalCode__s : (String.isNotBlank(acc.BillingPostalCode) ? acc.BillingPostalCode : acc.ShippingPostalCode);
            String shippingCountry = add != null ? add.Address__CountryCode__s : (String.isNotBlank(acc.BillingCountry) ? acc.BillingCountry : acc.ShippingCountry);
            Decimal shippingCosts = 0;
            if(String.isNotBlank(erpResponse) && erpResponseMap.containsKey('order')){
                Map<String, Object> orderMap = (Map<String, Object>) erpResponseMap.get('order');
                if(orderMap.containsKey('ShippingCosts__c')){
                    shippingCosts = (Decimal) orderMap.get('ListPrice');
                }
            }
            Order order = new Order(
                AccountId = cart.AccountId,
                OwnerId = cart.OwnerId,
                SalesStoreId = cart.WebStoreId,
                //PoNumber = orderNumber,
                Comment__c = comment,
                ShippingName__c = shippingName, 
                BillingStreet = shippingStreet,
                ShippingCosts__c = shippingCosts,
                BillingCity = shippingCity,
                BillingPostalCode = shippingPostalCode,
                BillingCountry = shippingCountry,
                EffectiveDate = Date.today(),
                OrderedDate = Date.today(),
                //CustomAddress__c = externalAddressId,
                //CustomAddressExtId__c = externalId,
                Status = 'Draft',
                WebshopOrder__c = TRUE,
                CustomerReference__c = orderNumber
            );
            insert order;
    
            OrderDeliveryGroup orderDeliveryGroup = new OrderDeliveryGroup(
                DeliverToName = shippingName,
                DeliverToStreet = shippingStreet,
                DeliverToCity = shippingCity,
                DeliverToPostalCode = shippingPostalCode,
                DeliverToCountry = shippingCountry,
                OrderDeliveryMethodId = [SELECT Id FROM OrderDeliveryMethod ORDER BY CreatedDate LIMIT 1].Id,
                OrderId = order.Id
            );
            insert orderDeliveryGroup;    
            List<OrderItem> oil = new List<OrderItem>();
            if(String.isBlank(erpResponse) || !erpResponseMap.containsKey('successfulItems')){
                for(CartItem cartItem : cartItems){
                    OrderItem orderItem = new OrderItem(
                        Product2Id = cartItem.Product2Id,
                        //Type = cartItem.Type,
                        Quantity = cartItem.Quantity,
                        ListPrice = cartItem.ListPrice,
                        UnitPrice = cartItem.SalesPrice,
                        OrderId = order.Id,
                        OrderDeliveryGroupId = orderDeliveryGroup.Id,
                        TotalLineAmount = (cartItem.Quantity ?? 0) * (cartItem.SalesPrice ?? 0)
                    );
                    if(orderItem.ListPrice == null){
                        orderItem.ListPrice = 0;
                    }
                    oil.add(orderItem);
                }
            } else {
                List<Object> objectList = (List<Object>) erpResponseMap.get('successfulItems');
                for (Object innerObj : objectList) {
                    Map<String, Object> innerMap = (Map<String, Object>) innerObj;
                    if (innerMap.containsKey('orderItem') && innerMap.containsKey('cartItem')) {
                        Map<String, Object> cartItem = (Map<String, Object>) innerMap.get('cartItem');
                        Map<String, Object> orderItem = (Map<String, Object>) innerMap.get('orderItem');
                        Decimal unitPrice = Decimal.valueOf(String.valueOf(orderItem.get('UnitPrice'))).setScale(2);
                        Decimal quantity = (Decimal) orderItem.get('Quantity');
                        OrderItem oi = new OrderItem(
                            Product2Id = (String) cartItem.get('Product2Id'),
                            Quantity = quantity,
                            ListPrice = (Decimal) cartItem.get('ListPrice'),
                            UnitPrice = unitPrice,
                            OrderId = order.Id,
                            OrderDeliveryGroupId = orderDeliveryGroup.Id,
                            TotalLineAmount = quantity * unitPrice,
                            LineNumber = (Integer) orderItem.get('LineNumber')
                        );
                        oil.add(oi);
                    }
                }
            }
            insert oil;    
            order.Status = 'Ready for Transmission to ERP';
            update order;
            ConnectApi.OrderSummaryInputRepresentation osir = new ConnectApi.OrderSummaryInputRepresentation();
            osir.orderId = order.Id;
            osir.orderLifeCycleType = 'MANAGED';
            if(!Test.isRunningTest()){    
                ConnectApi.OrderSummaryOutputRepresentation osor = ConnectApi.OrderSummaryCreation.createOrderSummary(osir);
            }
            // delete old cart
            delete cart;
            if(setNewsletter){
                setNewsletterOptin();
            }
            final ConnectApi.CartInput cartInput = new ConnectApi.CartInput();
            cartInput.effectiveAccountId = accountId;
            cartInput.name = 'Shopping Cart';
            // create a cart
            ConnectApi.CartSummary cartSummary = ConnectApi.CommerceCart.createCart(CURRENT_STORE_ID, cartInput);
            return new Map<String, String>{
                'cartId' => cartSummary.cartId,
                'orderId' => order.Id
            };
        } catch(Exception e){
            System.debug(e);
            return null;
        }
     }
     
    /********
     * 
     * UI/UX ELEMENTS
     * 
     ********/

    @AuraEnabled(cacheable=true)
    public static WebshopMegaMenuSuperiorWrapper getInterimMegaMenu(String megaMenuName, String accountId){
        try{
            Account acc = [SELECT Id, AssortmentExtended__c, NumberBrandAssignments__c   FROM Account WHERE Id = : accountId];
            Boolean assortmentExtended = acc.AssortmentExtended__c || acc.NumberBrandAssignments__c  > 0;
            List<WebshopMegaMenuWrapper> returnWrappers = new List<WebshopMegaMenuWrapper>();
            List<WebshopMegaMenuWrapper> returnWrappersFinal = new List<WebshopMegaMenuWrapper>();
            for(WebshopMegaMenuItem__c megaMenu : [SELECT Id, ParentMegaMenuItem__r.CategoryName__c, FeaturedAd__c, Name, Target__c, Hierarchy__c, Order__c, ThirdLevelFeatured__c, Subheader__c, SubheaderGerman__c, FeaturedSubheader__c, FeaturedSubheaderGerman__c, ParentMegaMenuItem__c, CategoryName__c, BrandItem__c, NewItem__c, FeaturedItem__c, GermanLabel__c, EnglishLabel__c FROM WebshopMegaMenuItem__c WHERE ParentMegaMenu__r.Name = : megaMenuName AND Hierarchy__c = 1 ORDER BY Order__c]){
                if(megaMenu.Hierarchy__c == 1){
                    returnWrappers.add(new WebshopMegaMenuWrapper(megaMenu, false, megaMenu.Target__c));
                }
            }
            for(WebshopMegaMenuWrapper wrapper : returnWrappers){
                if(wrapper.megaMenuItem.Target__c != '/my-products'){
                    if(assortmentExtended){
                        returnWrappersFinal.add(wrapper);
                    }
                } else {
                    if(wrapper.megaMenuItem.Target__c == '/all-products' && !assortmentExtended){
                        wrapper.label = System.Label.WebshopMyProducts;
                    }
                    returnWrappersFinal.add(wrapper);
                }
            }
            return new WebshopMegaMenuSuperiorWrapper(returnWrappersFinal, new List<Map<String, String>>());
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static WebshopMegaMenuSuperiorWrapper getMegaMenu(String megaMenuName, String accountId, String prefix, String prefixNew, String prefixFeatured, String prefixBrand){
        try{
            Map<String, String> activeCategories = new Map<String, String>();
            Map<String, String> activeCategoriesAlt = new Map<String, String>();
            List<Map<String, String>> activeBrands = new List<Map<String, String>>();
            Set<Id> activeBrandIds = new Set<Id>();
            Set<String> productCodes = new Set<String>();
            Set<Id> allBuyerGroupIds = new Set<Id>();
            Set<Id> allPolicyIds = new Set<Id>();
            Set<String> ownProductCodes = new Set<String>();
            Account acc = [SELECT Id, AssortmentExtended__c, NumberBrandAssignments__c  FROM Account WHERE Id = : accountId];
            Boolean assortmentExtended = acc.AssortmentExtended__c || acc.NumberBrandAssignments__c  > 0;
            if(assortmentExtended){           
                List<User> ul = [SELECT Id, Contact.AssortmentExtensionExclusion__c FROM User WHERE Id = : UserInfo.getUserId() AND Contact.AccountId = : accountId];
                if(!ul.isEmpty()){
                    assortmentExtended = !ul[0].Contact.AssortmentExtensionExclusion__c;
                } else {
                    List<DelegatedAccount> dl = [SELECT Id, AssortmentExtensionExclusion__c FROM DelegatedAccount WHERE ManagedById = :UserInfo.getUserId() AND TargetId = : accountId];
                    if(!dl.isEmpty()){
                        assortmentExtended = !dl[0].AssortmentExtensionExclusion__c;
                    }
                }
            }
            if(assortmentExtended){
                for(BuyerGroupMember bgm : [SELECT Id, BuyerGroupId FROM BuyerGroupMember WHERE BuyerId = : accountId]){
                    allBuyerGroupIds.add(bgm.BuyerGroupId);
                }
                for(WebStoreBuyerGroup wsb : [SELECT Id, BuyerGroupId FROM WebStoreBuyerGroup WHERE BuyerGroupId IN : allBuyerGroupIds AND WebStoreId = : CURRENT_STORE_ID]){
                    allBuyerGroupIds.add(wsb.BuyerGroupId);
                }
                for(CommerceEntitlementBuyerGroup cebg : [SELECT Id, PolicyId FROM CommerceEntitlementBuyerGroup WHERE BuyerGroupId IN : allBuyerGroupIds ]){
                    allPolicyIds.add(cebg.PolicyId);
                }
            } else {
                for(CommerceEntitlementPolicy policy : [SELECT Id FROM CommerceEntitlementPolicy WHERE Account__c = : accountId]){
                    allPolicyIds.add(policy.Id);
                }
            }
            for(CommerceEntitlementProduct entitlement : [SELECT Id, Policy.Account__c, Product.ProductCode, Product.BrandWebshop__c, Product.BrandWebshop__r.Name FROM CommerceEntitlementProduct  WHERE (Product.ProductClass = 'Variation' OR Product.ProductClass = 'Simple') AND PolicyId IN : allPolicyIds ORDER BY Product.BrandWebshop__r.Name]){
                productCodes.add(entitlement.Product.ProductCode);
                if(!activeBrandIds.contains(entitlement.Product.BrandWebshop__c)){
                    activeBrandIds.add(entitlement.Product.BrandWebshop__c);
                    if(String.isNotBlank(entitlement.Product.BrandWebshop__c)){
                        activeBrands.add(new Map<String, String>{'label' => entitlement.Product.BrandWebshop__r.Name, 'value' => prefixBrand + entitlement.Product.BrandWebshop__c + '/detail'});
                    }
                }
                if(entitlement.Policy.Account__c == accountId){
                    ownProductCodes.add(entitlement.Product.ProductCode);
                }
            }
            for(ProductCategoryProduct pcp : [SELECT Id, ProductCategoryId, ProductCategory.Name FROM ProductCategoryProduct WHERE Product.ProductCode IN : productCodes]){
                activeCategories.put(pcp.ProductCategory.Name, pcp.ProductCategoryId);
            }
            for(ProductCategoryProduct pcp : [SELECT Id, ProductCategoryId, ProductCategory.Name FROM ProductCategoryProduct WHERE Product.ProductCode IN : ownProductCodes]){
                activeCategoriesAlt.put(pcp.ProductCategory.Name, pcp.ProductCategoryId);
            }
            List<WebshopMegaMenuWrapper> returnWrappers = new List<WebshopMegaMenuWrapper>();
            Map<Id, List<WebshopMegaMenuWrapper>> wrapperMapFirstToSecond = new Map<Id, List<WebshopMegaMenuWrapper>>();
            Map<Id, List<WebshopMegaMenuWrapper>> wrapperMapSecondToThird = new Map<Id, List<WebshopMegaMenuWrapper>>();
            Map<Id, List<WebshopMegaMenuWrapper>> wrapperMapSecondToThirdFeat = new Map<Id, List<WebshopMegaMenuWrapper>>();
            List<WebshopMegaMenuWrapper> wrapperListSecondAlt = new List<WebshopMegaMenuWrapper>();
            Map<Id, List<WebshopMegaMenuWrapper>> wrapperMapSecondToThirdAlt = new Map<Id, List<WebshopMegaMenuWrapper>>();
            for(WebshopMegaMenuItem__c megaMenu : [SELECT Id, ParentMegaMenuItem__r.CategoryName__c, FeaturedAd__c, Name, Target__c, Hierarchy__c, Order__c, ThirdLevelFeatured__c, Subheader__c, SubheaderGerman__c, FeaturedSubheader__c, FeaturedSubheaderGerman__c, ParentMegaMenuItem__c, CategoryName__c, BrandItem__c, NewItem__c, FeaturedItem__c, GermanLabel__c, EnglishLabel__c FROM WebshopMegaMenuItem__c WHERE ParentMegaMenu__r.Name = : megaMenuName ORDER BY Hierarchy__c, Order__c]){
                if(megaMenu.Hierarchy__c == 1){
                    returnWrappers.add(new WebshopMegaMenuWrapper(megaMenu, false, megaMenu.Target__c));
                } else if(megaMenu.Hierarchy__c == 2){
                    List<WebshopMegaMenuWrapper> innerList = wrapperMapFirstToSecond.containsKey(megaMenu.ParentMegaMenuItem__c) ? wrapperMapFirstToSecond.get(megaMenu.ParentMegaMenuItem__c) : new List<WebshopMegaMenuWrapper>();
                    if(String.isNotBlank(megaMenu.CategoryName__c)){
                        if(activeCategories.containsKey(megaMenu.CategoryName__c)){
                            innerList.add(new WebshopMegaMenuWrapper(megaMenu, false, prefix + activeCategories.get(megaMenu.CategoryName__c)));
                        } else {
                            innerList.add(new WebshopMegaMenuWrapper(megaMenu, true, megaMenu.Target__c));
                        }
                        if(activeCategoriesAlt.containsKey(megaMenu.CategoryName__c)){
                            wrapperListSecondAlt.add(new WebshopMegaMenuWrapper(megaMenu, false, prefix + activeCategoriesAlt.get(megaMenu.CategoryName__c)));
                        } else {
                            wrapperListSecondAlt.add(new WebshopMegaMenuWrapper(megaMenu, true, megaMenu.Target__c));
                        }
                    } else {
                        innerList.add(new WebshopMegaMenuWrapper(megaMenu, false, megaMenu.Target__c));
                    }
                    wrapperMapFirstToSecond.put(megaMenu.ParentMegaMenuItem__c, innerList);
                }  else if(megaMenu.Hierarchy__c == 3){
                    if(!megaMenu.ThirdLevelFeatured__c){
                        List<WebshopMegaMenuWrapper> innerList = wrapperMapSecondToThird.containsKey(megaMenu.ParentMegaMenuItem__c) ? wrapperMapSecondToThird.get(megaMenu.ParentMegaMenuItem__c) : new List<WebshopMegaMenuWrapper>();
                        List<WebshopMegaMenuWrapper> innerListAlt = wrapperMapSecondToThirdAlt.containsKey(megaMenu.ParentMegaMenuItem__c) ? wrapperMapSecondToThirdAlt.get(megaMenu.ParentMegaMenuItem__c) : new List<WebshopMegaMenuWrapper>();

                        if(String.isNotBlank(megaMenu.CategoryName__c)){
                            if(activeCategories.containsKey(megaMenu.CategoryName__c)){
                                innerList.add(new WebshopMegaMenuWrapper(megaMenu, false, prefix + activeCategories.get(megaMenu.CategoryName__c)));
                            } else {
                                innerList.add(new WebshopMegaMenuWrapper(megaMenu, true, megaMenu.Target__c));
                            }
                            if(activeCategoriesAlt.containsKey(megaMenu.CategoryName__c)){
                                innerListAlt.add(new WebshopMegaMenuWrapper(megaMenu, false, prefix + activeCategoriesAlt.get(megaMenu.CategoryName__c)));
                            } else {
                                innerListAlt.add(new WebshopMegaMenuWrapper(megaMenu, true, megaMenu.Target__c));
                            }
                        } else {
                            innerList.add(new WebshopMegaMenuWrapper(megaMenu, false, megaMenu.Target__c));
                        }
                        wrapperMapSecondToThird.put(megaMenu.ParentMegaMenuItem__c, innerList);
                        wrapperMapSecondToThirdAlt.put(megaMenu.ParentMegaMenuItem__c, innerListAlt);
                    } else {
                        List<WebshopMegaMenuWrapper> innerList = wrapperMapSecondToThirdFeat.containsKey(megaMenu.ParentMegaMenuItem__c) ? wrapperMapSecondToThirdFeat.get(megaMenu.ParentMegaMenuItem__c) : new List<WebshopMegaMenuWrapper>();
                        if(megaMenu.NewItem__c){
                            if(String.isNotBlank(megaMenu.ParentMegaMenuItem__r.CategoryName__c) && activeCategories.containsKey(megaMenu.ParentMegaMenuItem__r.CategoryName__c)){
                                innerList.add(new WebshopMegaMenuWrapper(megaMenu, false, prefixNew + activeCategories.get(megaMenu.ParentMegaMenuItem__r.CategoryName__c)));
                            }
                        } else if(megaMenu.FeaturedItem__c){
                            if(String.isNotBlank(megaMenu.ParentMegaMenuItem__r.CategoryName__c) && activeCategories.containsKey(megaMenu.ParentMegaMenuItem__r.CategoryName__c)){
                                innerList.add(new WebshopMegaMenuWrapper(megaMenu, false, prefixFeatured + activeCategories.get(megaMenu.ParentMegaMenuItem__r.CategoryName__c)));
                            }
                        } else {
                            innerList.add(new WebshopMegaMenuWrapper(megaMenu, false, megaMenu.Target__c));
                        }
                        wrapperMapSecondToThirdFeat.put(megaMenu.ParentMegaMenuItem__c, innerList);
                    }
                } 
            }
            for(List<WebshopMegaMenuWrapper> wrapperList : wrapperMapFirstToSecond.values()){
                for(WebshopMegaMenuWrapper wrapper : wrapperList){
                    if(wrapperMapSecondToThird.containsKey(wrapper.megaMenuItem.Id)){
                        wrapper.children = wrapperMapSecondToThird.get(wrapper.megaMenuItem.Id);
                    }
                    if(wrapperMapSecondToThirdFeat.containsKey(wrapper.megaMenuItem.Id)){
                        wrapper.featuredChildren = wrapperMapSecondToThirdFeat.get(wrapper.megaMenuItem.Id);
                    }
                }
            }
            for(WebshopMegaMenuWrapper wrapper : wrapperListSecondAlt){
                if(wrapperMapSecondToThirdAlt.containsKey(wrapper.megaMenuItem.Id)){
                    wrapper.children = wrapperMapSecondToThirdAlt.get(wrapper.megaMenuItem.Id);
                }
            }
            List<WebshopMegaMenuWrapper> returnWrappersFinal = new List<WebshopMegaMenuWrapper>();
            for(WebshopMegaMenuWrapper wrapper : returnWrappers){
                if(wrapper.megaMenuItem.Target__c == '/my-products'){
                    if(assortmentExtended){
                        wrapper.children = wrapperListSecondAlt;
                        returnWrappersFinal.add(wrapper);
                    }
                } else {
                    if(wrapperMapFirstToSecond.containsKey(wrapper.megaMenuItem.Id)){
                        wrapper.children = wrapperMapFirstToSecond.get(wrapper.megaMenuItem.Id);
                        for(WebshopMegaMenuWrapper child : wrapper.children){
                            child.targetUrl += '?all';
                            for(WebshopMegaMenuWrapper grandchild : child.children){
                                grandchild.targetUrl += '?all';
                            }
                        }
                    }
                    if(wrapper.megaMenuItem.Target__c == '/all-products' && !assortmentExtended){
                        wrapper.label = System.Label.WebshopMyProducts;
                    }
                    returnWrappersFinal.add(wrapper);
                }
            }
            return new WebshopMegaMenuSuperiorWrapper(returnWrappersFinal, activeBrands);
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static WebshopFeaturedAd__c getFeaturedAdByName(String featuredAdName){
        try{
            List<WebshopFeaturedAd__c> featuredAds = [SELECT Id, Title__c, TitleGerman__c, Subtitle__c, SubtitleGerman__c, Image__c, Target__c, ButtonLabel__c, ButtonLabelGerman__c FROM WebshopFeaturedAd__c WHERE Name = : featuredAdName AND StartDate__c <= TODAY AND (EndDate__c >= TODAY OR EndDate__c = NULL) ORDER BY LastModifiedDate DESC];
            if(!featuredAds.isEmpty()){
                WebshopFeaturedAd__c featuredAd = featuredAds[0];
                featuredAd.Title__c = UserInfo.getLanguage().startsWith('de') && String.isNotBlank(featuredAd.TitleGerman__c) ? featuredAd.TitleGerman__c : featuredAd.Title__c;
                featuredAd.Subtitle__c = UserInfo.getLanguage().startsWith('de') && String.isNotBlank(featuredAd.SubtitleGerman__c) ? featuredAd.SubtitleGerman__c : featuredAd.Subtitle__c;
                featuredAd.ButtonLabel__c = UserInfo.getLanguage().startsWith('de') && String.isNotBlank(featuredAd.ButtonLabelGerman__c) ? featuredAd.ButtonLabelGerman__c : featuredAd.ButtonLabel__c;
                return featuredAd;
            } 
            return null;
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static WebshopFeaturedAd__c getFeaturedAdById(String featuredAdId){
        try{
            List<WebshopFeaturedAd__c> featuredAds = [SELECT Id, Title__c, TitleGerman__c, Subtitle__c, SubtitleGerman__c, Image__c, Target__c, ButtonLabel__c, ButtonLabelGerman__c FROM WebshopFeaturedAd__c WHERE Id = : featuredAdId AND StartDate__c <= TODAY AND (EndDate__c >= TODAY OR EndDate__c = NULL) ORDER BY LastModifiedDate DESC];
            if(!featuredAds.isEmpty()){
                WebshopFeaturedAd__c featuredAd = featuredAds[0];
                featuredAd.Title__c = UserInfo.getLanguage().startsWith('de') && String.isNotBlank(featuredAd.TitleGerman__c) ? featuredAd.TitleGerman__c : featuredAd.Title__c;
                featuredAd.Subtitle__c = UserInfo.getLanguage().startsWith('de') && String.isNotBlank(featuredAd.SubtitleGerman__c) ? featuredAd.SubtitleGerman__c : featuredAd.Subtitle__c;
                featuredAd.ButtonLabel__c = UserInfo.getLanguage().startsWith('de') && String.isNotBlank(featuredAd.ButtonLabelGerman__c) ? featuredAd.ButtonLabelGerman__c : featuredAd.ButtonLabel__c;
                return featuredAd;
            } 
            return null;
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<WebshopStaticSliderItem__c> getStaticSliderDataByName(String staticSliderName){
        try{
            return [SELECT Id, Text__c, Image__c FROM WebshopStaticSliderItem__c WHERE ParentStaticSlider__r.Name = : staticSliderName ORDER BY Order__c];
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<WebshopStaticSliderItem__c> getStaticSliderDataById(String staticSliderId){
        try{
            return [SELECT Id, Text__c, Image__c FROM WebshopStaticSliderItem__c WHERE ParentStaticSlider__r.Id = : staticSliderId ORDER BY Order__c];
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<WebshopIcon__c> getIcons(String iconCategory){
        try{
            return Database.query('SELECT Id, Image__c, Target__c FROM WebshopIcon__c WHERE Active__c = TRUE AND Category__c INCLUDES (\'' + iconCategory + '\') ORDER BY Order__c');
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }  
    
    /********
     * 
     * ACCOUNT AND USER
     * 
     ********/     

    @AuraEnabled(cacheable=true)
    public static String getWebstoreId() {
        return CURRENT_STORE_ID;
    }


     @AuraEnabled(cacheable=false)
     public static String createActivationRequiredUser(String accountId, String firstName, String lastName, String email, String phone, String roleName){
        try{
            Organization org = [SELECT Id, Name, IsSandbox FROM Organization LIMIT 1];
            String webshopString = org.isSandbox ? (System.Label.LetterCampaignUsernameSuffix + org.Id) : System.Label.LetterCampaignUsernameSuffix;
            String username = email + webshopString;
            List<User> userList = [SELECT Id FROM User WHERE Email = : email OR Email = : username OR Username = : email OR Username = : username];
            List<Contact> contactList = [SELECT Id FROM Contact WHERE AccountId = : accountId AND Email = : email];
            if(!userList.isEmpty() || !contactList.isEmpty()){
                return 'error: ' + System.Label.WebshopUserActivationError;
            } 
            Contact con = new Contact(
                FirstName = firstName, 
                LastName = lastName, 
                AccountId = accountId, 
                Email = email, 
                Phone = phone,
                WebshopCustomer__c = TRUE,
                PriceVisible__c = TRUE
            );
            insert con;
            futureCreateUserAndPermissionSetAssignment(con.Id, username);
            return 'success';
        } catch(Exception e){
            System.debug(e);
            return 'error: ' + e.getMessage();
        }
     }

    @future 
    private static void futureCreateUserAndPermissionSetAssignment(String conId, String username){
        // Create Role under J.J. Darboven (Holding)
        //List<UserRole> darbovenRoles = [SELECT Id FROM UserRole WHERE Name = 'J.J. Darboven GmbH'];
        Contact con = [SELECT Id, FirstName, LastName, Email, Account.ERPCustomerNumber__c FROM Contact WHERE Id = : conId];
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User'];
        List<PermissionSetAssignment> psasToCreate = new List<PermissionSetAssignment>();
        List<String> permissionSetNames = new List<String>{'B2BWebshopAccessWebshopAssets'};
        permissionSetNames.add(System.Label.WebshopDoNotTranslateMainPermissionSetName);
        List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name IN :permissionSetNames];
        if(!profiles.isEmpty()){
            User u = new User(
                FirstName = con.FirstName,
                LastName = con.LastName,
                ProfileId = profiles[0].Id,
                Email = con.Email,
                Username = username,
                IsActive = FALSE,
                ContactId = con.Id,
                LanguageLocaleKey='de', 
                LocaleSidKey='de_DE', 
                TimeZoneSidKey='Europe/Berlin',
                EmailEncodingKey='UTF-8',
                Alias = con.Account.ERPCustomerNumber__c != null ? con.Account.ERPCustomerNumber__c : (con.FirstName != null ? con.FirstName.substring(0, 1) : '') + (con.LastName.length() > 3 ? con.LastName.substring(0,3) : con.LastName),
                CreatedByGL__c = false,
                ActivationRequired__c = true
            );
            insert u;
            for(PermissionSet ps : permissionSets){
                psasToCreate.add(new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = u.Id));
            }
            insert psasToCreate;
        }

    }

    @AuraEnabled(cacheable=false)
    public static Boolean checkIfCustomerAssortmentExtended(String accountId) {
        Account acc = [SELECT Id, AssortmentExtended__c, NumberBrandAssignments__c  FROM Account WHERE Id = : accountId];
        Boolean assortmentExtended = acc.AssortmentExtended__c || acc.NumberBrandAssignments__c > 0;
        if(assortmentExtended){           
            List<User> ul = [SELECT Id, Contact.AssortmentExtensionExclusion__c FROM User WHERE Id = : UserInfo.getUserId() AND Contact.AccountId = : accountId];
            if(!ul.isEmpty()){
                return !ul[0].Contact.AssortmentExtensionExclusion__c;
            } else {
                List<DelegatedAccount> dl = [SELECT Id, AssortmentExtensionExclusion__c FROM DelegatedAccount WHERE ManagedById = :UserInfo.getUserId() AND TargetId = : accountId];
                if(!dl.isEmpty()){
                    return !dl[0].AssortmentExtensionExclusion__c;
                }
            }
        }
        return false;
    }

    @AuraEnabled(cacheable=false)
    public static Boolean uploadCsvFile(String accountId, String csvContent) {
        if (String.isNotBlank(csvContent)) {
            Account account = [SELECT Id, ERPCustomerNumber__c FROM Account WHERE Id = : accountId];
            Map<String, List<FTPOrderLine>> groupedOrders = new Map<String, List<FTPOrderLine>>();
            Map<String, String> allAccountsMap = new Map<String, String>{ account.ERPCustomerNumber__c => accountId };
            Set<Id> currentAccounts = new Set<Id>{ accountId };
            while (!currentAccounts.isEmpty()) {
                List<Account> checkingAccounts = [
                    SELECT Id, ERPCustomerNumber__c
                    FROM Account
                    WHERE ConditionChainParent__c IN :currentAccounts
                ];
                currentAccounts = new Set<Id>();
                for (Account acc : checkingAccounts) {
                    allAccountsMap.put(acc.ERPCustomerNumber__c, acc.Id);
                    currentAccounts.add(acc.Id);
                }
            }

            String accountNumber = account.ERPCustomerNumber__c;
            try {
                // File not found -> ignore
                if (String.isNotBlank(csvContent)) {
                    for (FTPOrderLine line : parseCsv(csvContent)) {
                        if (allAccountsMap.containsKey(line.childAccountNumber)) {
                            String childAccountId = allAccountsMap.get(line.childAccountNumber);
                            List<FTPOrderLine> innerList = groupedOrders.containsKey(childAccountId) ? groupedOrders.get( childAccountId) : new List<FTPOrderLine>();
                            innerList.add(line);
                            groupedOrders.put(childAccountId, innerList);
                        }
                    }
                }
                List<FTPOrderGroup> orderGroups = new List<FTPOrderGroup>();
                for (String accountNo : groupedOrders.keySet()) {
                    FTPOrderGroup groupWrapper = new FTPOrderGroup(accountNo, groupedOrders.get(accountNo));
                    orderGroups.add(groupWrapper);
                }
                if (!orderGroups.isEmpty()) {
                    Database.executeBatch(new FTPOrderProcessingBatch(orderGroups), 1);
                }
                return true;
            } catch (Exception ex) {
                System.debug(
                    LoggingLevel.ERROR,
                    'FTP processing failed for account ' +
                    accountNumber +
                    ': ' +
                    ex.getMessage()
                );
                return false;
            }

        }
        return false;
    }

    /**
     * CSV Parser
     */
    private static List<FTPOrderLine> parseCsv(String csvContent) {
        List<FTPOrderLine> result = new List<FTPOrderLine>();
        csvContent = csvContent.replace('\uFEFF', '');
        List<String> rows = csvContent.split('\n');
        for (String row : rows) {
            if (String.isNotBlank(row)) {
                List<String> columns = row.split(',');
                if (columns.size() >= 3) {
                    String childAccountNumber = columns[0].trim();
                    String sku = columns[1].trim();
                    Decimal quantity = Decimal.valueOf(columns[2].trim());
                    result.add(new FTPOrderLine(childAccountNumber, sku, quantity));
                }
            }
        }
        return result;
    }

    @AuraEnabled(cacheable=false)
    public static Boolean retrieveFTPInfo(String accountId) {
        return [SELECT Id, FTPOrdering__c  FROM Account WHERE Id = : accountId].FTPOrdering__c;
    }

    @AuraEnabled(cacheable=false)
    public static Boolean checkIfAssortmentExtended(String accountId) {
        Account acc = [SELECT Id, AssortmentExtended__c, NumberBrandAssignments__c  FROM Account WHERE Id = : accountId];
        return acc.AssortmentExtended__c || acc.NumberBrandAssignments__c > 0;
    }

    @AuraEnabled(cacheable=false)
    public static OptionSuperiorWrapper getAccountSwitcherOptions(String accountId) {
        try{
            List<OptionWrapper> options = new List<OptionWrapper>();
            String currentAccount = '-';
            if(String.isNotBlank(accountId)){
                for(Account ac : [SELECT Id, ERPCustomerNumber__c , Name, Name2__c, ShippingStreet, ShippingCity, ShippingPostalCode FROM Account WHERE Id = : accountId]){
                    currentAccount = ac.ERPCustomerNumber__c  + ' '  + ac.Name + + (String.isNotBlank(ac.Name2__c) ? ' (' + ac.Name2__c + ')' : '') + ', ' + ac.ShippingStreet + ', ' +  ac.ShippingPostalCode + ' ' + ac.ShippingCity;
                }
                for(User u : [SELECT Id, Contact.Account.ERPCustomerNumber__c , Contact.AccountId, Contact.Account.Name, Contact.Account.Name2__c, Contact.Account.ShippingStreet, Contact.Account.ShippingCity, Contact.Account.ShippingPostalCode FROM User WHERE Id = : UserInfo.getUserId() AND Contact.AccountId != : accountId]){
                    options.add(new OptionWrapper(u.Contact.Account.ERPCustomerNumber__c  + ' '  + u.Contact.Account.Name + (String.isNotBlank(u.Contact.Account.Name2__c) ? ' (' + u.Contact.Account.Name2__c + ')' : '') + ', ' + u.Contact.Account.ShippingStreet + ', ' +  u.Contact.Account.ShippingPostalCode + ' ' + u.Contact.Account.ShippingCity, u.Contact.AccountId, false));
                }
                for(DelegatedAccount delAcc : [SELECT Id, Target.ERPCustomerNumber__c , TargetId, Target.Name, Target.Name2__c, Target.ShippingStreet, Target.ShippingCity, Target.ShippingPostalCode FROM DelegatedAccount WHERE TargetId != : accountId AND ManagedById = : UserInfo.getUserId() ORDER BY Target.Name]){
                    options.add(new OptionWrapper(delAcc.Target.ERPCustomerNumber__c  + ' '  + delAcc.Target.Name + (String.isNotBlank(delAcc.Target.Name2__c) ? ' (' + delAcc.Target.Name2__c + ')' : '') + ', ' + delAcc.Target.ShippingStreet + ', ' +  delAcc.Target.ShippingPostalCode + ' ' + delAcc.Target.ShippingCity, delAcc.TargetId, false));
                }
            } else {
                for(User u : [SELECT Id, Contact.Account.ERPCustomerNumber__c , Contact.AccountId, Contact.Account.Name, Contact.Account.Name2__c, Contact.Account.ShippingStreet, Contact.Account.ShippingCity, Contact.Account.ShippingPostalCode FROM User WHERE Id = : UserInfo.getUserId()]){
                    options.add(new OptionWrapper(u.Contact.Account.ERPCustomerNumber__c  + ' '  + u.Contact.Account.Name + (String.isNotBlank(u.Contact.Account.Name2__c) ? ' (' + u.Contact.Account.Name2__c + ')' : '') + ', ' + u.Contact.Account.ShippingStreet + ', ' +  u.Contact.Account.ShippingPostalCode + ' ' + u.Contact.Account.ShippingCity, u.Contact.AccountId, false));
                }
                for(DelegatedAccount delAcc : [SELECT Id, Target.ERPCustomerNumber__c ,TargetId, Target.Name, Target.Name2__c, Target.ShippingStreet, Target.ShippingCity, Target.ShippingPostalCode FROM DelegatedAccount WHERE ManagedById = : UserInfo.getUserId() ORDER BY Target.Name]){
                    options.add(new OptionWrapper(delAcc.Target.ERPCustomerNumber__c  + ' '  + delAcc.Target.Name + (String.isNotBlank(delAcc.Target.Name2__c) ? ' (' + delAcc.Target.Name2__c + ')' : '') + ', ' + delAcc.Target.ShippingStreet + ', ' +  delAcc.Target.ShippingPostalCode + ' ' + delAcc.Target.ShippingCity, delAcc.TargetId, false));
                }
            }
            return new OptionSuperiorWrapper(options, currentAccount);
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }    
    
    @AuraEnabled(cacheable=false)
    public static Boolean retrieveNewsletterOptIn() {
        try{
            List<User> cl = [SELECT Id, ContactId, Contact.DoubleOptInRequested__c FROM User WHERE Id = : UserInfo.getUserId() AND ContactId != NULL];
            if(!cl.isEmpty()){
                return cl[0].Contact.DoubleOptInRequested__c;
            }
            return true;
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }   
    
    @AuraEnabled(cacheable=false)
    public static Boolean setNewsletterOptIn() {
        try{
            List<User> cl = [SELECT Id, ContactId, Contact.DoubleOptInRequested__c FROM User WHERE Id = : UserInfo.getUserId() AND ContactId != NULL];
            if(!cl.isEmpty()){
                try {
                    update new Contact(
                        Id = cl[0].ContactId,
                        DoubleOptInRequested__c = true
                    );
                    return true;
                } catch(Exception e){
                    System.debug(e);
                }
            }
            return false;
        } catch(Exception e){
            System.debug(e);
            return false;
        }
    }   
    
    @AuraEnabled(cacheable=false)
    public static String getUserImage() {
        try{
            return [SELECT Id, SmallPhotoUrl FROM User WHERE Id = : UserInfo.getUserId()].SmallPhotoUrl;
        } catch(Exception e){
            System.debug(e);
            return 'error';
        }
    }

    @AuraEnabled(cacheable=false)
    public static Boolean getShowPriceInfo(String accountId) {
        try{
            User u = [SELECT Id, Contact.PriceVisible__c, Contact.AccountId, Contact.Account.PriceInvisible__c FROM User WHERE Id = : UserInfo.getUserId() LIMIT 1];
            if(u.Contact.AccountId == accountId){
                return u.Contact.Account.PriceInvisible__c ? false : u.Contact.PriceVisible__c;
            } else {
                DelegatedAccount delAcc = [SELECT Id, Target.PriceInvisible__c, PriceVisible__c FROM DelegatedAccount WHERE ManagedById = : UserInfo.getUserId() AND TargetId = : accountId];
                return delAcc.Target.PriceInvisible__c ? false : delAcc.PriceVisible__c;
            }
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getAccountWarning(String accountId) {
        try{
            List<Account> al = [SELECT Id, WebshopFrontpageWarning__c  FROM Account WHERE Id = : accountId];
            if(!al.isEmpty()){
                return String.isNotBlank(al[0].WebshopFrontpageWarning__c) ? al[0].WebshopFrontpageWarning__c : 'null';
            }
            return 'null';
        } catch(Exception e){
            System.debug(e);
            return 'null';
        }
    }

    @AuraEnabled(cacheable=true)
    public static Account getActiveAccountInfo(String accountId) {
        try{
            List<Account> al = [SELECT Id, Name, BillingStreet, BillingCity, BillingPostalCode, BillingCountry, ShippingCountry, ShippingStreet, ShippingCity, ShippingPostalCode FROM Account WHERE Id = : accountId];
            if(!al.isEmpty()){
                return al[0];
            }
            return null;
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }

    @AuraEnabled(cacheable=false)
    public static Boolean getShowDoubleOptIn() {
        try{
            return [SELECT Id, Contact.DoubleOptInAbandonedCart__c FROM User WHERE Id = : UserInfo.getUserId() AND (Contact.DoubleOptInAbandonedCart__c = TRUE OR Contact.DoubleOptInAbandonedCartModalSeen__c = TRUE)].isEmpty();
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static Boolean getShowDoubleOptInCheckout() {
        try{
            return [SELECT Id, Contact.DoubleOptInAbandonedCart__c FROM User WHERE Id = : UserInfo.getUserId() AND Contact.DoubleOptInAbandonedCart__c = TRUE].isEmpty();
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static Boolean setDoubleOptInModalSeen() {
        try{
            Id CONTACT_ID = [SELECT Id, ContactId FROM User WHERE Id = : UserInfo.getUserId()].contactId;
            if(CONTACT_ID != null){
                Contact c = new Contact(
                    Id = CONTACT_ID,
                    DoubleOptInAbandonedCartModalSeen__c = true
                );
                Database.SaveResult saveResult = Database.update(c, false);
                return saveResult.isSuccess();
            }
            return false;
        } catch(Exception e){
            System.debug(e);
            return false;
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static Boolean setDoubleOptIn(Boolean doubleOptIn) {
        try{
            Id CONTACT_ID = [SELECT Id, ContactId FROM User WHERE Id = : UserInfo.getUserId()].contactId;
            if(CONTACT_ID != null){
                Contact c = new Contact(
                    Id = CONTACT_ID,
                    DoubleOptInAbandonedCart__c = doubleOptIn,
                    DoubleOptInAbandonedCartModalSeen__c = true
                );
                Database.SaveResult saveResult = Database.update(c, false);
                return saveResult.isSuccess();
            }
            return false;
        } catch(Exception e){
            System.debug(e);
            return false;
        }
    }
    
    /********
     * 
     * SELF SERVICE
     * 
     ********/  

    
    @AuraEnabled(cacheable=false)
    public static Boolean editUserDetails(String userid, String email, String contactid, String function) {
        try{
            if(String.isNotBlank(userid)){
                User u = new User(Id = userid, Email = email);
                update u;
            }
            Contact c = new Contact(Id = contactid, Function__c = function);
            update c;
            return true;
        } catch(Exception e){
            System.debug(e);
            return false;
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static User getCurrentUserInfo() {
        try{
            return [SELECT Id, FirstName, LastName, Username, Email, Phone, MobilePhone, LanguageLocaleKey, TimeZoneSidKey, ContactId, Contact.DoubleOptInRequested__c, Contact.DoubleOptInAbandonedCart__c FROM User WHERE Id = : UserInfo.getUserId()];
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }

    @AuraEnabled(cacheable=false)
    public static Boolean setPersonal(String firstName, String lastName, String email, String mobile, String phone) {
        try{
            User u = new User(Id = UserInfo.getUserId());
            u.FirstName = firstName;
            u.LastName = lastName;
            u.Email = email;
            u.MobilePhone = mobile;
            u.Phone = phone;
            update u;
            return true;
        } catch(Exception e){
            System.debug(e);
            return false;
        }
    }

    @AuraEnabled(cacheable=false)
    public static Boolean setConsent(Boolean optOut, Boolean abandonedCart) {
        try{
            List<User> ul = [SELECT Id, ContactId FROM User WHERE ContactId != NULL AND Id = : UserInfo.getUserId()];
            if(!ul.isEmpty()){
                Contact con = new Contact(Id = ul[0].ContactId);
                if(optOut != null){
                    con.DoubleOptInRequested__c = !optOut;
                }
                if(abandonedCart != null){
                    con.DoubleOptInAbandonedCart__c = abandonedCart;
                }
                update con;
                return true;
            }
            return false;
        } catch(Exception e){
            System.debug(e);
            return false;
        }
    }

    @AuraEnabled(cacheable=false)
    public static Boolean setCurrentUserInfo(String language, String timezone) {
        try{
            User u = new User(Id = UserInfo.getUserId());
            u.LanguageLocaleKey = language;
            u.TimeZoneSidKey = timezone;
            update u;
            return true;
        } catch(Exception e){
            System.debug(e);
            return false;
        }
    }

    @AuraEnabled(cacheable=false)
    public static OutletWrapper getSingleOutlet(String accountId) {
        try{
            List<Account> accs = [SELECT Id, Name, ERPCustomerNumber__c, BillingStreet, BillingCity, BillingPostalCode, ShippingStreet, ShippingCity, ShippingPostalCode, ShippingLatitude, ShippingLongitude FROM Account WHERE Id = : accountId];
            if(!accs.isEmpty()){
                List<String> additionalAddresses = new List<String>();
                
                for(CustomAddress__c add : [SELECT Id, ExternalID__c, Address__Street__s, Address__PostalCode__s, Address__City__s FROM CustomAddress__c WHERE Account__c = : accountId AND IsValid__c = TRUE AND AddressType__c = 'Shipping' ORDER BY ValidFrom__c]){
                    String shippingStreet =  String.isNotBlank(add.Address__Street__s) ? (add.Address__Street__s + ', ') : '';
                    String shippingPostalCode = String.isNotBlank(add.Address__PostalCode__s) ? (add.Address__PostalCode__s + ' ') : '';
                    String shippingCity = String.isNotBlank(add.Address__City__s) ? add.Address__City__s : '';
                    String totalString = shippingStreet + shippingPostalCode + shippingCity;
                    additionalAddresses.add(accs[0].Name + ', ' + totalString);
                }
                return new OutletWrapper(accs[0], additionalAddresses);
            }
        } catch(Exception e){
            System.debug(e);
        }
        return null;
    }     

    @AuraEnabled(Cacheable=true)
    public static List<OptionWrapper> getExternalAddresses(String accountId){
        try{
            List<OptionWrapper> options = new List<OptionWrapper>();
            List<Account> accs = [SELECT Id, Name, ERPCustomerNumber__c, BillingStreet, BillingCity, BillingPostalCode, ShippingStreet, ShippingCity, ShippingPostalCode, ShippingLatitude, ShippingLongitude FROM Account WHERE Id = : accountId];
            if(!accs.isEmpty()){
                Account acc = accs[0];
                Set<String> addressStrings = new Set<String>();
                String shippingStreet =  (String.isNotBlank(acc.ShippingStreet) ? (acc.ShippingStreet + ', ') : (String.isNotBlank(acc.BillingStreet) ? (acc.BillingStreet + ', ') : ''));
                String shippingPostalCode = (String.isNotBlank(acc.ShippingPostalCode) ? (acc.ShippingPostalCode + ' ') : (String.isNotBlank(acc.BillingPostalCode) ? (acc.BillingPostalCode + ' ') : ''));
                String shippingCity = (String.isNotBlank(acc.ShippingCity) ? acc.ShippingCity : (String.isNotBlank(acc.BillingCity) ? acc.BillingCity : ''));
                String totalString = shippingStreet + shippingPostalCode + shippingCity;
                addressStrings.add(totalString);
                options.add(new OptionWrapper(
                    acc.Name + ', ' +  totalString,
                    '',
                    true
                ));
                for(CustomAddress__c add : [SELECT Id, ExternalID__c, Address__Street__s, Address__PostalCode__s, Address__City__s FROM CustomAddress__c WHERE Account__c = : accountId AND IsValid__c = TRUE AND AddressType__c = 'Shipping' ORDER BY ValidFrom__c]){
                    shippingStreet =  String.isNotBlank(add.Address__Street__s) ? (add.Address__Street__s + ', ') : '';
                    shippingPostalCode = String.isNotBlank(add.Address__PostalCode__s) ? (add.Address__PostalCode__s + ' ') : '';
                    shippingCity = String.isNotBlank(add.Address__City__s) ? add.Address__City__s : '';
                    totalString = shippingStreet + shippingPostalCode + shippingCity;
                    if(!addressStrings.contains(totalString)){
                        addressStrings.add(totalString);
                        options.add(new OptionWrapper(
                            (acc.Name + ', ' + totalString),                            
                            add.Id,
                            false
                        ));
                    }
                }
                return options;
            }
        } catch(Exception e){
            System.debug(e);
        }
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getAllOutlets(String accountId, Integer lmt) {
        try{
            Map<Id, Account> accounts = new Map<Id, Account>();
            for(Account ac : [SELECT Id, AccountNumber , Name, ShippingStreet, ShippingCity, ShippingPostalCode, ShippingCountry, BillingStreet, BillingCity, BillingPostalCode, BillingCountry FROM Account WHERE Id = : accountId]){
                accounts.put(ac.Id, ac);
            }
            for(User u : [SELECT Id, Contact.AccountId, Contact.Account.AccountNumber , Contact.Account.Name, Contact.Account.Name2__c, Contact.Account.ShippingStreet, Contact.Account.ShippingCity, Contact.Account.ShippingPostalCode, Contact.Account.ShippingCountry, Contact.Account.BillingStreet, Contact.Account.BillingCity, Contact.Account.BillingPostalCode, Contact.Account.BillingCountry FROM User WHERE Id = : UserInfo.getUserId() AND Contact.AccountId != : accountId]){
                accounts.put(u.Contact.AccountId, u.Contact.Account);
            }
            Id userId = UserInfo.getUserId();
            String queryString = 'SELECT Id, TargetId, Target.AccountNumber, Target.Id, Target.Name, Target.ShippingStreet, Target.ShippingCity, Target.ShippingPostalCode, Target.ShippingCountry, Target.BillingStreet, Target.BillingCity, Target.BillingPostalCode, Target.BillingCountry FROM DelegatedAccount WHERE TargetId != : accountId AND ManagedById = : userId ORDER BY Target.Name ';
            if(lmt != null && lmt > 0){
                queryString += ' LIMIT ' + String.valueOf(lmt);
            }
            for(DelegatedAccount delAcc : Database.Query(queryString)){
                accounts.put(delAcc.TargetId, delAcc.Target);
            }
            return accounts.values();
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }    

    @AuraEnabled(cacheable=true)
    public static List<Invoice> getAllInvoices(String accountId, Integer lmt) {
        try{
            String queryString = 'SELECT Id, Status, TotalAmount, ERPInvoiceNumber__c, CreatedDate, CurrencyIsoCode FROM Invoice WHERE BillingAccountId = : accountId ORDER BY CreatedDate DESC ';
            if(lmt != null && lmt > 0){
                queryString += ' LIMIT ' + String.valueOf(lmt);
            }
            return Database.Query(queryString);
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }  

    @AuraEnabled(cacheable=false)
    public static List<Order> getAllOrders(String accountId, Integer lmt) {
        try{
            String queryString = 'SELECT Id, Status, TotalAmount, OrderNumber, Account.Name, CreatedDate, CurrencyIsoCode FROM Order WHERE Status != \'Draft\' AND AccountId = : accountId ORDER BY CreatedDate DESC ';
            if(lmt != null && lmt > 0){
                queryString += ' LIMIT ' + String.valueOf(lmt);
            }
            return Database.Query(queryString);
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }  

    @AuraEnabled(cacheable=true)
    public static InvoiceWrapper getInvoiceInfoByInvoiceId(String invoiceId, String accountId){
        try{
            String invoiceQuery = 'SELECT Id, ERPInvoiceNumber__c, BillingAccount.BillingStreet, BillingAccount.BillingCity, BillingAccount.BillingPostalCode, BillingAccount.BillingCountry,' + 
            'CreatedDate, CreatedBy.FirstName, CreatedBy.LastName, CreatedBy.Email, BillingAccount.Name,' + 
            'BillingAccount.ShippingStreet, BillingAccount.ShippingCity, BillingAccount.ShippingPostalCode, BillingAccount.ShippingCountry, TotalAmount, InvoiceNumber,' + 
            'CurrencyIsoCode, Status,' + 
            '(SELECT Id, LineAmount, Quantity, Product2.' +
            String.join(PRODUCT_FIELDS, ', Product2.') +
            ' FROM InvoiceLines WHERE Product2.ProductCode NOT IN : EXCLUDE_PRODUCTS)' + 
            ' FROM Invoice WHERE Id = : invoiceId AND BillingAccountId = : accountId';
            Invoice invoice = Database.query(invoiceQuery);
            InvoiceWrapper wrapper = new InvoiceWrapper(invoice);
            Map<String, InvoiceProductWrapper> invoiceProductsWrapperMap = new Map<String, InvoiceProductWrapper>();
            Set<String> wishlistItems = new Set<String>();
            for(WishlistItem wi : [SELECT Id, Product2Id FROM WishlistItem WHERE Wishlist.WebstoreId = : CURRENT_STORE_ID AND Wishlist.AccountId = : accountId AND Wishlist.OwnerId = : UserInfo.getUserId() ]){
                wishlistItems.add(wi.Product2Id);
            }
            for(InvoiceLine oi : invoice.InvoiceLines){
                invoiceProductsWrapperMap.put(oi.Product2Id, new InvoiceProductWrapper(oi, wishlistItems));
            }
            wrapper.products = invoiceProductsWrapperMap.values();
            return wrapper;
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static OrderWrapper getOrderInfoByOrderId(String orderId, String accountId){
        try{
            String orderQuery = 'SELECT Id, Name, BillingStreet, BillingCity, BillingPostalCode, BillingCountry,' + 
            'CreatedDate, CreatedBy.FirstName, CreatedBy.LastName, CreatedBy.Email, Account.Name,' + 
            'OrderReferenceNumber, ShippingStreet, ShippingCity, ShippingPostalCode, ShippingCountry, TotalAmount, OrderNumber,' + 
            'ProductCosts__c, ShippingCosts__c, CurrencyIsoCode, Status, CustomerReference__c, ' + 
            '(SELECT Id, TotalPrice, Quantity, Product2Id, Product2.' +
            String.join(PRODUCT_FIELDS, ', Product2.') +
            ' FROM OrderItems WHERE Product2.ProductCode NOT IN : EXCLUDE_PRODUCTS)' + 
            ' FROM Order WHERE Id = : orderId AND AccountId = : accountId';
            Order order = Database.query(orderQuery);
            OrderWrapper wrapper = new OrderWrapper(order);
            Map<String, OrderProductWrapper> orderProductsWrapperMap = new Map<String, OrderProductWrapper>();
            Set<String> wishlistItems = new Set<String>();
            for(WishlistItem wi : [SELECT Id, Product2Id FROM WishlistItem WHERE Wishlist.WebstoreId = : CURRENT_STORE_ID AND Wishlist.AccountId = : accountId AND Wishlist.OwnerId = : UserInfo.getUserId() ]){
                wishlistItems.add(wi.Product2Id);
            }
            for(OrderItem oi : order.OrderItems){
                orderProductsWrapperMap.put(oi.Product2Id, new OrderProductWrapper(oi, wishlistItems));
            }
            wrapper.products = orderProductsWrapperMap.values();
            return wrapper;
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static SelfServiceStatsWrapper getSelfServiceStats(String accountId) {
        try{
            List<AggregateResult> countOrders = [SELECT Count(Id) FROM Order WHERE AccountId = :accountId AND Status != 'Draft'];
            List<AggregateResult> countOrderItems = [SELECT Count(Product2Id) FROM OrderItem WHERE Order.AccountId = :accountId AND Order.Status != 'Draft'];
            SelfServiceStatsWrapper statsWrapper = new SelfServiceStatsWrapper();
            statsWrapper.orderCount = (Integer) countOrders[0].get('expr0');
            statsWrapper.individualItemCount = (Integer) countOrderItems[0].get('expr0');
            return statsWrapper;
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }    

    @AuraEnabled(cacheable=false)
    public static Boolean createDelegatedAccount(String accountId, String userId, Boolean isManager, Boolean priceVisible, Boolean extensionExclusion){
        try{
            List<DelegatedAccount> acl = [SELECT Id FROM DelegatedAccount WHERE ManagedById = :userId AND TargetId =: accountId];
            if(acl.isEmpty()){
                DelegatedAccount delAcc = new DelegatedAccount();
                delAcc.TargetId = accountId;
                delAcc.ManagedById = userId;
                delAcc.Manager__c = isManager;
                delAcc.AssortmentExtensionExclusion__c = extensionExclusion;
                delAcc.PriceVisible__c = priceVisible;
                insert delAcc;
            } else {
                DelegatedAccount delAcc = acl[0];
                delAcc.Manager__c = isManager;
                delAcc.AssortmentExtensionExclusion__c = extensionExclusion;
                delAcc.PriceVisible__c = priceVisible;
                update delAcc;
            }
            return true;
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<TeamMemberWrapper> getAllTeamMembers(String accountId){
        try{
            Map<Id, TeamMemberWrapper> teamMemberByUser = new Map<Id, TeamMemberWrapper>();
            Id contactId = [SELECT Id, ContactId FROM User WHERE Id = : UserInfo.getUserID()].ContactId;
            for(User usr : [SELECT Id, ContactId, FirstName, LastName, Contact.Email, Email, Contact.Function__c, Contact.ActiveWebshopUser__c, Contact.Manager__c, Contact.AssortmentExtensionExclusion__c, Contact.PriceVisible__c FROM User WHERE IsActive = TRUE AND Contact.ActiveWebshopUser__c = TRUE AND Contact.AccountId = : accountId AND Contact.Id != : contactId ORDER BY Contact.LastName]){
                teamMemberByUser.put(usr.Id, new TeamMemberWrapper(
                    usr.Id, 
                    usr.ContactId, 
                    usr.FirstName,
                    usr.LastName, 
                    usr.Email, 
                    usr.Contact.ActiveWebshopUser__c, 
                    null, 
                    usr.Contact.Manager__c, 
                    usr.Contact.PriceVisible__c, 
                    usr.Contact.AssortmentExtensionExclusion__c,
                    false, 
                    usr.Contact.Function__c, 
                    true
                ));
            }
            for(AggregateResult ar : [SELECT ManagedById FROM DelegatedAccount WHERE TargetId != : accountId AND ManagedById IN : teamMemberByUser.keySet() GROUP BY ManagedById]){
                Id managedById = (Id)ar.get('ManagedById');
                TeamMemberWrapper wrapper = teamMemberByUser.get(managedById);
                wrapper.deleteable = false;
                teamMemberByUser.put(managedById, wrapper);
            }
            for(DelegatedAccount delAcc : [SELECT Id, TargetId, ManagedBy.FirstName, Manager__c, PriceVisible__c, AssortmentExtensionExclusion__c, ManagedById, ManagedBy.LastName, ManagedBy.Email, ManagedBy.ContactId, ManagedBy.Contact.AccountId, ManagedBy.SmallPhotoUrl FROM DelegatedAccount WHERE TargetId = : accountId AND ManagedById != : UserInfo.getUserId() AND ManagedBy.IsActive = TRUE ORDER BY ManagedBy.LastName]){
                teamMemberByUser.put(delAcc.ManagedById, new TeamMemberWrapper(
                    delAcc.ManagedById, 
                    null, 
                    delAcc.ManagedBy.FirstName, 
                    delAcc.ManagedBy.LastName,
                    delAcc.ManagedBy.Email, 
                    true, 
                    delAcc.ManagedBy.SmallPhotoUrl,
                    delAcc.Manager__c,
                    delAcc.PriceVisible__c,
                    delAcc.AssortmentExtensionExclusion__c,
                    true,
                    System.Label.WebshopDelegatedUser,
                    true
                ));
            }
            // Get my enabled Accounts except for the current one
            Map<String, String> accsToNames = new Map<String, String>();
            for(User u : [SELECT Id, Contact.AccountId, Contact.Account.Name FROM User WHERE Id = : UserInfo.getUserId() AND Contact.Manager__c = TRUE AND Contact.AccountId != NULL AND Contact.AccountId != : accountId]){
                accsToNames.put(u.Contact.AccountId, u.Contact.Account.Name);
            }
            for(DelegatedAccount delAcc : [SELECT Id, TargetId, Target.Name FROM DelegatedAccount WHERE TargetId != : accountId AND Manager__c = TRUE AND ManagedById = : UserInfo.getUserId()]){
                accsToNames.put(delAcc.TargetId, delAcc.Target.Name);
            }
            // Make Map<String, Set<Account>> for all members directly and indirectly (DelegatedAccount) linked with my enabled Accounts
            // First level is user, second level are accounts.
            if(!accsToNames.isEmpty()){
                Map<String, Set<String>> userToAccounts = new Map<String, Set<String>>();
                for(User u : [SELECT Id, Contact.AccountId FROM User WHERE Id != : UserInfo.getUserId() AND Contact.AccountId IN : accsToNames.keySet() AND IsActive = TRUE]){
                    Set<String> innerSet = userToAccounts.containsKey(u.Id) ? userToAccounts.get(u.Id) : new Set<String>();
                    innerSet.add(u.Contact.AccountId);
                    userToAccounts.put(u.Id, innerSet);
                }
                for(DelegatedAccount delAcc : [SELECT Id, TargetId, ManagedById FROM DelegatedAccount WHERE TargetId IN : accsToNames.keySet() AND ManagedById != : UserInfo.getUserId() AND ManagedBy.IsActive = TRUE]){
                    Set<String> innerSet = userToAccounts.containsKey(delAcc.ManagedById) ? userToAccounts.get(delAcc.ManagedById) : new Set<String>();
                    innerSet.add(delAcc.TargetId);
                    userToAccounts.put(delAcc.ManagedById, innerSet);
                }
                // for every teamMemberByUser.values(), populate switchOptions as a Map<String, String> value, label
                for(TeamMemberWrapper wrapper : teamMemberByUser.values()){
                    for(String relatedAccId : accsToNames.keySet()){
                        if(!userToAccounts.containsKey(wrapper.userId) || !userToAccounts.get(wrapper.userId).contains(relatedAccId)){
                            wrapper.switchOptions.add(new Map<String, String>{
                                'value' => relatedAccId,
                                'label' => accsToNames.get(relatedAccId)
                            });
                        }
                    }
                }
            }
            return teamMemberByUser.values();
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    } 

    @AuraEnabled(cacheable=false)
    public static Boolean handleChangeWebshopCustomer(String contactId, Boolean checked){
        try {
            Contact con = new Contact(Id = contactId, WebshopCustomer__c = checked);
            update con;
            return true;
        } catch(Exception e){
            System.debug(e);
            return false;
        }
    }

    @AuraEnabled(cacheable=false)
    public static Boolean handleChangeAssortmentExtensionExclusion(String contactId, String accountId, Boolean checked){
        try {
            Contact con = [SELECT Id, AccountId FROM Contact WHERE Id = : contactId];
            if(con.AccountId == accountId){
                con.AssortmentExtensionExclusion__c = checked;
                update con;
                return true;
            } else {
                DelegatedAccount delAcc = [SELECT Id FROM DelegatedAccount WHERE TargetId = : accountId AND ManagedBy.ContactId = : contactId];
                delAcc.AssortmentExtensionExclusion__c = checked;
                update delAcc;
                return true;
            }
        } catch(Exception e){
            System.debug(e);
            return false;
        }
    }

    @AuraEnabled(cacheable=false)
    public static Boolean handleChangeManager(String contactId, String accountId, Boolean checked){
        try {
            Contact con = [SELECT Id, AccountId FROM Contact WHERE Id = : contactId];
            if(con.AccountId == accountId){
                con.Manager__c = checked;
                update con;
                return true;
            } else {
                DelegatedAccount delAcc = [SELECT Id FROM DelegatedAccount WHERE TargetId = : accountId AND ManagedBy.ContactId = : contactId];
                delAcc.Manager__c = checked;
                update delAcc;
                return true;
            }
        } catch(Exception e){
            System.debug(e);
            return false;
        }
    }

    @AuraEnabled(cacheable=false)
    public static Boolean deactivateUser(String userId, String accountId){
        try {
            List<User> ul = [SELECT Id FROM User WHERE Id = : userId AND Contact.AccountId = : accountId];
            if(!ul.isEmpty()){
                User u = ul[0];
                u.IsActive = false;
                update u;
                return true;
            } else {
                List<DelegatedAccount> delAcc = [SELECT Id FROM DelegatedAccount WHERE ManagedById = : userId AND TargetId = : accountId];
                if(!delAcc.isEmpty()){
                    delete delAcc[0];
                    return true;
                }
            }
            return false;
        } catch(Exception e){
            System.debug(e);
            return false;
        }
    }

    @AuraEnabled(cacheable=false)
    public static Boolean checkPriceInvisible(String accountId){
        try {
            return [SELECT Id, PriceInvisible__c FROM Account WHERE Id = : accountId].PriceInvisible__c;
        } catch(Exception e){
            System.debug(e);
            return false;
        }
    }

    @AuraEnabled(cacheable=false)
    public static Boolean handleChangePriceVisible(String contactId, String accountId, Boolean checked){
        try {
            Contact con = [SELECT Id, AccountId FROM Contact WHERE Id = : contactId];
            if(con.AccountId == accountId){
                con.PriceVisible__c = checked;
                update con;
                return true;
            } else {
                DelegatedAccount delAcc = [SELECT Id FROM DelegatedAccount WHERE TargetId = : accountId AND ManagedBy.ContactId = : contactId];
                delAcc.PriceVisible__c = checked;
                update delAcc;
                return true;
            }
        } catch(Exception e){
            System.debug(e);
            return false;
        }
    }

    public class UserWrapper{
        @AuraEnabled public Boolean isManager {get; set; }
        @AuraEnabled public String name {get; set; }
        @AuraEnabled public String function {get; set; }
        @AuraEnabled public Boolean isSwitcher {get; set; }
        public UserWrapper(Boolean isManager, String name, String function, Boolean isSwitcher){
            this.isManager = isManager;
            this.name = name;
            this.function = function;
            this.isSwitcher = isSwitcher;
        }
    }

    @AuraEnabled(cacheable=false)
    public static UserWrapper checkCurrentUserIsManager(String accountId){
        try{
            List<User> ul = [SELECT Id, Name, Contact.Function__c, Contact.Manager__c FROM User WHERE Id = : UserInfo.getUserId() AND Contact.AccountId = : accountId];
            if(!ul.isEmpty()){
                return new UserWrapper(ul[0].Contact.Manager__c, ul[0].Name, ul[0].Contact.Function__c, false);
            } else {
                List<DelegatedAccount> dl = [SELECT Id, ManagedBy.Name, Manager__c FROM DelegatedAccount WHERE ManagedById = :UserInfo.getUserId() AND TargetId = : accountId];
                if(!dl.isEmpty()){
                    return new UserWrapper(dl[0].Manager__c, dl[0].ManagedBy.Name, null, true);
                }
            }
            return null;
        } catch(Exception e){
            System.debug(e.getMessage());
            return null;
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<Product2> reorder(String orderId, String accountId, String cartId){
        try {
            if(String.isBlank(cartId)){
                cartId = getCartSummaryOrCreateCart(accountId);
            }
            Set<String> allowedProductIds = retrieveAllowedProductIds(accountId);
            List<Product2> failedProducts = new List<Product2>();
            List<ConnectApi.BatchInput> batchInputList = new List<ConnectApi.BatchInput>();
            for(OrderItem oi : [SELECT Id, TotalPrice, Quantity, Product2Id, Product2.Name, Product2.ProductCode FROM OrderItem WHERE OrderId = : orderId AND Product2.ProductCode NOT IN : EXCLUDE_PRODUCTS]){
                if(allowedProductIds.contains(oi.Product2Id)){
                    ConnectApi.CartItemInput input = new ConnectApi.CartItemInput();
                    input.productId = oi.Product2Id;
                    input.quantity = String.valueOf(oi.Quantity);
                    input.type = ConnectApi.CartItemType.Product;
                    batchInputList.add(new ConnectApi.BatchInput(input));
                } else {
                    failedProducts.add(new Product2(
                        Id = oi.Product2Id,
                        Name = oi.Product2.Name,
                        ProductCode = oi.Product2.ProductCode
                    ));
                }
            }
            if(!Test.isRunningTest()){
                ConnectApi.CommerceCart.addItemsToCart(CURRENT_STORE_ID, accountId, cartId, batchInputList);
            }
            return failedProducts;
        } catch(Exception e){
            System.debug(e.getMessage());
            return null;
        }
    }
    
    /********
     * 
     * MISC
     * 
     ********/  
    
    @AuraEnabled(cacheable=false)
    public static Boolean sendMessageNotLoggedIn(String subject, Boolean subjectIsOther, String message, String accountId, String name, String email, String phone, Boolean isLead) {
        try {
            List<Group> ecommerceQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'E-Commerce'];
            if(!ecommerceQueue.isEmpty()){
                if(isLead){
                    Lead ld = new Lead(
                        LastName = name,
                        Email = email,
                        Phone = phone,
                        LeadSource = 'Webshop'
                    );
                    insert ld;
                    insert new Case(
                        Subject = subject,
                        Type = 'Webshop', 
                        Origin = 'Webshop',
                        //RecordTypeId = CASE_RECORD_TYPE_ID,
                        Lead__c = ld.Id,
                        Description = message,
                        OwnerId = ecommerceQueue[0].Id
                    );
                    return true;
                } else {
                    Contact con = new Contact(
                        LastName = name,
                        Email = email,
                        Phone = phone
                    );
                    insert con;
                    insert new Case(
                        Subject = subject,
                        Type = 'Webshop', 
                        Origin = 'Webshop',
                        //RecordTypeId = CASE_RECORD_TYPE_ID,
                        ContactId = con.Id,
                        Description = message,
                        OwnerId = ecommerceQueue[0].Id
                    );
                    return true;
                }
            }
            return false;
        } catch(Exception e){
            System.debug(e);
            return false;
        }
    }   
    
    @AuraEnabled(cacheable=false)
    public static Boolean sendMessage(String subject, Boolean subjectIsOther, String message, String accountId) {
        try{
            List<User> cl = [SELECT Id, ContactId FROM User WHERE Id = : UserInfo.getUserId() AND ContactId != NULL];
            List<Group> ecommerceQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'E-Commerce'];
            if(!cl.isEmpty() && !ecommerceQueue.isEmpty()){
                try {
                    insert new Case(
                        Subject = subject,
                        Type = 'Webshop', 
                        Origin = 'Webshop',
                        //RecordTypeId = CASE_RECORD_TYPE_ID,
                        ContactId = cl[0].ContactId,
                        Description = message,
                        OwnerId = ecommerceQueue[0].Id
                    );
                    return true;
                } catch(Exception e){
                    System.debug(e);
                }
            }
            return false;
        } catch(Exception e){
            System.debug(e);
            return false;
        }
    }   
    
    @AuraEnabled(cacheable=false)
    public static String getLexOriginUrl() {
        try{
            return URL.getOrgDomainUrl().toExternalForm();
        } catch(Exception e){
            System.debug(e);
            return null;
        }
    }


    /********
     * 
     * ERP Integration
     * 
     *******/

    @AuraEnabled
    public static ERPResponseWrapper sendWebCartToERP(Id cartId, Id accountId) {
        try {
            // 1. Load data
            Account ac = [
                SELECT Id, ERPCustomerNumber__c, ERPPaymentTerms__c
                FROM Account
                WHERE Id = :accountId
            ];

            WebCart cart = [
                SELECT Id, AccountId, CurrencyIsoCode, PoNumber,
                    (SELECT Id, Quantity,
                            Product2Id,
                            Product2.ProductCode,
                            Product2.BaseProductCode__c,
                            Product2.QuantityUnitOfMeasure
                        FROM CartItems
                        ORDER BY CreatedDate)
                FROM WebCart
                WHERE Id = :cartId
                LIMIT 1
            ];

            ERPIntegrationSettings__mdt cfg = ERPIntegrationSettings__mdt.getInstance('Default');

            // 2. Build payload
            Map<String,Object> payload = buildPayload(cart, cart.CartItems, ac.ERPCustomerNumber__c, cfg);
            String body = JSON.serialize(payload);
            System.debug('REQUEST: ' + body);

            // 3. Callout
            HttpRequest req = new HttpRequest();
            req.setEndpoint((System.Label.OrderSimulationTestMode == '1' ? 'callout:ERP_API' : 'callout:ERP_API_NEW') + (cfg.EndpointPath__c ?? ''));
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(body);

            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('STATUS: ' + res.getStatusCode());
            System.debug('RESPONSE: ' + res.getBody());

            if(res.getStatusCode() >= 300){
                Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String errorMessage = data.containsKey('message') ? (String)data.get('message') : 'Unknown Error';
                ErrorLogging__c el = new ErrorLogging__c(
                    ProcessName__c = 'Order Simulation',
                    Error__c = errorMessage
                );
                insert el;
                return new ERPResponseWrapper(errorMessage, el.Id);
            }
            System.debug(res.getBody());
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, ERPResponseInnerWrapper> successOrderItemsMap = new Map<String, ERPResponseInnerWrapper>();
            Set<String> failedOrderItemsSet = new Set<String>();
            Map<String, CartItem> ciMap = new Map<String, CartItem>();
            Decimal totalCartAmount = 0;
            if(data != null && data.containsKey('OrderItems')){
                for(CartItem ci : [SELECT Id, Type, Quantity, ListPrice, CurrencyIsoCode, SalesPrice, TotalPrice,
                TotalAmount, TotalLineAmount, TotalPromoAdjustmentAmount, FreeItem__c, CartFreeItem__c,LetterCampaignFreeItem__c,
                Product2Id, Product2.ProductCode, Product2.Name, Product2.PackageUnit__c, Product2.ProductSubtitle__c,Product2.WebshopImageURL__c 
                FROM CartItem WHERE CartId = : cartId]){
                    ciMap.put(ci.Product2Id, ci);
                    if(ci.TotalLineAmount != null){
                        totalCartAmount += ci.TotalLineAmount;
                    }
                }
                if(System.Label.OrderSimulationTestMode != '1'){
                    for(Object oiObj : (List<Object>) data.get('OrderItems')){
                        Map<String, Object> oi = (Map<String, Object>) oiObj;
                        if(oi.containsKey('Product2')){
                            Map<String, Object> product2 = (Map<String, Object>) oi.get('Product2');
                            if(product2.containsKey('Id')){
                                String productId = (String) product2.get('Id');
                                if(String.isNotBlank(productId)){
                                    if(ciMap.containsKey(productId)){
                                        CartItem ci = ciMap.get(productId);
                                        successOrderItemsMap.put(productId, new ERPResponseInnerWrapper(ci, oi));
                                    }
                                }
                            }
                        } 
                    }
                } else {
                    Integer i = 0;
                    List<CartItem> ciList = (List<CartItem>) ciMap.values();
                    for(Object oiObj : (List<Object>) data.get('OrderItems')){
                        Map<String, Object> oi = (Map<String, Object>) oiObj;
                        if(oi.containsKey('Product2')){
                            Map<String, Object> product2 = (Map<String, Object>) oi.get('Product2');
                            if(product2.containsKey('Id')){
                                String productId = (String) product2.get('Id');
                                if(String.isNotBlank(productId)){
                                    if(ciList.size() > i){
                                        CartItem ci = ciList[i];
                                        successOrderItemsMap.put(productId, new ERPResponseInnerWrapper(ci, oi));
                                    }
                                }
                            }
                        } 
                        i++;
                    }
                }

            }
            return new ERPResponseWrapper(ac, data, totalCartAmount, successOrderItemsMap.values());
        } catch(Exception e){
            String errorMessage = e.getMessage();
            ErrorLogging__c el = new ErrorLogging__c(
                ProcessName__c = 'Order Simulation',
                Error__c = errorMessage
            );
            insert el;
            return new ERPResponseWrapper(errorMessage, el.Id);
        }
    }
    
    private static Map<String,Object> buildPayload(
        WebCart cart,
        List<CartItem> items,
        String customerReferenceId,
        ERPIntegrationSettings__mdt cfg
    ){
        Map<String,Object> root = new Map<String,Object>();
        
        // Order Items
        List<Object> orderItems = new List<Object>();
        Integer lineNum = 1;        
        for(CartItem ci : items){
            List<String> ciSplit = splitLastSuffix(ci.Product2.ProductCode);
            Map<String,Object> item = new Map<String,Object>();            
            item.put('Quantity', ci.Quantity);
            item.put('CurrencyIsoCode', cart.CurrencyIsoCode);
            item.put('LineNumber', lineNum++);            
            Map<String,Object> product = new Map<String,Object>();
            product.put('Id', ci.Product2Id);
            if(!ciSplit.isEmpty() && ciSplit.size() > 1 && ciSplit[1].isAlpha()){
                product.put('ProductCode', ciSplit[0].replace('OLD_', ''));
            } else {
                product.put('ProductCode', ci.Product2.ProductCode.replace('OLD_', ''));
            }
            if(String.isNotBlank(ci.Product2.BaseProductCode__c)){
                product.put('BaseProductCode__c', ci.Product2.BaseProductCode__c);
            }
            if(String.isNotBlank(ci.Product2.QuantityUnitOfMeasure)){
                product.put('QuantityUnitOfMeasure', ci.Product2.QuantityUnitOfMeasure);
            } else {
                if(!ciSplit.isEmpty() && ciSplit.size() > 1 && ciSplit[1].isAlpha()){
                    product.put('QuantityUnitOfMeasure', ciSplit[1]);
                }
            }        
            item.put('Product2', product);
            orderItems.add(item);
        }        
        root.put('OrderItems', orderItems);        
        // Partner Roles
        Map<String,Object> partner = new Map<String,Object>{
            'ERPCustomerNumber__c' => customerReferenceId
        };
        
        root.put('Account', partner);
        root.put('SoldTo__r', partner);
        root.put('BillTo__r', partner);
        root.put('ShipTo__r', partner);
        root.put('Payer__r', partner);
        
        // Order Header
        root.put('Type', cfg.OrderType__c);
        //root.put('OrderReferenceNumber', 'Test');
        root.put('CurrencyIsoCode', cart.CurrencyIsoCode);
        root.put('SalesOrganization__c', cfg.SalesOrg__c);
        root.put('DistributionChannel__c', cfg.DistChannel__c);
        root.put('OrganizationDivision__c', cfg.Division__c);
        root.put('RequestedDeliveryDate__c', String.valueOf(Date.today().addDays(7)));
        root.put('ConfirmedDeliveryDate__c', Date.today());
        root.put('ShippingCondition__c', '-');
        
        return root;
    }

    public static List<String> splitLastSuffix(String inputString){
        List<String> result = new List<String>();
        if (String.isNotBlank(inputString)) {
            Integer lastDash = inputString.lastIndexOf('-');
            // No dash found
            if (lastDash == -1) {
                result.add(inputString);
                return result;
            }
            result.add(inputString.substring(0, lastDash));
            result.add(inputString.substring(lastDash + 1));
        }
        return result;
    }

    /********
     * 
     * WRAPPER CLASSES
     * 
     ********/

     public without sharing class OutletWrapper {
        @AuraEnabled
        public Account outletData { get; set; }
        @AuraEnabled
        public List<String> deliveryAddresses { get; set; }
        public OutletWrapper(Account outletData, List<String> deliveryAddresses) {
            this.outletData = outletData;
            this.deliveryAddresses = deliveryAddresses;
        }
    }
    public class WebshopMegaMenuSuperiorWrapper {
        @AuraEnabled
        public List<WebshopMegaMenuWrapper> wrappers { get; set; }
        @AuraEnabled
        public List<Map<String, String>> brands { get; set; }
        @AuraEnabled
        public Boolean hasBrands{
            get{
                return !this.brands.isEmpty();
            } 
            private set;
        }
        public WebshopMegaMenuSuperiorWrapper(List<WebshopMegaMenuWrapper> wrappers, List<Map<String, String>> brands){
            this.wrappers = wrappers;
            this.brands = brands;
        }
    }
    public class WebshopMegaMenuWrapper {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String subheader { get; set; }
        @AuraEnabled
        public String subheaderFeatured { get; set; }
        @AuraEnabled
        public Boolean disabled { get; set; }
        @AuraEnabled
        public String targetUrl { get; set; }
        @AuraEnabled
        public WebshopMegaMenuItem__c megaMenuItem { get; set; }
        @AuraEnabled
        public List<WebshopMegaMenuWrapper> children { get; set; }
        @AuraEnabled
        public List<WebshopMegaMenuWrapper> featuredChildren { get; set; }
        @AuraEnabled
        public String childrenColStyle{
            get{
                Integer cols = !this.children.isEmpty() ? Integer.valueOf(Math.ceil(this.children.size() / Integer.valueOf(System.Label.WebshopMegaMenuRowsPerColumn))) : 1;
                return cols <= 1 ? 'display: none;' : ('display: none; columns: ' + String.valueOf(cols) + ';');
            } 
            private set;
        }
        @AuraEnabled
        public Boolean hasChildren{
            get{
                return !this.children.isEmpty();
            } 
            private set;
        }
        @AuraEnabled
        public Boolean hasFeaturedChildren{
            get{
                return !this.featuredChildren.isEmpty();
            } 
            private set;
        }
        @AuraEnabled
        public Boolean hasFeaturedAd{
            get{
                return this.megaMenuItem != null && String.isNotBlank(this.megaMenuItem.FeaturedAd__c);
            } 
            private set;
        }
        public WebshopMegaMenuWrapper(WebshopMegaMenuItem__c megaMenuItem, Boolean disabled, String targetUrl){
            this.megaMenuItem = megaMenuItem;
            this.disabled = disabled;
            this.id = megaMenuItem.Id;
            this.children = new List<WebshopMegaMenuWrapper>();
            this.featuredChildren = new List<WebshopMegaMenuWrapper>();
            this.targetUrl = targetUrl;
            this.label = UserInfo.getLanguage().startsWith('de') ? megaMenuItem.GermanLabel__c : megaMenuItem.EnglishLabel__c;
            this.subheader = UserInfo.getLanguage().startsWith('de') ? megaMenuItem.SubheaderGerman__c : megaMenuItem.Subheader__c;
            this.subheaderFeatured = UserInfo.getLanguage().startsWith('de') ? megaMenuItem.FeaturedSubheaderGerman__c : megaMenuItem.FeaturedSubheader__c;
        }
    }
    public without sharing class WebshopCategoryWrapper {
        @AuraEnabled
        public ProductCategory category { get; set; }
        @AuraEnabled
        public List<WebshopBreadcrumbWrapper> breadcrumbs { get; set; }
        public WebshopCategoryWrapper(ProductCategory category, List<WebshopBreadcrumbWrapper> breadcrumbs) { 
            this.category = category;
            this.breadcrumbs = breadcrumbs;
        }
    }
    public without sharing class WebshopBreadcrumbWrapper {
        @AuraEnabled
        public Boolean hasLink { get; set; }
        @AuraEnabled
        public String value { get; set; }
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String type { get; set; }
        public WebshopBreadcrumbWrapper(String value, String label, String type) { 
            this.value = value;
            this.label = label;
            this.type = type;
            this.hasLink = String.isNotBlank(this.value);
        }
    }
    public without sharing class WebshopProductWrapper implements Comparable {
        public Integer compareTo(Object obj) {
            if (obj instanceOf WebshopProductWrapper) {
                WebshopProductWrapper that = (WebshopProductWrapper)obj;
                return Decimal.valueOf(this.price) - Decimal.valueOf(that.price) > 0 ? 1 : 0;
            }
            return 0;
        }
        @AuraEnabled
        public Product2 product { get; set; }
        @AuraEnabled
        public List<WebshopBreadcrumbWrapper> breadcrumbs { get; set; }
        @AuraEnabled
        public Boolean inWishlist { get; set; }
        @AuraEnabled
        public Boolean hasRelatedProducts { get; set; }
        @AuraEnabled
        public String productId { get; set; }
        @AuraEnabled
        public String price { get; set; }        
        @AuraEnabled
        public Integer threshold = YELLOW_GREEN_THRESHOLD;
        public WebshopProductWrapper() { 
            this.product = null;
            this.productId = null;
            this.price = '0.00';
            this.inWishlist = false;
            this.hasRelatedProducts = false;
        }
        public WebshopProductWrapper(String productId, Decimal price) { 
            this.productId = productId;
            this.price = price != null ? String.valueOf(price.setScale(2)) : '0.00';
        }
        // From Single Product Page
        public WebshopProductWrapper(Product2 product, Decimal price, Boolean inWishlist) {
            this.product = product;
            this.productId = product.id;
            this.price = price != null ? String.valueOf(price.setScale(2)) : '0.00';
            this.inWishlist = inWishlist;
            this.breadcrumbs = new List<WebshopBreadcrumbWrapper>();
            String productCode = product.ProductCode;
            this.hasRelatedProducts = ![SELECT Id FROM WebshopProductLink__c WHERE Product1__c = : product.id OR Product2__c = : product.id].isEmpty();
            if(productCode != null){
                List<ProductCategoryProduct> pcpList = [SELECT Id, ProductCategoryId, ProductCategory.Name, ProductCategory.ParentCategoryId, ProductCategory.ParentCategory.Name, 
                    ProductCategory.ParentCategory.ParentCategoryId, ProductCategory.ParentCategory.ParentCategory.Name, 
                    ProductCategory.ParentCategory.ParentCategory.ParentCategoryId, ProductCategory.ParentCategory.ParentCategory.ParentCategory.Name
                    FROM ProductCategoryProduct WHERE Product.ProductCode = : productCode AND ProductCategory.ParentCategoryId != NULL ORDER BY CreatedDate LIMIT 1];
                if(!pcpList.isEmpty()){
                    ProductCategoryProduct pcp = pcpList[0];
                    if(String.isNotBlank(pcp.ProductCategory.ParentCategory.ParentCategory.ParentCategoryId)){
                        this.breadcrumbs.add(new WebshopBreadcrumbWrapper(pcp.ProductCategory.ParentCategory.ParentCategory.ParentCategoryId, pcp.ProductCategory.ParentCategory.ParentCategory.ParentCategory.Name, 'Category'));
                    }
                    if(String.isNotBlank(pcp.ProductCategory.ParentCategory.ParentCategoryId)){
                        this.breadcrumbs.add(new WebshopBreadcrumbWrapper(pcp.ProductCategory.ParentCategory.ParentCategoryId, pcp.ProductCategory.ParentCategory.ParentCategory.Name, 'Category'));
                    }
                    if(String.isNotBlank(pcp.ProductCategory.ParentCategoryId)){
                        this.breadcrumbs.add(new WebshopBreadcrumbWrapper(pcp.ProductCategory.ParentCategoryId, pcp.ProductCategory.ParentCategory.Name, 'Category'));
                    }
                    this.breadcrumbs.add(new WebshopBreadcrumbWrapper(pcp.ProductCategoryId, pcp.ProductCategory.Name, 'Category'));
                }
            }
        }
        public WebshopProductWrapper(Product2 product, String price, Boolean inWishlist) {
            this.product = product;
            this.productId = product.id;
            this.price = price;
            this.inWishlist = inWishlist;
        }
    }
    public without sharing class CategoryOptionWrapper {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public Integer count { get; set; }
        @AuraEnabled
        public String parentId { get; set; }
        @AuraEnabled
        public String parentParentId { get; set; }
        @AuraEnabled
        public String parentParentParentId { get; set; }
        @AuraEnabled
        public String parentParentParentParentId { get; set; }
        @AuraEnabled
        public List<CategoryOptionWrapper> children { get; set; }
        public CategoryOptionWrapper(String id, String name, String parentId, String parentParentId, String parentParentParentId, String parentParentParentParentId, Integer count) {
            this.id = id;
            this.name = name;
            this.parentId = parentId;
            this.parentParentId = parentParentId;
            this.parentParentParentId = parentParentParentId;
            this.parentParentParentParentId = parentParentParentParentId;
            this.count = count;
            this.children = new List<CategoryOptionWrapper>();
        }
    }
    public without sharing class WebshopSliderFilterWrapper implements Comparable {
        public Integer compareTo(Object obj) {
            if (obj instanceOf WebshopSliderFilterWrapper) {
                WebshopSliderFilterWrapper that = (WebshopSliderFilterWrapper)obj;
                return Decimal.valueOf(this.order) - Decimal.valueOf(that.order) > 0 ? 1 : 0;
            }
            return 0;
        }
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String fieldApiName { get; set; }
        @AuraEnabled
        public Boolean isMultiselectType { get; set; }
        @AuraEnabled
        public Boolean isRangeType { get; set; }
        @AuraEnabled
        public Boolean isPriceType { get; set; }
        @AuraEnabled
        public Boolean isBooleanType { get; set; }
        @AuraEnabled
        public Boolean isCategoryType { get; set; }
        @AuraEnabled
        public Boolean hasTrueVal { get; set; }
        @AuraEnabled
        public Decimal minVal { get; set; }
        @AuraEnabled
        public Decimal maxVal { get; set; }
        @AuraEnabled
        public Integer order { get; set; }
        @AuraEnabled
        public List<String> availableOptions { get; set; }
        @AuraEnabled
        public List<CategoryOptionWrapper> availableCategoryOptions { get; set; }
        @AuraEnabled
        public Boolean show{
            get{
                return 
                (this.isBooleanType && this.hasTrueVal) ||
                ((this.isPriceType || this.isRangeType) && this.minVal != null && this.maxVal != null && this.minVal != this.maxVal) ||
                (this.isMultiselectType && this.availableOptions.size() > 0) ||
                (this.isCategoryType && this.availableCategoryOptions.size() > 0);
            } 
            private set;
        }
    
        public WebshopSliderFilterWrapper(String label, String fieldApiName, Boolean isMultiselectType, Boolean isRangeType, Boolean isBooleanType, Boolean isPriceType, Boolean isCategoryType, Integer order) {
            this.label = label;
            this.fieldApiName = fieldApiName;
            this.isMultiselectType = isMultiselectType;
            this.isRangeType = isRangeType;
            this.isPriceType = isPriceType;
            this.isBooleanType = isBooleanType;
            this.isCategoryType = isCategoryType;
            this.minVal = null;
            this.maxVal = null;
            this.hasTrueVal = false;
            this.availableOptions = this.isBooleanType ? new List<String>{System.Label.GeneralYes, System.Label.GeneralNo} : new List<String>();
            this.availableCategoryOptions = new List<CategoryOptionWrapper>();
            this.order = order;
        }
    }
    public without sharing class InvoiceWrapper {
        @AuraEnabled
        public Invoice invoice { get; set; }
        @AuraEnabled
        public List<InvoiceProductWrapper> products { get; set; }
        public InvoiceWrapper(Invoice invoice) {
            this.invoice = invoice;
            this.products = new List<InvoiceProductWrapper>();
        }
    }
    public without sharing class InvoiceProductWrapper {
        @AuraEnabled
        public InvoiceLine invoiceProduct { get; set; }
        @AuraEnabled
        public String price { get; set; }
        @AuraEnabled
        public Boolean inWishlist { get; set; }
        @AuraEnabled
        public Boolean hasImage{
            get{
                return String.isNotBlank(this.invoiceProduct?.Product2?.WebshopImageURL__c);
            } 
            private set;
        }
        @AuraEnabled
        public Boolean hasProduct{
            get{
                return String.isNotBlank(this.invoiceProduct?.Product2Id);
            } 
            private set;
        }
        public InvoiceProductWrapper(InvoiceLine invoiceProduct, Set<String> wishlistItems) {
            this.invoiceProduct = invoiceProduct;
            this.price = '';
            this.inWishlist = wishlistItems.contains(invoiceProduct.Id);
        }
    }

    public without sharing class ERPResponseTaxWrapper {
        @AuraEnabled
        public Decimal taxRate { get; set; }
        @AuraEnabled
        public Decimal taxTotalAmount { get; set; }
        @AuraEnabled
        public String currencyIsoCode { get; set; }
        public ERPResponseTaxWrapper(Decimal taxRate, Decimal taxTotalAmount, String currencyIsoCode) {
            this.taxRate = taxRate;
            this.taxTotalAmount = taxTotalAmount;
            this.currencyIsoCode = currencyIsoCode;
        }
    }
    public without sharing class ERPResponseInnerWrapper {
        @AuraEnabled
        public Boolean hasImage { get; set; }
        @AuraEnabled
        public CartItem cartItem { get; set; }
        @AuraEnabled
        public Map<String, Object> orderItem { get; set; }
        @AuraEnabled
        public Boolean hasPromotion { get; set; }
        @AuraEnabled
        public Boolean freeItem { get; set; }
        @AuraEnabled
        public Boolean differentAmounts { get; set; }
        public ERPResponseInnerWrapper(CartItem cartItem, Map<String, Object> orderItem) {
            this.cartItem = cartItem;
            this.orderItem = orderItem;
            this.hasImage = cartItem != null && cartItem.Product2 != null && String.isNotBlank(cartItem.Product2.WebshopImageURL__c);
            this.hasPromotion = cartItem.TotalPromoAdjustmentAmount != null && cartItem.TotalPromoAdjustmentAmount < 0;
            this.freeItem = cartItem.FreeItem__c || cartItem.CartFreeItem__c || cartItem.LetterCampaignFreeItem__c;
            this.differentAmounts = (!orderItem.containsKey('TotalPrice') || cartItem.TotalLineAmount != ((Decimal)orderItem.get('TotalPrice'))) &&
                                    (!orderItem.containsKey('UnitPrice') || cartItem.SalesPrice != ((Decimal)orderItem.get('UnitPrice')));
        }
        public ERPResponseInnerWrapper(Map<String, Object> orderItem) {
            this.cartItem = null;
            this.orderItem = orderItem;
            this.hasImage = false;
            this.hasPromotion = false;
            this.freeItem = false;
            this.differentAmounts = false;
        }
    }

    public without sharing class ERPResponseWrapper {
        @AuraEnabled
        public Boolean success { get; set; }
        @AuraEnabled
        public String errorMessage { get; set; }
        @AuraEnabled
        public String errorLoggingId { get; set; }
        @AuraEnabled
        public Map<String, Object> order { get; set; }
        @AuraEnabled
        public Integer paymentTermsDays { get; set; }
        @AuraEnabled
        public Decimal paymentTermsPercent { get; set; }
        @AuraEnabled
        public Decimal totalCartAmount { get; set; }
        @AuraEnabled
        public Boolean hasPaymentTerms { get; set; }
        @AuraEnabled
        public Boolean hasActualPaymentTerms { get; set; }
        @AuraEnabled
        public Boolean hasTaxItems { get; set; }
        @AuraEnabled
        public Boolean hasSuccessfulItems { get; set; }
        @AuraEnabled
        public Boolean hasPriceDifference { get; set; }
        @AuraEnabled
        public Boolean hasTotalPriceDifference { get; set; }
        @AuraEnabled
        public List<ERPResponseInnerWrapper> successfulItems { get; set; }
        @AuraEnabled
        public List<ERPResponseTaxWrapper> taxItems { get; set; }
        
        // From Order Mask
        public ERPResponseWrapper(String errorMessage, String errorLoggingId) {
            this.errorMessage = errorMessage;
            this.errorLoggingId = errorLoggingId;
            this.success = false;
        }

        public ERPResponseWrapper(Map<String, Object> order, List<ERPResponseInnerWrapper> successfulItems) {
            this.errorMessage = null;
            this.success = true;
            this.order = order;
            this.successfulItems = successfulItems;
            this.hasSuccessfulItems = !successfulItems.isEmpty();
            this.hasPriceDifference = false;
            for(ERPResponseInnerWrapper successfulItem : successfulItems){
                if(successfulItem.differentAmounts){
                    this.hasPriceDifference = true;
                    break;
                }
            }
            this.hasTotalPriceDifference = false; 
            this.taxItems = new List<ERPResponseTaxWrapper>();
            if(order.containsKey('OrderTotalTax__c')){
                for(Object taxObj : (List<Object>) order.get('OrderTotalTax__c')){
                    Map<String, Object> taxMap = (Map<String, Object>) taxObj;
                    if(taxMap != null && taxMap.containsKey('TaxRate__c') && taxMap.containsKey('TaxTotalAmount__c') && taxMap.containsKey('CurrencyIsoCode')){
                        ERPResponseTaxWrapper taxWrapper = new ERPResponseTaxWrapper(
                            ((Decimal) taxMap.get('TaxRate__c')) * 100,
                            (Decimal) taxMap.get('TaxTotalAmount__c'),
                            (String) taxMap.get('CurrencyIsoCode')
                        );
                        this.taxItems.add(taxWrapper);
                    }
                }
            }
            this.hasTaxItems = this.taxItems.size() > 0;
        }
        
        public ERPResponseWrapper(Map<String, Object> order, Decimal totalCartAmount, List<ERPResponseInnerWrapper> successfulItems) {
            this(order, successfulItems);
            this.totalCartAmount = totalCartAmount;
            this.hasTotalPriceDifference = true; 
            if(order.containsKey('TotalAmount')){
                if(((Decimal) order.get('TotalAmount')).setScale(2) == this.totalCartAmount.setScale(2)){
                    this.hasTotalPriceDifference = false;
                }
            }
        }
        // With Account
        public ERPResponseWrapper(Account ac, Map<String, Object> order, Decimal totalCartAmount, List<ERPResponseInnerWrapper> successfulItems) {
            this(order, totalCartAmount, successfulItems);
            this.hasPaymentTerms = false;
            this.hasActualPaymentTerms = false;
            if(String.isNotBlank(ac.ERPPaymentTerms__c)){
                PaymentTermsMapping__mdt mapping = PaymentTermsMapping__mdt.getAll().get(ac.ERPPaymentTerms__c);
                if(mapping != null){
                    this.hasPaymentTerms = true;
                    System.debug(mapping);
                    this.paymentTermsDays = mapping.Days__c != null ? Integer.valueOf(mapping.Days__c) : null;
                    this.paymentTermsPercent = mapping.SkontoPercent__c;
                    this.hasActualPaymentTerms = this.paymentTermsDays != null && this.paymentTermsDays > 0 && this.paymentTermsPercent != null && this.paymentTermsPercent > 0;
                }
            }
        }
    }

    public without sharing class OrderWrapper {
        @AuraEnabled
        public Order order { get; set; }
        @AuraEnabled
        public List<OrderProductWrapper> products { get; set; }
        public OrderWrapper(Order order) {
            this.order = order;
            this.products = new List<OrderProductWrapper>();
        }
    }
    
    public without sharing class OrderProductWrapper {
        @AuraEnabled
        public OrderItem orderProduct { get; set; }
        @AuraEnabled
        public Decimal price { get; set; }
        @AuraEnabled
        public Boolean inWishlist { get; set; }
        @AuraEnabled
        public Boolean hasImage{
            get{
                return String.isNotBlank(this.orderProduct?.Product2?.WebshopImageURL__c);
            } 
            private set;
        }
        public OrderProductWrapper(OrderItem orderProduct, Set<String> wishlistItems) {
            this.orderProduct = orderProduct;
            this.price = orderProduct.TotalPrice;
            this.inWishlist = wishlistItems.contains(orderProduct.Id);
        }
    }
    public without sharing class WebshopProductSuperiorWrapper {
        @AuraEnabled
        public List<WebshopSliderFilterWrapper> filters { get; set; }
        @AuraEnabled
        public List<WebshopProductWrapper> data { get; set; }
        @AuraEnabled
        public Set<String> recordIds { get; set; }
        @AuraEnabled
        public Set<String> productIdsPreWithPricesKeys { get; set; }
        @AuraEnabled
        public Integer total { get; set; }
        @AuraEnabled
        public Integer threshold = YELLOW_GREEN_THRESHOLD;
        @AuraEnabled
        public Boolean showPagination{
            get{
                return this.total > RECORDS_PER_PAGE;
            } 
            private set;
        }
        public WebshopProductSuperiorWrapper() {
            //this.filters = new List<WebshopSliderFilterWrapper>();
            this.data = new List<WebshopProductWrapper>();
            this.total = 0;
            this.recordIds = new Set<String>();
            this.productIdsPreWithPricesKeys = new Set<String>();
        }
        public WebshopProductSuperiorWrapper(List<WebshopProductWrapper> data, Integer total, Integer offset, Set<String> recordIds, Set<String> productIdsPreWithPricesKeys) {
            this.data = data;
            this.total = total;
            //this.filters = new List<WebshopSliderFilterWrapper>();
            this.recordIds = recordIds;
            this.productIdsPreWithPricesKeys = productIdsPreWithPricesKeys;
        }
    }
    public without sharing class CartItemWrapper {
        @AuraEnabled
        public Boolean inWishlist { get; set; }
        @AuraEnabled
        public CartItem cartItem { get; set; }
        @AuraEnabled
        public List<Map<String, String>> quantityOptions { get; set; }
        @AuraEnabled
        public Boolean isRemoved { get; set; }
        @AuraEnabled
        public Boolean hasImage{
            get{
                return String.isNotBlank(this.cartItem?.Product2?.WebshopImageURL__c);
            } 
            private set;
        }
        public CartItemWrapper(CartItem cartItem, Boolean inWishlist) {
            this.cartItem = cartItem;
            this.inWishlist = inWishlist;
            this.isRemoved = false;
            this.quantityOptions = new List<Map<String, String>>();
        }
    }
    public without sharing class OptionSuperiorWrapper {
        @AuraEnabled
        public List<OptionWrapper> accountOptions { get; set; }
        @AuraEnabled
        public String mainAccountOption { get; set; }
        public OptionSuperiorWrapper(List<OptionWrapper> accountOptions, String mainAccountOption) {
            this.accountOptions = accountOptions;
            this.mainAccountOption = mainAccountOption;
        }
    }
    public without sharing class OptionWrapper {
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String value { get; set; }
        @AuraEnabled
        public Boolean selected { get; set; }
        public OptionWrapper(String label, String value, Boolean selected) {
            this.label = label;
            this.value = value;
            this.selected = selected;
        }
    }
    public without sharing class SelfServiceStatsWrapper {
        @AuraEnabled
        public Integer orderCount { get; set; }
        @AuraEnabled
        public Integer individualItemCount { get; set; }
        @AuraEnabled
        public Integer ordersInProgressCount { get; set; }
    }
    public without sharing class TeamMemberWrapper {
        @AuraEnabled
        public String userId { get; set; }
        @AuraEnabled
        public String function { get; set; }
        @AuraEnabled
        public String contactId { get; set; }
        @AuraEnabled
        public String firstName { get; set; }
        @AuraEnabled
        public String lastName { get; set; }
        @AuraEnabled
        public String smallPhotoUrl { get; set; }
        @AuraEnabled
        public String email { get; set; }
        @AuraEnabled
        public Boolean webshopActivated { get; set; }
        @AuraEnabled
        public Boolean manager { get; set; }
        @AuraEnabled
        public Boolean delegated { get; set; }
        @AuraEnabled
        public Boolean deleteable { get; set; }
        @AuraEnabled
        public Boolean assortmentExtensionExcluded { get; set; }
        @AuraEnabled
        public Boolean priceVisible { get; set; }
        @AuraEnabled
        public List<Map<String, String>> switchOptions { get; set; }
        @AuraEnabled
        public String fuilName{
            get{
                return (String.isNotBlank(this.firstName) ? this.firstName + ' ' : '') + this.lastName; 
            } 
            private set;
        }
        @AuraEnabled
        public Boolean hasSwitchOptions{
            get{
                return !this.switchOptions.isEmpty();
            } 
            private set;
        }
        @AuraEnabled
        public Boolean hasUserId{
            get{
                return String.isNotBlank(this.userId);
            } 
            private set;
        }
        @AuraEnabled
        public Boolean hasImage{
            get{
                return String.isNotBlank(this.smallPhotoUrl);
            } 
            private set;
        }
        @AuraEnabled
        public String recordName{
            get{
                return String.isNotBlank(this.firstName) ? this.firstName + ' ' + this.lastName : this.lastName;
            } 
            private set;
        }
        public TeamMemberWrapper(String userId, String contactId, String firstName, String lastName, String email, Boolean webshopActivated, String smallPhotoUrl, Boolean manager, Boolean priceVisible, Boolean assortmentExtensionExcluded, Boolean delegated, String function, Boolean deleteable) {
            this.userId = userId;
            this.contactId = contactId;
            this.firstName = firstName;
            this.lastName = lastName;
            this.email = email;
            this.webshopActivated = webshopActivated;
            this.smallPhotoUrl = smallPhotoUrl;
            this.manager = manager;
            this.priceVisible = priceVisible;
            this.assortmentExtensionExcluded = assortmentExtensionExcluded;
            this.delegated = delegated;
            this.function = function;
            this.deleteable = deleteable;
            this.switchOptions = new List<Map<String, String>>();
        }
    }
}