public without sharing class AccountTriggerHandler {

    // Related Accounts - Parents and, in case of deletion, children to reprocess in AccountCategoryReclassifyBatch
    private static Set<Id> relatedAccountIds = new Set<Id>();
    public static Boolean suppressClassification = false;

    public static void classify(List<Account> newRecords, Map<Id, Account> oldRecordsMap) {
        if(!suppressClassification){
            // Accounts for immediate processing in Before Trigger
            List<Account> relevantAccounts = new List<Account>();
            for(Account ac : newRecords){
                if(
                    ac.AccountCategorySource__c != AccountCategoryClassifier.CONST_MANUAL && (
                        oldRecordsMap == null ||
                        ac.InvoiceRecipient__c != oldRecordsMap.get(ac.Id).InvoiceRecipient__c ||
                        ac.SelfBilled__c != oldRecordsMap.get(ac.Id).SelfBilled__c ||
                        ac.LegalForm__c != oldRecordsMap.get(ac.Id).LegalForm__c ||
                        ac.TaxID__c != oldRecordsMap.get(ac.Id).TaxID__c ||
                        ac.AccountCategory__c != oldRecordsMap.get(ac.Id).AccountCategory__c ||
                        ac.AccountCategoryReason__c != oldRecordsMap.get(ac.Id).AccountCategoryReason__c ||
                        ac.AccountCategorySource__c != oldRecordsMap.get(ac.Id).AccountCategorySource__c ||
                        ac.IsChainMember__c != oldRecordsMap.get(ac.Id).IsChainMember__c ||
                        ac.ConditionChainParent__c != oldRecordsMap.get(ac.Id).ConditionChainParent__c ||
                        ac.ConditionChainHead__c != oldRecordsMap.get(ac.Id).ConditionChainHead__c ||
                        ac.CentralRegulator__c != oldRecordsMap.get(ac.Id).CentralRegulator__c
                    )
                ){
                    relevantAccounts.add(ac);
                    if(oldRecordsMap == null){
                        if(ac.ConditionChainParent__c != null){
                            relatedAccountIds.add(ac.ConditionChainParent__c);
                        }
                        if(ac.ConditionChainHead__c != null){
                            relatedAccountIds.add(ac.ConditionChainHead__c);
                        }
                        if(ac.CentralRegulator__c != null){
                            relatedAccountIds.add(ac.CentralRegulator__c);
                        }
                    } else {
                        if(ac.ConditionChainParent__c != oldRecordsMap.get(ac.Id).ConditionChainParent__c){
                            if(ac.ConditionChainParent__c != null){
                                relatedAccountIds.add(ac.ConditionChainParent__c);
                            }
                            if(oldRecordsMap.get(ac.Id).ConditionChainParent__c != null){
                                relatedAccountIds.add(oldRecordsMap.get(ac.Id).ConditionChainParent__c);
                            }
                        }
                        if(ac.ConditionChainHead__c != oldRecordsMap.get(ac.Id).ConditionChainHead__c){
                            if(ac.ConditionChainHead__c != null){
                                relatedAccountIds.add(ac.ConditionChainHead__c);
                            }
                            if(oldRecordsMap.get(ac.Id).ConditionChainHead__c != null){
                                relatedAccountIds.add(oldRecordsMap.get(ac.Id).ConditionChainHead__c);
                            }
                        }
                        if(ac.CentralRegulator__c != oldRecordsMap.get(ac.Id).CentralRegulator__c){
                            if(ac.CentralRegulator__c != null){
                                relatedAccountIds.add(ac.CentralRegulator__c);
                            }
                            if(oldRecordsMap.get(ac.Id).CentralRegulator__c != null){
                                relatedAccountIds.add(oldRecordsMap.get(ac.Id).CentralRegulator__c);
                            }
                        }
                    }
                }
            }
            if(!relevantAccounts.isEmpty()){
                // No DML as we are in Before context
                AccountCategoryClassifier.classify(relevantAccounts);
            }
        }
    }
    public static void fanOut() {
        if(!suppressClassification){
            if(!relatedAccountIds.isEmpty()){
                Database.executeBatch(new AccountCategoryReclassifyBatch(relatedAccountIds), 200);
            }
        }
    }
    public static void collectRelatedIds(List<Account> oldRecords) {
        if(!suppressClassification){
            for(Account ac : oldRecords){
                if(ac.ConditionChainParent__c != null){
                    relatedAccountIds.add(ac.ConditionChainParent__c);
                }
                if(ac.ConditionChainHead__c != null){
                    relatedAccountIds.add(ac.ConditionChainHead__c);
                }
                if(ac.CentralRegulator__c != null){
                    relatedAccountIds.add(ac.CentralRegulator__c);
                }
            }
            // Pre-empt manual category sources wherever possible. For parent records we shouldn't as it costs us queries, but for records to be queried it's perfectly fine
            for(Account ac : [SELECT Id FROM Account WHERE (ConditionChainParent__c IN : oldRecords OR ConditionChainHead__c IN : oldRecords OR CentralRegulator__c IN : oldRecords) AND Id NOT IN : oldRecords AND AccountCategorySource__c != : AccountCategoryClassifier.CONST_MANUAL]){
                relatedAccountIds.add(ac.Id);
            }
        }
    }


    public static void handleAfterInsert(Map<Id, Account> newRecordsMap) {
        handleAddressChange(newRecordsMap, null, new Set<Id>());
    }

    public static void handleAfterUpdate(Map<Id, Account> newRecordsMap, Map<Id, Account> oldRecordsMap) {
        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
            newRecordsMap.values(),
            oldRecordsMap
        );

        sendAccountToERP(newRecordsMap.values(), oldRecordsMap, erpUpdatedRecords);
        handleAddressChange(newRecordsMap, oldRecordsMap, erpUpdatedRecords);
    }

    private static void sendAccountToERP(List<Account> newRecords, Map<Id, Account> oldRecordsMap, Set<Id> erpUpdatedRecords) {
        ERPIntegrationEventPublisher.sendAccountsToERP(newRecords, oldRecordsMap, erpUpdatedRecords);
    }

    private static void handleAddressChange(Map<Id, Account> newRecordsMap, Map<Id, Account> oldRecordsMap, Set<Id> erpUpdatedRecords) {
        Map<Id, Account> filteredMap = new Map<Id, Account>();
        for (Id id : newRecordsMap.keySet()) {
            if (!erpUpdatedRecords.contains(id)) {
                filteredMap.put(id, newRecordsMap.get(id));
            }
        }
        if (filteredMap.isEmpty()) return;

        Map<Id, List<CustomAddressWrapper>> updatedAddresses = CustomAddressService.checkAddressChangesBulk(filteredMap, oldRecordsMap);
        if (!updatedAddresses.isEmpty()) {
            CustomAddressService.syncCustomAddress(updatedAddresses);
        }
    }
}