public without sharing class WebshopLoginController {
    @AuraEnabled(Cacheable=false)
    public static String loginWithId(String userId, String password){
        try{
            List<User> ul = [SELECT Id, Username, LanguageLocaleKey FROM User WHERE Id = : userId AND Contact.Account.BlockedForWebshop__c = FALSE AND Contact.WebshopCustomer__c = TRUE];
            if(!ul.isEmpty()){
                String returnUrl = Url.getOrgDomainUrl().toExternalForm().replace('.salesforce.', '.site.') + '/' + System.Label.WebshopLoginReturnURL + ul[0].LanguageLocaleKey.replaceAll('_', '-') + '/';
                ApexPages.PageReference lgn = Site.login(ul[0].Username, password, returnUrl);
                return lgn.getUrl();
            }
            return System.Label.WebshopLoginErrorMessage;
        }catch(Exception e){
            System.debug(e);
            return System.Label.WebshopLoginErrorMessage;
        }
    }
    @AuraEnabled(Cacheable=false)
    public static Map<String, String> login(String username, String password){
        try{
            List<PermissionSetAssignment> ul = [SELECT Id, Assignee.LanguageLocaleKey, AssigneeId, Assignee.Contact.AccountId FROM PermissionSetAssignment WHERE PermissionSet.Name = : System.Label.WebshopDoNotTranslateMainPermissionSetName AND Assignee.Contact.AccountId != NULL AND Assignee.UserName = : username AND Assignee.Contact.Account.BlockedForWebshop__c = FALSE];
            if(!ul.isEmpty()){
                String returnUrl = Url.getOrgDomainUrl().toExternalForm().replace('.salesforce.', '.site.') + '/' + System.Label.WebshopLoginReturnURL + ul[0].Assignee.LanguageLocaleKey.replaceAll('_', '-') + '/';
                ApexPages.PageReference lgn = Site.login(username, password, returnUrl);
                String cartId = WebshopDataController.getCartSummaryOrCreateCart(ul[0].Assignee.Contact.AccountId);
                System.debug(lgn.getUrl());
                return new Map<String, String>{
                    'cartId' => cartId,
                    'url' => lgn.getUrl()
                };
            }
            return new Map<String, String>{'error' => System.Label.WebshopLoginErrorMessage};
        }catch(Exception e){
            System.debug(e);
            return new Map<String, String>{'error' => System.Label.WebshopLoginErrorMessage};
        }
    }
    @AuraEnabled(Cacheable=false)
    public static Boolean forgotPassword(String username){
        try{
            List<PermissionSetAssignment> ul = [SELECT Id, AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = : System.Label.WebshopDoNotTranslateMainPermissionSetName AND Assignee.UserName = : username AND Assignee.Contact.Account.BlockedForWebshop__c = FALSE];
            if(!ul.isEmpty()){
                System.resetPasswordWithEmailTemplate(ul[0].AssigneeId, true, 'B2BShopChangedPasswordEmail');
                return true;
            }
            return false;
        } catch(Exception e){
            System.debug(e.getMessage());
            return false;
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static Boolean checkPendingVerification(String userId) {
        try {
            List<User> ul = [SELECT Id FROM User WHERE Id = : userId AND PendingActivation__c = TRUE];
            if(!ul.isEmpty()){
                ul[0].PendingActivation__c = false;
                update ul[0];
                return true;
            }
            return true;
        } catch(Exception e){
            System.debug(e);
            return false;
        }
    }

    @AuraEnabled(cacheable=false)
    public static Boolean setPassword(String password) {
        try {
            System.setPassword(UserInfo.getUserId(), password);
            return true;
        } catch(Exception e){
            System.debug(e);
            return false;
        }
    }
}