/**
 * Async wrapper around ProductVariationService.processBatch.
 *
 * WHY: the synchronous REST path (ProductVariationRestResource) runs the whole
 * batch — up to ~2 ConnectApi Commerce composite calls per product group — inside
 * one transaction and blows the 10s synchronous CPU limit on larger batches
 * (surfaces as "Apex CPU time limit exceeded" / CIRCULAR_OBJECT_GRAPH). Running the
 * work in a Queueable gives the 60s async CPU ceiling and fresh limits.
 *
 * Reconciliation model: FIRE-AND-FORGET + LOG. The controller returns a 202 ACK
 * (job id + correlationId) the instant it enqueues; per-product outcomes are NOT
 * returned to Mule. Instead every ProductResult is written to the debug log here,
 * tagged with the correlationId + async job id so a run can be traced end to end.
 *
 * Confirmed (throwaway CommerceAsyncProbe, 2026-07): compositeCommerceProductCreate
 * runs in async context and needs no Database.AllowsCallouts, so this class does not
 * implement it — processBatch performs ConnectApi + DML only, no HTTP callouts.
 *
 * NOTE: instance members are serialized across the async boundary, so they must stay
 * serializable — String scalars and a List<Object>/Map<String,Object> graph of
 * primitives (as produced by JSON.deserializeUntyped) all qualify.
 */
public with sharing class ProductVariationQueueable implements Queueable {

    private final String webStoreId;
    private final String attributeSetId;
    private final String correlationId;
    private final List<Object> products;

    public ProductVariationQueueable(
        String webStoreId,
        String attributeSetId,
        String correlationId,
        List<Object> products
    ) {
        this.webStoreId = webStoreId;
        this.attributeSetId = attributeSetId;
        this.correlationId = correlationId;
        this.products = products;
    }

    public void execute(QueueableContext context) {
        String tag = '[ProductVariationQueueable cid=' + correlationId + ' job=' + context.getJobId() + ']';
        Integer count = (products == null) ? 0 : products.size();
        System.debug(tag + ' START — product groups=' + count
            + ' webStoreId=' + webStoreId + ' attributeSetId=' + attributeSetId);

        // DIAGNOSTIC (temporary — remove once the variation-create Gack is resolved):
        // dump the raw incoming request so a single group can be replayed BY HAND against
        // ConnectApi.CommerceCatalogManagement.compositeCommerceVariationCreate. Printed
        // per-group so each line stays small enough to avoid debug-log truncation. This is
        // plain deserialized JSON (Maps/Lists of primitives), so serializing it is safe —
        // it is NOT a ConnectApi output rep, so no Gack risk here.
         System.debug(tag + ' REQUEST-META webStoreId=' + webStoreId + ' attributeSetId=' + attributeSetId);
        if (products != null) {
            for (Integer i = 0; i < products.size(); i++) {
                System.debug(tag + ' REQUEST-GROUP[' + i + ']=' + JSON.serializePretty(products[i]));
            }
        }

        try {
            List<ProductVariationService.ProductResult> results =
                ProductVariationService.processBatch(webStoreId, attributeSetId, products);
            logResults(tag, results);
        } catch (Exception fatalException) {
            // A whole-batch failure (e.g. a governor limit hit, or an uncatchable
            // condition surfacing before per-product handling) lands here so the job
            // record is still marked cleanly rather than left in an error state.
            System.debug(LoggingLevel.ERROR, tag + ' FATAL — '
                + fatalException.getTypeName() + ' :: ' + fatalException.getMessage());
            System.debug(LoggingLevel.ERROR, tag + ' STACK — ' + fatalException.getStackTraceString());
        }

        System.debug(tag + ' END');
    }

    private void logResults(String tag, List<ProductVariationService.ProductResult> results) {
        Integer succeeded = 0;
        Integer failed = 0;

        for (ProductVariationService.ProductResult result : results) {
            if (result.success == true) {
                succeeded++;
                System.debug(tag + ' OK   sku=' + result.parentSku
                    + ' erp=' + result.erpProductNumber
                    + ' parent=' + result.parentOperation
                    + ' varsCreated=' + result.variationsCreated
                    + ' varsUpdated=' + result.variationsUpdated
                    + ' parentId=' + result.parentId);
            } else {
                failed++;
                System.debug(LoggingLevel.ERROR, tag + ' FAIL sku=' + result.parentSku
                    + ' erp=' + result.erpProductNumber
                    + ' :: ' + result.message);
            }
        }

        System.debug(tag + ' SUMMARY — ok=' + succeeded + ' failed=' + failed
            + ' total=' + results.size());
    }
}