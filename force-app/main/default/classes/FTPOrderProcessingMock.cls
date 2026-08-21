@IsTest
global class FTPOrderProcessingMock implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        String endpoint = req.getEndpoint();

        // ----------------------------------------
        // Folder exists
        // ----------------------------------------
        if (endpoint.contains('/folder/exists')) {

            res.setBody('{"exists": true}');
            res.setStatusCode(200);
            return res;
        }

        // ----------------------------------------
        // File exists
        // ----------------------------------------
        if (endpoint.contains('/file/exists')) {

            res.setBody('{"exists": true}');
            res.setStatusCode(200);
            return res;
        }

        // ----------------------------------------
        // File download (CSV content)
        // ----------------------------------------
        if (endpoint.contains('/file/download')) {

            String csv =
                'CUST-001;SKU-001;2\n' +
                'CUST-001;SKU-002;1\n' +
                'CUST-002;SKU-001;5';

            res.setBody(csv);
            res.setStatusCode(200);
            return res;
        }

        // default fallback
        res.setStatusCode(404);
        res.setBody('{"error":"not found"}');
        return res;
    }
}