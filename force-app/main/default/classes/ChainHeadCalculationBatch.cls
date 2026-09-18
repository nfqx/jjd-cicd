/*
* Created by: Stanley Yin
* Created Date: 16-09.2026
*/

public class ChainHeadCalculationBatch implements Database.batchable<Account>{
    public List<Account> myList;    
    public class CircularException extends Exception {}
    public ChainHeadCalculationBatch(List<Account> objList){
        this.myList = objList;
    }    
    public List<Account> start(Database.BatchableContext bc) {
        return this.myList;
    }
    public void execute(Database.BatchableContext bc, List<Account> scope){
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        for(Account ac : scope){
            Boolean foundHead = false;
            Id headAccountId = ac.Id;
            Set<Id> visitedAccountIds = new Set<Id>();
            // Looping to top
            while(foundHead == false){
                if(visitedAccountIds.contains(headAccountId)){
                    insert new ErrorLogging__c( Error__c = 'Chain Head Calculation Circular Reference', RecordIDs__c = headAccountId, ProcessName__c = 'ChainHeadCalculationBatch.execute()');
                    throw new CircularException('Circular condition chain detected at Account ' + headAccountId);
                } else {
                    visitedAccountIds.add(headAccountId);
                    Account tempAcc = [SELECT Id, ConditionChainParent__c, ConditionChainParent__r.ConditionChainParent__c, ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__c,
                        ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__c, ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__c
                        FROM Account WHERE Id = : headAccountId];
                    if(tempAcc.ConditionChainParent__c == null){
                        headAccountId = tempAcc.Id;
                        foundHead = true;
                    } else if(tempAcc.ConditionChainParent__r.ConditionChainParent__c == null){
                        headAccountId = tempAcc.ConditionChainParent__c;
                        foundHead = true;
                    } else if(tempAcc.ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__c == null){
                        headAccountId = tempAcc.ConditionChainParent__r.ConditionChainParent__c;
                        foundHead = true;
                    } else if(tempAcc.ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__c == null){
                        headAccountId = tempAcc.ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__c;
                        foundHead = true;
                    } else if(tempAcc.ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__c == null){
                        headAccountId = tempAcc.ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__c;
                        foundHead = true;
                    } else {
                        headAccountId = tempAcc.ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__r.ConditionChainParent__c;
                    }
                }
            }
            accountsToUpdate.put(ac.Id, new Account(Id = ac.Id, ConditionChainHead__c = headAccountId));
            // Looping to bottom
            Set<Id> lowestAccIds = new Set<Id>{ac.Id};
            List<Account> nextLevelChildren = [SELECT Id FROM Account WHERE ConditionChainParent__c IN : lowestAccIds];
            while(!nextLevelChildren.isEmpty()){
                lowestAccIds = new Set<Id>();
                for(Account acc : nextLevelChildren){
                    lowestAccIds.add(acc.id);
                    accountsToUpdate.put(acc.Id, new Account(Id = acc.Id, ConditionChainHead__c = headAccountId));
                }
                nextLevelChildren =  [SELECT Id FROM Account WHERE ConditionChainParent__c IN : lowestAccIds];
            }
        }
        try {
            AccountTriggerHandler.suppressRecalcHead = true;
            update accountsToUpdate.values();
        } finally {
            AccountTriggerHandler.suppressRecalcHead = false;
        }
    }
    public void finish(Database.BatchableContext bc){
        // do nothing or notify the technical team
    }   
}