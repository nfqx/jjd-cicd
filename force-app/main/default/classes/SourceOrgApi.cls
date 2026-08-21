public with sharing class SourceOrgApi {

    private static final String SOURCE_URL = System.Label.SourceOrgTokenURL;

    public static List<Object> query(String soql){

        String token = SourceOrgAuth.getAccessToken();

        HttpRequest req = new HttpRequest();
        req.setEndpoint(
            SOURCE_URL + '/services/data/v65.0/query/?q=' +
            EncodingUtil.urlEncode(soql, 'UTF-8')
        );

        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');

        HttpResponse res = new Http().send(req);

        if(res.getStatusCode() != 200){
            throw new CalloutException(res.getBody());
        }

        Map<String,Object> payload =
            (Map<String,Object>)JSON.deserializeUntyped(res.getBody());

        return (List<Object>)payload.get('records');
    }
}