public class MigrationProductGroupLoadJob
implements Database.Batchable<Object>, Database.AllowsCallouts {

    private static final String SOURCE_URL = System.Label.SourceOrgTokenURL;

    public Iterable<Object> start(Database.BatchableContext bc){

        String token = SourceOrgAuth.getAccessToken();

        String soql =
            'SELECT Id, Name, Family ' +
            'FROM Product2 ' +
            'WHERE Family IN (\'Group\', \'Subgroup\')';

        HttpRequest req = new HttpRequest();

        req.setEndpoint(
            SOURCE_URL + '/services/data/v65.0/query/?q=' +
            EncodingUtil.urlEncode(soql, 'UTF-8')
        );

        req.setMethod('GET');
        req.setHeader('Authorization','Bearer ' + token);

        HttpResponse res = new Http().send(req);

        if(res.getStatusCode() != 200){
            throw new CalloutException(res.getBody());
        }

        Map<String,Object> payload =
            (Map<String,Object>)JSON.deserializeUntyped(res.getBody());

        return (List<Object>)payload.get('records');
    }

    public void execute(Database.BatchableContext bc, List<Object> scope){

        List<Product2> upserts = new List<Product2>();

        for(Object obj : scope){

            Map<String,Object> row = (Map<String,Object>)obj;

            Product2 p = new Product2();

            p.Name = (String)row.get('Name');
            p.Family = (String)row.get('Family');

            p.OldId__c = (String)row.get('Id');

            upserts.add(p);
        }

        Database.upsert(upserts, Product2.OldId__c, false);
    }

    public void finish(Database.BatchableContext bc){

        Database.executeBatch(
            new MigrationProductGroupMappingJob(),
            50
        );
    }
}