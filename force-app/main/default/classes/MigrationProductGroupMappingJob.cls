public class MigrationProductGroupMappingJob implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {

    private static final String SOURCE_URL = System.Label.SourceOrgTokenURL;

    private String token;

    // We accumulate updates across batches
    private List<Product2> stagedUpdates = new List<Product2>();

    public Database.QueryLocator start(Database.BatchableContext bc){

        return Database.getQueryLocator([
            SELECT Id,
                OldProductNumber__c,
                ProductGroup__c,
                ProductSubGroup__c
            FROM Product2
            WHERE OldProductNumber__c != NULL
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Product2> scope){

        if(token == null){
            token = SourceOrgAuth.getAccessToken();
        }

        /* -------------------------------------------------------
           1. Collect identifiers to query in source org
        ------------------------------------------------------- */

        Set<String> identifiers = new Set<String>();

        for(Product2 p : scope){
            identifiers.add(p.OldProductNumber__c);
        }

        if(identifiers.isEmpty()){
            return;
        }

        /* -------------------------------------------------------
           2. Query source org for matching products
        ------------------------------------------------------- */

        String soql =
            'SELECT Id, ProductCode, Produktgruppe__c, Produkt_Untergruppe__c ' +
            'FROM Product2 ' +
            'WHERE ProductCode IN (\'' +
            String.join(new List<String>(identifiers), '\',\'') +
            '\')';

        HttpRequest req = new HttpRequest();

        req.setEndpoint(
            SOURCE_URL + '/services/data/v65.0/query/?q=' +
            EncodingUtil.urlEncode(soql,'UTF-8')
        );

        req.setMethod('GET');
        req.setHeader('Authorization','Bearer ' + token);

        HttpResponse res = new Http().send(req);

        if(res.getStatusCode() != 200){
            throw new CalloutException(res.getBody());
        }

        Map<String,Object> payload =
            (Map<String,Object>)JSON.deserializeUntyped(res.getBody());

        List<Object> sourceProducts =
            (List<Object>)payload.get('records');

        if(sourceProducts.isEmpty()){
            return;
        }

        /* -------------------------------------------------------
           3. Build mapping Product Code → source row
        ------------------------------------------------------- */

        Map<String,Map<String,Object>> sourceByProductCode =
            new Map<String,Map<String,Object>>();

        Set<String> groupOldIds = new Set<String>();

        for(Object obj : sourceProducts){

            Map<String,Object> row = (Map<String,Object>)obj;

            String productCode = (String)row.get('ProductCode');

            if(productCode == null) continue;

            sourceByProductCode.put(productCode, row);

            if(row.get('Produktgruppe__c') != null){
                groupOldIds.add((String)row.get('Produktgruppe__c'));
            }

            if(row.get('Produkt_Untergruppe__c') != null){
                groupOldIds.add((String)row.get('Produkt_Untergruppe__c'));
            }
        }

        if(groupOldIds.isEmpty()){
            return;
        }

        /* -------------------------------------------------------
           4. Load group/subgroup records in new org
        ------------------------------------------------------- */

        Map<String,Id> groupIdByOldId = new Map<String,Id>();

        for(Product2 grp :
            [SELECT Id, OldId__c
             FROM Product2
             WHERE OldId__c IN :groupOldIds]){

            groupIdByOldId.put(grp.OldId__c, grp.Id);
        }

        /* -------------------------------------------------------
           5. Stage updates
        ------------------------------------------------------- */

        for(Product2 p : scope){

            String key = p.OldProductNumber__c;

            if(!sourceByProductCode.containsKey(key)){
                continue;
            }

            Map<String,Object> src = sourceByProductCode.get(key);

            Product2 upd = new Product2(Id = p.Id);

            String grpOldId = (String)src.get('Produktgruppe__c');
            String subOldId = (String)src.get('Produkt_Untergruppe__c');

            if(grpOldId != null && groupIdByOldId.containsKey(grpOldId)){
                upd.ProductGroup__c = groupIdByOldId.get(grpOldId);
            }

            if(subOldId != null && groupIdByOldId.containsKey(subOldId)){
                upd.ProductSubgroup__c = groupIdByOldId.get(subOldId);
            }

            stagedUpdates.add(upd);
        }
    }

    public void finish(Database.BatchableContext bc){

        if(!stagedUpdates.isEmpty()){
            Database.update(stagedUpdates, false);
        }

        System.debug('Product group mapping completed: ' + stagedUpdates.size());
    }
}