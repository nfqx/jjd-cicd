public class MigrationWebshopProductLinkJob implements Queueable, Database.AllowsCallouts {

    public void execute(QueueableContext context){

        /*
         * STEP 1: TARGET PRODUCTS (FLAT MAP)
         */
        Map<String, Id> targetByProductCode = new Map<String, Id>();

        for(Product2 p : [
            SELECT Id, OldProductNumber__c
            FROM Product2
            WHERE OldProductNumber__c != NULL
        ]){
            targetByProductCode.put(p.OldProductNumber__c, p.Id);
        }

        if(targetByProductCode.isEmpty()) return;

        /*
         * STEP 2: SOURCE PARENTS (Product Code → ParentId)
         */
        List<Object> parents = SourceOrgApi.query(
            'SELECT Id, ProductCode FROM Product2'
        );

        Map<String, String> parentByProductCode = new Map<String, String>();
        Map<String, String> parentIdToProductCode = new Map<String, String>();

        for(Object row : parents){
            Map<String,Object> m = (Map<String,Object>)row;

            String id = (String)m.get('Id');
            String productCode = (String)m.get('ProductCode');

            if(productCode != null){
                parentByProductCode.put(productCode, id);
                parentIdToProductCode.put(id, productCode);
            }
        }

        Set<String> parentIds = new Set<String>(parentByProductCode.values());

        /*
         * STEP 3: CHILD → PARENT mapping
         */
        List<Object> attrs = SourceOrgApi.query(
            'SELECT ProductId, VariantParentId ' +
            'FROM ProductAttribute'
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

        Set<String> childIds = childToParent.keySet();

        /*
         * STEP 4: CHILD → CHILD LINKS
         */
        List<Object> rawLinks = SourceOrgApi.query(
            'SELECT Product1__c, Product2__c ' +
            'FROM WebshopProductLink__c'
        );

        /*
         * STEP 5: COLLAPSE TO PARENT LINKS
         */
        Set<String> parentLinks = new Set<String>();

        for(Object row : rawLinks){

            Map<String,Object> m = (Map<String,Object>)row;

            String c1 = (String)m.get('Product1__c');
            String c2 = (String)m.get('Product2__c');

            String p1 = childToParent.get(c1);
            String p2 = childToParent.get(c2);

            if(p1 == null || p2 == null) continue;
            if(p1 == p2) continue;

            parentLinks.add(p1 + '-' + p2);
        }

        /*
         * STEP 6: TARGET INSERT (PRODUCT CODE MAPPED)
         */
        List<WebshopProductLink__c> inserts = new List<WebshopProductLink__c>();
        Set<String> seen = new Set<String>();

        for(String link : parentLinks){

            List<String> parts = link.split('-');
            String p1 = parts[0];
            String p2 = parts[1];

            String productCode1 = parentIdToProductCode.get(p1);
            String productCode2 = parentIdToProductCode.get(p2);

            if(productCode1 == null || productCode2 == null) continue;

            if(!targetByProductCode.containsKey(productCode1) || !targetByProductCode.containsKey(productCode2)) continue;

            Id t1 = targetByProductCode.get(productCode1);
            Id t2 = targetByProductCode.get(productCode2);

            String key = t1 + '-' + t2;
            if(seen.contains(key)) continue;
            seen.add(key);

            inserts.add(new WebshopProductLink__c(
                Product1__c = t1,
                Product2__c = t2
            ));
        }

        if(!inserts.isEmpty()){
            Database.insert(inserts, false);
        }

        /*
         * STEP 7: CHAIN NEXT JOB
         */
        System.enqueueJob(new MigrationWebshopBrandLinkJob());
    }
}