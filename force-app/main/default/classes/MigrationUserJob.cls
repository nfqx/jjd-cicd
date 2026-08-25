public class MigrationUserJob
implements Database.Batchable<SObject>, Database.AllowsCallouts {

    private static final String SOURCE_URL = System.Label.SourceOrgTokenURL;
    private String token;

    public Database.QueryLocator start(Database.BatchableContext bc){

        return Database.getQueryLocator([
            SELECT Id, OldId__c, FirstName, LastName, Account.ERPCustomerNumber__c
            FROM Contact
            WHERE OldId__c != NULL
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Contact> scope){

        if(token == null){
            token = SourceOrgAuth.getAccessToken();
        }

        /* -------------------------------------------------------
           1. Collect old Contact Ids
        ------------------------------------------------------- */

        Set<String> oldContactIds = new Set<String>();

        for(Contact c : scope){
            oldContactIds.add(c.OldId__c);
        }

        if(oldContactIds.isEmpty()){
            return;
        }

        /* -------------------------------------------------------
           2. Query Users from source org
        ------------------------------------------------------- */

        String soql =
        'SELECT Id, Username, ContactId,' +
        'PendingActivation__c, ActivationRequired__c, CreatedByGL__c ' +
        'FROM User WHERE ContactId IN (\'' +
        String.join(new List<String>(oldContactIds),'\',\'') + '\')';

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

        List<Object> sourceUsers =
            (List<Object>)payload.get('records');

        if(sourceUsers.isEmpty()){
            return;
        }

        /* -------------------------------------------------------
           3. Map Contact OldId → Contact
        ------------------------------------------------------- */

        Map<String,Contact> contactByOldId = new Map<String,Contact>();

        for(Contact c : scope){
            contactByOldId.put(c.OldId__c, c);
        }

        /* -------------------------------------------------------
           4. Load Profile + Permission Sets
        ------------------------------------------------------- */

        List<Profile> profiles = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Customer Community Plus User'
            LIMIT 1
        ];

        if(profiles.isEmpty()){
            throw new AuraHandledException(
                'Profile Customer Community Plus User not found'
            );
        }

        Id profileId = profiles[0].Id;

        List<PermissionSet> permissionSets = [
            SELECT Id
            FROM PermissionSet
            WHERE Name IN ('Buyer','J.J.Darboven Webshop')
        ];

        /* -------------------------------------------------------
           5. Build Users
        ------------------------------------------------------- */

        List<User> usersToInsert = new List<User>();

        Map<String,User> userByOldId = new Map<String,User>();

        for(Object rowPre : sourceUsers){

            Map<String,Object> row = (Map<String,Object>)rowPre;

            String oldContactId = (String)row.get('ContactId');

            Contact con = contactByOldId.get(oldContactId);

            if(con == null) continue;

            String username =
                ((String)row.get('Username')) + '.jjd2.0dev';

            String alias = con.Account.ERPCustomerNumber__c;

            if(alias == null){
                String first =
                    con.FirstName != null
                    ? con.FirstName.substring(0,1)
                    : '';

                String last =
                    con.LastName != null
                    ? (con.LastName.length() > 3
                        ? con.LastName.substring(0,3)
                        : con.LastName)
                    : '';

                alias = first + last;
            }

            User u = new User(

                OldId__c = (String)row.get('Id'),

                FirstName = con.FirstName,
                LastName = con.LastName,

                ProfileId = profileId,

                Email = 'darboven@nfq-x.com',
                Username = username,

                IsActive = true,

                ContactId = con.Id,

                LanguageLocaleKey = 'de',
                LocaleSidKey = 'de_DE',
                TimeZoneSidKey = 'Europe/Berlin',
                EmailEncodingKey = 'UTF-8',

                Alias = alias,

                PendingActivation__c =
                    (Boolean)row.get('PendingActivation__c'),

                ActivationRequired__c =
                    (Boolean)row.get('ActivationRequired__c'),

                CreatedByGL__c =
                    (Boolean)row.get('CreatedByGL__c')
            );

            usersToInsert.add(u);
            userByOldId.put(u.OldId__c, u);
        }

        if(usersToInsert.isEmpty()){
            return;
        }

        Database.upsert(usersToInsert, User.OldId__c, false);

        /* -------------------------------------------------------
           6. Assign Permission Sets
        ------------------------------------------------------- */

        List<PermissionSetAssignment> psasToCreate =
            new List<PermissionSetAssignment>();

        for(User u : usersToInsert){

            if(u.Id == null) continue;

            for(PermissionSet ps : permissionSets){

                psasToCreate.add(
                    new PermissionSetAssignment(
                        PermissionSetId = ps.Id,
                        AssigneeId = u.Id
                    )
                );
            }
        }

        if(!psasToCreate.isEmpty()){
            Database.insert(psasToCreate, false);
        }
    }

    public void finish(Database.BatchableContext bc){

        System.debug('User migration finished');

    }
}