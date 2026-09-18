public without sharing class LeadTriggerHandler {

    public static void handleAfterUpdate(List<Lead> newRecords, Map<Id, Lead> oldRecordsMap) {
        sendConvertedAccountsToERP(newRecords, oldRecordsMap);
    }

    // Converting a Lead into an existing Account inserts no new Account, so the Account insert
    // trigger never runs for it. Conversions into a new Account arrive here as well; the publisher
    // drops those because the Account insert already sent them.
    private static void sendConvertedAccountsToERP(List<Lead> newRecords, Map<Id, Lead> oldRecordsMap) {
        Set<Id> convertedAccountIds = new Set<Id>();

        for (Lead lead : newRecords) {
            Boolean isJustConverted = lead.IsConverted && !oldRecordsMap.get(lead.Id).IsConverted;

            if (isJustConverted && lead.ConvertedAccountId != null) {
                convertedAccountIds.add(lead.ConvertedAccountId);
            }
        }

        ERPIntegrationEventPublisher.sendConvertedAccountsToERP(convertedAccountIds);
    }
}