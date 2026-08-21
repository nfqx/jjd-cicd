public without sharing class OpportunityTriggerHandler {

    public static void handleAfterInsert(Map<Id, Opportunity> newRecordsMap) {
        ERPIntegrationEventPublisher.sendNewAccountToERPOnOpportunityQualified(newRecordsMap, null);
        PricingConditionSyncService.publishForClosedWonOpportunities(newRecordsMap, null);
    }

    public static void handleAfterUpdate(Map<Id, Opportunity> newRecordsMap, Map<Id, Opportunity> oldRecordsMap) {
        ERPIntegrationEventPublisher.sendNewAccountToERPOnOpportunityQualified(newRecordsMap, oldRecordsMap);
        PricingConditionSyncService.publishForClosedWonOpportunities(newRecordsMap, oldRecordsMap);
    }
}