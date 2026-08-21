public class MigrationBatchProductCategory implements Database.Batchable<Object>, Database.AllowsCallouts {

    private static final String SOURCE_URL = System.Label.SourceOrgTokenURL;

    public Iterable<Object> start(Database.BatchableContext bc) {

        String token = SourceOrgAuth.getAccessToken();

        HttpRequest req = new HttpRequest();
        req.setEndpoint(
            SOURCE_URL + '/services/data/v65.0/query/?q=' +
            EncodingUtil.urlEncode(
                'SELECT Id, Name, Subheader__c, ParentCategoryId, SortOrder FROM ProductCategory',
                'UTF-8'
            )
        );

        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if(res.getStatusCode() != 200){
            throw new CalloutException(res.getBody());
        }

        Map<String, Object> payload =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

        return (List<Object>) payload.get('records');
    }

    public void execute(Database.BatchableContext bc, List<Object> records) {
        Id catalogId = [SELECT Id FROM ProductCatalog LIMIT 1].Id;
        List<ProductCategory> toUpsert = new List<ProductCategory>();
        Set<Id> oldIds = new Set<Id>();

        for(Object obj : records){
            Map<String,Object> row = (Map<String,Object>) obj;

            String oldId = (String) row.get('Id');

            ProductCategory pc = new ProductCategory();
            pc.Name = (String) row.get('Name');
            pc.OldId__c = oldId;
            oldIds.add(oldId);

            if(row.get('SortOrder') != null){
                pc.SortOrder = ((Decimal) row.get('SortOrder')).intValue();
            }

            pc.Subheader__c = (String) row.get('Subheader__c');
            pc.CatalogId = catalogId;

            toUpsert.add(pc);
        }

        upsert toUpsert OldId__c;

        Map<String, ProductCategory> newByOldId = new Map<String, ProductCategory>();

        for(ProductCategory pc :
            [SELECT Id, OldId__c FROM ProductCategory WHERE OldId__c IN :oldIds]){

            newByOldId.put(pc.OldId__c, pc);
        }

        List<ProductCategory> updates = new List<ProductCategory>();

        for(Object obj : records){

            Map<String,Object> row = (Map<String,Object>) obj;
            String parentId = (String) row.get('ParentCategoryId');

            if(parentId != null && newByOldId.containsKey(parentId)){

                ProductCategory child = newByOldId.get((String)row.get('Id'));
                ProductCategory parent = newByOldId.get(parentId);

                if(child != null){
                    child.ParentCategoryId = parent.Id;
                    updates.add(child);
                }
            }
        }

        update updates;
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('ProductCategory migration finished');
    }
}