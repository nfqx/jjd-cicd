public class BatchPopulateBrandAssortmentChildren implements Database.Batchable<sObject>, Database.Stateful {

    public static final Id ENTITLEMENT_POLICY_ID = [SELECT Id FROM CommerceEntitlementPolicy WHERE Name = : System.Label.WebshopDoNotTranslateTeaAndCocayaEntPolicy LIMIT 1].Id;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Set<Id> productIds = new Set<Id>();
        for(CommerceEntitlementProduct cep : [SELECT Id, ProductId FROM CommerceEntitlementProduct WHERE PolicyId = : ENTITLEMENT_POLICY_ID]){
            productIds.add(cep.ProductId);
        }
        return Database.getQueryLocator('SELECT Id, ProductId, VariantParentId FROM ProductAttribute WHERE VariantParentId IN : productIds');
    }
    
    public void execute(Database.BatchableContext bc, List<ProductAttribute> scope) {
        List<CommerceEntitlementProduct> productsToInsert = new List<CommerceEntitlementProduct>();
        for(ProductAttribute pa : scope){
            CommerceEntitlementProduct entitlementProduct = new CommerceEntitlementProduct();
            entitlementProduct.PolicyId = ENTITLEMENT_POLICY_ID;
            entitlementProduct.ProductId = pa.ProductId;
            entitlementProduct.DoNotDelete__c = true;
            productsToInsert.add(entitlementProduct);
        }
        Database.insert(productsToInsert, false);
    }

    public void finish(Database.BatchableContext bc){
        if(!Test.isRunningTest()){ B2BSearchIndexRefresher.refreshSearchIndex(); }
    }
}