public class AccountCategoryReclassifyBatch implements Database.Batchable<sObject>, Database.Stateful {
    private Set<Id> accountIds {get; set;}
    private List<ErrorLogging__c> errorLogs = new List<ErrorLogging__c>();
    public AccountCategoryReclassifyBatch(){
        this.accountIds = new Set<Id>();
    }

    public AccountCategoryReclassifyBatch(Set<Id> accountIds){
        this.accountIds = accountIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Set<Id> queryAccountIds = this.accountIds;
        return !queryAccountIds.isEmpty() ? Database.getQueryLocator('SELECT Id, TaxID__c, LegalForm__c, AccountCategory__c, AccountCategorySource__c, AccountCategoryReason__c, ConditionChainParent__c, ConditionChainHead__c, CentralRegulator__c, IsChainMember__c, InvoiceRecipient__c FROM Account WHERE Id IN : queryAccountIds') : Database.getQueryLocator('SELECT Id, TaxID__c, LegalForm__c, AccountCategory__c, AccountCategorySource__c, AccountCategoryReason__c, ConditionChainParent__c, ConditionChainHead__c, CentralRegulator__c, IsChainMember__c, InvoiceRecipient__c FROM Account');
    }
    
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        scope = AccountCategoryClassifier.classify(scope);
        AccountTriggerHandler.suppressClassification = true;
        Integer i = 0;
        for (Database.SaveResult result : Database.update(scope, false)){
            if (!result.isSuccess()) {
                for (Database.Error err : result.getErrors()) {
                    this.errorLogs.add(new ErrorLogging__c( Error__c = err.getStatusCode() + ': ' + err.getMessage() + ', Fields: ' + String.join(err.getFields(), ', '), RecordIDs__c = scope[i].Id, ProcessName__c = 'AccountCategoryReclassifyBatch.execute()' ));
                }
            }
            i++;
        }
        AccountTriggerHandler.suppressClassification = false;
    }

    public void finish(Database.BatchableContext bc){
        if(!this.errorLogs.isEmpty()){
            insert errorLogs;
        }
    }
}