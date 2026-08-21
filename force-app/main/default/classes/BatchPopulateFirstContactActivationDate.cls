/*
* Created by: Stanley Yin
* Created Date: 09.02.2026
* Purpose: Batch Job to populate ExternalId on Product2 where missing
*/

public without sharing class BatchPopulateFirstContactActivationDate implements Schedulable {
    public static void execute(SchedulableContext sc) {
        List<Account> accountsToUpdate = new List<Account>();
        for(AggregateResult ar : [SELECT MIN(CreatedDate) minDate, Contact.AccountId contactAcc FROM User WHERE Profile.Name = 'Customer Community Plus User' AND Contact.AccountId != NULL AND Contact.Account.WebshopFirstContactActivationDate__c = NULL GROUP BY Contact.AccountId]){
            accountsToUpdate.add(new Account(Id = String.valueOf(ar.get('contactAcc')), WebshopFirstContactActivationDate__c = Date.valueOf(ar.get('minDate'))));
        }
        update accountsToUpdate;
    }
}