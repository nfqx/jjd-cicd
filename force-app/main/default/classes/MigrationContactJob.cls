public class MigrationContactJob
implements Database.Batchable<SObject>, Database.AllowsCallouts {

    private static final String SOURCE_URL = System.Label.SourceOrgTokenURL;
    private String token;

    public Database.QueryLocator start(Database.BatchableContext bc){

        return Database.getQueryLocator([
            SELECT Id, CustomerReferenceId__c
            FROM Account
            WHERE CustomerReferenceId__c != NULL
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope){

        if(token == null){
            token = SourceOrgAuth.getAccessToken();
        }

        /* Collect refs */

        Set<String> refs = new Set<String>();

        for(Account a : scope){
            refs.add(a.CustomerReferenceId__c);
        }

        if(refs.isEmpty()) return;

        /* Query old accounts */

        String soql =
            'SELECT Id, CustomerReferenceID__c ' +
            'FROM Account WHERE CustomerReferenceID__c IN (\'' +
            String.join(new List<String>(refs), '\',\'') + '\')';

        HttpRequest req = new HttpRequest();

        req.setEndpoint(
            SOURCE_URL + '/services/data/v65.0/query/?q=' +
            EncodingUtil.urlEncode(soql,'UTF-8')
        );

        req.setMethod('GET');
        req.setHeader('Authorization','Bearer '+token);

        HttpResponse res = new Http().send(req);

        Map<String,Object> payload =
            (Map<String,Object>)JSON.deserializeUntyped(res.getBody());

        List<Object> oldAccounts =
            (List<Object>)payload.get('records');

        if(oldAccounts.isEmpty()) return;

        Map<String,String> oldAccountIdByRef = new Map<String,String>();

        for(Object rowPre : oldAccounts){
            System.debug(rowPre);
            Map<String,Object> row = (Map<String,Object>)rowPre;

            oldAccountIdByRef.put(
                (String)row.get('CustomerReferenceID__c'),
                (String)row.get('Id')
            );
        }

        Set<String> oldAccountIds =
            new Set<String>(oldAccountIdByRef.values());

        if(oldAccountIds.isEmpty()) return;

        /* Query Contacts from old org */

        String contactSoql =
        'SELECT Id, AccountId, Salutation, FirstName, LastName, Email, Phone, MobilePhone,'+
        'ActiveWebshopUser__c, WebshopSelfActivationPending__c, WebshopSelfActivationTimestamp__c,'+
        'Webshop_Customer__c, PriceVisible__c, Double_Optin_requested__c,'+
        'DoubleOptInAbandonedCart__c, DoubleOptInAbandonedCartModalSeen__c,'+
        'Function__c, Manager__c, OrderNotificationRecipient__c '+
        'FROM Contact WHERE AccountId IN (\''+
        String.join(new List<String>(oldAccountIds),'\',\'')+'\')';

        HttpRequest reqContacts = new HttpRequest();

        reqContacts.setEndpoint(
            SOURCE_URL + '/services/data/v65.0/query/?q=' +
            EncodingUtil.urlEncode(contactSoql,'UTF-8')
        );

        reqContacts.setMethod('GET');
        reqContacts.setHeader('Authorization','Bearer '+token);

        HttpResponse resContacts = new Http().send(reqContacts);

        System.debug(resContacts.getBody());
        Map<String,Object> payloadContacts =
            (Map<String,Object>)JSON.deserializeUntyped(resContacts.getBody());

        List<Object> sourceContacts =
            (List<Object>)payloadContacts.get('records');

        if(sourceContacts.isEmpty()) return;

        Map<String,Account> newAccountByRef = new Map<String,Account>();

        for(Account a : scope){
            newAccountByRef.put(a.CustomerReferenceId__c, a);
        }

        List<Contact> upserts = new List<Contact>();
        System.debug(sourceContacts);
        for(Object rowPre : sourceContacts){

            Map<String,Object> row = (Map<String,Object>)rowPre;

            String oldAccountId = (String)row.get('AccountId');

            String ref;

            System.debug(oldAccountIdByRef);
            System.debug(oldAccountId);
            for(String r : oldAccountIdByRef.keySet()){
                if(oldAccountIdByRef.get(r) == oldAccountId){
                    ref = r;
                    break;
                }
            }
            System.debug('1');
            System.debug(ref);

            Account newAcc = newAccountByRef.get(ref);
            System.debug(newAcc);
            if(newAcc == null) continue;
            System.debug('2');

            Contact c = new Contact();

            c.OldId__c = (String)row.get('Id');
            c.AccountId = newAcc.Id;

            c.Salutation = (String)row.get('Salutation');
            c.FirstName = (String)row.get('FirstName');
            c.LastName = (String)row.get('LastName');
            c.Email = (String)row.get('Email');
            c.Phone = (String)row.get('Phone');
            c.MobilePhone = (String)row.get('MobilePhone');

            c.ActiveWebshopUser__c =
                (Boolean)row.get('ActiveWebshopUser__c');

            c.WebshopSelfActivationPending__c =
                (Boolean)row.get('WebshopSelfActivationPending__c');

            c.WebshopSelfActivationTimestamp__c =
                (Datetime)row.get('WebshopSelfActivationTimestamp__c');

            c.WebshopCustomer__c =
                (Boolean)row.get('Webshop_Customer__c');

            c.PriceVisible__c =
                (Boolean)row.get('PriceVisible__c');

            c.DoubleOptInRequested__c =
                (Boolean)row.get('Double_Optin_requested__c');

            c.DoubleOptInAbandonedCart__c =
                (Boolean)row.get('DoubleOptInAbandonedCart__c');

            c.DoubleOptInAbandonedCartModalSeen__c =
                (Boolean)row.get('DoubleOptInAbandonedCartModalSeen__c');

            c.Function__c = (String)row.get('Function__c');
            c.Manager__c = (Boolean)row.get('Manager__c');

            c.OrderNotificationRecipient__c =
                (Boolean)row.get('OrderNotificationRecipient__c');
            System.debug(c);
            upserts.add(c);
        }

        System.debug(Database.upsert(upserts, Contact.OldId__c, false));
    }

    public void finish(Database.BatchableContext bc){

        Database.executeBatch(
            new MigrationUserJob(),
            50
        );
    }
}