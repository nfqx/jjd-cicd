@IsTest
private class AccountTriggerTest {

    private static void insertWithoutClassification(List<Account> accounts) {
        AccountTriggerHandler.suppressClassification = true;
        try {
            insert accounts;
        } finally {
            AccountTriggerHandler.suppressClassification = false;
        }
    }

    @IsTest
    static void testBeforeInsertClassification() {
        Account ac = new Account(
            Name = 'Trigger Insert Test',
            IsChainMember__c = false
        );

        insert ac;

        ac = [
            SELECT Id,
                   AccountCategory__c,
                   AccountCategorySource__c,
                   AccountCategoryReason__c
            FROM Account
            WHERE Id = :ac.Id
        ];

        System.assertEquals(
            AccountCategoryClassifier.CAT_DIRECT_CUSTOMER,
            ac.AccountCategory__c
        );
        System.assertEquals(
            AccountCategoryClassifier.CONST_AUTOMATIC,
            ac.AccountCategorySource__c
        );
    }

    @IsTest
    static void testManualClassificationNotOverwritten() {
        Account ac = new Account(
            Name = 'Manual Account',
            IsChainMember__c = false,
            AccountCategory__c = AccountCategoryClassifier.CAT_UNCLASSIFIED,
            AccountCategorySource__c = AccountCategoryClassifier.CONST_MANUAL
        );

        insert ac;

        ac.Name = 'Changed Name';
        update ac;

        ac = [
            SELECT AccountCategory__c,
                   AccountCategorySource__c
            FROM Account
            WHERE Id = :ac.Id
        ];

        System.assertEquals(
            AccountCategoryClassifier.CAT_UNCLASSIFIED,
            ac.AccountCategory__c
        );
        System.assertEquals(
            AccountCategoryClassifier.CONST_MANUAL,
            ac.AccountCategorySource__c
        );
    }

    @IsTest
    static void testRelevantUpdateReclassifies() {
        Account invoiceRecipient = new Account(
            Name = 'Invoice Recipient'
        );
        Account ac = new Account(
            Name = 'Customer',
            IsChainMember__c = false
        );

        insert invoiceRecipient;
        insert ac;

        System.assertEquals(
            AccountCategoryClassifier.CAT_DIRECT_CUSTOMER,
            [
                SELECT AccountCategory__c
                FROM Account
                WHERE Id = :ac.Id
            ].AccountCategory__c
        );

        ac.InvoiceRecipient__c = invoiceRecipient.Id;
        update ac;

        ac = [
            SELECT AccountCategory__c,
                   AccountCategoryReason__c
            FROM Account
            WHERE Id = :ac.Id
        ];

        System.assertEquals(
            AccountCategoryClassifier.CAT_UNCLASSIFIED,
            ac.AccountCategory__c
        );
        System.assertEquals(
            AccountCategoryClassifier.FLAG_NO_CHAIN_FOREIGN_BILLED,
            ac.AccountCategoryReason__c
        );
    }

    @IsTest
    static void testParentChangeStartsReclassificationBatch() {
        Account oldParent = new Account(Name = 'Old Parent');
        Account newParent = new Account(Name = 'New Parent');
        Account child = new Account(
            Name = 'Child',
            IsChainMember__c = true
        );

        insertWithoutClassification(
            new List<Account>{oldParent, newParent, child}
        );

        child.ConditionChainParent__c = oldParent.Id;

        AccountTriggerHandler.suppressClassification = true;
        update child;
        AccountTriggerHandler.suppressClassification = false;

        Test.startTest();

        child.ConditionChainParent__c = newParent.Id;
        update child;

        Test.stopTest();

        Integer jobs = [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'AccountCategoryReclassifyBatch'
        ];

        System.assert(
            jobs > 0,
            'Changing the chain parent should start a reclassification batch.'
        );
    }

    @IsTest
    static void testDeleteStartsReclassificationBatch() {
        Account parent = new Account(
            Name = 'Parent',
            IsChainMember__c = true
        );
        Account child = new Account(
            Name = 'Child',
            IsChainMember__c = true
        );

        insertWithoutClassification(new List<Account>{parent, child});

        child.ConditionChainParent__c = parent.Id;

        AccountTriggerHandler.suppressClassification = true;
        update child;
        AccountTriggerHandler.suppressClassification = false;

        Test.startTest();

        delete child;

        Test.stopTest();

        Integer jobs = [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'AccountCategoryReclassifyBatch'
        ];

        System.assert(
            jobs > 0,
            'Deleting a related account should enqueue the reclassification batch.'
        );
    }

    @IsTest
    static void testSuppression() {
        Account ac = new Account(
            Name = 'Suppressed Account',
            IsChainMember__c = false
        );

        AccountTriggerHandler.suppressClassification = true;

        try {
            insert ac;
        } finally {
            AccountTriggerHandler.suppressClassification = false;
        }

        ac = [
            SELECT AccountCategory__c,
                   AccountCategorySource__c
            FROM Account
            WHERE Id = :ac.Id
        ];

        System.assertEquals(null, ac.AccountCategory__c);
        System.assertEquals(null, ac.AccountCategorySource__c);
    }
}