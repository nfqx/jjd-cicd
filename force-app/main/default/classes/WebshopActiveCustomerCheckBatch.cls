/**
* Processor for checking whether webshop customer is active. CRM-575
* @author: Stanley Yin (stanley.yin@nfq-x.com), Dec 17, 2023
*
*/

public without sharing class WebshopActiveCustomerCheckBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, (SELECT Id FROM Contacts WHERE ActiveWebshopUser__c = TRUE), (SELECT Id FROM ManagedAccount) FROM Account WHERE IsWebshopAccount__c = TRUE]);
    }
    
    public void execute(Database.BatchableContext bc, List<Account> scope){
        for(Account ac : scope){
            ac.HasActiveCustomer__c = !ac.Contacts.isEmpty() || !ac.ManagedAccount.isEmpty();
        }
        update scope;
    } 
    
    public void finish(Database.BatchableContext bc){ 
        // No actions
    }  
}