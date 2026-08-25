public class MigrationAccountBrandJob implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([
            SELECT Id,
                ERPCustomerNumber__c,
                ECommerceVIP__c,
                AssortmentExtended__c,
                AssortmentExtendedManual__c,
                AssortmentExtensionExclusion__c,
                WebshopFrontpageWarning__c,
                OrderNotifiesParent__c,
                IsWebshopAccount__c,
                WebshopFirstContactActivationDate__c,
                BlockedForWebshop__c
            FROM Account
            WHERE ERPCustomerNumber__c != NULL
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope){

    }

    public void finish(Database.BatchableContext bc){
        
    }
}