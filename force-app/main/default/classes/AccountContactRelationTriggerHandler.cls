public with sharing class AccountContactRelationTriggerHandler {

    public static void handleAfterInsert(List<AccountContactRelation> newRecords) {
        // Trigger 2 — New AccountContactRelationship.
        // Only indirect relations (IsDirect = false) represent additional account links;
        // the primary (direct) relation is already covered by the ContactCreated flow.
        List<AccountContactRelation> indirectRelations = new List<AccountContactRelation>();
        for (AccountContactRelation relation : newRecords) {
            if (relation.IsDirect == false) {
                indirectRelations.add(relation);
            }
        }
        ERPIntegrationEventPublisher.sendAccountContactRelationsToERP(indirectRelations);
    }

    // Step 16-6 (SF -> SAP) — End-dating / deactivation of a relationship.
    // The process starts when IsActive flips TRUE -> FALSE or EndDate is changed.
    public static void handleAfterUpdate(List<AccountContactRelation> newRecords, Map<Id, AccountContactRelation> oldRecordsMap) {
        List<AccountContactRelation> toEndDate = new List<AccountContactRelation>();
        Map<Id, Date> endDateByRelationId = new Map<Id, Date>();

        for (AccountContactRelation relation : newRecords) {
            AccountContactRelation oldRelation = oldRecordsMap.get(relation.Id);

            Boolean deactivated = oldRelation.IsActive == true && relation.IsActive == false;
            Boolean endDateChanged = relation.EndDate != oldRelation.EndDate;

            if (!deactivated && !endDateChanged) continue;

            // O4: EndDate change -> use the field value; deactivation -> Today().
            Date effectiveEndDate = (endDateChanged && relation.EndDate != null)
                ? relation.EndDate
                : Date.today();

            toEndDate.add(relation);
            endDateByRelationId.put(relation.Id, effectiveEndDate);
        }

        ERPIntegrationEventPublisher.sendAccountContactRelationEndDatingToERP(toEndDate, endDateByRelationId);
    }

    // Step 16-6 (SF -> SAP) — Deleting an ACR also ends the relationship in SAP.
    // The record no longer exists; the related Account/Contact still do.
    public static void handleAfterDelete(List<AccountContactRelation> oldRecords) {
        Map<Id, Date> endDateByRelationId = new Map<Id, Date>();
        for (AccountContactRelation relation : oldRecords) {
            // If the record in SF was deleted (as it should not) -> set ValidityEndDate to Today().
            endDateByRelationId.put(relation.Id, Date.today());
        }
        ERPIntegrationEventPublisher.sendAccountContactRelationEndDatingToERP(oldRecords, endDateByRelationId);
    }
}