/**
 * Settles Product_Import_Request__c records whose ProductVariationBatch scope
 * died with an unhandled exception — including UNCATCHABLE ones (Commerce Gacks,
 * limit breaches). BatchApexErrorEvent is the only mechanism that observes those:
 * the failed scope's own DML rolled back, so its staging record is still Pending
 * and would loop forever without this handler.
 *
 * Retry model: each scope failure increments RetryCount__c. Within the limit the
 * record goes back to Pending (transient Gacks — e.g. Commerce-internal errors —
 * usually pass on a later attempt); past the limit it is marked Failed with the
 * exception details, capping a genuinely poisoned group at MAX_RETRIES + 1
 * attempts total.
 *
 * Runs as the Automated Process user (platform event trigger context).
 */
public with sharing class BatchApexErrorEventTriggerHandler {

    // Total attempts per record = MAX_RETRIES + 1 (the initial one).
    @TestVisible
    private static final Integer MAX_RETRIES = 2;

    private static final String HANDLED_BATCH_CLASS = 'ProductVariationBatch';

    public static void handleAfterInsert(List<BatchApexErrorEvent> newRecords) {
        handle(newRecords);
    }

    @TestVisible
    private static void handle(List<BatchApexErrorEvent> events) {
        List<BatchApexErrorEvent> relevant = filterToHandledBatchClass(events);
        if (relevant.isEmpty()) {
            return;
        }

        // Count scope failures per staging record (JobScope carries the scope's
        // record ids) and keep the latest exception text for the audit trail.
        Map<Id, Integer> failureCounts = new Map<Id, Integer>();
        Map<Id, String> failureMessages = new Map<Id, String>();
        for (BatchApexErrorEvent event : relevant) {
            System.debug(LoggingLevel.ERROR, '[BatchApexErrorEventTriggerHandler] job=' + event.AsyncApexJobId
                + ' phase=' + event.Phase
                + ' type=' + event.ExceptionType
                + ' scope=' + event.JobScope
                + ' :: ' + event.Message);
            for (Id recordId : parseScopeIds(event.JobScope)) {
                Integer count = failureCounts.get(recordId);
                failureCounts.put(recordId, (count == null ? 0 : count) + 1);
                failureMessages.put(recordId, event.ExceptionType + ': ' + event.Message);
            }
        }
        if (failureCounts.isEmpty()) {
            return;
        }

        List<Product_Import_Request__c> requests = [
            SELECT Id, Status__c, RetryCount__c
            FROM Product_Import_Request__c
            WHERE Id IN :failureCounts.keySet()
              AND Status__c != :ProductVariationBatch.STATUS_DONE
        ];

        for (Product_Import_Request__c request : requests) {
            Integer previousCount = (request.RetryCount__c == null) ? 0 : request.RetryCount__c.intValue();
            Integer newCount = previousCount + failureCounts.get(request.Id);

            request.RetryCount__c = newCount;
            request.ErrorMessage__c = failureMessages.get(request.Id)
                + ' (batch scope failure, attempt ' + newCount + ')';
            if (newCount > MAX_RETRIES) {
                request.Status__c = ProductVariationBatch.STATUS_FAILED;
                request.ProcessedAt__c = System.now();
            } else {
                request.Status__c = ProductVariationBatch.STATUS_PENDING;
            }
        }
        update requests;

        // DELIBERATELY NO ProductVariationBatch.startIfIdle() here: this trigger
        // runs as the Automated Process user, and a batch submitted by it inherits
        // that context — where Connect API is blocked ("The Connect API is not
        // enabled for this user type").
        // Re-queued records are picked up by the running batch's own finish()
        // chain (correct submitting user) or by the next Mule POST.
    }

    private static List<BatchApexErrorEvent> filterToHandledBatchClass(List<BatchApexErrorEvent> events) {
        Set<Id> jobIds = new Set<Id>();
        for (BatchApexErrorEvent event : events) {
            jobIds.add(event.AsyncApexJobId);
        }

        Set<Id> handledJobIds = new Map<Id, AsyncApexJob>([
            SELECT Id FROM AsyncApexJob
            WHERE Id IN :jobIds AND ApexClass.Name = :HANDLED_BATCH_CLASS
        ]).keySet();

        List<BatchApexErrorEvent> relevant = new List<BatchApexErrorEvent>();
        for (BatchApexErrorEvent event : events) {
            if (handledJobIds.contains(event.AsyncApexJobId)) {
                relevant.add(event);
            }
        }
        return relevant;
    }

    private static List<Id> parseScopeIds(String jobScope) {
        List<Id> recordIds = new List<Id>();
        if (String.isBlank(jobScope)) {
            return recordIds;
        }
        for (String rawId : jobScope.split(',')) {
            try {
                Id recordId = Id.valueOf(rawId.trim());
                if (recordId.getSobjectType() == Product_Import_Request__c.SObjectType) {
                    recordIds.add(recordId);
                }
            } catch (Exception ignored) {
                // Malformed scope entry — nothing to settle for it.
            }
        }
        return recordIds;
    }
}