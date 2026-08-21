public class MigrationWebshopBrandLinkJob implements Queueable, Database.AllowsCallouts {

    public void execute(QueueableContext context){

        /*
         * STEP 1: TARGET (OLD PRODUCT CODE → Product)
         */
        Map<String, Id> targetByProductCode = new Map<String, Id>();

        for(Product2 p : [            
            SELECT Id,
                OldProductNumber__c
            FROM Product2
            WHERE OldProductNumber__c != NULL
        ]){
            targetByProductCode.put(p.OldProductNumber__c, p.Id);
        }

        if(targetByProductCode.isEmpty()) return;

        /*
         * STEP 2: SOURCE RAW BRAND LINKS
         */
        List<Object> raw = SourceOrgApi.query(
            'SELECT Produkt__c, Brand__r.Name ' +
            'FROM Webshop_Brand_Link__c'
        );

        Set<String> sourceProductIds = new Set<String>();

        for(Object row : raw){
            Map<String,Object> m = (Map<String,Object>)row;
            sourceProductIds.add((String)m.get('Produkt__c'));
        }

        /*
         * STEP 3: CHILD → PARENT mapping
         */
        List<Object> attrs = SourceOrgApi.query(
            'SELECT ProductId, VariantParentId ' +
            'FROM ProductAttribute '
        );

        Map<String, String> childToParent = new Map<String, String>();

        for(Object row : attrs){
            Map<String,Object> m = (Map<String,Object>)row;

            String child = (String)m.get('ProductId');
            String parent = (String)m.get('VariantParentId');

            if(child != null && parent != null){
                childToParent.put(child, parent);
            }
        }

        Set<String> parentIds = new Set<String>(childToParent.values());

        /*
         * STEP 4: SOURCE PARENT PRODUCT CODEs
         */
        List<Object> parents = SourceOrgApi.query(
            'SELECT Id, ProductCode ' +
            'FROM Product2 WHERE ProductCode != NULL'
        );

        Map<String, String> parentProductCode = new Map<String, String>();

        for(Object row : parents){
            Map<String,Object> m = (Map<String,Object>)row;
            parentProductCode.put((String)m.get('Id'), (String)m.get('ProductCode'));
        }

        /*
         * STEP 5: BUILD Product Code → BRAND MAP (PARENT LEVEL ONLY)
         */
        Map<String, Set<String>> brandsByProductCode = new Map<String, Set<String>>();

        for(Object row : raw){

            Map<String,Object> m = (Map<String,Object>)row;

            String productId = (String)m.get('Produkt__c');
            Map<String,Object> brandObj = (Map<String,Object>)m.get('Brand__r');

            if(productId == null || brandObj == null) continue;

            String brandName = (String)brandObj.get('Name');

            String parentId = childToParent.containsKey(productId)
                ? childToParent.get(productId)
                : productId;

            String productCode = parentProductCode.get(parentId);

            if(productCode == null || brandName == null) continue;

            if(!brandsByProductCode.containsKey(productCode)){
                brandsByProductCode.put(productCode, new Set<String>());
            }

            brandsByProductCode.get(productCode).add(brandName);
        }

        if(brandsByProductCode.isEmpty()) return;

        /*
         * STEP 6: TARGET BRAND LOOKUP
         */
        Map<String, Id> brandByName = new Map<String, Id>();

        for(WebshopBrand__c b : [
            SELECT Id, Name FROM WebshopBrand__c
        ]){
            brandByName.put(b.Name, b.Id);
        }

        /*
         * STEP 7: INSERT INTO TARGET
         */
        List<WebshopBrandLink__c> inserts = new List<WebshopBrandLink__c>();
        Set<String> seen = new Set<String>();

        for(String productCode : brandsByProductCode.keySet()){

            if(!targetByProductCode.containsKey(productCode)) continue;

            Id productId = targetByProductCode.get(productCode);

            for(String brandName : brandsByProductCode.get(productCode)){

                if(!brandByName.containsKey(brandName)) continue;

                Id brandId = brandByName.get(brandName);

                String key = productId + '-' + brandId;
                if(seen.contains(key)) continue;
                seen.add(key);

                inserts.add(new WebshopBrandLink__c(
                    Product__c = productId,
                    Brand__c = brandId
                ));
            }
        }

        if(!inserts.isEmpty()){
            Database.insert(inserts, false);
        }
    }
}