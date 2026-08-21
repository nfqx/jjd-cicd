public with sharing class CustomAddressService {

    public static final String FIELD_STREET            = 'Street';
    public static final String FIELD_CITY              = 'City';
    public static final String FIELD_STATE             = 'State';
    public static final String FIELD_POSTAL_CODE       = 'PostalCode';
    public static final String FIELD_COUNTRY           = 'Country';
    public static final String SOBJECT_ACCOUNT         = 'Account';
    public static final String SOBJECT_CONTACT         = 'Contact';
    public static final String BILLING_ADDRESS_TYPE    = 'Billing';
    public static final String SHIPPING_ADDRESS_TYPE   = 'Shipping';
    public static final String MAILING_ADDRESS_TYPE    = 'Mailing';

    // GENERAL ADDRESS DATASETS AND MAPPINGS
    public static final Map<String, String> VALID_COUNTRY_CODES = getCountryCodeMap();
    public static final List<String> ADDRESS_FIELDS = new List<String> { FIELD_STREET, FIELD_CITY, FIELD_STATE, FIELD_POSTAL_CODE, FIELD_COUNTRY };
    public static final Set<String>  ACCEPTED_SOBJECT_TYPES = new Set<String>  { SOBJECT_ACCOUNT, SOBJECT_CONTACT };
    public static final Map<String, List<String>> ADDRESS_TYPES_BY_SOBJECT = new Map<String, List<String>> {
        SOBJECT_ACCOUNT => new List<String> { BILLING_ADDRESS_TYPE, SHIPPING_ADDRESS_TYPE },
        SOBJECT_CONTACT => new List<String> { MAILING_ADDRESS_TYPE }
    };

    // IDENTIFYING IF SOBJECT HAS ANY CHANGES IN ANY TYPES OF ADDRESS.
    // COLLECTING CHANGED DATA BY SOBJECT ID => LIST OF ADDRESSES WITH DIFFERENT TYPES (IN CASE BILLING AND SHIPPING ARE CHANGED AT ONCE)
    public static Map<Id, List<CustomAddressWrapper>> checkAddressChangesBulk(Map<Id, sObject> newRecordsMap, Map<Id, sObject> oldRecordsMap) {
        Map<Id, List<CustomAddressWrapper>> result = new Map<Id, List<CustomAddressWrapper>>();
        if (newRecordsMap == null || newRecordsMap.isEmpty()) {
            return result;
        }

        String objectType = newRecordsMap.values()[0].getSObjectType().getDescribe().getName();
        if (!ACCEPTED_SOBJECT_TYPES.contains(objectType)) {
            return result;
        }

        for (Id recordId : newRecordsMap.keySet()) {
            sObject newRecord = newRecordsMap.get(recordId);
            sObject oldRecord = oldRecordsMap != null ? oldRecordsMap.get(recordId) : null;

            Boolean erpNumberPopulated = false;
            if (oldRecord != null) {
                String oldERPNumber = (String)oldRecord.get(objectType == SOBJECT_ACCOUNT ? 'ERPCustomerNumber__c' : 'ERPContactNumber__c');
                String newERPNumber = (String)newRecord.get(objectType == SOBJECT_ACCOUNT ? 'ERPCustomerNumber__c' : 'ERPContactNumber__c');
                erpNumberPopulated = String.isBlank(oldERPNumber) && !String.isBlank(newERPNumber);
            }

            for (String addressType : ADDRESS_TYPES_BY_SOBJECT.get(objectType)) {
                CustomAddressWrapper addressWrapper = new CustomAddressWrapper();
                addressWrapper.recordId = recordId;
                addressWrapper.objectType = objectType;
                addressWrapper.addressType = addressType;
                addressWrapper.isAddressChanged = false;
                addressWrapper.ecn = (String)newRecord.get(
                    objectType == SOBJECT_ACCOUNT ? 'ERPCustomerNumber__c' : 'ERPContactNumber__c'
                );

                for (String field : ADDRESS_FIELDS) {
                    String apiField = addressType + field;
                    Object newValue = newRecord.get(apiField);
                    Object oldValue = (oldRecord != null) ? oldRecord.get(apiField) : null;

                    switch on field {
                        when 'Street' {
                            addressWrapper.street = String.valueOf(newValue);
                            if (newValue != oldValue) {
                                addressWrapper.isAddressChanged = true;
                            }
                        }
                        when 'City' {
                            addressWrapper.city = String.valueOf(newValue);
                            if (newValue != oldValue) {
                                addressWrapper.isAddressChanged = true;
                            }
                        }
                        when 'State' {
                            addressWrapper.state = String.valueOf(newValue);
                            if (newValue != oldValue) {
                                addressWrapper.isAddressChanged = true;
                            }
                        }
                        when 'PostalCode' {
                            addressWrapper.postalCode = String.valueOf(newValue);
                            if (newValue != oldValue) {
                                addressWrapper.isAddressChanged = true;
                            }
                        }
                        when 'Country' {
                            addressWrapper.country = String.valueOf(newValue);
                            if (newValue != oldValue) {
                                addressWrapper.isAddressChanged = true;
                            }
                        }
                    }
                }

                if (addressWrapper.isAddressChanged || erpNumberPopulated) {
                    addressWrapper.fullAddress = compoundAddress(addressWrapper);

                    if (result.containsKey(recordId)) {
                        result.get(recordId).add(addressWrapper);
                    } else {
                        result.put(recordId, new List<CustomAddressWrapper> { addressWrapper });
                    }
                }
            }
        }

        return result;
    }

    // CREATED OR UPDATE CUSTOM ADDRESSES BASED ON THE CHANGED SOBJECT ADDRESS DATA
    public static void syncCustomAddress(Map<Id, List<CustomAddressWrapper>> updatedAddresses) {
        if (updatedAddresses == null || updatedAddresses.isEmpty()) {
            return;
        }

        List<CustomAddress__c> addresses = new List<CustomAddress__c>();
        Map<Id, List<CustomAddress__c>> addressesByEntity = getAddressesByEntity(
            getExistingCustomAddresses(updatedAddresses.keySet())
        );

        for (Id relatedObjectId : updatedAddresses.keySet()) {
            for (CustomAddressWrapper addressData : updatedAddresses.get(relatedObjectId)) {
                if (String.isBlank(addressData.postalCode) || String.isBlank(addressData.ecn)) {
                    continue;
                }

                CustomAddress__c address     = new CustomAddress__c();
                address.LookupType__c        = addressData.objectType;
                address.RelatedId__c         = relatedObjectId;
                address.ValidFrom__c         = Date.today();
                address.ValidTo__c           = Date.today().addYears(1000);
                address.AddressType__c       = addressData.addressType;
                address.ExternalID__c        = addressData.externalId;
                address.IsPrimary__c         = true;

                if (addressesByEntity.containsKey(relatedObjectId)) {
                    for (CustomAddress__c addressByEntity : addressesByEntity.get(relatedObjectId)) {
                        if (addressByEntity.AddressType__c == addressData.addressType) {
                            address = addressByEntity;
                            break;
                        }
                    }
                }

                address.Address__CountryCode__s = VALID_COUNTRY_CODES.get(addressData.country);
                address.Address__City__s        = addressData.city;
                address.Address__Street__s      = addressData.street;
                address.Address__PostalCode__s  = addressData.postalCode;
                address.Address__StateCode__s   = getStateCode(
                    VALID_COUNTRY_CODES.get(addressData.country),
                    addressData.state,
                    addressData.addressType
                );
                address.ErpCustomerNumber__c    = addressData.ecn;

                addresses.add(address);
            }
        }

        upsert addresses;
    }

    // IN THE COMPOUND FIELD SLITTED COUNTRY__S FIELD IS POPULATED BY THE SPECIAL COUNTRY CODE - NOT FULL COUNTRY NAME
    // EXTRACT MAPPING COUNTRY => CODE
    public static Map<String, String> getCountryCodeMap() {
        Map<String, String> validCountryCodes = new Map<String, String>();
        for (Schema.PicklistEntry ple : CustomAddress__c.Address__CountryCode__s.getDescribe().getPicklistValues()) {
            validCountryCodes.put(ple.getLabel(), ple.getValue());
        }

        return validCountryCodes;
    }

    public static Map<String, String> getStateCodeMap() {
        Map<String, String> validStateCodes = new Map<String, String>();
        for (Schema.PicklistEntry ple : CustomAddress__c.Address__StateCode__s.getDescribe().getPicklistValues()) {
            validStateCodes.put(ple.getLabel(), ple.getValue());
        }

        return validStateCodes;
    }

    public static Map<String, String> getCountryByCodeMap() {
        Map<String, String> validCountryCodes = new Map<String, String>();
        for (Schema.PicklistEntry ple : CustomAddress__c.Address__CountryCode__s.getDescribe().getPicklistValues()) {
            validCountryCodes.put(ple.getValue(), ple.getLabel());
        }

        return validCountryCodes;
    }

    public static Map<String, String> getStateByCodeMap() {
        Map<String, String> validStateCodes = new Map<String, String>();
        for (Schema.PicklistEntry ple : CustomAddress__c.Address__StateCode__s.getDescribe().getPicklistValues()) {
            validStateCodes.put(ple.getValue(), ple.getLabel());
        }

        return validStateCodes;
    }

    public static List<String> addressStreetParts(String fullAddress) {
        List<String> parts = new List<String>();

        String houseNumber = null;
        String streetOnly = null;

        if (fullAddress != null) {
            fullAddress = fullAddress.trim();

            Pattern patternEnd = Pattern.compile('^(.*?),\\s*(\\d+[\\-\\s]?\\d*[a-zA-Z]?)$');
            Matcher matcherEnd = patternEnd.matcher(fullAddress);
            Pattern patternStart = Pattern.compile('^(\\d+[\\-\\s]?\\d*[a-zA-Z]?)[\\s,]+(.*)$');
            Matcher matcherStart = patternStart.matcher(fullAddress);

            if (matcherEnd.matches()) {
                streetOnly = matcherEnd.group(1).trim();
                houseNumber = matcherEnd.group(2).trim();
            } else if (matcherStart.matches()) {
                houseNumber = matcherStart.group(1).trim();
                streetOnly = matcherStart.group(2).trim();
            } else {
                streetOnly = fullAddress;
            }
        }

        parts.add(streetOnly);
        parts.add(houseNumber);

        return parts;
    }

    private static String getStateCode(String countryCode, String stateLabel, String addressPrefix) {
        System.debug(addressPrefix);
        Schema.DescribeFieldResult countryDesc = Schema.SObjectType.Account.fields.getMap()?.get(addressPrefix + 'CountryCode')?.getDescribe();
        Schema.DescribeFieldResult stateDesc   = Schema.SObjectType.Account.fields.getMap()?.get(addressPrefix + 'StateCode')?.getDescribe();

        if (countryDesc == null || stateDesc == null) {
            return null;
        }

        // Find the index of the controller value (country)
        Integer countryIndex;
        List<Schema.PicklistEntry> countryEntries = countryDesc.getPicklistValues();

        for (Integer i = 0; i < countryEntries.size(); i++) {
            if (countryEntries[i].getValue() == countryCode) {
                countryIndex = i; break;
            }
        }

        if (countryIndex == null) return null;

        // Check dependent picklist values
        for (Schema.PicklistEntry pe : stateDesc.getPicklistValues()) {
            if (pe.getLabel() == stateLabel) {
                return pe.getValue();
            }
        }

        return null;
    }

    // JOIN FULL ADDRESS BY COMPOUND PARTS
    @TestVisible
    private static String compoundAddress(CustomAddressWrapper addressWrapper) {
        return String.join(new List<String>{
            addressWrapper.street,
            addressWrapper.city,
            addressWrapper.state,
            addressWrapper.postalCode,
            addressWrapper.country
        }, ', ').replaceAll('null,?', '').trim();
    }

    // COLLECT EXISTING ADDRESSES BY RELATED OBJECT ID
    private static Map<Id, List<CustomAddress__c>> getAddressesByEntity(List<CustomAddress__c> existingCustomAddresses) {
        Map<Id, List<CustomAddress__c>> addressesByEntity = new Map<Id, List<CustomAddress__c>>();
        for (CustomAddress__c existingCustomAddress : existingCustomAddresses) {
            if (addressesByEntity.containsKey(existingCustomAddress.RelatedId__c)) {
                addressesByEntity.get(existingCustomAddress.RelatedId__c).add(existingCustomAddress);
            } else {
                addressesByEntity.put(
                    existingCustomAddress.RelatedId__c,
                    new List<CustomAddress__c> { existingCustomAddress }
                );
            }
        }

        return addressesByEntity;
    }

    // QUERY EXISTING CUSTOM ADDRESSES TO MODIFY
    private static List<CustomAddress__c> getExistingCustomAddresses(Set<Id> relatedEntityIds) {
        return [
            SELECT  Id, LookupType__c, RelatedId__c, ValidFrom__c, ValidTo__c,
                    AddressType__c, Address__Street__s, Address__City__s, Address__PostalCode__s,
                    Address__StateCode__s, Address__CountryCode__s, Address__Latitude__s,
                    Address__Longitude__s, Address__GeocodeAccuracy__s, Address__c,
                    ExternalID__c, IsPrimary__c, ErpCustomerNumber__c
            FROM    CustomAddress__c
            WHERE   RelatedId__c IN :relatedEntityIds
        ];
    }
}