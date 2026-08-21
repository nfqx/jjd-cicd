@RestResource(urlMapping='/invoice/post')
global with sharing class InvoicePostRestResource {

    private static final Integer HTTP_BAD_REQUEST = 400;
    private static final Integer HTTP_CREATED = 201;
    private static final Integer HTTP_INTERNAL_ERROR = 500;
    private static final String MSG_REQUEST_BODY_REQUIRED = 'Request body is required';
    private static final String MSG_PAYLOAD_FORMAT_INVALID = 'Payload must contain "invoice" and "invoiceLines", or "records" array with Invoice and InvoiceLine types';
    private static final String MSG_RECORDS_FORMAT_INVALID = 'Records must contain one Invoice and at least one InvoiceLine';
    private static final String MSG_INVOICE_CREATED = 'Invoice created successfully';
    private static final String MSG_INVOICE_UPDATED = 'Invoice updated successfully';
    private static final String MSG_INTERNAL_ERROR_PREFIX = 'Internal error: ';
    private static final String KEY_INVOICE = 'invoice';
    private static final String KEY_INVOICE_LINES = 'invoiceLines';
    private static final String KEY_RECORDS = 'records';
    private static final String KEY_ATTRIBUTES = 'attributes';
    private static final String KEY_TYPE = 'type';
    private static final String RECORD_TYPE_INVOICE = 'Invoice';
    private static final String RECORD_TYPE_INVOICE_LINE = 'InvoiceLine';
    private static final String REGEX_SNEAKY_SPACES = '[\\u00A0\\u2007\\u202F]';

    @HttpPost
    global static ResponseWrapper doPost() {
        RestRequest request = RestContext.request;
        ResponseWrapper responseWrapper;

        responseWrapper = validateAndParseRequest(request);
        if (responseWrapper != null) {
            applyResponse(responseWrapper);
            return responseWrapper;
        }

        try {
            ParseResult parseResult = parsePayload(request.requestBody.toString());
            Id invoiceId = InvoiceCreationService.createInvoiceFromSap(
                parseResult.invoiceData,
                parseResult.invoiceLines
            );
            Boolean wasUpdate = Boolean.valueOf(InvoiceCreationService.lastOperationWasUpdate);
            responseWrapper = buildSuccessResponse(invoiceId, wasUpdate);
        } catch (InvoiceCreationService.InvoiceCreationException invoiceException) {
            responseWrapper = buildErrorResponse(
                HTTP_BAD_REQUEST,
                invoiceException.getMessage()
            );
        } catch (Exception errorException) {
            responseWrapper = buildErrorResponse(
                HTTP_INTERNAL_ERROR,
                MSG_INTERNAL_ERROR_PREFIX + errorException.getMessage()
            );
        }

        applyResponse(responseWrapper);
        return responseWrapper;
    }

    private static ResponseWrapper validateAndParseRequest(RestRequest request) {
        if (request.requestBody == null || request.requestBody.size() == 0) {
            return buildErrorResponse(HTTP_BAD_REQUEST, MSG_REQUEST_BODY_REQUIRED);
        }

        return null;
    }

    private static ParseResult parsePayload(String body) {
        String sanitizedBody = sanitizeJsonBody(body);
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(sanitizedBody);

        if (payload.containsKey(KEY_INVOICE) && payload.containsKey(KEY_INVOICE_LINES)) {
            return new ParseResult(
                (Map<String, Object>) payload.get(KEY_INVOICE),
                (List<Object>) payload.get(KEY_INVOICE_LINES)
            );
        }

        if (payload.containsKey(KEY_RECORDS)) {
            return parseRecordsFormat((List<Object>) payload.get(KEY_RECORDS));
        }

        throw new InvoiceCreationService.InvoiceCreationException(MSG_PAYLOAD_FORMAT_INVALID);
    }

    private static String sanitizeJsonBody(String body) {
        if (body == null) {
            return '';
        }

        return body.replaceAll(REGEX_SNEAKY_SPACES, ' ');
    }

    private static ParseResult parseRecordsFormat(List<Object> records) {
        Map<String, Object> invoiceData;
        List<Object> invoiceLines = new List<Object>();

        for (Object record : records) {
            Map<String, Object> recordMap = (Map<String, Object>) record;
            String recordType = getRecordType(recordMap);
            if (recordType == RECORD_TYPE_INVOICE) {
                invoiceData = recordMap;
            } else if (recordType == RECORD_TYPE_INVOICE_LINE) {
                invoiceLines.add(recordMap);
            }
        }

        if (invoiceData == null || invoiceLines.isEmpty()) {
            throw new InvoiceCreationService.InvoiceCreationException(MSG_RECORDS_FORMAT_INVALID);
        }

        return new ParseResult(invoiceData, invoiceLines);
    }

    private static String getRecordType(Map<String, Object> record) {
        Map<String, Object> attributes = (Map<String, Object>) record.get(KEY_ATTRIBUTES);
        return attributes != null ? (String) attributes.get(KEY_TYPE) : null;
    }

    private static ResponseWrapper buildSuccessResponse(Id invoiceId, Boolean wasUpdate) {
        ResponseWrapper responseWrapper = new ResponseWrapper();
        responseWrapper.success = true;
        responseWrapper.invoiceId = invoiceId;
        responseWrapper.message = (wasUpdate == true) ? MSG_INVOICE_UPDATED : MSG_INVOICE_CREATED;
        responseWrapper.statusCode = HTTP_CREATED;
        return responseWrapper;
    }

    private static ResponseWrapper buildErrorResponse(Integer statusCode, String message) {
        ResponseWrapper responseWrapper = new ResponseWrapper();
        responseWrapper.success = false;
        responseWrapper.message = message;
        responseWrapper.statusCode = statusCode;
        return responseWrapper;
    }

    private static void applyResponse(ResponseWrapper responseWrapper) {
        RestContext.response.statusCode = responseWrapper.statusCode;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseWrapper));
    }

    private class ParseResult {
        Map<String, Object> invoiceData;
        List<Object> invoiceLines;

        ParseResult(Map<String, Object> invoiceData, List<Object> invoiceLines) {
            this.invoiceData = invoiceData;
            this.invoiceLines = invoiceLines;
        }
    }

    global class ResponseWrapper {
        public Boolean success;
        public Id invoiceId;
        public String message;
        public Integer statusCode;
    }
}