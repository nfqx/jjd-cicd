/*
* Created by: Stanley Yin
* Created Date: 28.07.2026
*/

public without sharing class WebshopCheckNoOrderBatch implements Schedulable {
    public Boolean allContent {get; set;}
    public void execute(SchedulableContext sc) {
        DateTime dt = Datetime.now().addHours(-2);
        List<Order> orderList = [SELECT Id FROM Order WHERE CreatedDate >= : dt AND WebshopOrder__c = TRUE];
        List<OrgWideEmailAddress> oweaList = [ SELECT Id FROM OrgWideEmailAddress WHERE Address = : System.Label.NoReplyAddress ];
        if(orderList.isEmpty() && !oweaList.isEmpty()){
            Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
            emailToSend.setOrgWideEmailAddressId(oweaList[0].Id);
            emailToSend.setSubject('No Order Warning');
            emailToSend.setToAddresses(new List<String>{System.Label.WebshopNFQXAddress, System.Label.WebshopContactEmail});
            emailToSend.setUseSignature(false);
            emailToSend.setHTMLBody('JJD Webshop Org ' + UserInfo.getOrganizationId() + ': No orders in the last two hours!');
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{emailToSend});
        }
    }    
}