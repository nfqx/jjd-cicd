public with sharing class CustomAddressTriggerHandler {

    public static void handleBeforeInsert(List<CustomAddress__c> newRecords) {
        Set<String> customerNumbers = new Set<String>();

        for (CustomAddress__c ca : newRecords) {
            if (String.isNotBlank(ca.ERPCustomerNumber__c)) {
                customerNumbers.add(ca.ERPCustomerNumber__c);
            }
        }

        Map<String, Id> accountMap = new Map<String, Id>();

        for (Account a : [
            SELECT Id, ERPCustomerNumber__c
            FROM Account
            WHERE ERPCustomerNumber__c IN :customerNumbers
        ]) {
            accountMap.put(a.ERPCustomerNumber__c, a.Id);
        }

        for (CustomAddress__c ca : newRecords) {
            if(String.isNotBlank(ca.ERPCustomerNumber__c)){
                ca.Account__c = accountMap.get(ca.ERPCustomerNumber__c);
            }
        }
    }

    public static void handleAfterInsert(List<CustomAddress__c> newRecords) {
        publish(newRecords, null);
    }

    public static void handleAfterUpdate(List<CustomAddress__c> newRecords, Map<Id, CustomAddress__c> oldRecordsMap) {
        List<CustomAddress__c> addressesToPublish = new List<CustomAddress__c>();
        for (CustomAddress__c newAddress : newRecords) {
            CustomAddress__c oldAddress = oldRecordsMap.get(newAddress.Id);
            if (oldAddress != null) {
                Boolean externalIdChanged = newAddress.ExternalID__c != oldAddress.ExternalID__c;
                if (!externalIdChanged) {
                    addressesToPublish.add(newAddress);
                }
            } else {
                addressesToPublish.add(newAddress);
            }
        }

        if (!addressesToPublish.isEmpty()) {
            publish(addressesToPublish, oldRecordsMap);
        }
    }

    private static void publish(List<CustomAddress__c> newRecords, Map<Id, CustomAddress__c> oldRecordsMap) {
        ERPIntegrationEventPublisher.sendCustomAddressToERP(
            newRecords,
            ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
                newRecords,
                oldRecordsMap
            )
        );
    }
}