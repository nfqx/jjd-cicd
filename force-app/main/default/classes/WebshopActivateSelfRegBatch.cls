public without sharing class WebshopActivateSelfRegBatch implements Database.Batchable<SObject>,Database.Stateful,Schedulable {

    public List<Contact> contactList {get; set;}
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new WebshopActivateSelfRegBatch(), 1);
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        Date yesterday = Date.today().addDays(-1);
        Time myTime = Time.newInstance(17, 0, 0, 0);
        Datetime yesterdayThisTime = DateTime.newInstance(yesterday, myTime);
        this.contactList = new List<Contact>();
        return Database.getQueryLocator('SELECT Id FROM Contact WHERE WebshopSelfActivationPending__c  = TRUE AND WebshopSelfActivationTimestamp__c  < : yesterdayThisTime');
    }

    public void execute(Database.BatchableContext bc,  List<Contact> scope){
        this.contactList.addAll(scope);
        List<String> contactIds = CollectionUtils.generateStringListFromSObjectList(scope, 'Id', true, true);
        activateContacts(contactIds, true, false, true);
    }
    
    public static void activateContacts(List<String> allContactIds, Boolean newWebshop, Boolean createdByGL, Boolean selfRegistered){
        Organization org = [SELECT Id, Name, IsSandbox FROM Organization LIMIT 1];
        String webshopString = org.isSandbox ? (System.Label.LetterCampaignUsernameSuffix + org.Id) : System.Label.LetterCampaignUsernameSuffix;
        List<User> usersToCreate = new List<User>();
        List<PermissionSetAssignment> psasToCreate = new List<PermissionSetAssignment>();
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User'];
        List<UserRole> darbovenRoles = [SELECT Id FROM UserRole WHERE Name = 'J.J. Darboven GmbH'];
        // Create Role under J.J. Darboven (Holding)
        List<String> permissionSetNames = new List<String>{'B2BWebshopAccessWebshopAssets'};
        permissionSetNames.add(System.Label.WebshopDoNotTranslateMainPermissionSetName);
        List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name IN :permissionSetNames];
        if(!profiles.isEmpty() && !darbovenRoles.isEmpty()){
            Map<Id, UserRole> userRolesToCreate = new Map<Id, UserRole>();
            List<Contact> allContacts = [SELECT Id, FirstName, LastName, AccountId, Account.Name, Account.ERPCustomerNumber__c, EMail FROM Contact WHERE Id IN : allContactIds AND AccountId != NULL];
            for(Contact con : allContacts){
                User u = new User(
                    FirstName = con.FirstName,
                    LastName = con.LastName,
                    ProfileId = profiles[0].Id,
                    Email = con.Email,
                    Username = con.Email + webshopString,
                    IsActive = TRUE,
                    ContactId = con.Id,
                    LanguageLocaleKey='de', 
                    LocaleSidKey='de_DE', 
                    TimeZoneSidKey='Europe/Berlin',
                    EmailEncodingKey='UTF-8',
                    Alias = con.Account.ERPCustomerNumber__c != null ? con.Account.ERPCustomerNumber__c : (con.FirstName != null ? con.FirstName.substring(0, 1) : '') + (con.LastName.length() > 3 ? con.LastName.substring(0,3) : con.LastName),
                    CreatedByGL__c = createdByGL,
                    SelfRegistered__c = selfRegistered,
                    PendingActivation__c = true
                );
                usersToCreate.add(u);
            }
            if(!usersToCreate.isEmpty()){
                insert usersToCreate;
                List<User> usersToUpdate = new List<User>();
                for(User u : usersToCreate){
                    for(PermissionSet ps : permissionSets){
                        psasToCreate.add(new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = u.Id));
                    }
                }
                insert psasToCreate;
            }
        }
    }
  
    public void finish(Database.BatchableContext BC){ 
        for(Contact c : this.contactList){
            c.WebshopSelfActivationPending__c = false;
        }
        update this.contactList;
    }
}