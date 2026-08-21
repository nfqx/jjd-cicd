@isTest 
private without sharing class WebshopActivateSelfRegTest {
    @TestSetup 
    private static void setupData(){
        List<Contact> contacts = new List<Contact>();
        
        // One record that qualifies (activation pending, timestamp older than yesterday 17:00)
        contacts.add(new Contact(
            LastName = 'PendingContact',
            WebshopSelfActivationPending__c = true,
            WebshopSelfActivationTimestamp__c = DateTime.now().addDays(-2)
        ));
        
        // One record that does NOT qualify (timestamp too new)
        contacts.add(new Contact(
            LastName = 'RecentContact',
            WebshopSelfActivationPending__c = true,
            WebshopSelfActivationTimestamp__c = DateTime.now()
        ));
        
        insert contacts;
    }
    @isTest 
    private static void testLogic(){
        Test.startTest();
        WebshopActivateSelfRegBatch batch = new WebshopActivateSelfRegBatch();
        Database.executeBatch(batch, 1);
        Test.stopTest();
        
        // Only the old one should have been processed (PendingContact)
        Contact updatedContact = [SELECT Id, WebshopSelfActivationPending__c 
                                  FROM Contact 
                                  WHERE LastName = 'PendingContact' 
                                  LIMIT 1];
        
        System.assertEquals(false, updatedContact.WebshopSelfActivationPending__c, 
                            'PendingContact should have been updated to false');
    }
}