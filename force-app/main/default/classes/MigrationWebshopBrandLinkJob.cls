public class MigrationWebshopBrandLinkJob  implements Database.Batchable<sObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, OldProductNumber__c
            FROM Product2
            WHERE OldProductNumber__c != NULL
            AND ProductClass IN ('Simple', 'Variation')
        ]);
    }

    public void execute(
        Database.BatchableContext bc,
        List<Product2> scope
    ) {
        Map<String, Set<Id>> targetIdsByProductCode =
            MigrationProductMappingUtil.getOwnedTargetIdsByCode(scope);

        if (targetIdsByProductCode.isEmpty()) {
            return;
        }

        /*
         * SOURCE PRODUCTS REPRESENTED BY THIS BATCH
         */
        List<Object> sourceParents =
            MigrationProductMappingUtil.queryRemoteInChunks(
                'SELECT Id, ProductCode FROM Product2',
                'ProductCode',
                targetIdsByProductCode.keySet()
            );

        Map<String, String> sourceParentCodeById =
            new Map<String, String>();

        for (Object row : sourceParents) {
            Map<String, Object> values = (Map<String, Object>) row;

            String productId = (String) values.get('Id');
            String productCode = (String) values.get('ProductCode');

            if (productId != null && productCode != null) {
                sourceParentCodeById.put(productId, productCode);
            }
        }

        if (sourceParentCodeById.isEmpty()) {
            return;
        }

        /*
         * CHILDREN OF THOSE SOURCE PRODUCTS
         */
        List<Object> sourceAttributes =
            MigrationProductMappingUtil.queryRemoteInChunks(
                'SELECT ProductId, VariantParentId FROM ProductAttribute',
                'VariantParentId',
                sourceParentCodeById.keySet()
            );

        Map<String, String> parentByChildId =
            new Map<String, String>();

        for (Object row : sourceAttributes) {
            Map<String, Object> values = (Map<String, Object>) row;

            String childId = (String) values.get('ProductId');
            String parentId = (String) values.get('VariantParentId');

            if (childId != null && parentId != null) {
                parentByChildId.put(childId, parentId);
            }
        }

        Set<String> relevantSourceProductIds = new Set<String>();
        relevantSourceProductIds.addAll(sourceParentCodeById.keySet());
        relevantSourceProductIds.addAll(parentByChildId.keySet());

        /*
         * ONLY RELEVANT SOURCE BRAND LINKS
         */
        List<Object> sourceBrandLinks =
            MigrationProductMappingUtil.queryRemoteInChunks(
                'SELECT Produkt__c, Brand__r.Name ' +
                'FROM Webshop_Brand_Link__c',
                'Produkt__c',
                relevantSourceProductIds
            );

        Map<String, Set<String>> brandsByProductCode =
            new Map<String, Set<String>>();

        Set<String> relevantBrandNames = new Set<String>();

        for (Object row : sourceBrandLinks) {
            Map<String, Object> values = (Map<String, Object>) row;

            String linkedProductId =
                (String) values.get('Produkt__c');

            Map<String, Object> brandValues =
                (Map<String, Object>) values.get('Brand__r');

            if (linkedProductId == null || brandValues == null) {
                continue;
            }

            String brandName = (String) brandValues.get('Name');

            if (String.isBlank(brandName)) {
                continue;
            }

            String parentId = parentByChildId.containsKey(linkedProductId)
                ? parentByChildId.get(linkedProductId)
                : linkedProductId;

            String productCode =
                sourceParentCodeById.get(parentId);

            if (productCode == null) {
                continue;
            }

            if (!brandsByProductCode.containsKey(productCode)) {
                brandsByProductCode.put(
                    productCode,
                    new Set<String>()
                );
            }

            brandsByProductCode.get(productCode).add(brandName);
            relevantBrandNames.add(brandName);
        }

        if (brandsByProductCode.isEmpty()) {
            return;
        }

        /*
         * RELEVANT TARGET BRANDS
         */
        Map<String, Id> targetBrandByName =
            new Map<String, Id>();

        for (WebshopBrand__c brand : [
            SELECT Id, Name
            FROM WebshopBrand__c
            WHERE Name IN :relevantBrandNames
        ]) {
            targetBrandByName.put(brand.Name, brand.Id);
        }

        /*
         * EXISTING TARGET LINKS
         */
        Set<Id> relevantTargetProductIds =
            MigrationProductMappingUtil.flattenIds(
                targetIdsByProductCode
            );

        Set<String> seenTargetLinks = new Set<String>();

        for (WebshopBrandLink__c existingLink : [
            SELECT Product__c, Brand__c
            FROM WebshopBrandLink__c
            WHERE Product__c IN :relevantTargetProductIds
        ]) {
            seenTargetLinks.add(
                String.valueOf(existingLink.Product__c) +
                '|' +
                String.valueOf(existingLink.Brand__c)
            );
        }

        /*
         * APPLY EACH BRAND TO EVERY MATCHING TARGET PRODUCT
         */
        List<WebshopBrandLink__c> recordsToInsert =
            new List<WebshopBrandLink__c>();

        for (String productCode : brandsByProductCode.keySet()) {
            Set<Id> targetProductIds =
                targetIdsByProductCode.get(productCode);

            if (targetProductIds == null) {
                continue;
            }

            for (String brandName : brandsByProductCode.get(productCode)) {
                Id targetBrandId =
                    targetBrandByName.get(brandName);

                if (targetBrandId == null) {
                    continue;
                }

                for (Id targetProductId : targetProductIds) {
                    String linkKey =
                        String.valueOf(targetProductId) +
                        '|' +
                        String.valueOf(targetBrandId);

                    if (!seenTargetLinks.add(linkKey)) {
                        continue;
                    }

                    recordsToInsert.add(
                        new WebshopBrandLink__c(
                            Product__c = targetProductId,
                            Brand__c = targetBrandId
                        )
                    );
                }
            }
        }

        if (!recordsToInsert.isEmpty()) {
            Database.insert(recordsToInsert, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Do nothing
    }
}