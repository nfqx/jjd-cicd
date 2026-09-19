public class MigrationWebshopProductLinkJob implements Database.Batchable<sObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        delete [SELECT Id FROM WebshopProductLink__c];

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
         * SOURCE PARENTS FOR THE OWNED PRODUCT CODES
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

            String parentId = (String) values.get('Id');
            String productCode = (String) values.get('ProductCode');

            if (parentId != null && productCode != null) {
                sourceParentCodeById.put(parentId, productCode);
            }
        }

        if (sourceParentCodeById.isEmpty()) {
            return;
        }

        /*
         * SOURCE CHILDREN FOR THOSE PARENTS
         */
        List<Object> sourceAttributes =
            MigrationProductMappingUtil.queryRemoteInChunks(
                'SELECT ProductId, VariantParentId FROM ProductAttribute',
                'VariantParentId',
                sourceParentCodeById.keySet()
            );

        Map<String, String> sourceParentByChildId =
            new Map<String, String>();

        for (Object row : sourceAttributes) {
            Map<String, Object> values = (Map<String, Object>) row;

            String childId = (String) values.get('ProductId');
            String parentId = (String) values.get('VariantParentId');

            if (childId != null && parentId != null) {
                sourceParentByChildId.put(childId, parentId);
            }
        }

        if (sourceParentByChildId.isEmpty()) {
            return;
        }

        /*
         * LINKS WHOSE FIRST PRODUCT BELONGS TO THE CURRENT CODE SET
         */
        List<Object> sourceLinks =
            MigrationProductMappingUtil.queryRemoteInChunks(
                'SELECT Product1__c, Product2__c ' +
                'FROM WebshopProductLink__c',
                'Product1__c',
                sourceParentByChildId.keySet()
            );

        Set<String> counterpartChildIds = new Set<String>();

        for (Object row : sourceLinks) {
            Map<String, Object> values = (Map<String, Object>) row;
            String counterpartChildId =
                (String) values.get('Product2__c');

            if (counterpartChildId != null) {
                counterpartChildIds.add(counterpartChildId);
            }
        }

        if (counterpartChildIds.isEmpty()) {
            return;
        }

        /*
         * COUNTERPART CHILD → PARENT
         */
        List<Object> counterpartAttributes =
            MigrationProductMappingUtil.queryRemoteInChunks(
                'SELECT ProductId, VariantParentId FROM ProductAttribute',
                'ProductId',
                counterpartChildIds
            );

        Map<String, String> counterpartParentByChildId =
            new Map<String, String>();

        Set<String> counterpartParentIds = new Set<String>();

        for (Object row : counterpartAttributes) {
            Map<String, Object> values = (Map<String, Object>) row;

            String childId = (String) values.get('ProductId');
            String parentId = (String) values.get('VariantParentId');

            if (childId != null && parentId != null) {
                counterpartParentByChildId.put(childId, parentId);
                counterpartParentIds.add(parentId);
            }
        }

        if (counterpartParentIds.isEmpty()) {
            return;
        }

        /*
         * COUNTERPART PARENT → PRODUCT CODE
         */
        List<Object> counterpartParents =
            MigrationProductMappingUtil.queryRemoteInChunks(
                'SELECT Id, ProductCode FROM Product2',
                'Id',
                counterpartParentIds
            );

        Map<String, String> counterpartCodeByParentId =
            new Map<String, String>();

        Set<String> counterpartProductCodes = new Set<String>();

        for (Object row : counterpartParents) {
            Map<String, Object> values = (Map<String, Object>) row;

            String parentId = (String) values.get('Id');
            String productCode = (String) values.get('ProductCode');

            if (parentId != null && productCode != null) {
                counterpartCodeByParentId.put(parentId, productCode);
                counterpartProductCodes.add(productCode);
            }
        }

        /*
         * ADD EVERY TARGET PRODUCT MATCHING THE COUNTERPART CODES
         */
        MigrationProductMappingUtil.addTargetProducts(
            targetIdsByProductCode,
            counterpartProductCodes
        );

        /*
         * COLLAPSE VARIANT LINKS TO PRODUCT-CODE LINKS
         */
        Map<String, Set<String>> linkedCodesByFirstCode =
            new Map<String, Set<String>>();

        for (Object row : sourceLinks) {
            Map<String, Object> values = (Map<String, Object>) row;

            String child1Id = (String) values.get('Product1__c');
            String child2Id = (String) values.get('Product2__c');

            String parent1Id =
                sourceParentByChildId.get(child1Id);

            String parent2Id =
                counterpartParentByChildId.get(child2Id);

            if (parent1Id == null || parent2Id == null) {
                continue;
            }

            if (parent1Id == parent2Id) {
                continue;
            }

            String productCode1 =
                sourceParentCodeById.get(parent1Id);

            String productCode2 =
                counterpartCodeByParentId.get(parent2Id);

            if (productCode1 == null || productCode2 == null) {
                continue;
            }

            if (!linkedCodesByFirstCode.containsKey(productCode1)) {
                linkedCodesByFirstCode.put(
                    productCode1,
                    new Set<String>()
                );
            }

            linkedCodesByFirstCode.get(productCode1).add(productCode2);
        }

        /*
         * EXPAND EACH CODE RELATIONSHIP TO ALL TARGET COMBINATIONS
         */
        List<WebshopProductLink__c> recordsToInsert =
            new List<WebshopProductLink__c>();

        Set<String> seenTargetLinks = new Set<String>();

        for (String productCode1 : linkedCodesByFirstCode.keySet()) {
            Set<Id> targetIds1 =
                targetIdsByProductCode.get(productCode1);

            if (targetIds1 == null || targetIds1.isEmpty()) {
                continue;
            }

            for (
                String productCode2 :
                linkedCodesByFirstCode.get(productCode1)
            ) {
                Set<Id> targetIds2 =
                    targetIdsByProductCode.get(productCode2);

                if (targetIds2 == null || targetIds2.isEmpty()) {
                    continue;
                }

                for (Id targetId1 : targetIds1) {
                    for (Id targetId2 : targetIds2) {
                        if (targetId1 == targetId2) {
                            continue;
                        }

                        String linkKey =
                            String.valueOf(targetId1) +
                            '|' +
                            String.valueOf(targetId2);

                        if (!seenTargetLinks.add(linkKey)) {
                            continue;
                        }

                        recordsToInsert.add(
                            new WebshopProductLink__c(
                                Product1__c = targetId1,
                                Product2__c = targetId2
                            )
                        );
                    }
                }
            }
        }

        if (!recordsToInsert.isEmpty()) {
            Database.insert(recordsToInsert, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
        Database.executeBatch(
            new MigrationWebshopBrandLinkJob(),
            100
        );
    }
}