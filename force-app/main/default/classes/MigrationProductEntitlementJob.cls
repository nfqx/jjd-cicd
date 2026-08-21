public class MigrationProductEntitlementJob
implements Database.Batchable<SObject>, Database.AllowsCallouts {

    private static final String SOURCE_URL = System.Label.SourceOrgTokenURL;

    private String token;

    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([
            SELECT Id, CustomerReferenceId__c
            FROM Account
            WHERE CustomerReferenceId__c != NULL
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {

        if(token == null){
            token = SourceOrgAuth.getAccessToken();
        }

        /* -------------------------------------------------------
           1. Collect CustomerReferenceIds
        ------------------------------------------------------- */

        Set<String> customerRefs = new Set<String>();

        for(Account a : scope){
            customerRefs.add(a.CustomerReferenceId__c);
        }

        if(customerRefs.isEmpty()){
            return;
        }

        /* -------------------------------------------------------
           2. Query Accounts from source org
        ------------------------------------------------------- */

        String soql =
            'SELECT Id, CustomerReferenceId__c ' +
            'FROM Account ' +
            'WHERE CustomerReferenceId__c IN (\'' +
            String.join(new List<String>(customerRefs), '\',\'') +
            '\')';

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

        List<Object> sourceAccounts =
            (List<Object>)payload.get('records');

        if(sourceAccounts.isEmpty()){
            return;
        }

        /* -------------------------------------------------------
           3. Build Account mappings
        ------------------------------------------------------- */

        Map<String,Account> newAccountByRef = new Map<String,Account>();

        for(Account a : scope){
            newAccountByRef.put(a.CustomerReferenceId__c, a);
        }

        Map<String,String> oldAccountIdByRef = new Map<String,String>();

        for(Object rowPre : sourceAccounts){

            Map<String,Object> row = (Map<String,Object>)rowPre;

            oldAccountIdByRef.put(
                (String)row.get('CustomerReferenceId__c'),
                (String)row.get('Id')
            );
        }

        /* -------------------------------------------------------
           4. Fetch CommerceEntitlementProduct from source
        ------------------------------------------------------- */

        Set<String> oldAccountIds = new Set<String>(oldAccountIdByRef.values());

        if(oldAccountIds.isEmpty()){
            return;
        }

        String productSoql =
            'SELECT Id, Product.ProductCode, Policy.Account__r.CustomerReferenceId__c ' +
            'FROM CommerceEntitlementProduct ' +
            'WHERE Policy.Account__c IN (\'' +
            String.join(new List<String>(oldAccountIds), '\',\'') +
            '\')';

        HttpRequest reqProducts = new HttpRequest();

        reqProducts.setEndpoint(
            SOURCE_URL + '/services/data/v65.0/query/?q=' +
            EncodingUtil.urlEncode(productSoql,'UTF-8')
        );

        reqProducts.setMethod('GET');
        reqProducts.setHeader('Authorization','Bearer ' + token);

        HttpResponse resProducts = new Http().send(reqProducts);

        if(resProducts.getStatusCode() != 200){
            throw new CalloutException(resProducts.getBody());
        }

        Map<String,Object> payloadProducts =
            (Map<String,Object>)JSON.deserializeUntyped(resProducts.getBody());

        List<Object> sourceLinks =
            (List<Object>)payloadProducts.get('records');

        if(sourceLinks.isEmpty()){
            return;
        }

        /* -------------------------------------------------------
           5. Collect Product Codes
        ------------------------------------------------------- */

        Set<String> productCodes = new Set<String>();

        for(Object rowPre : sourceLinks){

            Map<String,Object> row = (Map<String,Object>)rowPre;

            Map<String,Object> prod =
                (Map<String,Object>)row.get('Product');

            if(prod != null && prod.get('ProductCode') != null){
                productCodes.add((String)prod.get('ProductCode'));
            }
        }

        if(productCodes.isEmpty()){
            return;
        }

        /* -------------------------------------------------------
           6. Map Products in new org (ProductCode)
        ------------------------------------------------------- */

        Map<String,List<Product2>> productsByProductCode = new Map<String,List<Product2>>();

        for(Product2 p :
            [SELECT Id, OldProductNumber__c
             FROM Product2
             WHERE OldProductNumber__c IN :productCodes]){

            if(p.OldProductNumber__c != null){
                if(!productsByProductCode.containsKey(p.OldProductNumber__c)){
                    productsByProductCode.put(p.OldProductNumber__c, new List<Product2>());
                }
                productsByProductCode.get(p.OldProductNumber__c).add(p);
            }
        }

        /* -------------------------------------------------------
           7. Detect variant children
        ------------------------------------------------------- */

        Set<Id> allProductIds = new Set<Id>();

        for(List<Product2> lst : productsByProductCode.values()){
            for(Product2 p : lst){
                allProductIds.add(p.Id);
            }
        }

        Set<Id> childProductIds = new Set<Id>();

        if(!allProductIds.isEmpty()){
            for(ProductAttribute pa :
                [SELECT ProductId
                 FROM ProductAttribute
                 WHERE VariantParentId != NULL
                 AND ProductId IN :allProductIds]){

                childProductIds.add(pa.ProductId);
            }
        }

        /* -------------------------------------------------------
           8. Load or create policies
        ------------------------------------------------------- */

        Map<Id,CommerceEntitlementPolicy> policyByAccount =
            new Map<Id,CommerceEntitlementPolicy>();

        for(CommerceEntitlementPolicy p :
            [SELECT Id, Account__c
             FROM CommerceEntitlementPolicy
             WHERE Account__c IN :scope]){

            policyByAccount.put(p.Account__c, p);
        }

        List<CommerceEntitlementPolicy> policiesToInsert =
            new List<CommerceEntitlementPolicy>();

        for(Account acc : scope){
            if(!policyByAccount.containsKey(acc.Id)){
                policiesToInsert.add(
                    new CommerceEntitlementPolicy(Account__c = acc.Id)
                );
            }
        }

        if(!policiesToInsert.isEmpty()){
            Database.insert(policiesToInsert, false);

            for(CommerceEntitlementPolicy p : policiesToInsert){
                policyByAccount.put(p.Account__c, p);
            }
        }

        /* -------------------------------------------------------
           9. Build entitlement inserts
        ------------------------------------------------------- */

        List<CommerceEntitlementProduct> parentRecords = new List<CommerceEntitlementProduct>();
        List<CommerceEntitlementProduct> childRecords  = new List<CommerceEntitlementProduct>();

        for(Object rowPre : sourceLinks){

            Map<String,Object> row = (Map<String,Object>)rowPre;

            Map<String,Object> prod =
                (Map<String,Object>)row.get('Product');

            Map<String,Object> policyAcc =
                (Map<String,Object>)((Map<String,Object>)row.get('Policy'))
                .get('Account__r');

            if(prod == null || policyAcc == null) continue;

            String productCode = (String)prod.get('ProductCode');
            String ref = (String)policyAcc.get('CustomerReferenceId__c');

            Account newAcc = newAccountByRef.get(ref);
            if(newAcc == null) continue;

            CommerceEntitlementPolicy policy = policyByAccount.get(newAcc.Id);
            if(policy == null) continue;

            List<Product2> matches = productsByProductCode.get(productCode);

            if(matches == null) continue;

            for(Product2 product : matches){

                CommerceEntitlementProduct link =
                    new CommerceEntitlementProduct();

                link.ProductId = product.Id;
                link.PolicyId  = policy.Id;

                if(childProductIds.contains(product.Id)){
                    childRecords.add(link);
                } else {
                    parentRecords.add(link);
                }
            }
        }

        /* -------------------------------------------------------
           10. Insert parent then child
        ------------------------------------------------------- */

        if(!parentRecords.isEmpty()){
            Database.insert(parentRecords, false);
        }

        if(!childRecords.isEmpty()){
            Database.insert(childRecords, false);
        }
    }

    public void finish(Database.BatchableContext bc) {

        System.debug('Product Entitlement migration finished');

    }
}