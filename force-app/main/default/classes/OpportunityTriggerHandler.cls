public without sharing class OpportunityTriggerHandler {

    public static void handleAfterInsert(Map<Id, Opportunity> newRecordsMap) {
        PricingConditionSyncService.publishForClosedWonOpportunities(newRecordsMap, null);
    }

    public static void handleAfterUpdate(Map<Id, Opportunity> newRecordsMap, Map<Id, Opportunity> oldRecordsMap) {
        PricingConditionSyncService.publishForClosedWonOpportunities(newRecordsMap, oldRecordsMap);
    }
}