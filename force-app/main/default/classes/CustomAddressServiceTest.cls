@IsTest
private class CustomAddressServiceTest {

    @TestSetup
    private static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = 'Marienplatz 1',
            BillingCity = 'Munich',
            BillingPostalCode = '80331',
            BillingCountry = 'Germany',
            ShippingStreet = 'Marienplatz 1',
            ShippingCity = 'Munich',
            ShippingPostalCode = '80331',
            ShippingCountry = 'Germany',
            ERPCustomerNumber__c = '123'
        );
        insert testAccount;

        Contact testContact = new Contact(
            LastName = 'Test Contact',
            AccountId = testAccount.Id,
            MailingStreet = '1600 Amphitheatre Parkway',
            MailingCity = 'Mountain View',
            MailingState = 'Texas',
            MailingPostalCode = '94043',
            MailingCountry = 'United States'
        );
        insert testContact;
    }

    @IsTest
    static void checkAddressChangesBulk_WhenAccountBillingAddressChanges_ShouldReturnChangedAddress() {
        // Having
        Account testAccount = [
            SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
            ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, ERPCustomerNumber__c
            FROM Account
            LIMIT 1
        ];
        Account oldAccount = testAccount.clone(true);

        // Modify billing address to new Berlin address
        testAccount.BillingStreet = 'Unter den Linden 77';
        testAccount.BillingCity = 'Berlin';
        testAccount.BillingState = 'CA';
        testAccount.BillingPostalCode = '10117';

        Map<Id, Account> newAccountsMap = new Map<Id, Account>{testAccount.Id => testAccount};
        Map<Id, Account> oldAccountsMap = new Map<Id, Account>{oldAccount.Id => oldAccount};

        // When
        Test.startTest();
        Map<Id, List<CustomAddressWrapper>> result = CustomAddressService.checkAddressChangesBulk(newAccountsMap, oldAccountsMap);
        Test.stopTest();

        // Then
        System.assertEquals(1, result.size(), 'Should detect changes for one account');
        System.assertEquals(1, result.get(testAccount.Id).size(), 'Should detect one address type change');
        System.assertEquals(CustomAddressService.BILLING_ADDRESS_TYPE, result.get(testAccount.Id)[0].addressType, 'Should detect Billing address change');
        System.assertEquals(true, result.get(testAccount.Id)[0].isAddressChanged, 'Should flag address as changed');
    }

    @IsTest
    static void checkAddressChangesBulk_WhenContactMailingAddressChanges_ShouldReturnChangedAddress() {
        // Having
        Contact testContact = [
            SELECT Id, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, Account.ERPCustomerNumber__c, ERPContactNumber__c
            FROM Contact
            LIMIT 1
        ];
        Contact oldContact = testContact.clone(true);

        // Modify mailing address to New York address
        testContact.MailingStreet = '20 W 34th St';
        testContact.MailingCity = 'New York';
        testContact.MailingState = 'NY';
        testContact.MailingPostalCode = '10001';

        Map<Id, Contact> newContactsMap = new Map<Id, Contact>{testContact.Id => testContact};
        Map<Id, Contact> oldContactsMap = new Map<Id, Contact>{oldContact.Id => oldContact};

        // When
        Test.startTest();
        Map<Id, List<CustomAddressWrapper>> result =
            CustomAddressService.checkAddressChangesBulk(newContactsMap, oldContactsMap);
        Test.stopTest();

        // Then
        System.assertEquals(1, result.size(), 'Should detect changes for one contact');
        System.assertEquals(1, result.get(testContact.Id).size(), 'Should detect one address type change');
        System.assertEquals(CustomAddressService.MAILING_ADDRESS_TYPE, result.get(testContact.Id)[0].addressType, 'Should detect Mailing address change');
        System.assertEquals(true, result.get(testContact.Id)[0].isAddressChanged, 'Should flag address as changed');
    }

    @IsTest
    static void checkAddressChangesBulk_WhenNoAddressChanges_ShouldReturnEmptyMap() {
        // Having
        Account testAccount = [
            SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
            ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, ERPCustomerNumber__c
            FROM Account
            LIMIT 1
        ];
        Account oldAccount = testAccount.clone(true);

        Map<Id, Account> newAccountsMap = new Map<Id, Account>{testAccount.Id => testAccount};
        Map<Id, Account> oldAccountsMap = new Map<Id, Account>{oldAccount.Id => oldAccount};

        // When
        Test.startTest();
        Map<Id, List<CustomAddressWrapper>> result =
            CustomAddressService.checkAddressChangesBulk(newAccountsMap, oldAccountsMap);
        Test.stopTest();

        // Then
        System.assertEquals(0, result.size(), 'Should not detect any address changes');
    }

    @IsTest
    static void syncCustomAddress_WhenAccountBillingAddressChanges_ShouldUpsertCustomAddress() {
        // Having
        Account testAccount = [
            SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
            ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, ERPCustomerNumber__c
            FROM Account
            LIMIT 1
        ];

        // When
        Test.startTest();
        testAccount.BillingStreet = 'Kaiserstraße 29';
        testAccount.BillingCity = 'Frankfurt';
        testAccount.BillingPostalCode = '60311';
        update testAccount;
        Test.stopTest();

        // Then
        List<CustomAddress__c> customAddresses = [
            SELECT Id, Address__Street__s, Address__City__s, Address__StateCode__s, Address__PostalCode__s
            FROM CustomAddress__c
            WHERE RelatedId__c = :testAccount.Id
        ];

        System.assertEquals('Kaiserstraße 29', customAddresses[0].Address__Street__s, 'Street should be updated');
        System.assertEquals('Frankfurt', customAddresses[0].Address__City__s, 'City should be updated');
        System.assertEquals('60311', customAddresses[0].Address__PostalCode__s, 'Postal code should be updated');
    }

    @IsTest
    static void compoundAddress_WhenAllFieldsArePopulated_ShouldReturnFormattedString() {
        // Having
        CustomAddressWrapper wrapper = new CustomAddressWrapper();
        wrapper.street = 'Brandenburger Tor 1';
        wrapper.city = 'Berlin';
        wrapper.state = 'NY';
        wrapper.postalCode = '10117';
        wrapper.country = 'Germany';

        // When
        Test.startTest();
        String result = CustomAddressService.compoundAddress(wrapper);
        Test.stopTest();

        // Then
        System.assertEquals(
            'Brandenburger Tor 1, Berlin, NY, 10117, Germany', result, 'Should return properly formatted address string'
        );
    }

    @IsTest
    static void compoundAddress_WhenSomeFieldsAreNull_ShouldSkipNullValues() {
        // Having
        CustomAddressWrapper wrapper = new CustomAddressWrapper();
        wrapper.street = 'Reichstagsgebäude Platz der Republik 1';
        wrapper.city = null;
        wrapper.state = 'NY';
        wrapper.postalCode = '11011';
        wrapper.country = 'Germany';

        // When
        Test.startTest();
        String result = CustomAddressService.compoundAddress(wrapper);
        Test.stopTest();

        // Then
        System.assertEquals(
            'Reichstagsgebäude Platz der Republik 1, , NY, 11011, Germany', result, 'Should skip null values in address string'
        );
    }
}