public with sharing class BankInfoTriggerHandler{
    public static void handleBeforeInsert(List<BankInfo__c> newRecords) {
        prepopulateERPCustomerNumber(newRecords, null);
    }

    public static void handleBeforeUpdate(List<BankInfo__c> newRecords, Map<Id, BankInfo__c> oldRecordsMap) {
        prepopulateERPCustomerNumber(newRecords, oldRecordsMap);
    }

    public static void handleAfterInsert(List<BankInfo__c> newRecords) {
        publish(newRecords, null);
    }

    public static void handleAfterUpdate(List<BankInfo__c> newRecords, Map<Id, BankInfo__c> oldRecordsMap) {
        publish(newRecords, oldRecordsMap);
    }

    private static void publish(List<BankInfo__c> newRecords, Map<Id, BankInfo__c> oldRecordsMap) {
        ERPIntegrationEventPublisher.sendBankAccountToERP(
            newRecords,
            ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
                newRecords,
                oldRecordsMap
            )
        );
    }

    private static void prepopulateERPCustomerNumber(List<BankInfo__c> bankInfoItems, Map<Id, BankInfo__c> oldBankInfoItems) {
        Map<Id, List<Id>> bankAccountToAccount = new Map<Id, List<Id>>();
        Map<Id, BankInfo__c> bankAccounts = new Map<Id, BankInfo__c>();

        for (BankInfo__c bankInfoItem : bankInfoItems) {
            bankAccounts.put(bankInfoItem.Id, bankInfoItem);

            if (oldBankInfoItems == null || bankInfoItem.Account__c != oldBankInfoItems.get(bankInfoItem.Id).Account__c) {
                if (bankAccountToAccount.containsKey(bankInfoItem.Account__c)) {
                    bankAccountToAccount.get(bankInfoItem.Account__c).add(bankInfoItem.Id);
                } else {
                    bankAccountToAccount.put(bankInfoItem.Account__c, new List<Id> { bankInfoItem.Id });
                }
            }
        }

        for (Account account : [SELECT ERPCustomerNumber__c FROM Account WHERE Id IN :bankAccountToAccount.keySet()]) {
            for (Id bankAccountId : bankAccountToAccount.get(account.Id)) {
                bankAccounts.get(bankAccountId).ERPCustomerNumber__c = account.ERPCustomerNumber__c;
            }
        }
    }
}