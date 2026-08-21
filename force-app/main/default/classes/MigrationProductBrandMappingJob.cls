public class MigrationProductBrandMappingJob implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([
            SELECT Id,
                OldProductNumber__c,
                BrandWebshop__c,
                PackageUnit__c, Description, Ingredients__c,
                Allergens__c, NutritionalValue__c, ProductSubtitle__c
            FROM Product2
            WHERE OldProductNumber__c != NULL
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope){

        List<Product2> products = (List<Product2>)scope;

        Set<String> identifiers = new Set<String>();

        for(Product2 p : products){
            identifiers.add(p.OldProductNumber__c);
        }

        if(identifiers.isEmpty()) return;

        List<Object> records = SourceOrgApi.query(
            'SELECT ProductCode, Brand_Webshop__r.Name, ' +
            'Package_Unit__c, Description, Ingredients__c, Product_subtitel__c, ' +
            'Allergens__c, Nutritional_Value__c ' +
            'FROM Product2 WHERE ProductCode IN (\'' +
            String.join(new List<String>(identifiers), '\',\'') + '\')'
        );

        Map<String,String> brandByProductCode = new Map<String,String>();
        Map<String,Map<String,Object>> dataByProductCode = new Map<String,Map<String,Object>>();

        for(Object rowPre : records){
            Map<String,Object> row = (Map<String,Object>)rowPre;

            String productCode = (String)row.get('ProductCode');
            if(productCode == null) continue;

            dataByProductCode.put(productCode, row);

            Map<String,Object> brand =
                (Map<String,Object>)row.get('Brand_Webshop__r');

            if(brand != null){
                brandByProductCode.put(productCode, (String)brand.get('Name'));
            }
        }

        Map<String,Id> brandByName = new Map<String,Id>();
        for(WebshopBrand__c b : [SELECT Id, Name FROM WebshopBrand__c]){
            brandByName.put(b.Name, b.Id);
        }

        List<Product2> updates = new List<Product2>();

        for(Product2 p : products){

            String key = p.OldProductNumber__c;

            if(!dataByProductCode.containsKey(key)) continue;

            Map<String,Object> source = dataByProductCode.get(key);

            Boolean changed = false;

            // Brand mapping
            if(brandByProductCode.containsKey(key)){
                String brandName = brandByProductCode.get(key);
                if(brandByName.containsKey(brandName)){
                    Id brandId = brandByName.get(brandName);
                    if(p.BrandWebshop__c != brandId){
                        p.BrandWebshop__c = brandId;
                        changed = true;
                    }
                }
            }

            // Field mappings
            if(p.PackageUnit__c != (String)source.get('Package_Unit__c')){
                p.PackageUnit__c = (String)source.get('Package_Unit__c');
                changed = true;
            }

            if(p.Description != (String)source.get('Description')){
                p.Description = (String)source.get('Description');
                changed = true;
            }

            if(p.Ingredients__c != (String)source.get('Ingredients__c')){
                p.Ingredients__c = (String)source.get('Ingredients__c');
                changed = true;
            }

            if(p.ProductSubtitle__c != (String)source.get('Product_subtitel__c')){
                p.ProductSubtitle__c = (String)source.get('Product_subtitel__c');
                changed = true;
            }

            if(p.Allergens__c != (String)source.get('Allergens__c')){
                p.Allergens__c = (String)source.get('Allergens__c');
                changed = true;
            }

            if(p.NutritionalValue__c != (String)source.get('Nutritional_Value__c')){
                p.NutritionalValue__c = (String)source.get('Nutritional_Value__c');
                changed = true;
            }

            if(changed){
                updates.add(p);
            }
        }

        if(!updates.isEmpty()){
            Database.update(updates, false);
        }
    }

    public void finish(Database.BatchableContext bc){
        Database.executeBatch(new MigrationProductCategoryLinkJob(), 200);
    }
}