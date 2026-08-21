public class MigrationProductCategoryLinkJob implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([
            SELECT Id,
                OldProductNumber__c
            FROM Product2
            WHERE OldProductNumber__c != NULL
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope){

        List<Product2> products = (List<Product2>)scope;

        Set<String> productCodes = new Set<String>();

        for(Product2 p : products){
            productCodes.add(p.OldProductNumber__c);
        }

        if(productCodes.isEmpty()) return;

        List<Object> records = SourceOrgApi.query(
            'SELECT Product.ProductCode, ProductCategory.Name ' +
            'FROM ProductCategoryProduct ' +
            'WHERE Product.ProductCode IN (\'' +
            String.join(new List<String>(productCodes), '\',\'') + '\')'
        );

        Map<String,List<String>> categoriesByProductCode = new Map<String,List<String>>();

        for(Object rowPre : records){

            Map<String,Object> row = (Map<String,Object>)rowPre;

            Map<String,Object> prod = (Map<String,Object>)row.get('Product');
            Map<String,Object> cat  = (Map<String,Object>)row.get('ProductCategory');

            if(prod == null || cat == null) continue;

            String productCode = (String)prod.get('ProductCode');
            String name = (String)cat.get('Name');

            if(!categoriesByProductCode.containsKey(productCode)){
                categoriesByProductCode.put(productCode, new List<String>());
            }

            categoriesByProductCode.get(productCode).add(name);
        }

        Map<String,Id> categoryByName = new Map<String,Id>();
        for(ProductCategory c : [SELECT Id, Name FROM ProductCategory]){
            categoryByName.put(c.Name, c.Id);
        }

        List<ProductCategoryProduct> upserts = new List<ProductCategoryProduct>();
        Set<String> uniqueKeys = new Set<String>();

        for(Product2 p : products){

            String key = p.OldProductNumber__c;
            if(!categoriesByProductCode.containsKey(key)) continue;
            for(String catName : categoriesByProductCode.get(key)){
                if(!categoryByName.containsKey(catName)) continue;
                Id categoryId = categoryByName.get(catName);
                String uniqueKey = p.Id + '|' + categoryId;
                if(uniqueKeys.contains(uniqueKey)) continue;
                ProductCategoryProduct link = new ProductCategoryProduct();
                link.ProductId = p.Id;
                link.ProductCategoryId = categoryId;
                link.UniqueKey__c = uniqueKey;

                upserts.add(link);
                uniqueKeys.add(uniqueKey);
            }
        }

        if(!upserts.isEmpty()){
            Database.upsert(upserts, ProductCategoryProduct.UniqueKey__c, false);
        }
    }

    public void finish(Database.BatchableContext bc){
        System.enqueueJob(new MigrationWebshopProductLinkJob());
    }
}