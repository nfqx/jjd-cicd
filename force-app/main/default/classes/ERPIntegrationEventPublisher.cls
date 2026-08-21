public without sharing class ERPIntegrationEventPublisher {

    public static final String NOT_SANCTIONED_STATUS = 'Not Sanctioned';
    public static final String CREDIT_RATING_STATUS = 'Credit Rating';
    public static final Set<String> QUALIFIED_OPPORTUNITY_STAGE_NAMES = new Set<String>{
        'Quotation Phase', 'Angebotsphase', 'Angebot verschickt', 'Nachverhandlung', 'Angebot unterzeichnet', 'Closed Won'
    };
    public static final List<String> BANK_ACCOUNT_FIELD_APIS = new List<String>{
        'ERPCustomerNumber__c', 'ERPInternalBankId__c', 'BankCountry__c',
        'BankName__c', 'BankNumber__c', 'SwiftCode__c', 'BankControlKey__c',
        'BankAccountHolderName__c', 'BankAccountName__c', 'ValidFrom__c',
        'ValidTo__c', 'IBAN__c', 'IBANValidFrom__c', 'BankAccount__c',
        'BankAccountReferenceText__c', 'DirectDebitAuthorization__c',
        'City__c', 'AccountId__c'
    };

    // Fields an Account update has to touch for the ERP to see anything change. Derived from the
    // two Mule flows that consume the AccountChanged__e payload:
    //   erp-sap-de-s/account.xml      -> account_changed_to_sap_flow (A_CustomerSalesArea, A_CustomerCompany, A_BusinessPartner)
    //   erp-sap-de-s/account-link.xml -> update_account_link_in_sap  (KNVH hierarchy)
    // An update touching none of them produces an SAP call that writes back the same values, so
    // the event is not worth publishing.
    // Deliberately absent: ILNNo__c and CustomerTaxClassification__c - the update path does not
    // send either to SAP yet. See TICKETS/JJD-44/analysis.md before adding fields here.
    public static final List<ERPSyncRecursionPrevention.ERPFieldConfig> ACCOUNT_MAPPING_RELEVANT_FIELDS =
        new List<ERPSyncRecursionPrevention.ERPFieldConfig>{
            // A_BusinessPartner
            new ERPSyncRecursionPrevention.ERPFieldConfig('ERPCustomerNumber__c', Schema.DisplayType.STRING),
            new ERPSyncRecursionPrevention.ERPFieldConfig('Name', Schema.DisplayType.STRING),
            new ERPSyncRecursionPrevention.ERPFieldConfig('LegalForm__c', Schema.DisplayType.PICKLIST),
            new ERPSyncRecursionPrevention.ERPFieldConfig('Salutation__c', Schema.DisplayType.PICKLIST),
            new ERPSyncRecursionPrevention.ERPFieldConfig('BusinessPartnerGrouping__c', Schema.DisplayType.PICKLIST),
            new ERPSyncRecursionPrevention.ERPFieldConfig('BusinessPartnerCategory__c', Schema.DisplayType.PICKLIST),
            new ERPSyncRecursionPrevention.ERPFieldConfig('ERPLockStatus__c', Schema.DisplayType.PICKLIST),
            // A_CustomerSalesArea
            new ERPSyncRecursionPrevention.ERPFieldConfig('SalesCategory__c', Schema.DisplayType.PICKLIST),
            new ERPSyncRecursionPrevention.ERPFieldConfig('CustomerGroup2__c', Schema.DisplayType.PICKLIST),
            new ERPSyncRecursionPrevention.ERPFieldConfig('SalesOrganization__c', Schema.DisplayType.PICKLIST),
            new ERPSyncRecursionPrevention.ERPFieldConfig('DistributionChannel__c', Schema.DisplayType.PICKLIST),
            new ERPSyncRecursionPrevention.ERPFieldConfig('ShippingCondition__c', Schema.DisplayType.PICKLIST),
            // A_CustomerSalesArea + A_CustomerCompany
            new ERPSyncRecursionPrevention.ERPFieldConfig('ERPPaymentTerms__c', Schema.DisplayType.PICKLIST),
            // KNVH hierarchy. Both pairs are watched on purpose: JJD-39 moved the reads to
            // ConditionChainParent__r / StatisticChainParent__r, and the superseded pair is kept
            // here until the old fields are confirmed dead.
            new ERPSyncRecursionPrevention.ERPFieldConfig('ConditionChainParent__c', Schema.DisplayType.REFERENCE),
            new ERPSyncRecursionPrevention.ERPFieldConfig('StatisticChainParent__c', Schema.DisplayType.REFERENCE),
            new ERPSyncRecursionPrevention.ERPFieldConfig('ChainParentConditionID__c', Schema.DisplayType.REFERENCE),
            new ERPSyncRecursionPrevention.ERPFieldConfig('ParentId', Schema.DisplayType.REFERENCE),
            // Denormalised copies carried in the event itself
            new ERPSyncRecursionPrevention.ERPFieldConfig('ParentERPCustomerNumber__c', Schema.DisplayType.STRING),
            new ERPSyncRecursionPrevention.ERPFieldConfig('StatisticParentERPCustomerNumber__c', Schema.DisplayType.STRING)
        };

    @TestVisible
    private static Boolean useTestMock = Test.isRunningTest();

    public static Set<Id> erpUpdatedAccounts = new Set<Id>();

    public static void sendNewAccountToERPOnOpportunityQualified(Map<Id, Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunities) {
        if (newOpportunities == null || newOpportunities.isEmpty()) return;

        Set<Id> qualifiedOpportunityAccountIds = new Set<Id>();
        for (Id opportunityId : newOpportunities.keySet()) {
            Opportunity newOpportunity = newOpportunities.get(opportunityId);

            Boolean isQualifiedOpportunityNew = oldOpportunities == null &&
                QUALIFIED_OPPORTUNITY_STAGE_NAMES.contains(newOpportunity.StageName);

            Boolean isStageChanged = oldOpportunities != null &&
                !QUALIFIED_OPPORTUNITY_STAGE_NAMES.contains(oldOpportunities.get(opportunityId).StageName) &&
                QUALIFIED_OPPORTUNITY_STAGE_NAMES.contains(newOpportunity.StageName);

            if (isQualifiedOpportunityNew || isStageChanged) {
                qualifiedOpportunityAccountIds.add(newOpportunity.AccountId);
            }
        }

        if (qualifiedOpportunityAccountIds.isEmpty()) return;
        List<NewAccount__e> accounts = new List<NewAccount__e>();

        for (Account account : getNewAccountsForERP(qualifiedOpportunityAccountIds)) {
            accounts.add(
                new NewAccount__e(
                    Id__c = account.Id,
                    Name__c = account.Name,
                    ParentErpCustomerNumber__c = account.ConditionChainParent__r.ERPCustomerNumber__c,
                    ParentDistributionChannel__c = account.ConditionChainParent__r.DistributionChannel__c,
                    ParentSalesOrganization__c = account.ConditionChainParent__r.SalesOrganization__c,
                    StatisticParentErpCustomerNumber__c = account.StatisticChainParent__r.ERPCustomerNumber__c,
                    StatisticParentDistributionChannel__c = account.StatisticChainParent__r.DistributionChannel__c,
                    StatisticParentSalesOrganization__c = account.StatisticChainParent__r.SalesOrganization__c,
                    OwnerId__c = account.OwnerId,
                    Country__c = account.BillingCountry,
                    LegalForm__c = account.LegalForm__c,
                    ILNNo__c = account.ILNNo__c,
                    Salutation__c = account.Salutation__c,
                    BusinessPartnerCategory__c = account.BusinessPartnerCategory__c,
                    CustomerGroup2__c = account.CustomerGroup2__c,
                    BusinessPartnerGrouping__c = account.BusinessPartnerGrouping__c,
                    DistributionChannel__c = account.DistributionChannel__c,
                    SalesOrganization__c = account.SalesOrganization__c,
                    ERPPaymentTerms__c = account.ERPPaymentTerms__c,
                    ShippingCondition__c = account.ShippingCondition__c,
                    CustomerTaxClassification__c = account.CustomerTaxClassification__c,
                    SalesCategory__c = account.SalesCategory__c,
                    BillingCity__c = account.BillingCity,
                    BillingCountryCode__c = CustomAddressService.getCountryCodeMap().get(account.BillingCountry),
                    BillingHouseNumber__c = CustomAddressService.addressStreetParts(account.BillingStreet)[1],
                    BillingPostal__c = account.BillingPostalCode,
                    BillingState__c = account.BillingState,
                    BillingStreet__c =  CustomAddressService.addressStreetParts(account.BillingStreet)[0],
                    ShippingCity__c = account.ShippingCity,
                    ShippingCountryCode__c = CustomAddressService.getCountryCodeMap().get(account.ShippingCountry),
                    ShippingHouseNumber__c = CustomAddressService.addressStreetParts(account.ShippingStreet)[1],
                    ShippingPostal__c = account.ShippingPostalCode,
                    ShippingState__c = account.ShippingState,
                    ShippingStreet__c =  CustomAddressService.addressStreetParts(account.ShippingStreet)[0],
                    BillingAddress__c = formatAddress(
                        account.BillingStreet,
                        account.BillingCity,
                        account.BillingState,
                        account.BillingPostalCode,
                        account.BillingCountry
                    ),
                    ShippingAddress__c = formatAddress(
                        account.ShippingStreet,
                        account.ShippingCity,
                        account.ShippingState,
                        account.ShippingPostalCode,
                        account.ShippingCountry
                    )
                )
            );
        }

        publishEvents(accounts);
    }

    // Kept for callers that have no previous state to compare against; every record is then
    // treated as relevant, which is the behaviour that existed before the field filter.
    public static void sendAccountsToERP(List<Account> accounts, Set<Id> erpUpdatedRecords) {
        sendAccountsToERP(accounts, null, erpUpdatedRecords);
    }

    public static void sendAccountsToERP(List<Account> accounts, Map<Id, Account> oldRecordsMap, Set<Id> erpUpdatedRecords) {
        if (accounts == null || accounts.isEmpty()) return;

        // 1. Collect the IDs of the accounts we need to send
        Set<Id> validAccountIds = new Set<Id>();
        for (Account account : accounts) {
            if (String.isNotBlank(account.ERPCustomerNumber__c)
                && !erpUpdatedRecords.contains(account.Id)
                && hasMappingRelevantChange(account, oldRecordsMap)) {
                validAccountIds.add(account.Id);
            }
        }

        if (validAccountIds.isEmpty()) return;

        // 2. Query the related parent fields
        Map<Id, Account> parentDataMap = new Map<Id, Account>([
            SELECT Id, 
                   ConditionChainParent__r.ERPCustomerNumber__c, ConditionChainParent__r.DistributionChannel__c, ConditionChainParent__r.SalesOrganization__c,
                   StatisticChainParent__r.ERPCustomerNumber__c, StatisticChainParent__r.DistributionChannel__c, StatisticChainParent__r.SalesOrganization__c
            FROM Account 
            WHERE Id IN :validAccountIds
        ]);

        List<AccountChanged__e> accountsToSend = new List<AccountChanged__e>();
        
        for (Account account : accounts) {
            if (!validAccountIds.contains(account.Id)) continue;

            // Take parent data from the query above
            Account parentData = parentDataMap.get(account.Id);

            accountsToSend.add(
                new AccountChanged__e(
                    Id__c = account.Id,
                    Name__c = account.Name,
                    
                    // Take from the queried data (parentData), not from (account)
                    ParentErpCustomerNumber__c = parentData.ConditionChainParent__r?.ERPCustomerNumber__c,
                    ParentDistributionChannel__c = parentData.ConditionChainParent__r?.DistributionChannel__c,
                    ParentSalesOrganization__c = parentData.ConditionChainParent__r?.SalesOrganization__c,
                    StatisticParentErpCustomerNumber__c = parentData.StatisticChainParent__r?.ERPCustomerNumber__c,
                    StatisticParentDistributionChannel__c = parentData.StatisticChainParent__r?.DistributionChannel__c,
                    StatisticParentSalesOrganization__c = parentData.StatisticChainParent__r?.SalesOrganization__c,
                    
                    // All other flat fields still come from the original account
                    OwnerId__c = account.OwnerId,
                    Country__c = account.BillingCountry,
                    LegalForm__c = account.LegalForm__c,
                    CustomerGroup2__c = account.CustomerGroup2__c,
                    ILNNo__c = account.ILNNo__c,
                    BusinessPartnerCategory__c = account.BusinessPartnerCategory__c,
                    BusinessPartnerGrouping__c = account.BusinessPartnerGrouping__c,
                    DistributionChannel__c = account.DistributionChannel__c,
                    SalesOrganization__c = account.SalesOrganization__c,
                    ERPPaymentTerms__c = account.ERPPaymentTerms__c,
                    ShippingCondition__c = account.ShippingCondition__c,
                    CustomerTaxClassification__c = account.CustomerTaxClassification__c,
                    SalesCategory__c = account.SalesCategory__c,
                    Salutation__c = account.Salutation__c,
                    BillingCity__c = account.BillingCity,
                    BillingCountryCode__c = CustomAddressService.getCountryCodeMap().get(account.BillingCountry),
                    BillingHouseNumber__c = CustomAddressService.addressStreetParts(account.BillingStreet)[1],
                    BillingPostal__c = account.BillingPostalCode,
                    BillingState__c = account.BillingState,
                    BillingStreet__c =  CustomAddressService.addressStreetParts(account.BillingStreet)[0],
                    ShippingCity__c = account.ShippingCity,
                    ShippingCountryCode__c = CustomAddressService.getCountryCodeMap().get(account.ShippingCountry),
                    ShippingHouseNumber__c = CustomAddressService.addressStreetParts(account.ShippingStreet)[1],
                    ShippingPostal__c = account.ShippingPostalCode,
                    ShippingState__c = account.ShippingState,
                    ShippingStreet__c =  CustomAddressService.addressStreetParts(account.ShippingStreet)[0],
                    BillingAddress__c = formatAddress(
                        account.BillingStreet,
                        account.BillingCity,
                        account.BillingState,
                        account.BillingPostalCode,
                        account.BillingCountry
                    ),
                    ShippingAddress__c = formatAddress(
                        account.ShippingStreet,
                        account.ShippingCity,
                        account.ShippingState,
                        account.ShippingPostalCode,
                        account.ShippingCountry
                    ),
                    ERPCustomerNumber__c = account.ERPCustomerNumber__c,
                    ERPLockStatus__c = account.ERPLockStatus__c
                )
            );
        }

        publishEvents(accountsToSend);
    }

    // Without a previous state - insert context, or a caller that does not supply Trigger.oldMap -
    // the change cannot be classified, so the record is published as before.
    private static Boolean hasMappingRelevantChange(Account newRecord, Map<Id, Account> oldRecordsMap) {
        if (oldRecordsMap == null) {
            return true;
        }

        Account oldRecord = oldRecordsMap.get(newRecord.Id);

        if (oldRecord == null) {
            return true;
        }

        return ERPSyncRecursionPrevention.isAnyFieldChanged(newRecord, oldRecord, ACCOUNT_MAPPING_RELEVANT_FIELDS);
    }

    public static void sendContactsToERP(Map<Id, Contact> newContacts, Set<Id> erpUpdatedRecords, Boolean isCreatedContact) {
        if (newContacts == null || newContacts.isEmpty()) return;

        Map<Id, Contact> relatedAccountIds = new Map<Id, Contact>();
        for (Contact contact : newContacts.values()) {
            relatedAccountIds.put(contact.AccountId, contact);
        }

        if (relatedAccountIds.isEmpty()) return;

        List<SObject> contactEvents = buildContactEvents(relatedAccountIds, erpUpdatedRecords, isCreatedContact);

        if (!contactEvents.isEmpty()) {
            publishEvents(contactEvents);
        }
    }

    private static List<SObject> buildContactEvents(Map<Id, Contact> relatedAccountIds, Set<Id> erpUpdatedRecords, Boolean isCreatedContact) {
        List<SObject> events = new List<SObject>();

        for (Account account : [SELECT Id, BillingCountry, ERPCustomerNumber__c FROM Account WHERE Id IN :relatedAccountIds.keySet() AND ERPCustomerNumber__c != NULL]) {
            Contact contactToSend = relatedAccountIds.get(account.Id);

            if (erpUpdatedRecords.contains(contactToSend.Id)) continue;

            SObject contactEvent = isCreatedContact
                ? (SObject) new ContactCreated__e()
                : (SObject) new ContactChanged__e();

            mapContactFields(contactToSend, account, contactEvent);
            events.add(contactEvent);
        }

        return events;
    }

    private static void mapContactFields(Contact contact, Account account, SObject event) {
        event.put('Id__c', contact.Id);
        event.put('Salutation__c', contact.Salutation);
        event.put('FirstName__c', contact.FirstName);
        event.put('LastName__c', contact.LastName);
        event.put('Name__c', contact.Name);
        event.put('OwnerId__c', contact.OwnerId);
        event.put('AccountId__c', account.Id);
        event.put('ERPCustomerNumber__c', account.ERPCustomerNumber__c);
        event.put('ERPContactNumber__c', contact.ERPContactNumber__c);
        event.put('MailingCity__c', contact.MailingCity);
        event.put('MailingCountryCode__c', CustomAddressService.getCountryCodeMap().get(contact.MailingCountry));
        event.put('MailingHouseNumber__c', CustomAddressService.addressStreetParts(contact.MailingStreet)[1]);
        event.put('MailingPostal__c', contact.MailingPostalCode);
        event.put('MailingState__c', contact.MailingState);
        event.put('MailingStreet__c', contact.MailingStreet);
        event.put('MailingAddress__c', formatAddress(
            contact.MailingStreet,
            contact.MailingCity,
            contact.MailingState,
            contact.MailingPostalCode,
            contact.MailingCountry
        ));
        event.put('Email__c', contact.Email);
        event.put('Fax__c', contact.Fax);
        event.put('Phone__c', contact.Phone);
        event.put('MobilePhone__c', contact.MobilePhone);
    }

    // Trigger 2 — New AccountContactRelationship (SF -> SAP).
    // Publishes one AccountContactRelationCreated__e per (already-synced account, contact) pair.
    // Reuses the existing contact mapping/pipeline; the SAP BP relationship (step 16-8) and the
    // "already synchronized -> skip to 16-8" branch are handled on the Mule/SAP side.
    public static void sendAccountContactRelationsToERP(List<AccountContactRelation> relations) {
        if (relations == null || relations.isEmpty()) return;

        Map<Id, Id> contactToAccount = new Map<Id, Id>();
        for (AccountContactRelation relation : relations) {
            if (relation.ContactId != null && relation.AccountId != null) {
                contactToAccount.put(relation.ContactId, relation.AccountId);
            }
        }
        if (contactToAccount.isEmpty()) return;

        Map<Id, Contact> contacts = new Map<Id, Contact>([
            SELECT Id, Salutation, FirstName, LastName, Name, OwnerId, ERPContactNumber__c,
                   MailingCity, MailingCountry, MailingState, MailingPostalCode, MailingStreet,
                   Email, Fax, Phone, MobilePhone
            FROM Contact WHERE Id IN :contactToAccount.keySet()
        ]);

        // Only accounts already present in SAP (ERPCustomerNumber__c populated) can receive a relationship.
        Map<Id, Account> accounts = new Map<Id, Account>([
            SELECT Id, BillingCountry, ERPCustomerNumber__c
            FROM Account WHERE Id IN :contactToAccount.values() AND ERPCustomerNumber__c != NULL
        ]);

        List<SObject> events = new List<SObject>();
        for (Id contactId : contacts.keySet()) {
            Account account = accounts.get(contactToAccount.get(contactId));
            if (account == null) continue;

            SObject event = new AccountContactRelationCreated__e();
            mapContactFields(contacts.get(contactId), account, event);
            events.add(event);
        }

        publishEvents(events);
    }

    // Step 16-6 — End-dating / deactivation of an AccountContactRelationship (SF -> SAP).
    // Publishes one AccountContactRelationChanged__e per (account, contact) pair that is already in SAP.
    // The effective end date is decided by the caller (EndDate change -> field value; deactivation/delete -> Today()).
    // The SAP-side relationship end-dating (ValidityEndDate update) is handled on the Mule/SAP side.
    public static void sendAccountContactRelationEndDatingToERP(List<AccountContactRelation> relations, Map<Id, Date> endDateByRelationId) {
        if (relations == null || relations.isEmpty()) return;

        Set<Id> contactIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        for (AccountContactRelation relation : relations) {
            if (relation.ContactId != null) contactIds.add(relation.ContactId);
            if (relation.AccountId != null) accountIds.add(relation.AccountId);
        }
        if (contactIds.isEmpty() || accountIds.isEmpty()) return;

        // Only pairs already present in SAP carry a relationship that can be end-dated.
        Map<Id, Contact> contacts = new Map<Id, Contact>([
            SELECT Id, ERPContactNumber__c
            FROM Contact WHERE Id IN :contactIds AND ERPContactNumber__c != NULL
        ]);
        Map<Id, Account> accounts = new Map<Id, Account>([
            SELECT Id, ERPCustomerNumber__c
            FROM Account WHERE Id IN :accountIds AND ERPCustomerNumber__c != NULL
        ]);

        List<SObject> events = new List<SObject>();
        for (AccountContactRelation relation : relations) {
            Contact contact = contacts.get(relation.ContactId);
            Account account = accounts.get(relation.AccountId);
            if (contact == null || account == null) continue;

            events.add(new AccountContactRelationChanged__e(
                Id__c = relation.Id,
                ERPCustomerNumber__c = account.ERPCustomerNumber__c,
                ERPContactNumber__c = contact.ERPContactNumber__c,
                EndDate__c = endDateByRelationId.get(relation.Id),
                IsActive__c = false
            ));
        }

        publishEvents(events);
    }

    public static void sendCustomAddressToERP(List<CustomAddress__c> addresses, Set<Id> erpUpdatedAddressed) {
        if (addresses == null || addresses.isEmpty()) return;

        List<CustomAddressEvent__e> addressesToSend = new List<CustomAddressEvent__e>();

        Map<String, String> countries = CustomAddressService.getCountryByCodeMap();
        Map<String, String> states = CustomAddressService.getStateByCodeMap();

        for (CustomAddress__c address : addresses) {
            if (erpUpdatedAddressed.contains(address.Id)) continue;

            addressesToSend.add(
                new CustomAddressEvent__e(
                    Id__c = address.Id,
                    LookupType__c = address.LookupType__c,
                    RelatedId__c = address.RelatedId__c,
                    ValidFrom__c = address.ValidFrom__c,
                    ValidTo__c = address.ValidTo__c,
                    AddressType__c = address.AddressType__c,
                    ExternalID__c = address.ExternalID__c,
                    IsPrimary__c = address.IsPrimary__c,
                    ERPCustomerNumber__c = address.ERPCustomerNumber__c,
                    Country__c = countries.get(address.Address__CountryCode__s),
                    City__c = address.Address__City__s,
                    Street__c = address.Address__Street__s,
                    PostalCode__c = address.Address__PostalCode__s,
                    Address__c = formatAddress(
                        address.Address__Street__s,
                        address.Address__City__s,
                        states.get(address.Address__StateCode__s),
                        address.Address__PostalCode__s,
                        countries.get(address.Address__CountryCode__s)
                    )
                )
            );
        }

        publishEvents(addressesToSend);
    }

    public static void sendBankAccountToERP(List<BankInfo__c> bankAccounts, Set<Id> erpUpdatedAddressed) {
        List<BankAccountCreated__e> bankAccountsToBeCreated = new List<BankAccountCreated__e>();
        List<BankAccountUpdated__e> bankAccountsToBeUpdated = new List<BankAccountUpdated__e>();

        for (BankInfo__c bankAccount : bankAccounts) {
            if (bankAccount.ERPCustomerNumber__c == null || bankAccount.Account__c == null || erpUpdatedAddressed.contains(bankAccount.Id)) {
                continue;
            }

            Boolean isBankIdentificationExist = bankAccount.ERPInternalBankId__c == null;
            SObject bankAccountEvent = isBankIdentificationExist
            ? (SObject)new BankAccountCreated__e()
            : (SObject)new BankAccountUpdated__e();

            mapDynamicFields(bankAccount, bankAccountEvent, BANK_ACCOUNT_FIELD_APIS);
            bankAccountEvent.put('Id__c', bankAccount.Id);

            if (isBankIdentificationExist) {
                bankAccountsToBeCreated.add((BankAccountCreated__e)bankAccountEvent);
            } else {
                bankAccountsToBeUpdated.add((BankAccountUpdated__e)bankAccountEvent);
            }
        }

        if (!bankAccountsToBeCreated.isEmpty()) {
            publishEvents(bankAccountsToBeCreated);
        }

        if (!bankAccountsToBeUpdated.isEmpty()) {
            publishEvents(bankAccountsToBeUpdated);
        }
    }

    private static void mapDynamicFields(SObject source, SObject target, List<String> fieldNames) {
        for (String fieldName : fieldNames) {
            Object value = source.get(fieldName);
            if (value != null) {
                target.put(fieldName, value);
            }
        }
    }

    private static void publishEvents(List<SObject> events) {
        if (useTestMock) {
            ERPIntegrationEventPublisherTest.mockEventBusPublish(events);
        } else {
            EventBus.publish(events);
        }
    }

    @TestVisible
    private static List<Account> getNewAccountsForERP(Set<Id> qualifiedOpportunityAccountIds) {
        return [
            SELECT Id, Name, OwnerId, LegalForm__c, ILNNo__c, Salutation__c,
                   BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                   ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry,
                   BusinessPartnerCategory__c, BusinessPartnerGrouping__c, DistributionChannel__c,
                   SalesOrganization__c, ERPPaymentTerms__c, ShippingCondition__c, CustomerGroup2__c, CustomerTaxClassification__c, SalesCategory__c,
            	   StatisticChainParent__r.ERPCustomerNumber__c, ConditionChainParent__r.ERPCustomerNumber__c, ConditionChainParent__r.DistributionChannel__c,
            	   ConditionChainParent__r.SalesOrganization__c, StatisticChainParent__r.DistributionChannel__c, StatisticChainParent__r.SalesOrganization__c
            FROM Account
            WHERE Id IN :qualifiedOpportunityAccountIds
            AND ERPCustomerNumber__c = NULL
            AND ERPLockStatus__c != :NOT_SANCTIONED_STATUS
            AND ERPLockStatus__c != :CREDIT_RATING_STATUS
        ];
    }

    @TestVisible
    private static String formatAddress(String street, String city, String state, String postalCode, String country) {
        List<String> addressParts = new List<String>();

        if (String.isNotBlank(street)) addressParts.add(street);
        if (String.isNotBlank(city)) addressParts.add(city);
        if (String.isNotBlank(state)) addressParts.add(state);
        if (String.isNotBlank(postalCode)) addressParts.add(postalCode);
        if (String.isNotBlank(country)) addressParts.add(country);

        return addressParts.isEmpty() ? null : String.join(addressParts, ', ');
    }
}