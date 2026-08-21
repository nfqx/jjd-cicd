public with sharing class FTPClient {

    // Usually a Named Credential (recommended)
    private static final String NAMED_CREDENTIAL = 'FTP_API';

    // Centralized endpoint builder
    private static String endpoint(String path) {
        return 'callout:' + NAMED_CREDENTIAL + path;
    }

    /**
     * Downloads file content as String (CSV)
     *
     * Returns:
     * - file contents if found
     * - null if file does not exist
     */
    public static String downloadFileAsString(String filePath) {
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(endpoint('/download?fileName=' + filePath));
        req.setTimeout(120000);
        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> files = (List<Object>) body.get('Files');

            if (files == null || files.isEmpty()) {
                return null;
            }

            Map<String, Object> file = (Map<String, Object>) files[0];
            String base64Content = (String) file.get('body');
            if (String.isBlank(base64Content)) {
                return null;
            }
            Blob decoded = EncodingUtil.base64Decode(base64Content);
            return decoded.toString();
        }

        // File not found -> ignore
        if (res.getStatusCode() == 404) {
            return null;
        }

        throw new FTPException(
            'FTP API call failed: ' +
            res.getStatusCode() +
            ' - ' +
            res.getBody()
        );
    }

    // -----------------------------
    // EXCEPTION CLASS
    // -----------------------------
    public class FTPException extends Exception {}
}