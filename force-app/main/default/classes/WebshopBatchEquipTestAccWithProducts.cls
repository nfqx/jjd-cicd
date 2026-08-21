public with sharing class WebshopBatchEquipTestAccWithProducts 
    implements Database.Batchable<SObject>, Schedulable {

    private Id accountId;
    private Id policyId;

    public WebshopBatchEquipTestAccWithProducts() {
        initializeContext();
    }

    private void initializeContext() {
        String accName = System.Label.WebshopDoNotTranslateTestCustomerName;

        Account acc = [
            SELECT Id
            FROM Account
            WHERE Name = :accName
            LIMIT 1
        ];

        accountId = acc.Id;

        CommerceEntitlementPolicy policy = [
            SELECT Id
            FROM CommerceEntitlementPolicy
            WHERE Account__c = :accountId
            LIMIT 1
        ];

        policyId = policy.Id;
    }

    /*
     * START
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, ProductClass
            FROM Product2
            WHERE IsActive = TRUE
            AND ProductClass IN ('Variation', 'Simple')
        ]);
    }

    /*
     * EXECUTE
     */
    public void execute(Database.BatchableContext bc, List<Product2> scope) {

        Set<Id> allProductIds = new Set<Id>();
        Set<Id> variationIds = new Set<Id>();

        for (Product2 p : scope) {
            allProductIds.add(p.Id);
            if (p.ProductClass == 'Variation') {
                variationIds.add(p.Id);
            }
        }

        /*
         * 🔗 Resolve parent relationships via ProductAttribute
         */
        Map<Id, Id> childToParent = new Map<Id, Id>();
        Set<Id> parentIds = new Set<Id>();

        if (!variationIds.isEmpty()) {
            for (ProductAttribute pa : [
                SELECT ProductId, VariantParentId
                FROM ProductAttribute
                WHERE ProductId IN :variationIds
            ]) {
                if (pa.VariantParentId != null) {
                    childToParent.put(pa.ProductId, pa.VariantParentId);
                    parentIds.add(pa.VariantParentId);
                }
            }
        }

        // Combine all relevant product IDs (children + parents)
        Set<Id> relevantProductIds = new Set<Id>();
        relevantProductIds.addAll(allProductIds);
        relevantProductIds.addAll(parentIds);

        /*
         * Existing entitlements
         */
        Map<Id, CommerceEntitlementProduct> existingMap = new Map<Id, CommerceEntitlementProduct>();

        for (CommerceEntitlementProduct cep : [
            SELECT Id, ProductId
            FROM CommerceEntitlementProduct
            WHERE PolicyId = :policyId
            AND ProductId IN :relevantProductIds
        ]) {
            existingMap.put(cep.ProductId, cep);
        }

        List<CommerceEntitlementProduct> toInsert = new List<CommerceEntitlementProduct>();

        /*
         * 🥇 STEP 1: Ensure PARENTS first
         */
        for (Id parentId : parentIds) {
            if (!existingMap.containsKey(parentId)) {
                toInsert.add(createEntitlement(parentId));
                existingMap.put(parentId, null); // prevent duplicates in same batch
            }
        }

        /*
         * 🥈 STEP 2: Process products
         */
        for (Product2 p : scope) {

            // Simple products
            if (p.ProductClass == 'Simple') {
                if (!existingMap.containsKey(p.Id)) {
                    toInsert.add(createEntitlement(p.Id));
                    existingMap.put(p.Id, null);
                }
            }

            // Variation products
            else if (p.ProductClass == 'Variation') {

                // Ensure child entitlement
                if (!existingMap.containsKey(p.Id)) {
                    toInsert.add(createEntitlement(p.Id));
                    existingMap.put(p.Id, null);
                }

                // Ensure parent entitlement (safety, though already handled)
                Id parentId = childToParent.get(p.Id);
                if (parentId != null && !existingMap.containsKey(parentId)) {
                    toInsert.add(createEntitlement(parentId));
                    existingMap.put(parentId, null);
                }
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }

    private CommerceEntitlementProduct createEntitlement(Id productId) {
        return new CommerceEntitlementProduct(
            PolicyId = policyId,
            ProductId = productId
        );
    }

    public void finish(Database.BatchableContext bc) {}

    /*
     * SCHEDULABLE
     */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new WebshopBatchEquipTestAccWithProducts(), 200);
    }
}