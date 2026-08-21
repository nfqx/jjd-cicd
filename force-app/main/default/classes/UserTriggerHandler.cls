public with sharing class UserTriggerHandler {
    
    private static final String TARGET_PROFILE = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User' LIMIT 1].Id;
    
    public static void handleWebshopSync(List<User> newList, Map<Id, User> oldMap) {
        Set<Id> contactIdsToQuery = new Set<Id>();
        Map<Id, User> usersByContactId = new Map<Id, User>();
        for (User u : newList) {
            if (u.ProfileId != null && u.ProfileId == TARGET_PROFILE) {
                if (oldMap == null || u.IsActive != oldMap.get(u.Id).IsActive) {
                    if (u.IsActive == true && u.ContactId != null) {
                        contactIdsToQuery.add(u.ContactId);
                        usersByContactId.put(u.ContactId, u);
                    }
                    if (u.IsActive == false){
                        if(u.ContactId != null) {
                            contactIdsToQuery.add(u.ContactId);
                            usersByContactId.put(u.ContactId, u);
                        }
                    }
                }
            }
        }

        if (!contactIdsToQuery.isEmpty()){
            Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, ActiveWebshopUser__c FROM Contact WHERE Id IN :contactIdsToQuery]);
            List<Contact> contactsToUpdate = new List<Contact>();

            for (User u : newList) {
                if (u.ProfileId != null && u.ProfileId == TARGET_PROFILE) {
                    if (u.IsActive && u.ContactId != null && contacts.containsKey(u.ContactId)) {
                        Contact c = contacts.get(u.ContactId);
                        c.ActiveWebshopUser__c = true;
                        contactsToUpdate.add(c);
                    }

                    if (u.IsActive == false && u.ContactId != null && contacts.containsKey(u.ContactId)) {
                        Contact c = contacts.get(u.ContactId);
                        c.ActiveWebshopUser__c = false;
                        contactsToUpdate.add(c);
                    }
                }
            }
            if (!contactsToUpdate.isEmpty()) {
                updateContacts(JSON.serialize(contactsToUpdate));
            }
        }
    }

    public static void unsetActivationRequired(List<User> newRecords, Map<Id, User> oldRecordsMap){
        for(User u : newRecords){
            User oldUser = oldRecordsMap.get(u.Id);
            if(u.IsActive && !oldUser.isActive){
                u.ActivationRequired__c = false;
            }
        }
    }

    @future
    public static void updateContacts(String serializedPayload) {
        List<Contact> payload = (List<Contact>) JSON.deserialize(serializedPayload, List<Contact>.class);
        update payload;
    }

    public class UserWebshopFutureWrapper {
        public Id userId;
        public Id contactId;
        public UserWebshopFutureWrapper(Id userId, Id contactId){
            this.userId = userId;
            this.contactId = contactId;
        }
    }
}