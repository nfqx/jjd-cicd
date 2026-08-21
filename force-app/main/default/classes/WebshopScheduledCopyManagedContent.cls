/*
* Created by: Stanley Yin
* Created Date: 06.11.2024
*/

public without sharing class WebshopScheduledCopyManagedContent implements Schedulable, Database.Batchable<sObject>, Database.Stateful {
    public Boolean allContent {get; set;}
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new WebshopScheduledCopyManagedContent(false), 100);
    }
    public WebshopScheduledCopyManagedContent(){
        this.allContent = false;
    }
    public WebshopScheduledCopyManagedContent(Boolean allContent){
        this.allContent = allContent;
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime dt = System.Now().addDays(-2);
        return Test.isRunningTest() ? 
            Database.getQueryLocator('SELECT Id, ContentKey FROM ManagedContent ORDER BY CreatedDate DESC LIMIT 1') : 
            !this.allContent ? Database.getQueryLocator('SELECT Id, ContentKey FROM ManagedContent WHERE LastModifiedDate >= :dt') : Database.getQueryLocator('SELECT Id, ContentKey FROM ManagedContent');
    }
    
    public void execute(Database.BatchableContext bc, List<ManagedContent> scope) {
        List<ManagedContent__c> newRecords = new List<ManagedContent__c>();
        for(ManagedContent mc : scope){
            newRecords.add(new ManagedContent__c(
                ManagedContentId__c = mc.Id,
                ContentKey__c = mc.ContentKey
            ));
        }
        upsert newRecords ManagedContentId__c;
    }

    public void finish(Database.BatchableContext bc){ /* Do nothing */ }
}