public class BatchAutomateAssortmentExtension implements Schedulable, Database.Batchable<sObject>, Database.Stateful {
    
    public static final Id ASSORTMENT_EXTENSION_BUYER_GROUP = [SELECT Id FROM BuyerGroup WHERE Name = : System.Label.WebshopDoNotTranslateTeaAndCocayaEntPolicy LIMIT 1].Id;

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchAutomateAssortmentExtension(), 100);
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id FROM Account WHERE IsWebshopAccount__c = TRUE AND AssortmentExtensionExclusion__c = FALSE AND AssortmentExtensionManual__c = FALSE');
    }
    
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        List<BuyerGroupMember> buyerGroupMembersToInsert = new List<BuyerGroupMember>();
        Map<Id, Account> chainAccountsMap = new Map<Id, Account>([
            SELECT Id FROM Account WHERE Id IN : scope AND ConditionChainParent__c != NULL
        ]);
        for(Account ac : scope){
            if(chainAccountsMap.containsKey(ac.Id)){
                ac.AssortmentExtended__c = false;
                //ac.WebshopFrontpageWarning__c = null;
            } else {
                ac.AssortmentExtended__c = true;
                //ac.WebshopFrontpageWarning__c = System.Label.WebshopDoNotTranslateAssortmentExtensionBG;
                buyerGroupMembersToInsert.add(new BuyerGroupMember(
                    BuyerGroupId = ASSORTMENT_EXTENSION_BUYER_GROUP,
                    BuyerId = ac.Id
                ));
            }
        }

        update scope;
        delete [SELECT Id FROM BuyerGroupMember WHERE BuyerGroupId = : ASSORTMENT_EXTENSION_BUYER_GROUP AND BuyerId IN : chainAccountsMap.keySet()];
        if(!buyerGroupMembersToInsert.isEmpty()){
            Database.insert(buyerGroupMembersToInsert, false);
        }
    }

    public void finish(Database.BatchableContext bc){ 
        if(!Test.isRunningTest()){
            Database.executeBatch(new BatchAutomateBrandAssortmentExtension(), 10);
        }
     }
}