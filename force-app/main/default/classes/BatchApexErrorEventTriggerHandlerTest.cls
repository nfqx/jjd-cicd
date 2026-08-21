@IsTest
public class BatchApexErrorEventTriggerHandlerTest {

    /**
     * BatchApexErrorEvent fields are read-only, so test events are built via the
     * JSON.deserialize trick. A real ProductVariationBatch AsyncApexJob id is
     * needed for the handler's class-name filter — starting the batch with no
     * Pending records creates one without side effects.
     */
    private static Id realBatchJobId() {
        return Database.executeBatch(new ProductVariationBatch(), ProductVariationBatch.SCOPE_SIZE);
    }

    private static BatchApexErrorEvent buildEvent(Id jobId, Id scopeRecordId) {
        return (BatchApexErrorEvent) JSON.deserialize(
            '{"AsyncApexJobId":"' + jobId + '",'
            + '"JobScope":"' + scopeRecordId + '",'
            + '"ExceptionType":"System.UnexpectedException",'
            + '"Message":"Salesforce System Error: 1389484174-386952",'
            + '"Phase":"EXECUTE"}',
            BatchApexErrorEvent.class);
    }

    private static Product_Import_Request__c insertRequest(Integer retryCount) {
        Product_Import_Request__c request = new Product_Import_Request__c(
            Payload__c = '{}',
            Status__c = ProductVariationBatch.STATUS_PENDING,
            CorrelationId__c = 'cid-handler-test',
            RetryCount__c = retryCount
        );
        insert request;
        return request;
    }

    @IsTest
    static void handle_shouldRequeueRequest_whenUnderRetryLimit() {
        //Having
        // Materialize a real ProductVariationBatch job BEFORE the staging record
        // exists, so the drainer runs over an empty set at stopTest and cannot
        // touch the record this test asserts on.
        Test.startTest();
        Id jobId = realBatchJobId();
        Test.stopTest();
        Product_Import_Request__c request = insertRequest(0);

        //When
        BatchApexErrorEventTriggerHandler.handle(
            new List<BatchApexErrorEvent>{ buildEvent(jobId, request.Id) });

        //Then
        request = [SELECT Status__c, RetryCount__c, ErrorMessage__c FROM Product_Import_Request__c WHERE Id = :request.Id];
        System.assertEquals(ProductVariationBatch.STATUS_PENDING, request.Status__c, 'under the limit the record is re-queued');
        System.assertEquals(1, request.RetryCount__c, 'scope failure increments the retry count');
        System.assert(request.ErrorMessage__c.contains('Salesforce System Error'), 'exception details are recorded');
    }

    @IsTest
    static void handle_shouldMarkFailed_whenRetriesExhausted() {
        //Having
        // Job materialized before the record exists — see handle_shouldRequeueRequest.
        Test.startTest();
        Id jobId = realBatchJobId();
        Test.stopTest();
        Product_Import_Request__c request = insertRequest(BatchApexErrorEventTriggerHandler.MAX_RETRIES);

        //When
        BatchApexErrorEventTriggerHandler.handle(
            new List<BatchApexErrorEvent>{ buildEvent(jobId, request.Id) });

        //Then
        request = [SELECT Status__c, RetryCount__c, ProcessedAt__c FROM Product_Import_Request__c WHERE Id = :request.Id];
        System.assertEquals(ProductVariationBatch.STATUS_FAILED, request.Status__c, 'past the limit the record fails for good');
        System.assertEquals(BatchApexErrorEventTriggerHandler.MAX_RETRIES + 1, request.RetryCount__c, 'final failure is counted');
        System.assertNotEquals(null, request.ProcessedAt__c, 'terminal timestamp is stamped');
    }

    @IsTest
    static void handle_shouldIgnoreEvents_whenJobIsNotProductVariationBatch() {
        //Having
        // A real AsyncApexJob id of a DIFFERENT Apex class — exactly what the
        // handler's class-name filter must ignore. The empty Queueable run is
        // harmless (processBatch over an empty list).
        Test.startTest();
        Id foreignJobId = System.enqueueJob(
            new ProductVariationQueueable(null, null, 'cid-foreign', new List<Object>()));
        Test.stopTest();
        Product_Import_Request__c request = insertRequest(0);

        //When
        BatchApexErrorEventTriggerHandler.handle(
            new List<BatchApexErrorEvent>{ buildEvent(foreignJobId, request.Id) });

        //Then
        request = [SELECT Status__c, RetryCount__c FROM Product_Import_Request__c WHERE Id = :request.Id];
        System.assertEquals(ProductVariationBatch.STATUS_PENDING, request.Status__c, 'foreign batch events are ignored');
        System.assertEquals(0, request.RetryCount__c, 'retry count untouched for foreign events');
    }
}