public with sharing class FTPOrderCollectionBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts, Schedulable {        
    private Map<String, List<FTPOrderLine>> groupedOrders = new Map<String, List<FTPOrderLine>>();

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new FTPOrderCollectionBatch(), 1);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, Name, ERPCustomerNumber__c FROM Account WHERE FTPOrdering__c = TRUE AND ERPCustomerNumber__c != NULL]);
    }
    
    public void execute(Database.BatchableContext bc, List<Account> scope) {

    String fileName = Datetime.now().format('yyyyMMdd') + '.csv';

    for (Account headAccount : scope) {

        Map<String, String> allAccountsMap = new Map<String, String>{ headAccount.ERPCustomerNumber__c => headAccount.Id };
        Set<Id> currentAccounts = new Set<Id>{ headAccount.Id };
        while (!currentAccounts.isEmpty()) {
            List<Account> checkingAccounts = [
                SELECT Id, ERPCustomerNumber__c
                FROM Account
                WHERE ConditionChainParent__c IN :currentAccounts
            ];
            currentAccounts = new Set<Id>();
            for (Account acc : checkingAccounts) {
                allAccountsMap.put(acc.ERPCustomerNumber__c, acc.Id);
                currentAccounts.add(acc.Id);
            }
        }

        String accountNumber = headAccount.ERPCustomerNumber__c;
        try {
            String filePath = accountNumber + '/' + fileName;
            String csvContent = FTPClient.downloadFileAsString(filePath);
            // File not found -> ignore
            if (String.isNotBlank(csvContent)) {
                for (FTPOrderLine line : parseCsv(csvContent)) {
                    System.debug(line.childAccountNumber);
                    System.debug(allAccountsMap);
                    System.debug(allAccountsMap.containsKey(line.childAccountNumber));
                    if (allAccountsMap.containsKey(line.childAccountNumber)) {
                        String childAccountId = allAccountsMap.get(line.childAccountNumber);
                        List<FTPOrderLine> innerList = groupedOrders.containsKey(childAccountId) ? groupedOrders.get( childAccountId) : new List<FTPOrderLine>();
                        innerList.add(line);
                        groupedOrders.put(childAccountId, innerList);
                    }
                }
            }


        } catch (Exception ex) {
            System.debug(
                LoggingLevel.ERROR,
                'FTP processing failed for account ' +
                accountNumber +
                ': ' +
                ex.getMessage()
            );
        }
    }
}
    
    public void finish(Database.BatchableContext bc) {
        List<FTPOrderGroup> orderGroups = new List<FTPOrderGroup>();
        for (String accountNumber : groupedOrders.keySet()) {
            FTPOrderGroup groupWrapper = new FTPOrderGroup(accountNumber, groupedOrders.get(accountNumber));
            orderGroups.add(groupWrapper);
        }
        if (!orderGroups.isEmpty()) {
            Database.executeBatch(new FTPOrderProcessingBatch(orderGroups), 1);
        }
    }

    /**
     * CSV Parser
     */
    private List<FTPOrderLine> parseCsv(String csvContent) {
        List<FTPOrderLine> result = new List<FTPOrderLine>();
        csvContent = csvContent.replace('\uFEFF', '');
        List<String> rows = csvContent.split('\n');
        for (String row : rows) {
            if (String.isNotBlank(row)) {
                List<String> columns = row.split(',');
                if (columns.size() >= 3) {
                    String childAccountNumber = columns[0].trim();
                    String sku = columns[1].trim();
                    Decimal quantity = Decimal.valueOf(columns[2].trim());
                    result.add(new FTPOrderLine(childAccountNumber, sku, quantity));
                }
            }
        }
        return result;
    }
}