public class SourceOrgAuth {

    private static String CLIENT_ID = System.Label.SourceOrgClientId;
    private static String CLIENT_SECRET = System.Label.SourceOrgClientSecret;
    private static String TOKEN_URL = System.Label.SourceOrgTokenURL + '/services/oauth2/token'; //'https://login.salesforce.com/services/oauth2/token';

    public static String getAccessToken() {

        HttpRequest req = new HttpRequest();
        req.setEndpoint(TOKEN_URL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        String body =
            'grant_type=client_credentials' +
            '&client_id=' + EncodingUtil.urlEncode(CLIENT_ID, 'UTF-8') +
            '&client_secret=' + EncodingUtil.urlEncode(CLIENT_SECRET, 'UTF-8');

        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if(res.getStatusCode() != 200){
            throw new CalloutException('OAuth failed: ' + res.getBody());
        }

        Map<String,Object> result =
            (Map<String,Object>) JSON.deserializeUntyped(res.getBody());

        return (String) result.get('access_token');
    }
}