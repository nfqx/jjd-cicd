public with sharing class ContactTriggerHandler {

    public static void handleAfterInsert(Map<Id, Contact> newRecordsMap) {
        publish(newRecordsMap, null, true);
        handleAddressChange(newRecordsMap, null);
    }

    public static void handleAfterUpdate(Map<Id, Contact> newRecordsMap, Map<Id, Contact> oldRecordsMap) {
        publish(newRecordsMap, oldRecordsMap, false);
        handleAddressChange(newRecordsMap, oldRecordsMap);
    }

    private static void publish(Map<Id, Contact> newRecordsMap, Map<Id, Contact> oldRecordsMap, Boolean isCreationContext) {
        ERPIntegrationEventPublisher.sendContactsToERP(
            newRecordsMap,
            ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
                newRecordsMap.values(),
                oldRecordsMap
            ),
            isCreationContext
        );
    }

    public static void handleAddressChange(Map<Id, Contact> newRecordsMap, Map<Id, Contact> oldRecordsMap) {
        Map<Id, List<CustomAddressWrapper>> updatedAddresses = CustomAddressService.checkAddressChangesBulk(
            newRecordsMap, oldRecordsMap
        );

        if (!updatedAddresses.isEmpty()) {
            CustomAddressService.syncCustomAddress(updatedAddresses);
        }
    }
}