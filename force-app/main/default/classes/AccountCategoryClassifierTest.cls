@IsTest
private class AccountCategoryClassifierTest {

    private static void insertWithoutClassification(List<Account> accounts) {
        AccountTriggerHandler.suppressClassification = true;
        try {
            insert accounts;
        } finally {
            AccountTriggerHandler.suppressClassification = false;
        }
    }

    @IsTest
    static void testNotChainMemberDirectCustomer() {
        Account ac = new Account(
            Name = 'Direct Customer',
            IsChainMember__c = false
        );

        insertWithoutClassification(new List<Account>{ac});

        AccountCategoryClassifier.classify(new List<Account>{ac});

        System.assertEquals(
            AccountCategoryClassifier.CAT_DIRECT_CUSTOMER,
            ac.AccountCategory__c
        );
        System.assertEquals(
            AccountCategoryClassifier.CONST_AUTOMATIC,
            ac.AccountCategorySource__c
        );
        System.assertNotEquals(null, ac.AccountCategoryDerivedAt__c);
    }

    @IsTest
    static void testNotChainMemberForeignBilled() {
        Account invoiceRecipient = new Account(Name = 'Invoice Recipient');
        Account ac = new Account(
            Name = 'Foreign Billed',
            IsChainMember__c = false
        );

        insertWithoutClassification(new List<Account>{invoiceRecipient, ac});

        ac.InvoiceRecipient__c = invoiceRecipient.Id;

        AccountCategoryClassifier.classify(new List<Account>{ac});

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
    static void testChainMemberWithoutEvidence() {
        Account ac = new Account(
            Name = 'Chain Member Without Evidence',
            IsChainMember__c = true
        );

        insertWithoutClassification(new List<Account>{ac});

        AccountCategoryClassifier.classify(new List<Account>{ac});

        System.assertEquals(
            AccountCategoryClassifier.CAT_UNCLASSIFIED,
            ac.AccountCategory__c
        );
        System.assertEquals(
            AccountCategoryClassifier.FLAG_NO_EVIDENCE,
            ac.AccountCategoryReason__c
        );
    }

    @IsTest
    static void testDepartmentByLegalForm() {
        Account parent = new Account(Name = 'Parent');
        Account child = new Account(
            Name = 'Department',
            IsChainMember__c = true,
            LegalForm__c = AccountCategoryClassifier.CONST_NO_OWN_LEGAL_FORM
        );

        insertWithoutClassification(new List<Account>{parent, child});

        child.ConditionChainParent__c = parent.Id;

        AccountCategoryClassifier.classify(new List<Account>{child});

        System.assertEquals(
            AccountCategoryClassifier.CAT_DEPARTMENT,
            child.AccountCategory__c
        );
    }

    @IsTest
    static void testMissingLegalFormAndTaxId() {
        Account parent = new Account(Name = 'Parent');
        Account child = new Account(
            Name = 'Missing Legal Form',
            IsChainMember__c = true
        );

        insertWithoutClassification(new List<Account>{parent, child});

        child.ConditionChainParent__c = parent.Id;

        AccountCategoryClassifier.classify(new List<Account>{child});

        System.assertEquals(
            AccountCategoryClassifier.CAT_UNCLASSIFIED,
            child.AccountCategory__c
        );
        System.assertEquals(
            AccountCategoryClassifier.FLAG_LEGALFORM_MISSING,
            child.AccountCategoryReason__c
        );
    }

    @IsTest
    static void testSelfBilledDirectCustomer() {
        Account parent = new Account(Name = 'Parent');
        Account child = new Account(
            Name = 'Self Billed',
            IsChainMember__c = true,
            LegalForm__c = 'GmbH',
            SelfBilled__c = true
        );

        insertWithoutClassification(new List<Account>{parent, child});

        child.ConditionChainParent__c = parent.Id;

        AccountCategoryClassifier.classify(new List<Account>{child});

        System.assertEquals(
            AccountCategoryClassifier.CAT_DIRECT_CUSTOMER,
            child.AccountCategory__c
        );
    }

    @IsTest
    static void testAssociationMember() {
        Account parent = new Account(Name = 'Parent');
        Account invoiceRecipient = new Account(Name = 'Invoice Recipient');
        Account child = new Account(
            Name = 'Association Member',
            IsChainMember__c = true,
            LegalForm__c = 'GmbH',
            SelfBilled__c = false
        );

        insertWithoutClassification(
            new List<Account>{parent, invoiceRecipient, child}
        );

        child.ConditionChainParent__c = parent.Id;
        child.InvoiceRecipient__c = invoiceRecipient.Id;

        AccountCategoryClassifier.classify(new List<Account>{child});

        System.assertEquals(
            AccountCategoryClassifier.CAT_ASSOCIATION_MEMBER,
            child.AccountCategory__c
        );
    }

    @IsTest
    static void testBillingUnknown() {
        Account parent = new Account(Name = 'Parent');
        Account child = new Account(
            Name = 'Billing Unknown',
            IsChainMember__c = true,
            LegalForm__c = 'GmbH',
            SelfBilled__c = false
        );

        insertWithoutClassification(new List<Account>{parent, child});

        child.ConditionChainParent__c = parent.Id;

        AccountCategoryClassifier.classify(new List<Account>{child});

        System.assertEquals(
            AccountCategoryClassifier.CAT_UNCLASSIFIED,
            child.AccountCategory__c
        );
        System.assertEquals(
            AccountCategoryClassifier.FLAG_BILLING_UNKNOWN,
            child.AccountCategoryReason__c
        );
    }

    @IsTest
    static void testCentralRegulator() {
        Account regulator = new Account(
            Name = 'Central Regulator',
            IsChainMember__c = true
        );
        Account member = new Account(
            Name = 'Member',
            IsChainMember__c = true
        );

        insertWithoutClassification(new List<Account>{regulator, member});

        member.CentralRegulator__c = regulator.Id;

        AccountTriggerHandler.suppressClassification = true;
        update member;
        AccountTriggerHandler.suppressClassification = false;

        AccountCategoryClassifier.classify(new List<Account>{regulator});

        System.assertEquals(
            AccountCategoryClassifier.CAT_CENTRAL_REGULATOR,
            regulator.AccountCategory__c
        );
        System.assertEquals(
            AccountCategoryClassifier.REGULATOR_ALL,
            regulator.RegulatorLevel__c
        );
    }

    @IsTest
    static void testManualClassificationUntouched() {
        Account ac = new Account(
            Name = 'Manual Account',
            IsChainMember__c = false,
            AccountCategory__c = AccountCategoryClassifier.CAT_UNCLASSIFIED,
            AccountCategorySource__c = AccountCategoryClassifier.CONST_MANUAL
        );

        insertWithoutClassification(new List<Account>{ac});

        AccountCategoryClassifier.classify(new List<Account>{ac});

        System.assertEquals(
            AccountCategoryClassifier.CAT_UNCLASSIFIED,
            ac.AccountCategory__c
        );
        System.assertEquals(
            AccountCategoryClassifier.CONST_MANUAL,
            ac.AccountCategorySource__c
        );
    }
}