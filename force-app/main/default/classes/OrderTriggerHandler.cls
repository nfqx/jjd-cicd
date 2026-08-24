public without sharing class OrderTriggerHandler {

    @TestVisible
    private static final String LETTER_BONUS_ERROR = 'This bonus has already been used!';
    @TestVisible
    private static final String ACTIVATED_STATUS = 'Activated';

    private static Map<Id, Set<String>> checkContactsToNotify(Set<Id> accountIds){
        Map<Id, Set<String>> returnMap = new Map<Id, Set<String>>();
        // get ultimate parents of accounts
        Map<Id, Set<Id>> parentToChildren = new Map<Id, Set<Id>>();
        for(Account ac : [SELECT Id, ConditionChainParent__c, ConditionChainParent__r.ConditionChainParent__c,
            ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__c
        FROM Account WHERE Id IN : accountIds ]){
            if(ac.ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__c != null){
                if(parentToChildren.containsKey(ac.ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__c)){
                    parentToChildren.get(ac.ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__c).add(ac.Id);
                } else {
                    parentToChildren.put(ac.ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__c, new Set<Id>{ac.Id});
                }
            } else if(ac.ConditionChainParent__r.ConditionChainParent__c != null){
                if(parentToChildren.containsKey(ac.ConditionChainParent__r.ConditionChainParent__c)){
                    parentToChildren.get(ac.ConditionChainParent__r.ConditionChainParent__c).add(ac.Id);
                } else {
                    parentToChildren.put(ac.ConditionChainParent__r.ConditionChainParent__c, new Set<Id>{ac.Id});
                }
            } else if(ac.ConditionChainParent__c != null){
                if(parentToChildren.containsKey(ac.ConditionChainParent__c)){
                    parentToChildren.get(ac.ConditionChainParent__c).add(ac.Id);
                } else {
                    parentToChildren.put(ac.ConditionChainParent__c, new Set<Id>{ac.Id});
                }
            } else {
                if(parentToChildren.containsKey(ac.Id)){
                    parentToChildren.get(ac.Id).add(ac.Id);
                } else {
                    parentToChildren.put(ac.Id, new Set<Id>{ac.Id});
                }
            } 
        }
        // populate returnMap
        if(!parentToChildren.isEmpty()){
            Map<Id, Account> accountContactMap = new Map<Id, Account>([SELECT Id, (SELECT Id, Email FROM Contacts WHERE Email != NULL AND OrderNotificationRecipient__c = TRUE) FROM Account WHERE Id IN : parentToChildren.keySet()]);
            for(Id accountId : parentToChildren.keySet()){
                if(accountContactMap.containsKey(accountId)){
                    Account queriedAcc = accountContactMap.get(accountId);
                    if(!queriedAcc.Contacts.isEmpty()){
                        Set<String> contactEmails = new Set<String>();
                        for(Contact con : queriedAcc.Contacts){
                            contactEmails.add(con.Email);
                        }
                        for(Id accId : parentToChildren.get(accountId)){
                            returnMap.put(accId, contactEmails);
                        }
                    }
                }
            }
        }
        return returnMap;
    }

    public static void sendParentNotification(List<Order> newRecords){
        Set<Id> allAccountIds = new Set<Id>();
        for(Order o : newRecords){
            allAccountIds.add(o.AccountId);
        }
        Map<Id, Account> eligibleAccountIds = new Map<Id, Account>([SELECT Id, OrderNotifiesParent__c  FROM Account WHERE id IN : allAccountIds]);
        Map<Id, Set<String>> contactsToNotify = checkContactsToNotify(eligibleAccountIds.keySet());

        if(!contactsToNotify.isEmpty()){
            List<OrgWideEmailAddress> oweaList = [
                SELECT Id
                FROM OrgWideEmailAddress
                WHERE Address = : System.Label.NoReplyAddress
            ];
            if(!oweaList.isEmpty()){
                List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
                Map<Id, Order> orderMap = new Map<Id, Order>([SELECT Id, OrderNumber, (SELECT Id, Quantity, Product2.Name FROM OrderItems) FROM Order WHERE Id IN : newRecords AND AccountId IN : contactsToNotify.keySet()]);
                Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, OwnerId, Name FROM Account WHERE Id IN : contactsToNotify.keySet()]);
                for(Order o : newRecords){
                    if(contactsToNotify.containsKey(o.AccountId)){
                        Account ac = accountMap.get(o.AccountId);
                        Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
                        // Set OWEA as sender
                        emailToSend.setOrgWideEmailAddressId(oweaList[0].Id);
                        // Set recipient with setTargetObjectId in order not to hit Org Limits
                        emailToSend.setTargetObjectId(ac.OwnerId);
                        emailToSend.setToAddresses(new List<String>(contactsToNotify.get(o.AccountId)));
                        emailToSend.setBccAddresses(new List<String>{System.Label.ZKSTeamleadEmail, System.Label.WebshopContactEmail, System.Label.WebshopNFQXAddress});
                        // Set Email Subject
                        emailToSend.setSubject('Neue Bestellung: Account ' + ac.Name);
                        emailToSend.saveAsActivity = false;
                        emailToSend.setUseSignature(false);
                        // Substitute Merge Field and populate Email Body
                        // Use baseUrl constant and only set HTML Email Body
                        String formattedBody = 'Eine neue Bestellung ist eingegangen!<br /><br />';
                        Order orderWithItems = orderMap.get(o.Id);
                        formattedBody += (ac.Name + ': Bestellung Nr. ' + orderWithItems.OrderNumber + '<br /><br />');
                        for(OrderItem oi : orderWithItems.OrderItems){
                            formattedBody += ('  ' + oi.Quantity + 'x ' + oi.Product2.Name + '<br />');
                        }
                        emailToSend.setHTMLBody(formattedBody);
                        emailsToSend.add(emailToSend);
                    }
                }
                if(!emailsToSend.isEmpty()){
                    Messaging.sendEmail(emailsToSend);
                }
            }
        }
    }

    public static void informAboutVIPCustomers(List<Order> newRecords){
        Map<Id, List<Order>> ordersPerAccount = new Map<Id, List<Order>>();
        Set<Id> eligibleOrderIds = new Set<Id>();
        for(Order o : newRecords){
            eligibleOrderIds.add(o.Id);
            List<Order> innerList = ordersPerAccount.containsKey(o.AccountId) ? ordersPerAccount.get(o.AccountId) : new List<Order>();
            innerList.add(o);
            ordersPerAccount.put(o.AccountId, innerList);
        }
        List<String> allAccountIds = CollectionUtils.generateStringListFromSObjectList(newRecords, 'AccountId', true, true);
        if(!ordersPerAccount.isEmpty()){
            Map<Id, Order> ordersPerAccountMap = new Map<Id, Order>([SELECT Id, OrderNumber, (SELECT Id, Quantity, Product2.Name FROM OrderItems) FROM Order WHERE Id IN : eligibleOrderIds]);
            List<OrgWideEmailAddress> oweaList = [
                SELECT Id
                FROM OrgWideEmailAddress
                WHERE Address = : System.Label.NoReplyAddress
            ];
            if(!oweaList.isEmpty()){
                List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
                Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Name, ECommerceVIP__c, OwnerId FROM Account WHERE Id IN : ordersPerAccount.keySet() AND OwnerId != NULL AND ECommerceVIP__c = TRUE]);
                for(Id accountId : accountMap.keySet()){
                    Account ac = accountMap.get(accountId);
                    Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
                    // Set OWEA as sender
                    emailToSend.setOrgWideEmailAddressId(oweaList[0].Id);
                    // Set recipient with setTargetObjectId in order not to hit Org Limits
                    emailToSend.setTargetObjectId(ac.OwnerId);
                    emailToSend.setBccAddresses(new List<String>{System.Label.ZKSTeamleadEmail, System.Label.WebshopContactEmail, System.Label.WebshopNFQXAddress});
                    // Set Email Subject
                    emailToSend.setSubject('Neue VIP Bestellung: Account ' + ac.Name);
                    emailToSend.saveAsActivity = false;
                    emailToSend.setUseSignature(false);
                    // Substitute Merge Field and populate Email Body
                    // Use baseUrl constant and only set HTML Email Body
                    String formattedBody = 'Eine neue VIP Bestellung ist eingegangen!<br /><br />';
                    for(Order o : ordersPerAccount.get(accountId)){
                        Order orderWithItems = ordersPerAccountMap.get(o.Id);
                        formattedBody += (ac.Name + ': Bestellung Nr. <a href="' + URL.getOrgDomainURL().toExternalForm() + '/' + orderWithItems.id + '">' + orderWithItems.OrderNumber + '</a><br />');
                        for(OrderItem oi : orderWithItems.OrderItems){
                            formattedBody += ('  ' + oi.Quantity + 'x ' + oi.Product2.Name + '<br />');
                        }
                        formattedBody += '<br /><br />';
                    }
                    emailToSend.setHTMLBody(formattedBody);
                    emailsToSend.add(emailToSend);
                }
                if(!emailsToSend.isEmpty()){
                    Messaging.sendEmail(emailsToSend);
                }
            }
        }
    }

    public static void removeFromVoucherBuyerGroup(List<Order> newRecords){
        List<String> allAccountIds = CollectionUtils.generateStringListFromSObjectList(newRecords, 'AccountId', true, true);
        if(!allAccountIds.isEmpty()){
            delete [SELECT Id FROM BuyerGroupMember WHERE BuyerId IN : allAccountIds AND BuyerGroup.Name = : System.Label.WebshopDoNotTranslateBuyerGroupVoucher];
        }
    }

    public static void checkLetterCampaignFreeItems(List<Order> newRecords, Map<Id, Order> oldRecordsMap){
        List<Account> accountsToUpdate = new List<Account>();
        Set<Id> orderIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        for(Order o : newRecords){
            accountIds.add(o.AccountId);
        }
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT ID, LetterCampaignBonusUsed__c FROM Account WHERE Id IN : accountIds]);
        for(OrderItem oi : [SELECT Id, OrderId FROM OrderItem WHERE FreeReason__c = : System.Label.LetterCampaignFreeReason AND OrderId IN : newRecords]){
            orderIds.add(oi.OrderId);
        }
        if(!orderIds.isEmpty()){
            for(Order o : newRecords){
                Account ac = accountMap.get(o.AccountId);
                if(orderIds.contains(o.Id) && o.Status != oldRecordsMap.get(o.Id).Status && o.Status == ACTIVATED_STATUS){
                    if(ac == null || !ac.LetterCampaignBonusUsed__c){
                        accountsToUpdate.add(new Account(Id = o.AccountId, LetterCampaignBonusUsed__c = true));
                    } else {
                        o.addError(LETTER_BONUS_ERROR);
                    }
                }
            }
        }
        if(!accountsToUpdate.isEmpty()){
            update accountsToUpdate;
        }
    }

    public static void handleERPAfterInsert(List<Order> newRecords) {
        pushReadyForTransmissionERPOrders(newRecords);
    }

    public static void handleERPAfterUpdate(List<Order> newRecords) {
        pushReadyForTransmissionERPOrders(newRecords);
    }

    private static void pushReadyForTransmissionERPOrders(List<Order> orders) {
        Set<Id> readyForTransmissionOrders = new Set<Id>();

        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
            (List<Order>)Trigger.new,
            (Map<Id, Order>)Trigger.oldMap
        );

        for (Order order : orders) {
            if (order.Status == 'Ready for Transmission to ERP' && !erpUpdatedRecords.contains(order.Id)) {
                readyForTransmissionOrders.add(
                    order.Id
                );
            }
        }

        if (readyForTransmissionOrders.isEmpty()) {
            return;
        }

        OrderSyncService.pushOrders(
            readyForTransmissionOrders
        );
    }
}