/**
 * SAP -> Salesforce product variation sync.
 *
 * Thin controller: validate the envelope, stage one Product_Import_Request__c per
 * product group, start the serialized drainer (ProductVariationBatch) if idle,
 * and ACK 202 immediately.
 *
 * Invoked from Mule (salesforce-crm-e) via salesforce:invoke-apex-rest-method on
 * Salesforce_Config (JWT). Mule groups the canonical product-processor payload by
 * parent, maps fields to Product2 API names, attaches webStoreId + attributeSetId
 * (config properties), and POSTs here. The shim owns the diff (create vs update).
 *
 * WHY staging instead of one Queueable per POST: parallel Queueables making
 * Commerce ConnectApi composite calls Gack sporadically (uncatchable
 * "Salesforce System Error", confirmed 2026-07-22), killing whole chunks. The
 * batch drains staged groups strictly serially with per-group failure isolation;
 * the staging records double as a queryable audit trail.
 *
 * Request body:
 * {
 *   "webStoreId": "...",          // required (Mule config property)
 *   "attributeSetId": "...",      // Product Attribute Set Id (parent create)
 *   "correlationId": "..."        // The MuleSoft correlation id
 *   "products": [
 *     {
 *       "parent":     { Product2 fields keyed by API name, e.g. ProductCode, Name, ... },
 *       "variations": [ { Product2 fields + "Unit__c": "<SAP code>" }, ... ]
 *     }
 *   ]
 * }
 */
@RestResource(urlMapping='/product-variation/post')
global with sharing class ProductVariationRestResource {

    private static final Integer HTTP_ACCEPTED = 202;
    private static final Integer HTTP_BAD_REQUEST = 400;
    private static final Integer HTTP_INTERNAL_ERROR = 500;

    private static final String MSG_BODY_REQUIRED = 'Request body is required';
    private static final String MSG_WEBSTORE_REQUIRED = 'webStoreId is required';
    private static final String MSG_PRODUCTS_REQUIRED = 'products must be a non-empty array';
    private static final String MSG_ACCEPTED = 'Accepted for asynchronous processing';
    private static final String MSG_ACCEPTED_QUEUED = 'Accepted; queued behind the active import job';
    private static final String MSG_INTERNAL_PREFIX = 'Internal error: ';

    private static final String KEY_WEBSTORE_ID = 'webStoreId';
    private static final String KEY_ATTRIBUTE_SET_ID = 'attributeSetId';
    private static final String KEY_PRODUCTS = 'products';
    private static final String KEY_CORRELATION_ID = 'correlationId';
    private static final String KEY_PARENT = 'parent';
    private static final String KEY_SKU = 'StockKeepingUnit';
    private static final String KEY_ERP_NUMBER = 'ERPProductNumber__c';

    // Non-breaking / narrow spaces that sometimes sneak into JSON from upstream.
    private static final String REGEX_SNEAKY_SPACES = '[\\u00A0\\u2007\\u202F]';

    @HttpPost
    global static ResponseWrapper doPost() {
        RestRequest request = RestContext.request;
        ResponseWrapper response;

        try {
            if (request == null || request.requestBody == null || request.requestBody.size() == 0) {
                return applyResponse(buildError(HTTP_BAD_REQUEST, MSG_BODY_REQUIRED));
            }

            String body = request.requestBody.toString().replaceAll(REGEX_SNEAKY_SPACES, ' ');
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(body);

            String webStoreId = (String) payload.get(KEY_WEBSTORE_ID);
            String attributeSetId = (String) payload.get(KEY_ATTRIBUTE_SET_ID);
            String correlationId = (String) payload.get(KEY_CORRELATION_ID);
            Object productsRaw = payload.get(KEY_PRODUCTS);

            if (String.isBlank(webStoreId)) {
                return applyResponse(buildError(HTTP_BAD_REQUEST, MSG_WEBSTORE_REQUIRED));
            }
            if (!(productsRaw instanceof List<Object>) || ((List<Object>) productsRaw).isEmpty()) {
                return applyResponse(buildError(HTTP_BAD_REQUEST, MSG_PRODUCTS_REQUIRED));
            }

            // Stage one record per group, then make sure the serialized drainer is
            // running. Per-group errors (missing parent, bad units, ...) surface on
            // the staging record's Status/ErrorMessage, not in this response — the
            // fire-and-forget contract with Mule is unchanged.
            List<Product_Import_Request__c> staged =
                stageGroups(webStoreId, attributeSetId, correlationId, (List<Object>) productsRaw);
            insert staged;

            Id jobId = ProductVariationBatch.startIfIdle();

            response = new ResponseWrapper();
            response.success = true;
            response.statusCode = HTTP_ACCEPTED;
            response.message = (jobId == null) ? MSG_ACCEPTED_QUEUED : MSG_ACCEPTED;
            response.jobId = (jobId == null) ? null : String.valueOf(jobId);
            response.correlationId = correlationId;
            response.stagedCount = staged.size();
        } catch (ProductVariationService.ProductVariationException knownException) {
            response = buildError(HTTP_BAD_REQUEST, knownException.getMessage());
        } catch (Exception errorException) {
            response = buildError(HTTP_INTERNAL_ERROR, MSG_INTERNAL_PREFIX + errorException.getMessage());
        }

        return applyResponse(response);
    }

    private static List<Product_Import_Request__c> stageGroups(
        String webStoreId,
        String attributeSetId,
        String correlationId,
        List<Object> groups
    ) {
        List<Product_Import_Request__c> staged = new List<Product_Import_Request__c>();
        for (Object groupRaw : groups) {
            // Parent SKU / ERP number are best-effort index fields for list views;
            // a malformed group still gets staged and fails visibly in the batch.
            String parentSku;
            String erpNumber;
            if (groupRaw instanceof Map<String, Object>) {
                Object parentRaw = ((Map<String, Object>) groupRaw).get(KEY_PARENT);
                if (parentRaw instanceof Map<String, Object>) {
                    Map<String, Object> parent = (Map<String, Object>) parentRaw;
                    parentSku = stringValue(parent.get(KEY_SKU));
                    erpNumber = stringValue(parent.get(KEY_ERP_NUMBER));
                }
            }
            staged.add(new Product_Import_Request__c(
                Payload__c = JSON.serialize(groupRaw),
                Status__c = ProductVariationBatch.STATUS_PENDING,
                CorrelationId__c = correlationId,
                WebStoreId__c = webStoreId,
                AttributeSetId__c = attributeSetId,
                ParentSKU__c = parentSku,
                ERPProductNumber__c = erpNumber,
                RetryCount__c = 0
            ));
        }
        return staged;
    }

    private static String stringValue(Object value) {
        return (value == null) ? null : String.valueOf(value);
    }

    private static ResponseWrapper buildError(Integer statusCode, String message) {
        ResponseWrapper response = new ResponseWrapper();
        response.success = false;
        response.statusCode = statusCode;
        response.message = message;
        return response;
    }

    private static ResponseWrapper applyResponse(ResponseWrapper response) {
        RestContext.response.statusCode = response.statusCode;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
        return response;
    }

    global class ResponseWrapper {
        public Boolean success;
        public Integer statusCode;
        public String message;
        public String jobId;          // drainer batch job id; null when one was already active
        public String correlationId;  // echoed back from the request for trace correlation
        public Integer stagedCount;   // number of Product_Import_Request__c records staged
        public List<ProductVariationService.ProductResult> results;  // always null in async (fire-and-forget) mode
    }
}