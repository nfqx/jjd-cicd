public class BatchAutomateBrandAssortmentExtension implements Database.Batchable<sObject>, Database.Stateful {
    public Map<Id, Id> buyerGroupByBrandMap {get; set;}
    private static final String COFFEE_CATEGORY = 'KAFFEE';
    public Database.QueryLocator start(Database.BatchableContext bc) {
        this.buyerGroupByBrandMap = new Map<Id, Id>();
        for(BuyerGroup bg : [SELECT Id, Brand__c FROM BuyerGroup WHERE Brand__c != NULL]){
            buyerGroupByBrandMap.put(bg.Brand__c, bg.Id);
        }
        delete [SELECT Id FROM BuyerGroupMember WHERE Dynamic__c = TRUE];
        return Test.isRunningTest() ? Database.getQueryLocator('SELECT Id FROM Account') : Database.getQueryLocator('SELECT Id FROM Account WHERE IsWebshopAccount__c = TRUE AND AssortmentExtensionExclusion__c = FALSE');
    }
    
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        List<BuyerGroupMember> buyerGroupMembersToInsert = new List<BuyerGroupMember>();
        
        Set<Id> allBuyerGroupIdsPre = new Set<Id>();
        Set<Id> allBuyerGroupIds = new Set<Id>();
        Set<Id> allPolicyIds = new Set<Id>();
        Set<Id> allProductIds = new Set<Id>();
        Map<Id, Set<Id>> accountsByBuyerGroupPre = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> accountsByBuyerGroup = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> accountsByPolicy = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> policiesByProduct = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> coffeeBrandsByAccount = new Map<Id, Set<Id>>();

        for(BuyerGroupMember bgm : [SELECT Id, BuyerGroupId, BuyerId FROM BuyerGroupMember WHERE BuyerId IN : scope]){
            Set<Id> innerSet = accountsByBuyerGroupPre.containsKey(bgm.BuyerGroupId) ? accountsByBuyerGroupPre.get(bgm.BuyerGroupId) : new Set<Id>();
            innerSet.add(bgm.BuyerId);
            accountsByBuyerGroupPre.put(bgm.BuyerGroupId, innerSet);
            allBuyerGroupIdsPre.add(bgm.BuyerGroupId);
        }
        for(WebStoreBuyerGroup wsb : [SELECT Id, BuyerGroupId FROM WebStoreBuyerGroup WHERE BuyerGroupId IN : allBuyerGroupIdsPre AND WebStore.Name = : System.Label.WebshopDoNotTranslateStoreName]){
            accountsByBuyerGroup.put(wsb.BuyerGroupId, accountsByBuyerGroupPre.get(wsb.BuyerGroupId));
            allBuyerGroupIds.add(wsb.BuyerGroupId);
        }
        for(CommerceEntitlementBuyerGroup cebg : [SELECT Id, PolicyId, BuyerGroupId FROM CommerceEntitlementBuyerGroup WHERE BuyerGroupId IN : allBuyerGroupIds]){
            Set<Id> innerSet = accountsByPolicy.containsKey(cebg.PolicyId) ? accountsByPolicy.get(cebg.PolicyId) : new Set<Id>();
            Set<Id> buyers = accountsByBuyerGroup.get(cebg.BuyerGroupId);
            if (buyers != null) {
                innerSet.addAll(buyers);
            }
            accountsByPolicy.put(cebg.PolicyId, innerSet);
            allPolicyIds.add(cebg.PolicyId);
        }
        for(CommerceEntitlementProduct cep : [SELECT Id, ProductId, PolicyId FROM CommerceEntitlementProduct WHERE PolicyId IN : allPolicyIds]){
            Set<Id> innerSet = policiesByProduct.containsKey(cep.ProductId) ? policiesByProduct.get(cep.ProductId) : new Set<Id>();
            innerSet.add(cep.PolicyId);
            policiesByProduct.put(cep.ProductId, innerSet);
            allProductIds.add(cep.ProductId);
        }
        Set<Id> brandKeys = this.buyerGroupByBrandMap.keySet();
        for(ProductCategoryProduct pcp : [SELECT Id, ProductId, Product.BrandWebshop__c FROM ProductCategoryProduct WHERE 
        ProductId IN : allProductIds AND Product.BrandWebshop__c != NULL AND Product.BrandWebshop__r.AssortmentExtensionEnabled__c = TRUE AND
        Product.BrandWebshop__c IN : brandKeys AND
        (
            ProductCategory.Name = : COFFEE_CATEGORY 
            OR ProductCategory.ParentCategory.Name = : COFFEE_CATEGORY 
            OR ProductCategory.ParentCategory.ParentCategory.Name = : COFFEE_CATEGORY 
            OR ProductCategory.ParentCategory.ParentCategory.ParentCategory.Name = : COFFEE_CATEGORY
        ) ORDER BY CreatedDate DESC]){
            if(policiesByProduct.get(pcp.ProductId) != null){
                for(Id policyId : policiesByProduct.get(pcp.ProductId)){                            
                    if(accountsByPolicy.get(policyId) != null){
                        for(Id accountId : accountsByPolicy.get(policyId)){                            
                            Set<Id> innerSet = coffeeBrandsByAccount.containsKey(accountId) ? coffeeBrandsByAccount.get(accountId) : new Set<Id>();
                            innerSet.add(pcp.Product.BrandWebshop__c);
                            coffeeBrandsByAccount.put(accountId, innerSet);
                        }
                    }
                }
            }
        }

        for(Id accountId : coffeeBrandsByAccount.keySet()){
            for(Id brandId : coffeeBrandsByAccount.get(accountId)){
                Id brandBuyerGroupId = this.buyerGroupByBrandMap.get(brandId);
                buyerGroupMembersToInsert.add(new BuyerGroupMember(
                    BuyerGroupId = brandBuyerGroupId,
                    BuyerId = accountId,
                    Dynamic__c = TRUE
                ));
            }
        }                

        if(!buyerGroupMembersToInsert.isEmpty()){
            Database.insert(buyerGroupMembersToInsert, false);
        }
    }

    public void finish(Database.BatchableContext bc){ 
        // DO nothing
     }
}