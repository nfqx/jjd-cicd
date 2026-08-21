public with sharing class AccountAllProductsController {

    public class ProductRowDTO {
        @AuraEnabled public Id productId;
        @AuraEnabled public String productName;
        @AuraEnabled public String productUrl;
        @AuraEnabled public String productCode;

        @AuraEnabled public Id groupId;
        @AuraEnabled public String groupName;
        @AuraEnabled public String groupUrl;

        @AuraEnabled public Decimal listPrice;
        @AuraEnabled public Decimal ownPrice;

        @AuraEnabled public Boolean isOwnAssortment;
        @AuraEnabled public Boolean isExtension;
        @AuraEnabled public Boolean isOther;

        @AuraEnabled public String ownAssortmentSourceId;
        @AuraEnabled public String extensionSourceId;
        @AuraEnabled public String otherSourceId;
        @AuraEnabled public String ownAssortmentSourceName;
        @AuraEnabled public String extensionSourceName;
        @AuraEnabled public String otherSourceName;
    }


    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getAccountProducts(Id accountId){

        Map<String,Object> result = new Map<String,Object>();

        Account acc = [
            SELECT Id, AssortmentExtended__c, NumberBrandAssignments__c 
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        Boolean assortmentExtended = acc.AssortmentExtended__c || acc.NumberBrandAssignments__c  > 0;

        Set<Id> buyerGroupIds = new Set<Id>();

        for(BuyerGroupMember bgm :
            [SELECT BuyerGroupId
             FROM BuyerGroupMember
             WHERE BuyerId = :accountId]){

            buyerGroupIds.add(bgm.BuyerGroupId);
        }

        for(WebStoreBuyerGroup wsb :
            [SELECT BuyerGroupId
             FROM WebStoreBuyerGroup
             WHERE BuyerGroupId IN :buyerGroupIds]){

            buyerGroupIds.add(wsb.BuyerGroupId);
        }

        Set<Id> policyIsOwn = new Set<Id>();
        Set<Id> policyIsExtension = new Set<Id>();
        Set<Id> policyIds = new Set<Id>();

        for(CommerceEntitlementPolicy p :
            [SELECT Id, Account__c
             FROM CommerceEntitlementPolicy
             WHERE Account__c = :accountId]){

            policyIds.add(p.Id);
            policyIsOwn.add(p.Id);
        }

        for(CommerceEntitlementBuyerGroup cebg : [SELECT PolicyId, BuyerGroup.Name FROM CommerceEntitlementBuyerGroup WHERE BuyerGroupId IN :buyerGroupIds]){
            policyIds.add(cebg.PolicyId);
            if(cebg.BuyerGroup.Name.startsWith('Sortimentserweiterung')){
                policyIsExtension.add(cebg.PolicyId);
            }
        }

        Map<Id, CommerceEntitlementPolicy> productOwnMap = new Map<Id, CommerceEntitlementPolicy>();
        Map<Id, CommerceEntitlementPolicy> productExtensionMap = new Map<Id, CommerceEntitlementPolicy>();
        Map<Id, CommerceEntitlementPolicy> productOtherMap = new Map<Id, CommerceEntitlementPolicy>();
        Set<Id> productIds = new Set<Id>();

        for(CommerceEntitlementProduct ep : [SELECT ProductId, Policy.Id, Policy.Name FROM CommerceEntitlementProduct WHERE PolicyId IN :policyIds]){
            productIds.add(ep.ProductId);
            if(policyIsOwn.contains(ep.PolicyId)){
                productOwnMap.put(ep.ProductId, ep.Policy);
            }
            if(policyIsExtension.contains(ep.PolicyId)){
                productExtensionMap.put(ep.ProductId, ep.Policy);
            }
            if(!policyIsOwn.contains(ep.PolicyId) && !policyIsExtension.contains(ep.PolicyId)){
                productOtherMap.put(ep.ProductId, ep.Policy);
            }
        }

        Map<Id,Product2> productMap =
            new Map<Id,Product2>([
                SELECT Id,
                       Name,
                       ProductGroup__c,
                       ProductGroup__r.Name,
                       ProductCode
                FROM Product2 WHERE Id IN :productIds AND IsActive = TRUE AND ProductClass IN ('Variation','Simple')
            ]);

        Id standardPb = Test.isRunningTest() ? Test.getStandardPricebookId() : [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1].Id;

        Id accountPb;
        List<Pricebook2> accPb = [SELECT Id FROM Pricebook2 WHERE Account__c = :accountId LIMIT 1];
        if(!accPb.isEmpty()){
            accountPb = accPb[0].Id;
        }

        Map<Id,Decimal> listPrices = new Map<Id,Decimal>();
        Map<Id,Decimal> ownPrices = new Map<Id,Decimal>();

        for(PricebookEntry pbe :
            [SELECT Product2Id, UnitPrice, Pricebook2Id
             FROM PricebookEntry
             WHERE Product2Id IN :productIds
             AND Pricebook2Id IN :new Set<Id>{standardPb, accountPb}]){

            if(pbe.Pricebook2Id == standardPb){
                listPrices.put(pbe.Product2Id,pbe.UnitPrice);
            }

            if(pbe.Pricebook2Id == accountPb){
                ownPrices.put(pbe.Product2Id,pbe.UnitPrice);
            }
        }

        List<ProductRowDTO> rows = new List<ProductRowDTO>();

        for(Product2 p : productMap.values()){

            ProductRowDTO row = new ProductRowDTO();

            row.productId = p.Id;
            row.productName = p.Name;
            row.productUrl = '/' + p.Id;
            row.productCode = p.ProductCode;

            if(p.ProductGroup__c != null){
                row.groupId = p.ProductGroup__c;
                row.groupName = p.ProductGroup__r.Name;
                row.groupUrl = '/' + p.ProductGroup__c;
            }

            row.listPrice = listPrices.get(p.Id);
            row.ownPrice = ownPrices.get(p.Id);
            row.isOwnAssortment = productOwnMap.containsKey(p.Id);
            row.isExtension = productExtensionMap.containsKey(p.Id);
            row.isOther = productOtherMap.containsKey(p.Id);
            row.ownAssortmentSourceId = productOwnMap.containsKey(p.Id) ? '/' + productOwnMap.get(p.Id).Id : null;
            row.extensionSourceId = productExtensionMap.containsKey(p.Id) ? '/' + productExtensionMap.get(p.Id).Id : null;
            row.otherSourceId = productOtherMap.containsKey(p.Id) ? '/' + productOtherMap.get(p.Id).Id : null;
            row.ownAssortmentSourceName = productOwnMap.containsKey(p.Id) ? productOwnMap.get(p.Id).Name : null;
            row.extensionSourceName = productExtensionMap.containsKey(p.Id) ? productExtensionMap.get(p.Id).Name : null;
            row.otherSourceName = productOtherMap.containsKey(p.Id) ? productOtherMap.get(p.Id).Name : null;

            rows.add(row);
        }

        result.put('rows',rows);
        result.put('assortmentExtended',assortmentExtended);

        return result;
    }
    private static Set<Id> getParentProductIds(Set<Id> variationIds){

        Set<Id> parentIds = new Set<Id>();

        for(ProductAttribute pa : [
            SELECT ProductId, VariantParentId
            FROM ProductAttribute
            WHERE ProductId IN :variationIds
        ]){
            if(pa.VariantParentId != null){
                parentIds.add(pa.VariantParentId);
            }
        }

        return parentIds;
    }
    private static CommerceEntitlementPolicy getAccountPolicy(Id accountId){
        return [
            SELECT Id
            FROM CommerceEntitlementPolicy
            WHERE Account__c = :accountId
            LIMIT 1
        ];
    }

    @AuraEnabled
    public static void addEntitlement(Id accountId, Id productId){

        CommerceEntitlementPolicy policy = getAccountPolicy(accountId);

        Set<Id> variationIds = new Set<Id>{productId};

        Set<Id> parentIds = getParentProductIds(variationIds);

        List<CommerceEntitlementProduct> inserts = new List<CommerceEntitlementProduct>();

        // create parent entitlements first
        for(Id parentId : parentIds){
            inserts.add(new CommerceEntitlementProduct(
                PolicyId = policy.Id,
                ProductId = parentId
            ));
        }

        // then variation entitlement
        for(Id varId : variationIds){
            inserts.add(new CommerceEntitlementProduct(
                PolicyId = policy.Id,
                ProductId = varId
            ));
        }

        Database.insert(inserts,false);
    }

    @AuraEnabled
    public static void removeEntitlement(Id accountId, Id productId){

        CommerceEntitlementPolicy policy = getAccountPolicy(accountId);

        Set<Id> variationIds = new Set<Id>{productId};
        Set<Id> parentIds = getParentProductIds(variationIds);

        List<CommerceEntitlementProduct> variationEntitlements = [
            SELECT Id
            FROM CommerceEntitlementProduct
            WHERE PolicyId = :policy.Id
            AND ProductId IN :variationIds
        ];

        delete variationEntitlements;

        if(!parentIds.isEmpty()){

            List<CommerceEntitlementProduct> parentEntitlements = [
                SELECT Id
                FROM CommerceEntitlementProduct
                WHERE PolicyId = :policy.Id
                AND ProductId IN :parentIds
            ];

            Database.delete(parentEntitlements,false);
        }
    }
}