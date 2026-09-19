public inherited sharing class MigrationProductMappingUtil {

    private static final Integer REMOTE_IN_CHUNK_SIZE = 150;

    /*
     * Returns every target Product2 Id for each OldProductNumber__c.
     *
     * A product number may occur in several batch scopes. The code is
     * processed only by the scope containing its canonical, lowest Id.
     */
    public static Map<String, Set<Id>> getOwnedTargetIdsByCode(
        List<Product2> scope
    ) {
        Set<String> candidateCodes = new Set<String>();
        Set<Id> scopeProductIds = new Set<Id>();

        for (Product2 product : scope) {
            if (String.isNotBlank(product.OldProductNumber__c)) {
                candidateCodes.add(product.OldProductNumber__c);
                scopeProductIds.add(product.Id);
            }
        }

        Map<String, Set<Id>> allTargetIdsByCode =
            new Map<String, Set<Id>>();

        Map<String, Id> canonicalIdByCode =
            new Map<String, Id>();

        if (candidateCodes.isEmpty()) {
            return allTargetIdsByCode;
        }

        /*
         * ORDER BY Id ensures that the first record encountered for
         * each code is always the same canonical record.
         */
        for (Product2 product : [
            SELECT Id, OldProductNumber__c
            FROM Product2
            WHERE OldProductNumber__c IN :candidateCodes
            AND ProductClass IN ('Simple', 'Variation')
            ORDER BY OldProductNumber__c, Id
        ]) {
            String productCode = product.OldProductNumber__c;

            if (!allTargetIdsByCode.containsKey(productCode)) {
                allTargetIdsByCode.put(productCode, new Set<Id>());
                canonicalIdByCode.put(productCode, product.Id);
            }

            allTargetIdsByCode.get(productCode).add(product.Id);
        }

        /*
         * Retain only codes whose canonical record belongs to this scope.
         */
        Map<String, Set<Id>> ownedTargetIdsByCode =
            new Map<String, Set<Id>>();

        for (String productCode : allTargetIdsByCode.keySet()) {
            Id canonicalId = canonicalIdByCode.get(productCode);

            if (scopeProductIds.contains(canonicalId)) {
                ownedTargetIdsByCode.put(
                    productCode,
                    allTargetIdsByCode.get(productCode)
                );
            }
        }

        return ownedTargetIdsByCode;
    }

    public static void addTargetProducts(
        Map<String, Set<Id>> targetIdsByCode,
        Set<String> productCodes
    ) {
        if (productCodes == null || productCodes.isEmpty()) {
            return;
        }

        for (Product2 product : [
            SELECT Id, OldProductNumber__c
            FROM Product2
            WHERE OldProductNumber__c IN :productCodes
            AND ProductClass IN ('Simple', 'Variation')
        ]) {
            String productCode = product.OldProductNumber__c;

            if (!targetIdsByCode.containsKey(productCode)) {
                targetIdsByCode.put(productCode, new Set<Id>());
            }

            targetIdsByCode.get(productCode).add(product.Id);
        }
    }

    public static Set<Id> flattenIds(
        Map<String, Set<Id>> idsByCode
    ) {
        Set<Id> result = new Set<Id>();

        for (Set<Id> ids : idsByCode.values()) {
            result.addAll(ids);
        }

        return result;
    }

    public static List<Object> queryRemoteInChunks(
        String baseQuery,
        String fieldName,
        Set<String> values
    ) {
        List<Object> results = new List<Object>();

        if (values == null || values.isEmpty()) {
            return results;
        }

        List<String> quotedValues = new List<String>();

        for (String value : values) {
            if (String.isBlank(value)) {
                continue;
            }

            quotedValues.add(
                '\'' + String.escapeSingleQuotes(value) + '\''
            );

            if (quotedValues.size() == REMOTE_IN_CHUNK_SIZE) {
                results.addAll(
                    executeRemoteInQuery(
                        baseQuery,
                        fieldName,
                        quotedValues
                    )
                );

                quotedValues.clear();
            }
        }

        if (!quotedValues.isEmpty()) {
            results.addAll(
                executeRemoteInQuery(
                    baseQuery,
                    fieldName,
                    quotedValues
                )
            );
        }

        return results;
    }

    private static List<Object> executeRemoteInQuery(
        String baseQuery,
        String fieldName,
        List<String> quotedValues
    ) {
        String soql =
            baseQuery +
            ' WHERE ' +
            fieldName +
            ' IN (' +
            String.join(quotedValues, ',') +
            ')';

        return SourceOrgApi.query(soql);
    }
}