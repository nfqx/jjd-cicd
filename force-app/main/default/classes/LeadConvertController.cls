public without sharing class LeadConvertController {

    public static Boolean inhibitTrigger = false;
    @TestVisible
    private static final List<Schema.DisplayType> NUMBER_TYPES = new List<Schema.DisplayType>{
        Schema.DisplayType.CURRENCY,
        Schema.DisplayType.DOUBLE,
        Schema.DisplayType.INTEGER,
        Schema.DisplayType.LONG,
        Schema.DisplayType.PERCENT
    };

    @TestVisible 
    private static final LeadStatus CONVERT_STATUS = [SELECT Id, ApiName FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];

    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getContactRoleOptions(){
        List<Map<String, String>> picklistValuesList = new List<Map<String, String>>();
        Schema.DescribeSObjectResult describeSObjectResult = AccountContactRelation.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = describeSObjectResult.fields.getMap();
        Schema.DescribeFieldResult fieldResult = fieldMap.get('Roles').getDescribe();

        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            Map<String, String> picklistEntryMap = new Map<String, String>{
                'label' => entry.getLabel(),
                'value' => entry.getValue()
            };
            picklistValuesList.add(picklistEntryMap);
        }

        return picklistValuesList;
    }
    @AuraEnabled(cacheable=false)
    public static List<AccountContactRelation> getContactAccountRelations(String contactId){
        return [SELECT Id, AccountId, Account.Name, Account.CreatedBy.Name, Account.CreatedDate FROM AccountContactRelation WHERE ContactId = : contactId];
    }

    @AuraEnabled(cacheable=false)
    public static List<FieldMappingWrapper> getLeadAccountMergeMap(String leadId, String accountId){
        List<FieldMappingWrapper> wrapperList = new List<FieldMappingWrapper>();
        Map<String, LeadConversionMapping__c> lcmMap = new Map<String, LeadConversionMapping__c>();

        List<String> leadFields = new List<String>{'Id'};
        List<String> accountFields = new List<String>{'Id'};
        Map<String, Schema.sObjectField> leadMap = new Lead().getSObjectType().getDescribe().fields.getMap();
        Map<String, Schema.sObjectField> accountMap = new Account().getSObjectType().getDescribe().fields.getMap();
        List<LeadConversionMapping__c> lcms = [SELECT Id, SourceFieldName__c, TargetFieldName__c FROM LeadConversionMapping__c WHERE TargetObjectName__c = 'Account' ORDER BY SourceFieldName__c];
        for(LeadConversionMapping__c lcm : lcms){
            leadFields.add(lcm.SourceFieldName__c);
            accountFields.add(lcm.TargetFieldName__c);
            lcmMap.put(lcm.TargetFieldName__c, lcm);
            if(leadMap.get(lcm.SourceFieldName__c).getDescribe().getType() == Schema.DisplayType.PICKLIST){
                leadFields.add('TOLABEL(' + lcm.SourceFieldName__c + ') ' + lcm.SourceFieldName__c.removeEnd('__c') + '_label');
            }
            if(accountMap.get(lcm.TargetFieldName__c).getDescribe().getType() == Schema.DisplayType.PICKLIST){
                accountFields.add('TOLABEL(' + lcm.TargetFieldName__c + ') ' + lcm.TargetFieldName__c.removeEnd('__c') + '_label');
            }
        }

        sObject sourceLead = Database.query('SELECT ' + String.join(leadFields, ',') + ' FROM Lead WHERE Id = \'' + leadId + '\'');
        sObject sourceAccount = Database.query('SELECT ' + String.join(accountFields, ',') + ' FROM Account WHERE Id = \'' + accountId + '\'');

        for(LeadConversionFieldSetting__mdt fieldSetting : [SELECT Id, Field__r.QualifiedApiName FROM LeadConversionFieldSetting__mdt WHERE ShowMerge__c = TRUE AND Object__r.QualifiedApiName = 'Account' ORDER BY MergeOrder__c]){
            if(fieldSetting.Field__r.QualifiedApiName == 'ShippingAddress'){
                Set<String> fields = new Set<String>{'ShippingStreet', 'ShippingPostalCode', 'ShippingCity', 'ShippingCountry'};
                for(String field : fields){
                    if(lcmMap.containsKey(field)){
                        LeadConversionMapping__c lcm = lcmMap.get(field);
                        wrapperList.add(new FieldMappingWrapper(
                            lcm.SourceFieldName__c,
                            leadMap.get(lcm.SourceFieldName__c).getDescribe().getLabel(),
                            lcm.TargetFieldName__c,
                            accountMap.get(lcm.TargetFieldName__c).getDescribe().getLabel(),
                            String.valueOf(sourceLead.get(lcm.SourceFieldName__c)),
                            String.valueOf(sourceAccount.get(lcm.TargetFieldName__c)),
                            leadMap.get(lcm.SourceFieldName__c).getDescribe().getType() == Schema.DisplayType.PICKLIST ? String.valueOf(sourceLead.get(lcm.SourceFieldName__c.removeEnd('__c') + '_label')) : processTrueFalse(String.valueOf(sourceLead.get(lcm.SourceFieldName__c))),
                            accountMap.get(lcm.TargetFieldName__c).getDescribe().getType() == Schema.DisplayType.PICKLIST ? String.valueOf(sourceAccount.get(lcm.TargetFieldName__c.removeEnd('__c') + '_label')) : processTrueFalse(String.valueOf(sourceAccount.get(lcm.TargetFieldName__c))),
                            leadMap.get(lcm.SourceFieldName__c).getDescribe().getType() == Schema.DisplayType.MULTIPICKLIST && accountMap.get(lcm.TargetFieldName__c).getDescribe().getType() == Schema.DisplayType.MULTIPICKLIST,
                            leadMap.get(lcm.SourceFieldName__c).getDescribe().getType() == Schema.DisplayType.TEXTAREA && accountMap.get(lcm.TargetFieldName__c).getDescribe().getType() == Schema.DisplayType.TEXTAREA
                        ));
                    }
                }
            } else {
                if(lcmMap.containsKey(fieldSetting.Field__r.QualifiedApiName)){
                    LeadConversionMapping__c lcm = lcmMap.get(fieldSetting.Field__r.QualifiedApiName);
                    wrapperList.add(new FieldMappingWrapper(
                        lcm.SourceFieldName__c,
                        leadMap.get(lcm.SourceFieldName__c).getDescribe().getLabel(),
                        lcm.TargetFieldName__c,
                        accountMap.get(lcm.TargetFieldName__c).getDescribe().getLabel(),
                        String.valueOf(sourceLead.get(lcm.SourceFieldName__c)),
                        String.valueOf(sourceAccount.get(lcm.TargetFieldName__c)),
                        leadMap.get(lcm.SourceFieldName__c).getDescribe().getType() == Schema.DisplayType.PICKLIST ? String.valueOf(sourceLead.get(lcm.SourceFieldName__c.removeEnd('__c') + '_label')) : processTrueFalse(String.valueOf(sourceLead.get(lcm.SourceFieldName__c))),
                        accountMap.get(lcm.TargetFieldName__c).getDescribe().getType() == Schema.DisplayType.PICKLIST ? String.valueOf(sourceAccount.get(lcm.TargetFieldName__c.removeEnd('__c') + '_label')) : processTrueFalse(String.valueOf(sourceAccount.get(lcm.TargetFieldName__c))),
                        leadMap.get(lcm.SourceFieldName__c).getDescribe().getType() == Schema.DisplayType.MULTIPICKLIST && accountMap.get(lcm.TargetFieldName__c).getDescribe().getType() == Schema.DisplayType.MULTIPICKLIST,
                        leadMap.get(lcm.SourceFieldName__c).getDescribe().getType() == Schema.DisplayType.TEXTAREA && accountMap.get(lcm.TargetFieldName__c).getDescribe().getType() == Schema.DisplayType.TEXTAREA
                    ));
                }
            }
        }
        return wrapperList;
    }
    @AuraEnabled(cacheable=false)
    public static List<FieldMappingWrapper> getLeadContactMergeMap(String leadId, String contactId){
        List<FieldMappingWrapper> wrapperList = new List<FieldMappingWrapper>();
        Map<String, LeadConversionMapping__c> lcmMap = new Map<String, LeadConversionMapping__c>();

        List<String> leadFields = new List<String>{'Id'};
        List<String> contactFields = new List<String>{'Id'};
        Map<String, Schema.sObjectField> leadMap = new Lead().getSObjectType().getDescribe().fields.getMap();
        Map<String, Schema.sObjectField> contactMap = new Contact().getSObjectType().getDescribe().fields.getMap();
        List<LeadConversionMapping__c> lcms = [SELECT Id, SourceFieldName__c, TargetFieldName__c FROM LeadConversionMapping__c WHERE TargetObjectName__c = 'Contact' ORDER BY SourceFieldName__c];
        for(LeadConversionMapping__c lcm : lcms){
            leadFields.add(lcm.SourceFieldName__c);
            contactFields.add(lcm.TargetFieldName__c);
            lcmMap.put(lcm.TargetFieldName__c, lcm);
            if(leadMap.get(lcm.SourceFieldName__c).getDescribe().getType() == Schema.DisplayType.PICKLIST){
                leadFields.add('TOLABEL(' + lcm.SourceFieldName__c + ') ' + lcm.SourceFieldName__c.removeEnd('__c') + '_label');
            }
            if(contactMap.get(lcm.TargetFieldName__c).getDescribe().getType() == Schema.DisplayType.PICKLIST){
                contactFields.add('TOLABEL(' + lcm.TargetFieldName__c + ') ' + lcm.TargetFieldName__c.removeEnd('__c') + '_label');
            }
        }

        sObject sourceLead = Database.query('SELECT ' + String.join(leadFields, ',') + ' FROM Lead WHERE Id = \'' + leadId + '\'');
        sObject sourceContact = Database.query('SELECT ' + String.join(contactFields, ',') + ' FROM Contact WHERE Id = \'' + contactId + '\'');

        for(LeadConversionFieldSetting__mdt fieldSetting : [SELECT Id, Field__r.QualifiedApiName FROM LeadConversionFieldSetting__mdt WHERE ShowMerge__c = TRUE AND Object__r.QualifiedApiName = 'Contact' ORDER BY MergeOrder__c]){
            if(lcmMap.containsKey(fieldSetting.Field__r.QualifiedApiName)){
                LeadConversionMapping__c lcm = lcmMap.get(fieldSetting.Field__r.QualifiedApiName);
                wrapperList.add(new FieldMappingWrapper(
                    lcm.SourceFieldName__c,
                    leadMap.get(lcm.SourceFieldName__c).getDescribe().getLabel(),
                    lcm.TargetFieldName__c,
                    contactMap.get(lcm.TargetFieldName__c).getDescribe().getLabel(),
                    String.valueOf(sourceLead.get(lcm.SourceFieldName__c)),
                    String.valueOf(sourceContact.get(lcm.TargetFieldName__c)),
                    leadMap.get(lcm.SourceFieldName__c).getDescribe().getType() == Schema.DisplayType.PICKLIST ? String.valueOf(sourceLead.get(lcm.SourceFieldName__c.removeEnd('__c') + '_label')) : processTrueFalse(String.valueOf(sourceLead.get(lcm.SourceFieldName__c))),
                    contactMap.get(lcm.TargetFieldName__c).getDescribe().getType() == Schema.DisplayType.PICKLIST ? String.valueOf(sourceContact.get(lcm.TargetFieldName__c.removeEnd('__c') + '_label')) : processTrueFalse(String.valueOf(sourceContact.get(lcm.TargetFieldName__c))),
                    leadMap.get(lcm.SourceFieldName__c).getDescribe().getType() == Schema.DisplayType.MULTIPICKLIST && contactMap.get(lcm.TargetFieldName__c).getDescribe().getType() == Schema.DisplayType.MULTIPICKLIST,
                    leadMap.get(lcm.SourceFieldName__c).getDescribe().getType() == Schema.DisplayType.TEXTAREA && contactMap.get(lcm.TargetFieldName__c).getDescribe().getType() == Schema.DisplayType.TEXTAREA
                ));
            }
        }
        return wrapperList;
    }

    public class SearchResultsWrapper{
        @AuraEnabled public List<sObject> records {get; set;}
        @AuraEnabled public Map<String, String> displayedFields {get; set;}
        public SearchResultsWrapper(List<sObject> records, Map<String, String> displayedFields){
            this.records = records;
            this.displayedFields = displayedFields;    
        }
    }
    @AuraEnabled(cacheable=false)
    public static SearchResultsWrapper getPotentialContactDuplicates(String leadId){
        List<Lead> leads = [SELECT Id, Email, HashStreetCompany__c, HashLastNameCompany__c FROM Lead WHERE Id = :leadId];
        List<Contact> records = new List<Contact>();
        Map<String, String> fields = new Map<String, String>(); // TODO Use fields in query
        for(LeadConversionFieldSetting__mdt fieldSetting : [SELECT Id, Field__r.Label, Field__r.QualifiedApiName FROM LeadConversionFieldSetting__mdt WHERE ShowTableColumn__c = TRUE AND Object__r.QualifiedApiName = 'Contact' ORDER BY TableOrder__c]){
            fields.put(fieldSetting.Field__r.QualifiedApiName, fieldSetting.Field__r.Label);
        }
        if(!leads.isEmpty()){
            String leadEmail = leads[0].Email;
            String leadStreetCompanyHash = leads[0].HashStreetCompany__c;
            String leadLastNameCompanyHash = leads[0].HashLastNameCompany__c;
            String queryString = 'SELECT Id, Name, CreatedDate, CreatedBy.Name, AccountId, Account.Name, Account.ShippingStreet, ';
            queryString += String.join(new List<String>(fields.keySet()), ', ');
            queryString = queryString.removeEnd(', ');
            if(String.isNotBlank(leadEmail)){
                queryString += ' FROM Contact WHERE Email = : leadEmail OR HashStreetCompany__c = : leadStreetCompanyHash OR HashLastNameCompany__c = : leadLastNameCompanyHash';
            } else {
                queryString += ' FROM Contact WHERE HashStreetCompany__c = : leadStreetCompanyHash OR HashLastNameCompany__c = : leadLastNameCompanyHash';
            }
            records = Database.query(queryString);
        }
        return new SearchResultsWrapper(records, fields);
    }
    @AuraEnabled(cacheable=false)
    public static SearchResultsWrapper getPotentialAccountDuplicates(String leadId){
        List<Account> records = new List<Account>();
        Map<String, String> fields = new Map<String, String>();
        for(LeadConversionFieldSetting__mdt fieldSetting : [SELECT Id, Field__r.Label, Field__r.QualifiedApiName FROM LeadConversionFieldSetting__mdt WHERE ShowTableColumn__c = TRUE AND Object__r.QualifiedApiName = 'Account' ORDER BY TableOrder__c]){
            if(fieldSetting.Field__r.QualifiedApiName == 'ShippingAddress'){
                fields.put('ShippingStreet', System.Label.GeneralShippingStreet);
                fields.put('ShippingPostalCode', System.Label.GeneralShippingPostalCode);
                fields.put('ShippingCity', System.Label.GeneralShippingCity);
                fields.put('ShippingCountry', System.Label.GeneralShippingCountry);
            } else {
                fields.put(fieldSetting.Field__r.QualifiedApiName, fieldSetting.Field__r.Label);
            }
        }
        List<Lead> leads = [SELECT Id, Company FROM Lead WHERE Id = :leadId];
        if(!leads.isEmpty() && String.isNotBlank(leads[0].Company)){
            String leadCompany = '%' + leads[0].Company + '%';
            String queryString = 'SELECT Id, Name, CreatedDate, CreatedBy.Name, ';
            queryString += String.join(new List<String>(fields.keySet()), ', ');
            queryString = queryString.removeEnd(', ');
            queryString += ' FROM Account WHERE Name LIKE : leadCompany';
            records = Database.query(queryString);
        }
        return new SearchResultsWrapper(records, fields);
    }
    @AuraEnabled(cacheable=false)
    public static SearchResultsWrapper soslSearchContact(String searchTerm){
        Map<String, String> fields = new Map<String, String>(); // TODO Use fields in query
        for(LeadConversionFieldSetting__mdt fieldSetting : [SELECT Id, Field__r.Label, Field__r.QualifiedApiName FROM LeadConversionFieldSetting__mdt WHERE ShowTableColumn__c = TRUE AND Object__r.QualifiedApiName = 'Contact' ORDER BY TableOrder__c]){
            fields.put(fieldSetting.Field__r.QualifiedApiName, fieldSetting.Field__r.Label);
        }
        List<SObject> results = new List<SObject>();       
        if(String.isNotBlank(searchTerm)){
            String soslQuery = 'FIND \'' + searchTerm + '\' IN ALL FIELDS RETURNING Contact(Id, Name, AccountId, Account.ShippingStreet, Account.Name, CreatedDate, CreatedBy.Name';
            if(!fields.isEmpty()){
                soslQuery += ', ';
                soslQuery += String.join(new List<String>(fields.keySet()), ', ');
            }
            soslQuery += ')'; 
            List<String> referenceObjectTypes = new List<String>{'Contact'};
            Search.SearchResults searchResults = Search.find(soslQuery);
            for(String reference : referenceObjectTypes) {
                List<Search.SearchResult> objectResult = searchResults.get(reference);
                for (Search.SearchResult searchResult : objectResult) {
                    SObject sobj = searchResult.getSObject();
                    results.add(sobj);
                }
            }
        }
        return new SearchResultsWrapper(results, fields);
    }
    @AuraEnabled(cacheable=false)
    public static SearchResultsWrapper soslSearchAccount(String searchTerm){
        Map<String, String> fields = new Map<String, String>(); // TODO Use fields in query
        for(LeadConversionFieldSetting__mdt fieldSetting : [SELECT Id, Field__r.Label, Field__r.QualifiedApiName FROM LeadConversionFieldSetting__mdt WHERE ShowTableColumn__c = TRUE AND Object__r.QualifiedApiName = 'Account' ORDER BY TableOrder__c]){
            if(fieldSetting.Field__r.QualifiedApiName == 'ShippingAddress'){
                fields.put('ShippingStreet', System.Label.GeneralShippingStreet);
                fields.put('ShippingPostalCode', System.Label.GeneralShippingPostalCode);
                fields.put('ShippingCity', System.Label.GeneralShippingCity);
                fields.put('ShippingCountry', System.Label.GeneralShippingCountry);
            } else {
                fields.put(fieldSetting.Field__r.QualifiedApiName, fieldSetting.Field__r.Label);
            }
        }
        List<SObject> results = new List<SObject>();       
        if(String.isNotBlank(searchTerm)){
            String soslQuery = 'FIND \'' + searchTerm + '\' IN ALL FIELDS RETURNING Account(Id, Name, CreatedDate, CreatedBy.Name';
            if(!fields.isEmpty()){
                soslQuery += ', ';
                soslQuery += String.join(new List<String>(fields.keySet()), ', ');
            }
            soslQuery += ')'; 
            List<String> referenceObjectTypes = new List<String>{'Account'};
            Search.SearchResults searchResults = Search.find(soslQuery);
            for(String reference : referenceObjectTypes) {
                List<Search.SearchResult> objectResult = searchResults.get(reference);
                for (Search.SearchResult searchResult : objectResult) {
                    SObject sobj = searchResult.getSObject();
                    results.add(sobj);
                }
            }
        }
        return new SearchResultsWrapper(results, fields);
    }
    @AuraEnabled(cacheable=false)
    public static ConvertedLeadWrapper convertLeadWithExistingAccount(
        Id leadId, 
        Id accountId, 
        Map<String, String> accountFieldMapping, 
        Boolean withOpp, 
        String oppName
    ){
        try{
            inhibitTrigger = true;
            SObject sobj = accountId.getSObjectType().newSObject(accountId);
            Map<String, Schema.SObjectField> fieldsMap = accountId.getSObjectType().getDescribe().fields.getMap();
            for(String fieldName : accountFieldMapping.keySet()){
                if(fieldName != 'Id' && fieldsMap.containsKey(fieldName)){
                    if(NUMBER_TYPES.contains(fieldsMap.get(fieldName).getDescribe().getType())){
                        sobj.put(
                            fieldName, 
                            Decimal.valueOf(String.valueOf(accountFieldMapping.get(fieldName)))
                        );
                    } else if(fieldsMap.get(fieldName).getDescribe().getType() == Schema.DisplayType.BOOLEAN){
                        sObj.put(
                            fieldName,
                            String.valueOf(accountFieldMapping.get(fieldName)) == 'true' ? true : false
                        );
                    }  else {
                        sobj.put(
                            fieldName, 
                            String.valueOf(accountFieldMapping.get(fieldName))
                        );
                    }
                }
            }
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.allowFieldTruncation = true;
            Database.update(sobj, dml);
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(leadId);
            lc.setAccountId(accountId);
            lc.setConvertedStatus(CONVERT_STATUS.ApiName);
            if(!withOpp){
                lc.setDoNotCreateOpportunity(true);
            } else {
                if(String.isNotBlank(oppName)){
                    lc.setOpportunityName(oppName);
                }
            }
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            inhibitTrigger = false;
            if(!lcr.isSuccess()){
                return new ConvertedLeadWrapper('Error: Lead Conversion Error');
            } else {
                return new ConvertedLeadWrapper(
                    lcr.getAccountId(), [SELECT Id, Name FROM Account WHERE Id = : lcr.getAccountId()].Name,
                    lcr.getContactId(), [SELECT Id, Name FROM Contact WHERE Id = : lcr.getContactId()].Name,
                    withOpp ? lcr.getOpportunityId() : null,
                    withOpp ? [SELECT Id, Name FROM Opportunity WHERE Id = : lcr.getOpportunityId()].Name : null);
            }
        } catch(Exception e){
            return new ConvertedLeadWrapper(e.getMessage());
        }
    }
    @AuraEnabled(cacheable=false)
    public static ConvertedLeadWrapper convertLeadWithExistingContact(
        Id leadId, 
        Id contactId, 
        Id accountId,
        Map<String, String> contactFieldMapping, 
        Boolean withOpp, 
        String oppName,
        List<String> contactRoles
    ){
        try{
            inhibitTrigger = true;
            SObject sobj = contactId.getSObjectType().newSObject(contactId);
            Map<String, Schema.SObjectField> fieldsMap = contactId.getSObjectType().getDescribe().fields.getMap();
            for(String fieldName : contactFieldMapping.keySet()){
                if(fieldName != 'Id' && fieldsMap.containsKey(fieldName)){
                    if(NUMBER_TYPES.contains(fieldsMap.get(fieldName).getDescribe().getType())){
                        sobj.put(
                            fieldName, 
                            Decimal.valueOf(String.valueOf(contactFieldMapping.get(fieldName)))
                        );
                    } else if(fieldsMap.get(fieldName).getDescribe().getType() == Schema.DisplayType.BOOLEAN){
                        sObj.put(
                            fieldName,
                            String.valueOf(contactFieldMapping.get(fieldName)) == 'true' ? true : false
                        );
                    } else {
                        sobj.put(
                            fieldName, 
                            String.valueOf(contactFieldMapping.get(fieldName))
                        );
                    }
                }
            }
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.allowFieldTruncation = true;
            Database.update(sobj, dml);
            Contact con = [SELECT Id, AccountId FROM Contact WHERE Id = : contactId];
            Lead ld = [SELECT Id, Company FROM Lead WHERE Id = : leadId];
            Account acc = null;
            if(String.isBlank(accountId)){
                acc = new Account(
                    Name = ld.Company
                );
                insert acc;
                if(con.AccountId == null){
                    con.AccountId = acc.Id;
                    update con;
                } else {
                    AccountContactRelation acr = new AccountContactRelation(
                        AccountId = acc.Id,
                        ContactId = contactId,
                        Roles = String.join(contactRoles, ';')
                    );
                    insert acr;
                }
                accountId = acc.Id;
            } else if(con.AccountId != accountId){
                AccountContactRelation acr = new AccountContactRelation(
                    AccountId = accountId,
                    ContactId = contactId,
                    Roles = String.join(contactRoles, ';')
                );
                insert acr;
            }
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(leadId);
            lc.setContactId(contactId);
            lc.setConvertedStatus(CONVERT_STATUS.ApiName);
            if(String.isNotBlank(accountId)){
                lc.setAccountId(accountId);
            }
            if(!withOpp){
                lc.setDoNotCreateOpportunity(true);
            } else {
                if(String.isNotBlank(oppName)){
                    lc.setOpportunityName(oppName);
                }
            }
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            inhibitTrigger = false;
            if(!lcr.isSuccess()){
                if(acc != null){
                    delete acc;
                }
                return new ConvertedLeadWrapper('Error: Lead Conversion Error');
            } else {
                return new ConvertedLeadWrapper(
                    lcr.getAccountId(), [SELECT Id, Name FROM Account WHERE Id = : lcr.getAccountId()].Name,
                    lcr.getContactId(), [SELECT Id, Name FROM Contact WHERE Id = : lcr.getContactId()].Name,
                    withOpp ? lcr.getOpportunityId() : null,
                    withOpp ? [SELECT Id, Name FROM Opportunity WHERE Id = : lcr.getOpportunityId()].Name : null);
            }
        } catch(Exception e){
            return new ConvertedLeadWrapper(e.getMessage());
        }
    }
    @AuraEnabled(cacheable=false)
    public static ConvertedLeadWrapper convertLead(
        Id leadId, 
        Boolean withOpp, 
        String oppName
    ){
        try{
            inhibitTrigger = true;
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(leadId);
            lc.setConvertedStatus(CONVERT_STATUS.ApiName);
            if(!withOpp){
                lc.setDoNotCreateOpportunity(true);
            } else {
                if(String.isNotBlank(oppName)){
                    lc.setOpportunityName(oppName);
                }
            }
            // No Mapping
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            inhibitTrigger = false;
            update new Contact(Id = lcr.getContactId());
            if(!lcr.isSuccess()){
                return new ConvertedLeadWrapper('Error: Lead Conversion Error');
            } else {
                return new ConvertedLeadWrapper(
                    lcr.getAccountId(), [SELECT Id, Name FROM Account WHERE Id = : lcr.getAccountId()].Name,
                    lcr.getContactId(), [SELECT Id, Name FROM Contact WHERE Id = : lcr.getContactId()].Name,
                    withOpp ? lcr.getOpportunityId() : null,
                    withOpp ? [SELECT Id, Name FROM Opportunity WHERE Id = : lcr.getOpportunityId()].Name : null);
            }
        } catch(Exception e){
            return new ConvertedLeadWrapper(e.getMessage());
        }
    }

    public class ConvertedLeadWrapper{
        @AuraEnabled public String accountId {get; set;}
        @AuraEnabled public String contactId {get; set;}
        @AuraEnabled public String opportunityId {get; set;}
        @AuraEnabled public String accountIdAlt {get; set;}
        @AuraEnabled public String contactIdAlt {get; set;}
        @AuraEnabled public String opportunityIdAlt {get; set;}
        @AuraEnabled public String accountName {get; set;}
        @AuraEnabled public String contactName {get; set;}
        @AuraEnabled public String opportunityName {get; set;}
        @AuraEnabled public String errorMessage {get; set;}
        public ConvertedLeadWrapper(String errorMessage){
            this.errorMessage = errorMessage;
        }
        public ConvertedLeadWrapper(String accountId, String accountName, String contactId, String contactName, String opportunityId, String opportunityName){
            this.accountId = accountId;
            this.contactId = contactId;
            this.opportunityId = opportunityId;
            this.accountIdAlt = '/' + accountId;
            this.contactIdAlt = '/' + contactId;
            this.opportunityIdAlt = '/' + opportunityId;
            this.accountName = accountName;
            this.contactName = contactName;
            this.opportunityName = opportunityName;
        }
    }


    @AuraEnabled(cacheable=false)
    public static FieldMappingSuperiorWrapperMultiple getLeadLeadMergeMap(String leadId, List<String> secondLeadIds){
        List<FieldMappingWrapperMultiple> wrapperList = new List<FieldMappingWrapperMultiple>();
        List<String> recordNames = new List<String>();
        Map<String, List<String>> fieldValues = new Map<String, List<String>>();
        Map<String, List<String>> fieldLabels = new Map<String, List<String>>();

        Map<String, Boolean> leadFieldsOriginal = new Map<String, Boolean>();
        Set<String> leadFields = new Set<String>{'Id', 'Name'};
        Set<String> lookupFields = new Set<String>();
        Map<String, Schema.sObjectField> leadMap = new Lead().getSObjectType().getDescribe().fields.getMap();
        List<LeadConversionFieldSetting__mdt> lcms = [SELECT Id, Field__r.DataType, Field__r.QualifiedApiName, MergeOrder__c FROM LeadConversionFieldSetting__mdt WHERE ShowMerge__c = TRUE AND Object__r.QualifiedApiName = 'Lead' ORDER BY MergeOrder__c];
        for(LeadConversionFieldSetting__mdt lcm : lcms){
            leadFields.add(lcm.Field__r.QualifiedApiName);
            leadFieldsOriginal.put(lcm.Field__r.QualifiedApiName, lcm.Field__r.DataType == 'Picklist' || lcm.Field__r.DataType == 'Auswahlliste');
            if(lcm.Field__r.DataType == 'Picklist' || lcm.Field__r.DataType == 'Auswahlliste'){
                leadFields.add('TOLABEL(' + lcm.Field__r.QualifiedApiName + ') ' + lcm.Field__r.QualifiedApiName.removeEnd('__c') + '_label');
            } else if(lcm.Field__r.DataType.contains('Lookup') || lcm.Field__r.DataType.contains('Nachschlagen')){
                lookupFields.add(lcm.Field__r.QualifiedApiName);
                if(lcm.Field__r.QualifiedApiName.endsWith('__c')){
                    leadFields.add(lcm.Field__r.QualifiedApiName.removeEnd('__c') + '__r.Name');
                } else {
                    leadFields.add(lcm.Field__r.QualifiedApiName.removeEnd('Id') + '.Name');
                }
            }
        }
        String leadQueryString = 'SELECT ' + String.join(leadFields, ',') + ' FROM Lead WHERE Id = \'' + leadId + '\'';
        Lead sourceLead = Database.query(leadQueryString);
        Map<String, String> mappedFields = new Map<String, String>();
        for(String leadField : leadFieldsOriginal.keySet()){
            mappedFields.put(leadField, String.valueOf(sourceLead.get(leadField)));
        }
        recordNames.add(sourceLead.Name);
        for(Lead ld : Database.query('SELECT ' + String.join(leadFields, ',') + ' FROM Lead WHERE Id IN : secondLeadIds ORDER BY Id')){
            recordNames.add(ld.Name);
            for(String leadField : leadFieldsOriginal.keySet()){
                List<String> valuesList = fieldValues.containsKey(leadField) ? fieldValues.get(leadField) : new List<String>();
                List<String> labelsList = fieldLabels.containsKey(leadField) ? fieldLabels.get(leadField) : new List<String>();
                valuesList.add(String.valueOf(ld.get(leadField)));
                if(!lookupFields.contains(leadField)){
                    labelsList.add(leadFieldsOriginal.get(leadField) == false ? processTrueFalse(String.valueOf(ld.get(leadField))) : String.valueOf(ld.get(leadField.removeEnd('__c') + '_label')));
                } else {
                    String rawObjectName = leadField.endsWith('__c') ? (leadField.removeEnd('__c') + '__r') : leadField.removeEnd('Id');
                    labelsList.add(ld.getsObject(rawObjectName) != null ? String.valueOf(ld.getsObject(rawObjectName).get('Name')) : null);
                }
                fieldValues.put(leadField, valuesList);
                fieldLabels.put(leadField, labelsList);
            }
        }

        for(LeadConversionFieldSetting__mdt lcm : lcms){
            String field = lcm.Field__r.QualifiedApiName;
            Schema.DescribeFieldResult describe = leadMap.get(field).getDescribe();
            String rawObjectName = field.endsWith('__c') ? (field.removeEnd('__c') + '__r') : field.removeEnd('Id');
            wrapperList.add(new FieldMappingWrapperMultiple(
                field,
                describe.getLabel(),
                field,
                describe.getLabel(),
                String.valueOf(sourceLead.get(field)),
                lookupFields.contains(field) ? 
                    (sourceLead.getsObject(rawObjectName) != null ? String.valueOf(sourceLead.getsObject(rawObjectName).get('Name')) : null) :
                    (leadFieldsOriginal.get(field) == false ? processTrueFalse(String.valueOf(sourceLead.get(field))) : String.valueOf(sourceLead.get(field.removeEnd('__c') + '_label'))),
                fieldValues.get(field),
                fieldLabels.get(field),
                describe.getType() == Schema.DisplayType.MULTIPICKLIST,
                describe.getType() == Schema.DisplayType.TEXTAREA
            ));
        }
        return new FieldMappingSuperiorWrapperMultiple(wrapperList, recordNames, mappedFields);
    }

    private static String processTrueFalse(String value){
        if(value == 'true'){
            return System.Label.GeneralYes;
        } else if(value == 'false'){
            return System.Label.GeneralNo;
        }
        return value;
    }

    @AuraEnabled(cacheable=false)
    public static String saveLeadDuplicates(Id masterLeadId, List<String> duplicateLeadIds, Map<String, String> fieldValues){
        try {
            SObject sobj = masterLeadId.getSObjectType().newSObject(masterLeadId);
            Map<String, Schema.SObjectField> fieldsMap = masterLeadId.getSObjectType().getDescribe().fields.getMap();
            for(String fieldName : fieldValues.keySet()){
                if(fieldName != 'Id' && fieldsMap.containsKey(fieldName)){
                    if(NUMBER_TYPES.contains(fieldsMap.get(fieldName).getDescribe().getType())){
                        sobj.put(
                            fieldName, 
                            Decimal.valueOf(String.valueOf(fieldValues.get(fieldName)))
                        );
                    } else if(fieldsMap.get(fieldName).getDescribe().getType() == Schema.DisplayType.BOOLEAN){
                        sObj.put(
                            fieldName,
                            String.valueOf(fieldValues.get(fieldName)) == 'true' ? true : false
                        );
                    } else {
                        sobj.put(
                            fieldName, 
                            String.valueOf(fieldValues.get(fieldName))
                        );
                    }
                }
            }
            Set<String> masterComments = new Set<String>();
            Set<String> comments = new Set<String>();
            Map<String, Boolean> boolMap = new Map<String, Boolean>{
                'doiRequested' => false,
                'doiSent' => false,
                'doiConfirmed' => false,
                'newsletterOptin' => false,
                'emailOptOut' => false,
                'doNotCall' => false,
                'faxOptOut' => false
            };
            Map<String, DateTime> dateTimeMap = new Map<String, DateTime>{
                'doiRequested' => null,
                'doiSent' => null,
                'doiConfirmed' => null,
                'newsletterOptin' => null,
                'emailOptOut' => null
            };
            for(Lead ld : [SELECT Id, DoubleOptinRequestedDateTime__c, DoubleOptinSentDateTime__c, DoubleOptinConfirmedDateTime__c,
            NewsletterOptinDateTime__c, EMailOptoutDateTime__c, DoubleOptinRequested__c, DoubleOptinSent__c, DoubleOptinConfirmed__c,
            NewsletterOptedIn__c, HasOptedOutOfEmail,
            HasOptedOutOfFax, DoNotCall, GeneralComments__c, AllGeneralComments__c  FROM Lead WHERE Id = : masterLeadId]){              
            //HasOptedOutOfFax, DoNotCall, GeneralComments__c, AllGeneralComments__c, pi__comments__c  FROM Lead WHERE Id = : masterLeadId]){
                if(String.isNotBlank(ld.GeneralComments__c)){
                    masterComments.add(ld.GeneralComments__c);
                }
                /*
                if(String.isNotBlank(ld.pi__comments__c)){
                    masterComments.add(ld.pi__comments__c);
                }
                */
                if(String.isNotBlank(ld.AllGeneralComments__c)){
                    masterComments.add(ld.AllGeneralComments__c);
                }
                if(ld.HasOptedOutOfFax == true){
                    boolMap.put('faxOptOut', true);
                }
                if(ld.DoNotCall == true){
                    boolMap.put('doNotCall', true);
                }
                if(dateTimeMap.get('doiRequested') == null || (ld.DoubleOptinRequestedDateTime__c != null && ld.DoubleOptinRequestedDateTime__c > dateTimeMap.get('doiRequested'))){
                    boolMap.put('doiRequested', ld.DoubleOptinRequested__c);
                    dateTimeMap.put('doiRequested', ld.DoubleOptinRequestedDateTime__c);
                }
                if(dateTimeMap.get('doiSent') == null || (ld.DoubleOptinSentDateTime__c != null && ld.DoubleOptinSentDateTime__c > dateTimeMap.get('doiSent'))){
                    boolMap.put('doiSent', ld.DoubleOptinSent__c);
                    dateTimeMap.put('doiSent', ld.DoubleOptinSentDateTime__c);
                }
                if(dateTimeMap.get('doiConfirmed') == null || (ld.DoubleOptinConfirmedDateTime__c != null && ld.DoubleOptinConfirmedDateTime__c > dateTimeMap.get('doiConfirmed'))){
                    boolMap.put('doiConfirmed', ld.DoubleOptinConfirmed__c);
                    dateTimeMap.put('doiConfirmed', ld.DoubleOptinConfirmedDateTime__c);
                }
                if(dateTimeMap.get('newsletterOptin') == null || (ld.NewsletterOptinDateTime__c != null && ld.NewsletterOptinDateTime__c > dateTimeMap.get('newsletterOptin'))){
                    boolMap.put('newsletterOptin', ld.NewsletterOptedIn__c);
                    dateTimeMap.put('newsletterOptin', ld.NewsletterOptinDateTime__c);
                }
                if(dateTimeMap.get('emailOptOut') == null || (ld.EMailOptoutDateTime__c != null && ld.EMailOptoutDateTime__c > dateTimeMap.get('emailOptOut'))){
                    boolMap.put('emailOptOut', ld.HasOptedOutOfEmail);
                    dateTimeMap.put('emailOptOut', ld.EMailOptoutDateTime__c);
                }
            }
            for(Lead ld : [SELECT Id, DoubleOptinRequestedDateTime__c, DoubleOptinSentDateTime__c, DoubleOptinConfirmedDateTime__c,
            NewsletterOptinDateTime__c, EMailOptoutDateTime__c, DoubleOptinRequested__c, DoubleOptinSent__c, DoubleOptinConfirmed__c,
            NewsletterOptedIn__c, HasOptedOutOfEmail,
            HasOptedOutOfFax, DoNotCall, GeneralComments__c, AllGeneralComments__c FROM Lead WHERE Id IN : duplicateLeadIds]){
            //HasOptedOutOfFax, DoNotCall, GeneralComments__c, AllGeneralComments__c, pi__comments__c  FROM Lead WHERE Id IN : duplicateLeadIds]){
                if(String.isNotBlank(ld.GeneralComments__c)){
                    comments.add(ld.GeneralComments__c);
                }
                /*
                if(String.isNotBlank(ld.pi__comments__c)){
                    comments.add(ld.pi__comments__c);
                }
                */
                if(String.isNotBlank(ld.AllGeneralComments__c)){
                    comments.add(ld.AllGeneralComments__c);
                }
                if(ld.HasOptedOutOfFax == true){
                    boolMap.put('faxOptOut', true);
                }
                if(ld.DoNotCall == true){
                    boolMap.put('doNotCall', true);
                }
                if(dateTimeMap.get('doiRequested') == null || (ld.DoubleOptinRequestedDateTime__c != null && ld.DoubleOptinRequestedDateTime__c > dateTimeMap.get('doiRequested'))){
                    boolMap.put('doiRequested', ld.DoubleOptinRequested__c);
                    dateTimeMap.put('doiRequested', ld.DoubleOptinRequestedDateTime__c);
                }
                if(dateTimeMap.get('doiSent') == null || (ld.DoubleOptinSentDateTime__c != null && ld.DoubleOptinSentDateTime__c > dateTimeMap.get('doiSent'))){
                    boolMap.put('doiSent', ld.DoubleOptinSent__c);
                    dateTimeMap.put('doiSent', ld.DoubleOptinSentDateTime__c);
                }
                if(dateTimeMap.get('doiConfirmed') == null || (ld.DoubleOptinConfirmedDateTime__c != null && ld.DoubleOptinConfirmedDateTime__c > dateTimeMap.get('doiConfirmed'))){
                    boolMap.put('doiConfirmed', ld.DoubleOptinConfirmed__c);
                    dateTimeMap.put('doiConfirmed', ld.DoubleOptinConfirmedDateTime__c);
                }
                if(dateTimeMap.get('newsletterOptin') == null || (ld.NewsletterOptinDateTime__c != null && ld.NewsletterOptinDateTime__c > dateTimeMap.get('newsletterOptin'))){
                    boolMap.put('newsletterOptin', ld.NewsletterOptedIn__c);
                    dateTimeMap.put('newsletterOptin', ld.NewsletterOptinDateTime__c);
                }
                if(dateTimeMap.get('emailOptOut') == null || (ld.EMailOptoutDateTime__c != null && ld.EMailOptoutDateTime__c > dateTimeMap.get('emailOptOut'))){
                    boolMap.put('emailOptOut', ld.HasOptedOutOfEmail);
                    dateTimeMap.put('emailOptOut', ld.EMailOptoutDateTime__c);
                }
            }
            String commentsString = !masterComments.isEmpty() ? String.join(masterComments, '\r\n\r\n---\r\n\r\n') : '';
            if(!masterComments.isEmpty() && !comments.isEmpty()){
                commentsString += '\r\n\r\n---\r\n\r\n';
            }
            commentsString += String.join(comments, '\r\n\r\n---\r\n\r\n');
            sobj.put('AllGeneralComments__c', commentsString);
            sobj.put('MergeMaster__c', true);
            sobj.put('DoubleOptinRequested__c', boolMap.get('doiRequested'));
            sobj.put('DoubleOptinSent__c', boolMap.get('doiSent'));
            sobj.put('DoubleOptinConfirmed__c', boolMap.get('doiConfirmed'));
            sobj.put('NewsletterOptedIn__c', boolMap.get('newsletterOptin'));
            sobj.put('HasOptedOutOfEmail', boolMap.get('emailOptOut'));
            sobj.put('DoNotCall', boolMap.get('doNotCall'));
            sobj.put('HasOptedOutOfFax', boolMap.get('faxOptOut'));
            sobj.put('DoubleOptinRequestedDateTime__c', dateTimeMap.get('doiRequested'));
            sobj.put('DoubleOptinSentDateTime__c', dateTimeMap.get('doiSent'));
            sobj.put('DoubleOptinConfirmedDateTime__c', dateTimeMap.get('doiConfirmed'));
            sobj.put('NewsletterOptinDateTime__c', dateTimeMap.get('newsletterOptin'));
            sobj.put('EMailOptoutDateTime__c', dateTimeMap.get('emailOptOut'));
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.allowFieldTruncation = true;
            Database.update(sobj, dml);

            List<Lead> leadsToMarkAsDupe = new List<Lead>();
            for(String duplicateLeadId : duplicateLeadIds){
                leadsToMarkAsDupe.add(new Lead(
                    Id = duplicateLeadId,
                    MergedInto__c = masterLeadId,
                    Status = 'Disqualified',
                    DisqualificationReason__c = 'Merged'
                ));
            }
            List<CampaignMember> cml = [SELECT Id, CampaignId, LeadId FROM CampaignMember WHERE LeadId IN : duplicateLeadIds];
            Map<String, CampaignMember> cmlInsert = new Map<String, CampaignMember>();
            for(CampaignMember cm : cml){
                cmlInsert.put(masterLeadId + '' + cm.CampaignId, new CampaignMember(
                    LeadId = masterLeadId,
                    CampaignId = cm.CampaignId
                ));
            }
            delete cml;
            Database.insert(cmlInsert.values(), false);
            if(!leadsToMarkAsDupe.isEmpty()){
                Database.update(leadsToMarkAsDupe, false);
            }
            return 'success';
        } catch(Exception e){
            return e.getMessage();
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<LeadDuplicateWrapper> getPotentialLeadDuplicates(String leadId){
        Map<Id, LeadDuplicateWrapper> returnMap = new Map<Id, LeadDuplicateWrapper>();
        Lead originalLead = [SELECT Id, Email, HashLastNameCompany__c, HashStreetCompany__c FROM Lead WHERE Id = : leadId];
        if(String.isNotBlank(originalLead.Email)){
            for(Lead ld : [SELECT Id, FirstName, LastName, Company, Email, City, PostalCode, Street FROM Lead WHERE Id != : leadId AND EMail = : originalLead.Email AND IsConverted = FALSE]){
                LeadDuplicateWrapper wrapper = new LeadDuplicateWrapper(ld, true, false, false);
                returnMap.put(ld.Id, wrapper);
            }
        }
        if(String.isNotBlank(originalLead.HashLastNameCompany__c)){
            for(Lead ld : [SELECT Id, FirstName, LastName, Company, Email, City, PostalCode, Street FROM Lead WHERE Id != : leadId AND HashLastNameCompany__c = : originalLead.HashLastNameCompany__c AND IsConverted = FALSE]){
                if(returnMap.containsKey(ld.Id)){
                    LeadDuplicateWrapper wrapper = returnMap.get(ld.Id);
                    wrapper.isLastNameCompanyDupe = true;
                    returnMap.put(ld.Id, wrapper);
                } else {
                    LeadDuplicateWrapper wrapper = new LeadDuplicateWrapper(ld, false, true, false);
                    returnMap.put(ld.Id, wrapper);
                }
            }
        }
        if(String.isNotBlank(originalLead.HashStreetCompany__c)){
            for(Lead ld : [SELECT Id, FirstName, LastName, Company, Email, City, PostalCode, Street FROM Lead WHERE Id != : leadId AND HashStreetCompany__c = : originalLead.HashStreetCompany__c AND IsConverted = FALSE]){
                if(returnMap.containsKey(ld.Id)){
                    LeadDuplicateWrapper wrapper = returnMap.get(ld.Id);
                    wrapper.isCompanyStreetDupe = true;
                    returnMap.put(ld.Id, wrapper);
                } else {
                    LeadDuplicateWrapper wrapper = new LeadDuplicateWrapper(ld, false, false, true);
                    returnMap.put(ld.Id, wrapper);
                }
            }
        }
        return returnMap.values();
    }
    
    public class LeadDuplicateWrapper{
        @AuraEnabled public Boolean isEmailDupe {get; set;}
        @AuraEnabled public Boolean isLastNameCompanyDupe {get; set;}
        @AuraEnabled public Boolean isCompanyStreetDupe {get; set;}
        @AuraEnabled public String id {get; set;}
        @AuraEnabled public String url {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String email {get; set;}
        @AuraEnabled public String company {get; set;}
        @AuraEnabled public String address {get; set;}
        public LeadDuplicateWrapper(Lead record, Boolean isEmailDupe, Boolean isLastNameCompanyDupe, Boolean isCompanyStreetDupe){
            this.isEmailDupe = isEmailDupe;
            this.isLastNameCompanyDupe = isLastNameCompanyDupe;
            this.isCompanyStreetDupe = isCompanyStreetDupe;
            this.id = record.Id;
            this.url = '/' + record.Id;
            this.email = record.Email;
            this.name = String.isNotBlank(record.FirstName) ? record.FirstName + ' ' + record.LastName : record.LastName;
            this.company = record.Company;
            this.address = ((record.Street ?? '') + ' ' + (record.PostalCode ?? '') + ' ' + (record.City ?? '')).trim();
        }
    }

    public class FieldMappingSuperiorWrapperMultiple{
        @AuraEnabled public List<FieldMappingWrapperMultiple> wrappers {get; set;}
        @AuraEnabled public List<String> recordNames {get; set;}
        @AuraEnabled public Map<String, String> mappedFields {get; set;}
        public FieldMappingSuperiorWrapperMultiple(List<FieldMappingWrapperMultiple> wrappers, List<String> recordNames, Map<String, String> mappedFields){
            this.wrappers = wrappers;
            this.recordNames = recordNames;
            this.mappedFields = mappedFields;
        }
    }

    public class ValueWrapper{
        @AuraEnabled public Boolean isNull {get; set;}
        @AuraEnabled public String value {get; set;}
        @AuraEnabled public String label {get; set;}
        public ValueWrapper(String value, String label){
            this.label = label;
            this.value = value;
            this.isNull = !String.isNotBlank(value);
        }
    }

    public class FieldMappingWrapperMultiple{
        @AuraEnabled public String sourceFieldName {get; set;}
        @AuraEnabled public String sourceFieldLabel {get; set;}
        @AuraEnabled public String targetFieldName {get; set;}
        @AuraEnabled public String targetFieldLabel {get; set;}
        @AuraEnabled public String sourceValueRaw {get; set;}
        @AuraEnabled public String targetValuesRaw {get; set;}
        @AuraEnabled public ValueWrapper sourceValue {get; set;}
        @AuraEnabled public List<ValueWrapper> targetValues {get; set;}
        @AuraEnabled public Boolean isMultiPicklist {get; set;}
        @AuraEnabled public Boolean isTextArea {get; set;}
        @AuraEnabled public Boolean hideRow {get; set;}
        public FieldMappingWrapperMultiple(String sourceFieldName, String sourceFieldLabel, String targetFieldName, String targetFieldLabel, String sourceValue, String sourceLabel, List<String> targetValues, List<String> targetLabels, Boolean isMultiPicklist, Boolean isTextArea){
            this.sourceFieldName = sourceFieldName;
            this.sourceFieldLabel = sourceFieldLabel;
            this.targetFieldName = targetFieldName;
            this.targetFieldLabel = targetFieldLabel;
            if(String.isBlank(sourceValue) || sourceValue == 'null'){
                this.sourceValue = new ValueWrapper(null, null);
            } else if(sourceValue == 'true') {
                this.sourceValue = new ValueWrapper(sourceValue, System.Label.GeneralYes);
            } else if(sourceValue == 'false') {
                this.sourceValue = new ValueWrapper(sourceValue, System.Label.GeneralNo);
            } else {
                this.sourceValue = new ValueWrapper(sourceValue, sourceLabel);
            }
            this.hideRow = true;
            this.sourceValueRaw = sourceValue;
            this.targetValues = new List<ValueWrapper>();
            this.targetValuesRaw = '';
            for(Integer i = 0; i < targetValues.size(); i++){
                String targetVal = targetValues[i];
                if(String.isBlank(targetVal) || targetVal == 'null'){
                    targetVal = null;
                }
                if(targetVal != sourceValue){
                    this.hideRow = false;
                }
                this.targetValues.add(new ValueWrapper(targetVal, targetLabels[i]));
            }
            this.targetValuesRaw = String.join(new List<String>(targetValues), ';;;;;');
            this.isMultiPicklist = isMultiPicklist;
            this.isTextArea = isTextArea;
        }
    }

    public class FieldMappingWrapper{
        @AuraEnabled public String sourceFieldName {get; set;}
        @AuraEnabled public String sourceFieldLabel {get; set;}
        @AuraEnabled public String targetFieldName {get; set;}
        @AuraEnabled public String targetFieldLabel {get; set;}
        @AuraEnabled public String sourceValue {get; set;}
        @AuraEnabled public String targetValue {get; set;}
        @AuraEnabled public String sourceLabel {get; set;}
        @AuraEnabled public String targetLabel {get; set;}
        @AuraEnabled public Boolean sourceValueIsNull {get; set;}
        @AuraEnabled public Boolean targetValueIsNull {get; set;}
        @AuraEnabled public Boolean sourceEqualTarget {get; set;}
        @AuraEnabled public Boolean isMultiPicklist {get; set;}
        @AuraEnabled public Boolean isTextArea {get; set;}
        @AuraEnabled public Boolean sourceOrTargetEmpty {get; set;}
        public FieldMappingWrapper(String sourceFieldName, String sourceFieldLabel, String targetFieldName, String targetFieldLabel, String sourceValue, String targetValue, String sourceLabel, String targetLabel, Boolean isMultiPicklist, Boolean isTextArea){
            this.sourceFieldName = sourceFieldName;
            this.sourceFieldLabel = sourceFieldLabel;
            this.targetFieldName = targetFieldName;
            this.targetFieldLabel = targetFieldLabel;
            if(String.isBlank(sourceValue) || sourceValue == 'null'){
                this.sourceValue = null;
                this.sourceValueisNull = true;
            } else {
                this.sourceValue = sourceValue;
                this.sourceValueisNull = false;
            }
            if(String.isBlank(targetValue) || targetValue == 'null'){
                this.targetValue = null;
                this.targetValueIsNull = true;
            } else {
                this.targetValue = targetValue;
                this.targetValueIsNull = false;
            }
            this.targetValue = targetValue;
            this.sourceLabel = sourceLabel;
            this.targetLabel = targetLabel;
            this.isMultiPicklist = isMultiPicklist;
            this.isTextArea = isTextArea;
            this.sourceEqualTarget = sourceValue == targetValue;
            this.sourceOrTargetEmpty = this.sourceValueisNull || this.targetValueisNull;
        }
    }
}