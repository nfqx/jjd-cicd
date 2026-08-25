public class MigrationAccountJob implements Database.Batchable<SObject>, Database.AllowsCallouts {

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

        List<Account> accounts = (List<Account>)scope;

        Set<String> identifiers = new Set<String>();

        for(Account ac : accounts){
            identifiers.add(ac.ERPCustomerNumber__c);
        }

        if(identifiers.isEmpty()) return;

        List<Object> records = SourceOrgApi.query(
            'SELECT Id, AccountNumber, E_Commerce_VIP__c, AssortmentExtended__c, AssortmentExtendedManual__c, AssortmentExtensionExclusion__c, ' +
            'WebshopFrontpageWarning__c, OrderNotifiesParent__c, Is_Webshop_Customer__c, WebshopFirstContactActivationDate__c, Blocked_for_Webshop__c ' + 
            'FROM Account WHERE AccountNumber IN (\'' +
            String.join(new List<String>(identifiers), '\',\'') + '\')'
        );

        Map<String,Map<String,Object>> dataByAccountNumber = new Map<String,Map<String,Object>>();

        for(Object rowPre : records){
            Map<String,Object> row = (Map<String,Object>)rowPre;

            String accountNumber = (String)row.get('AccountNumber');
            if(accountNumber == null) continue;

            dataByAccountNumber.put(accountNumber, row);
        }

        Map<String,Id> brandByName = new Map<String,Id>();

        List<Account> updates = new List<Account>();

        for(Account ac : accounts){

            String key = ac.ERPCustomerNumber__c;

            if(!dataByAccountNumber.containsKey(key)) continue;

            Map<String,Object> source = dataByAccountNumber.get(key);

            Boolean changed = false;

            // Field mappings
            if(ac.ECommerceVIP__c != (Boolean)source.get('E_Commerce_VIP__c')){
                ac.ECommerceVIP__c = (Boolean)source.get('E_Commerce_VIP__c');
                changed = true;
            }

            if(ac.AssortmentExtended__c != (Boolean)source.get('AssortmentExtended__c')){
                ac.AssortmentExtended__c = (Boolean)source.get('AssortmentExtended__c');
                changed = true;
            }

            if(ac.AssortmentExtendedManual__c != (Boolean)source.get('AssortmentExtendedManual__c')){
                ac.AssortmentExtendedManual__c = (Boolean)source.get('AssortmentExtendedManual__c');
                changed = true;
            }

            if(ac.AssortmentExtensionExclusion__c != (Boolean)source.get('AssortmentExtensionExclusion__c')){
                ac.AssortmentExtensionExclusion__c = (Boolean)source.get('AssortmentExtensionExclusion__c');
                changed = true;
            }

            if(ac.WebshopFrontpageWarning__c != (String)source.get('WebshopFrontpageWarning__c')){
                ac.WebshopFrontpageWarning__c = (String)source.get('WebshopFrontpageWarning__c');
                changed = true;
            }

            if(ac.OrderNotifiesParent__c != (Boolean)source.get('OrderNotifiesParent__c')){
                ac.OrderNotifiesParent__c = (Boolean)source.get('OrderNotifiesParent__c');
                changed = true;
            }

            if(source.get('WebshopFirstContactActivationDate__c') != null){
                if(ac.WebshopFirstContactActivationDate__c != Date.valueOf(String.valueOf(source.get('WebshopFirstContactActivationDate__c')))){
                    ac.WebshopFirstContactActivationDate__c = Date.valueOf(String.valueOf(source.get('WebshopFirstContactActivationDate__c')));
                    changed = true;
                }
            } else {
                if(ac.WebshopFirstContactActivationDate__c != null){
                    ac.WebshopFirstContactActivationDate__c = null;
                    changed = true;
                }
            }

            if(ac.BlockedForWebshop__c != (Boolean)source.get('Blocked_for_Webshop__c')){
                ac.BlockedForWebshop__c = (Boolean)source.get('Blocked_for_Webshop__c');
                changed = true;
            }

            if(changed){
                updates.add(ac);
            }
        }

        if(!updates.isEmpty()){
            Database.update(updates, false);
        }
    }

    public void finish(Database.BatchableContext bc){
        Database.executeBatch(new MigrationAccountBrandJob(), 100);
    }
}