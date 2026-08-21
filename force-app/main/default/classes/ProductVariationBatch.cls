/**
 * Serialized drainer for the SAP -> Salesforce product variation import.
 * 
 * DESIGN (serialization + isolation, both platform-native):
 *  - ProductVariationRestResource stages one Product_Import_Request__c per product
 *    group and starts this batch only if none is active (startIfIdle).
 *  - Batch scopes run strictly serially -> at most ONE Commerce call chain in
 *    flight org-wide. SCOPE_SIZE=1 -> a scope failure (even a Gack) costs exactly
 *    one group; the platform continues with the next scope.
 *  - Database.RaisesPlatformEvents -> a BatchApexErrorEvent fires for every failed
 *    scope, INCLUDING uncatchable exceptions. BatchApexErrorEventTriggerHandler
 *    marks the record for retry or Failed (scope DML rolls back on failure, so the
 *    record itself stays Pending until that handler acts).
 *  - finish(): sweeps old terminal records (Done > 7 days, Failed > 30 days) and
 *    chains a fresh batch if new Pending records arrived mid-run.
 *
 * KNOWN EDGE: a POST that lands while the running batch is inside finish() (after
 * its chain check) can strand its records as Pending until the next POST or run.
 * Window is milliseconds; the next scheduled sync recovers it.
 */
public with sharing class ProductVariationBatch implements Database.Batchable<SObject>, Database.RaisesPlatformEvents {

    public static final Integer SCOPE_SIZE = 1;

    public static final String STATUS_PENDING = 'Pending';
    public static final String STATUS_DONE = 'Done';
    public static final String STATUS_FAILED = 'Failed';

    private static final Integer DONE_RETENTION_DAYS = 7;
    private static final Integer FAILED_RETENTION_DAYS = 30;
    private static final Integer SWEEP_DELETE_LIMIT = 5000;

    // AsyncApexJob statuses that mean "a drainer is (or will be) running".
    private static final Set<String> ACTIVE_JOB_STATUSES =
        new Set<String>{ 'Holding', 'Queued', 'Preparing', 'Processing' };

    public Database.QueryLocator start(Database.BatchableContext context) {
        // Id as tie-breaker: same-transaction inserts share a CreatedDate timestamp.
        return Database.getQueryLocator([
            SELECT Id, Payload__c, WebStoreId__c, AttributeSetId__c, CorrelationId__c,
                   ParentSKU__c, Status__c, RetryCount__c
            FROM Product_Import_Request__c
            WHERE Status__c = :STATUS_PENDING
            ORDER BY CreatedDate, Id
        ]);
    }

    public void execute(Database.BatchableContext context, List<Product_Import_Request__c> scope) {
        for (Product_Import_Request__c request : scope) {
            processOne(context, request);
        }
    }

    private void processOne(Database.BatchableContext context, Product_Import_Request__c staleRequest) {
        // Re-read with a row lock: if a rare second batch job overlaps (start-guard
        // race), only one of them claims the record; the other skips.
        List<Product_Import_Request__c> claimed = [
            SELECT Id, Payload__c, WebStoreId__c, AttributeSetId__c, CorrelationId__c, ParentSKU__c
            FROM Product_Import_Request__c
            WHERE Id = :staleRequest.Id AND Status__c = :STATUS_PENDING
            LIMIT 1
            FOR UPDATE
        ];
        if (claimed.isEmpty()) {
            return;
        }
        Product_Import_Request__c request = claimed[0];
        String tag = '[ProductVariationBatch cid=' + request.CorrelationId__c
            + ' job=' + context.getJobId() + ' req=' + request.Id + ']';

        try {
            List<Object> groups = new List<Object>{ JSON.deserializeUntyped(request.Payload__c) };
            List<ProductVariationService.ProductResult> results =
                ProductVariationService.processBatch(request.WebStoreId__c, request.AttributeSetId__c, groups);

            ProductVariationService.ProductResult result = results.isEmpty() ? null : results[0];
            if (result != null && result.success == true) {
                request.Status__c = STATUS_DONE;
                request.ErrorMessage__c = null;
                System.debug(tag + ' OK   sku=' + result.parentSku
                    + ' erp=' + result.erpProductNumber
                    + ' parent=' + result.parentOperation
                    + ' varsCreated=' + result.variationsCreated
                    + ' varsUpdated=' + result.variationsUpdated
                    + ' parentId=' + result.parentId);
            } else {
                request.Status__c = STATUS_FAILED;
                request.ErrorMessage__c = (result == null)
                    ? 'processBatch returned no result for the group'
                    : result.message;
                System.debug(LoggingLevel.ERROR, tag + ' FAIL sku=' + request.ParentSKU__c
                    + ' :: ' + request.ErrorMessage__c);
            }
        } catch (Exception processException) {
            // Catchable failures (parse errors, validation) resolve here. An
            // UNCATCHABLE Gack rolls this whole scope back instead — the record
            // stays Pending and BatchApexErrorEventTriggerHandler settles it.
            request.Status__c = STATUS_FAILED;
            request.ErrorMessage__c = processException.getTypeName() + ': ' + processException.getMessage();
            System.debug(LoggingLevel.ERROR, tag + ' FAIL sku=' + request.ParentSKU__c
                + ' :: ' + request.ErrorMessage__c);
        }

        request.ProcessedAt__c = System.now();
        update request;
    }

    public void finish(Database.BatchableContext context) {
        sweepOldRecords();

        // Chain a fresh run if new work arrived while this one was draining.
        // Guarded in tests: chaining from finish is not allowed in test context.
        if (!Test.isRunningTest() && pendingCount() > 0) {
            startIfIdle(context.getJobId());
        }
    }

    /**
     * Starts the drainer unless one is already active. Returns the new job id,
     * or null when an active job was found (its finish() will pick up the work).
     */
    public static Id startIfIdle() {
        return startIfIdle(null);
    }

    private static Id startIfIdle(Id excludeJobId) {
        Integer active = [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
              AND ApexClass.Name = 'ProductVariationBatch'
              AND Status IN :ACTIVE_JOB_STATUSES
              AND Id != :excludeJobId
        ];
        if (active > 0) {
            return null;
        }
        return Database.executeBatch(new ProductVariationBatch(), SCOPE_SIZE);
    }

    private Integer pendingCount() {
        return [SELECT COUNT() FROM Product_Import_Request__c WHERE Status__c = :STATUS_PENDING];
    }

    /**
     * Retention sweep: Done records older than 7 days and Failed records older
     * than 30 days are deleted (Failed kept longer as the audit trail). LIMIT
     * keeps a backlog from blowing DML limits; leftovers go next run.
     */
    private void sweepOldRecords() {
        DateTime doneCutoff = System.now().addDays(-DONE_RETENTION_DAYS);
        DateTime failedCutoff = System.now().addDays(-FAILED_RETENTION_DAYS);

        List<Product_Import_Request__c> expired = [
            SELECT Id
            FROM Product_Import_Request__c
            WHERE (Status__c = :STATUS_DONE AND ProcessedAt__c < :doneCutoff)
               OR (Status__c = :STATUS_FAILED AND ProcessedAt__c < :failedCutoff)
            LIMIT :SWEEP_DELETE_LIMIT
        ];
        if (!expired.isEmpty()) {
            System.debug('[ProductVariationBatch] retention sweep deleting ' + expired.size() + ' record(s)');
            delete expired;
        }
    }
}