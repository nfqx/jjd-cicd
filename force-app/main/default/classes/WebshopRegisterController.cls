public without sharing class WebshopRegisterController {

    // Szenario 0: Accountsuche
    @AuraEnabled(cacheable=false)
    public static String checkAccountNumber(String accountNumber, String email){
        try{
            List<Account> accounts = [SELECT Id, IsWebshopAccount__c FROM Account WHERE ERPCustomerNumber__c = : accountNumber];
            if(!accounts.isEmpty()){
                Account acc = accounts[0];
                if(acc.IsWebshopAccount__c){
                    return 'already_active';
                } else {
                    activateAccountForRegistration(acc.Id);
                    List<EmailTemplate> emailTemplates = [
                        SELECT Id, HtmlValue, Body, Subject
                        FROM EmailTemplate
                        WHERE DeveloperName = : System.Label.WebshopDoNotTranslateEmailTemplateConfirm
                    ];    
                    List<OrgWideEmailAddress> oweaList = [
                        SELECT Id
                        FROM OrgWideEmailAddress
                        WHERE Address = : System.Label.NoReplyAddress
                    ];
                    if(!emailTemplates.isEmpty() && !oweaList.isEmpty()){
                        EmailTemplate emailTemplate = emailTemplates[0];
                        // Initialize Email Template Details    
                        Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
                        // Set OWEA as sender
                        emailToSend.setOrgWideEmailAddressId(oweaList[0].Id);
                        // Set recipient with setTargetObjectId in order not to hit Org Limits
                        emailToSend.setToAddresses(new List<String>{email});
                        emailToSend.setBccAddresses(new List<String>{System.Label.WebshopNFQXAddress, System.Label.WebshopContactEmail});
                        // Set Email Subject
                        emailToSend.setSubject(emailTemplate.Subject);
                        emailToSend.saveAsActivity = false;
                        emailToSend.setUseSignature(false);
                        // Substitute Merge Field and populate Email Body
                        String confirmUrl = System.Label.WebshopDoNotTranslateUrl + '/complete-registration?emailaddress=' + email + '&accountid=' + acc.Id;

                        // HTML
                        if (String.isNotBlank(emailTemplate.HtmlValue)) {
                            String formattedBody = emailTemplate.HtmlValue.replace('placeholder', confirmUrl);
                            emailToSend.setHtmlBody(formattedBody);
                        }

                        // Plain text
                        if (String.isNotBlank(emailTemplate.Body)) {
                            String formattedTextBody = emailTemplate.Body.replace('placeholder', confirmUrl);
                            emailToSend.setPlainTextBody(formattedTextBody);
                        }
                        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{emailToSend});
                        return 'success';
                    }  
                }
            }
            return 'not_found';
        } catch(Exception e){
            System.debug(e.getMessage());
            return e.getMessage();
        }
    }

    @AuraEnabled(cacheable=false)
    public static Boolean checkShowGLPage(){
        try{
            return ![SELECT Id FROM PermissionSetAssignment WHERE PermissionSet.Name = : System.Label.WebshopDoNotTranslatePermissionSetName AND AssigneeId = : UserInfo.getUserId()].isEmpty();
        } catch(Exception e){
            System.debug(e.getMessage());
            return null;
        }
    }

    @AuraEnabled(cacheable=false)
    public static Boolean activateAccountForRegistration(String accountId){
        try{
            insert new WebshopAccountActivation__c(Account__c = accountId);
            return true;
        } catch(Exception e){
            System.debug(e.getMessage());
            return false;
        }
    }

    @AuraEnabled(cacheable=false)
    public static Boolean verifyRegistrationActivation(String accountId){
        try{
            List<WebshopAccountActivation__c> activations = [SELECT Id, Account__c FROM WebshopAccountActivation__c WHERE Account__c = : accountId];
            if(!activations.isEmpty()){
                delete activations;
                return true;
            } 
            return false;
        } catch(Exception e){
            System.debug(e.getMessage());
            return false;
        }
    }

    @AuraEnabled(cacheable=false)
    public static Boolean sendNotification(String notificationText, String accountId){
        List<OrgWideEmailAddress> oweaList = [
            SELECT Id
            FROM OrgWideEmailAddress
            WHERE Address = : System.Label.NoReplyAddress
        ];
        if(!oweaList.isEmpty()){ 
            Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
            emailToSend.setOrgWideEmailAddressId(oweaList[0].Id);
            emailToSend.setToAddresses(new List<String>{System.Label.WebshopNFQXAddress, System.Label.WebshopContactEmail});
            emailToSend.setSubject('Webshop Self-Registration: Automated Notification');
            emailToSend.saveAsActivity = false;
            emailToSend.setUseSignature(false);
            emailToSend.setHTMLBody(notificationText + ', Account: ' + accountId);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{emailToSend});
        }
        return true;
    }
    @AuraEnabled(cacheable=false)
    public static Boolean verifyAccount(String postalCode, String accountId){
        try{
            return ![SELECT Id FROM Account WHERE (ShippingPostalCode = : postalCode OR BillingPostalCode = : postalCode) AND Id = : accountId].isEmpty();
        } catch(Exception e){
            System.debug(e.getMessage());
            return null;
        }
    }

    // Identische Logik für
    // Szenario 1: Reguläre Registrierung auf bestehendem Account.
    // Szenario 2: Bestehender Webshopkunde fügt im Self-Service auf bestehendem, authentifiziertem Account weitere Benutzer hinzu.
    // Mechanismus wurde mehrfach auch mit René besprochen. Erneute Bestätigung der Logik nur zur Absicherung.
    @AuraEnabled(cacheable=false)
    public static String checkRegisterUser(String firstName, String lastName, String email, String phone, String accountId, Boolean noVerification){
        try{
            List<Account> accounts = [SELECT Id, Name, Website, IsWebshopAccount__c FROM Account WHERE Id = : accountId];
            if(!accounts.isEmpty()){
                //if(accounts[0].IsWebshopAccount__c){
                // Check if email already exists in system
                List<User> ul = [SELECT Id, ContactId, Contact.AccountId, Contact.WebshopCustomer__c FROM User WHERE Email = : email];
                if(ul.isEmpty()){
                    // check if user meets suffix criteria
                    Account acc = accounts[0];
                    Contact con = new Contact(
                        FirstName = firstName, 
                        LastName = lastName, 
                        AccountId = acc.Id, 
                        Email = email, 
                        Phone = phone,
                        PriceVisible__c = TRUE
                    );
                    if((String.isNotBlank(acc.Website) && email.endsWith(acc.Website)) || noVerification){
                        // Create and activate Contact
                        con.WebshopCustomer__c = TRUE;
                        con.WebshopSelfActivationPending__c = TRUE;
                        con.WebshopSelfActivationTimestamp__c = Datetime.now();
                        insert con;
                        //LeadTriggerHandler.futureActivateContacts(new List<String>{con.Id}, true, noVerification, true);
                        //futureCreateBuyerAcc(acc.Id, acc.Name);
                        acc.CreateOrActivateBuyerAccount__c = true;
                        update acc;
                        return 'success';
                    } else {
                        // Create contact with WebshopRegisterCheck__c =  true
                        con.WebshopRegisterCheck__c = TRUE;
                        insert con;
                        return 'postal';
                    }
                } else {
                    // if yes, check if user is webshop activated
                    User u = ul[0];
                    if(String.isNotBlank(u.ContactId) && u.Contact.WebshopCustomer__c && u.Contact.AccountId == accountId){
                        return 'already_active';
                    } else {
                        List<EmailTemplate> emailTemplates = [
                            SELECT Id, HtmlValue, Subject
                            FROM EmailTemplate
                            WHERE DeveloperName = : System.Label.WebshopDoNotTranslateEmailTemplateInternal
                        ];    
                        List<OrgWideEmailAddress> oweaList = [
                            SELECT Id
                            FROM OrgWideEmailAddress
                            WHERE Address = : System.Label.NoReplyAddress
                        ];
                        if(!emailTemplates.isEmpty() && !oweaList.isEmpty()){
                            EmailTemplate emailTemplate = emailTemplates[0];
                            // Initialize Email Template Details    
                            Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
                            // Set OWEA as sender
                            emailToSend.setOrgWideEmailAddressId(oweaList[0].Id);
                            // Set recipient with setTargetObjectId in order not to hit Org Limits
                            emailToSend.setToAddresses(new List<String>{System.Label.WebshopContactEmail});
                            emailToSend.setBccAddresses(new List<String>{System.Label.WebshopNFQXAddress, System.Label.WebshopContactEmail});
                            // Set Email Subject
                            emailToSend.setSubject(emailTemplate.Subject);
                            emailToSend.saveAsActivity = false;
                            emailToSend.setUseSignature(false);
                            // Substitute Merge Field and populate Email Body
                            // Use baseUrl constant and only set HTML Email Body
                            String formattedBody = 
                                String.format(
                                emailTemplate.HTMLValue.replace('placeholder', '{0}'),
                                new List<String>{
                                    firstName,
                                    lastName,
                                    email, 
                                    phone, 
                                    accounts.isEmpty() ? System.Label.GeneralInvalid : accounts[0].Name,
                                    u.ContactId != null && !u.Contact.WebshopCustomer__c ? System.Label.WebshopNotWebshopCustomer : '',
                                    u.ContactId != null && u.Contact?.AccountId != accountId ? System.Label.WebshopWrongAccount : ''
                                }
                            );
                            emailToSend.setHTMLBody(formattedBody);
                            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{emailToSend});
                        } 
                        return 'no_contact_or_not_webshop_customer'; 
                    }
                }
            } /*else if(!accounts.isEmpty() && !accounts[0].IsWebshopAccount__c){
                return 'account_not_webshop_activated';
            } */ else {
                return 'no_account_found';
            }
        } catch(Exception e){
            System.debug(e.getMessage());
            return e.getMessage();
        }
    }

    /*
    @future 
    private static void futureCreateBuyerAcc(String accountId, String accountName){
        List<BuyerAccount> baList = [SELECT Id FROM BuyerAccount WHERE BuyerId = : accountId];
        if(baList.isEmpty()){
            BuyerAccount bacc = new BuyerAccount(
                BuyerId = accountId,
                Name = accountName,
                isActive = true
            );
            insert bacc;
        } else {
            baList[0].isActive = true;
            update baList[0];
        }
    }

    @AuraEnabled(cacheable=false)
    public static Boolean addOutlet(){
        return false;
    }*/
}