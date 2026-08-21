public class BatchPopulateBrandAssortmentExtension implements Database.Batchable<sObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String compareStr = System.Label.WebshopDoNotTranslateAssortmentExtensionBrandPrefix + '%';
        delete [SELECT Id FROM CommerceEntitlementProduct WHERE Policy.Name LIKE : compareStr];
        return Database.getQueryLocator('SELECT Id, ProductId, ProductCategoryId, Product.BrandWebshop__c ' +
                    'FROM ProductCategoryProduct WHERE Product.BrandWebshop__c != NULL AND Product.IsActive = TRUE AND Product.ProductClass = \'VariationParent\' AND (' +
                    'ProductCategory.Name = \'Food-Zubehör\' OR ProductCategory.Name = \'Non-Food-Zubehör\' OR '  +
                    'ProductCategory.ParentCategory.Name = \'Food-Zubehör\' OR ProductCategory.ParentCategory.Name = \'Non-Food-Zubehör\' OR ' +
                    'ProductCategory.ParentCategory.ParentCategory.Name = \'Food-Zubehör\' OR ProductCategory.ParentCategory.ParentCategory.Name = \'Non-Food-Zubehör\' OR ' +
                    'ProductCategory.ParentCategory.ParentCategory.ParentCategory.Name = \'Food-Zubehör\' OR ProductCategory.ParentCategory.ParentCategory.ParentCategory.Name = \'Non-Food-Zubehör\')'
                    );
    }
    
    public void execute(Database.BatchableContext bc, List<ProductCategoryProduct> scope) {
        Map<Id, Id> brandToPolicyMap = new Map<Id, Id>();
        for(ProductCategoryProduct pcp : scope){
            brandToPolicyMap.put(pcp.Product.BrandWebshop__c, null);
        }
        for(CommerceEntitlementPolicy cep : [SELECT Id, Brand__c FROM CommerceEntitlementPolicy WHERE Brand__c IN : brandToPolicyMap.keySet()]){
            brandToPolicyMap.put(cep.Brand__c, cep.Id);
        }
        List<CommerceEntitlementProduct> productsToInsert = new List<CommerceEntitlementProduct>();
        for(ProductCategoryProduct pcp : scope){
            if(brandToPolicyMap.get(pcp.Product.BrandWebshop__c) != null){
                CommerceEntitlementProduct entitlementProduct = new CommerceEntitlementProduct();
                entitlementProduct.PolicyId = brandToPolicyMap.get(pcp.Product.BrandWebshop__c);
                entitlementProduct.ProductId = pcp.ProductId;
                entitlementProduct.DoNotDelete__c = true;
                productsToInsert.add(entitlementProduct);
            }
        }
        Database.insert(productsToInsert, false);
    }

    public void finish(Database.BatchableContext bc){ 
        Database.executeBatch(new BatchPopulateBrandAssortmentChildren(), 100);
     }
}