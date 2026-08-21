public without sharing class AbandonedCartActiveEmailBatch implements Database.Batchable<SObject>,Schedulable {
    

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new AbandonedCartActiveEmailBatch(), 10);
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        Integer dayBack = Integer.valueOf(System.Label.AbandonedCartActiveEmailDays);
        Datetime daysBack = Datetime.now().addSeconds(dayBack * 60 * -1);
        List<String> excludeProducts = System.Label.ShippingProductCodes.split(',');
        return Database.getQueryLocator('SELECT Id, AccountId, CreatedById, CreatedBy.Name, (SELECT Id FROM CartItems WHERE Product2Id NOT IN : excludeProducts) FROM WebCart WHERE AbandonedActiveEmailSent__c = FALSE AND Status = \'Active\' AND LastModifiedDate < = : daysBack');
    }

    public void execute(Database.BatchableContext bc,  List<WebCart> scope){
        List<String> userIds = CollectionUtils.generateStringListFromSObjectList(scope, 'CreatedById', true, true);
        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Contact.DoubleOptInAbandonedCart__c FROM User WHERE Id IN : userIds]);

        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        List<OrgWideEmailAddress> oweaList = [ SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@darboven.com' ];
        // Initialize Email Template Details
        List<EmailTemplate> emailTemplateList = [ SELECT Id, HtmlValue, Subject FROM EmailTemplate WHERE DeveloperName = 'Warenkorbabbrecher'];
        if (oweaList.size() > 0 && emailTemplateList.size() > 0) {
            for(WebCart wc : scope){
                if(!wc.CartItems.isEmpty() && userMap.containsKey(wc.CreatedById) && userMap.get(wc.CreatedById).Contact.DoubleOptInAbandonedCart__c){
                    Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
                    emailToSend.setOrgWideEmailAddressId(oweaList[0].Id);
                    // Set recipient with setTargetObjectId in order not to hit Org Limits
                    emailToSend.setTargetObjectId(wc.CreatedById);
                    // Set Email Subject
                    emailToSend.setSubject(emailTemplateList[0].Subject);
                    emailToSend.saveAsActivity = false;
                    emailToSend.setUseSignature(false);
                    // Substitute Merge Field and populate Email Body
                    // Use baseUrl constant and only set HTML Email Body
                    emailToSend.setHTMLBody(emailTemplateList[0].HTMLValue
                                            .replace('{{{Recipient.Name}}}', wc.CreatedBy.Name)
                                            .replace('{{{Recipient.Date_Time_24_Hours__c}}}', Datetime.now().addDays(1).format('dd.MM.yyyy HH:mm'))
                                            .replace('{{{Sender.Email}}}', UserInfo.getUserEmail()));
                    messages.add(emailToSend);
                    wc.AbandonedActiveEmailSent__c = true;
                }
            }
        }
        update scope;
        Messaging.sendEmail(messages);
    }
  
    public void finish(Database.BatchableContext BC){ 
        if(!Test.isRunningTest()){
            Database.executeBatch(new AbandonedCartActiveDeleteBatch(), 1);
        }
    }
}