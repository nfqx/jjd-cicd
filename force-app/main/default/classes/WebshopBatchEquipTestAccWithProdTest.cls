@IsTest
private class WebshopBatchEquipTestAccWithProdTest {

    @TestSetup
    static void setupData() {

        /*
         * 1. Account (matches Custom Label)
         */
        Account acc = new Account(
            Name = System.Label.WebshopDoNotTranslateTestCustomerName
        );
        insert acc;

        /*
         * 2. Policy
         */
        CommerceEntitlementPolicy policy = new CommerceEntitlementPolicy(
            Name = 'Test Policy',
            Account__c = acc.Id
        );
        insert policy;

        /*
         * 3. Create Products (NO ProductClass assignment!)
         */
        List<Product2> products = new List<Product2>();

        for (Integer i = 0; i < 3; i++) {
            products.add(new Product2(
                Name = 'Test Product ' + i,
                IsActive = true
            ));
        }

        insert products;

        /*
         * 4. Try to simulate variation relationship (optional)
         * This will only work if your org allows it
         */
        try {
            insert new ProductAttribute(
                ProductId = products[1].Id,
                VariantParentId = products[0].Id
            );
        } catch (Exception e) {
            // Ignore if object constraints prevent insert
            System.debug('ProductAttribute insert not supported in this org: ' + e.getMessage());
        }
    }
    
    @IsTest
    static void testBatchExecution() {

        Test.startTest();

        Database.executeBatch(
            new WebshopBatchEquipTestAccWithProducts(),
            50
        );

        Test.stopTest();

        /*
         * Validate entitlements created
         */
        List<CommerceEntitlementProduct> entitlements = [
            SELECT Id, ProductId
            FROM CommerceEntitlementProduct
        ];

        System.assert(
            entitlements.size() > 0,
            'Entitlements should have been created'
        );
    }

    @IsTest
    static void testNoDuplicates() {

        Test.startTest();

        Database.executeBatch(new WebshopBatchEquipTestAccWithProducts(), 50);
        Database.executeBatch(new WebshopBatchEquipTestAccWithProducts(), 50);

        Test.stopTest();

        Map<Id, Integer> counts = new Map<Id, Integer>();

        for (CommerceEntitlementProduct cep : [
            SELECT ProductId
            FROM CommerceEntitlementProduct
        ]) {
            counts.put(
                cep.ProductId,
                counts.containsKey(cep.ProductId)
                    ? counts.get(cep.ProductId) + 1
                    : 1
            );
        }

        for (Id productId : counts.keySet()) {
            System.assertEquals(
                1,
                counts.get(productId),
                'Duplicate entitlement found for product ' + productId
            );
        }
    }
    
    @IsTest
    static void testSchedulable() {

        Test.startTest();

        String jobId = System.schedule(
            'Test Job',
            '0 0 0 1 1 ? 2099',
            new WebshopBatchEquipTestAccWithProducts()
        );

        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }
}