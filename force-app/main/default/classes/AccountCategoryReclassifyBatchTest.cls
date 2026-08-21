@IsTest
private class AccountCategoryReclassifyBatchTest {

    private static void insertWithoutClassification(List<Account> accounts) {
        AccountTriggerHandler.suppressClassification = true;
        try {
            insert accounts;
        } finally {
            AccountTriggerHandler.suppressClassification = false;
        }
    }

    @IsTest
    static void testBatchReclassifiesAccounts() {
        Account ac1 = new Account(
            Name = 'Account 1',
            IsChainMember__c = false
        );
        Account ac2 = new Account(
            Name = 'Account 2',
            IsChainMember__c = true
        );
        Account manualAccount = new Account(
            Name = 'Manual Account',
            IsChainMember__c = false,
            AccountCategory__c = AccountCategoryClassifier.CAT_UNCLASSIFIED,
            AccountCategorySource__c = AccountCategoryClassifier.CONST_MANUAL
        );

        insertWithoutClassification(
            new List<Account>{ac1, ac2, manualAccount}
        );

        Set<Id> accountIds = new Set<Id>{
            ac1.Id,
            ac2.Id,
            manualAccount.Id
        };

        Test.startTest();

        Database.executeBatch(
            new AccountCategoryReclassifyBatch(accountIds),
            200
        );

        Test.stopTest();

        Map<Id, Account> results = new Map<Id, Account>([
            SELECT Id,
                   AccountCategory__c,
                   AccountCategorySource__c,
                   AccountCategoryReason__c
            FROM Account
            WHERE Id IN :accountIds
        ]);

        System.assertEquals(
            AccountCategoryClassifier.CAT_DIRECT_CUSTOMER,
            results.get(ac1.Id).AccountCategory__c
        );
        System.assertEquals(
            AccountCategoryClassifier.CONST_AUTOMATIC,
            results.get(ac1.Id).AccountCategorySource__c
        );

        System.assertEquals(
            AccountCategoryClassifier.CAT_UNCLASSIFIED,
            results.get(ac2.Id).AccountCategory__c
        );
        System.assertEquals(
            AccountCategoryClassifier.FLAG_NO_EVIDENCE,
            results.get(ac2.Id).AccountCategoryReason__c
        );

        System.assertEquals(
            AccountCategoryClassifier.CAT_UNCLASSIFIED,
            results.get(manualAccount.Id).AccountCategory__c
        );
        System.assertEquals(
            AccountCategoryClassifier.CONST_MANUAL,
            results.get(manualAccount.Id).AccountCategorySource__c
        );
    }

    @IsTest
    static void testBatchWithEmptySet() {
        Test.startTest();

        Database.executeBatch(
            new AccountCategoryReclassifyBatch(new Set<Id>()),
            200
        );

        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testBatchProcessesRequestedAccountsOnly() {
        Account included = new Account(
            Name = 'Included',
            IsChainMember__c = false
        );
        Account excluded = new Account(
            Name = 'Excluded',
            IsChainMember__c = false
        );

        insertWithoutClassification(new List<Account>{included, excluded});

        Test.startTest();

        Database.executeBatch(
            new AccountCategoryReclassifyBatch(
                new Set<Id>{included.Id}
            ),
            200
        );

        Test.stopTest();

        Map<Id, Account> results = new Map<Id, Account>([
            SELECT Id,
                   AccountCategory__c,
                   AccountCategorySource__c
            FROM Account
            WHERE Id IN :new Set<Id>{included.Id, excluded.Id}
        ]);

        System.assertEquals(
            AccountCategoryClassifier.CAT_DIRECT_CUSTOMER,
            results.get(included.Id).AccountCategory__c
        );

        System.assertEquals(
            null,
            results.get(excluded.Id).AccountCategory__c
        );
    }
}