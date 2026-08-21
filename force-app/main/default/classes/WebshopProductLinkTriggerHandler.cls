public with sharing class WebshopProductLinkTriggerHandler {
    public static void validateDuplicates(List<WebshopProductLink__c> newRecords){
        for(WebshopProductLink__c newRecord : newRecords){
            List<String> sortedLinks = new List<String>{newRecord.Product1__c, newRecord.Product2__c};
            sortedLinks.sort();
            newRecord.UniqueIdentifier__c = String.join(sortedLinks, '');
        }
    }
}