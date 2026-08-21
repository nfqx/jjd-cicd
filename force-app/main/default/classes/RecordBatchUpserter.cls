/*
* Created by: Stanley Yin
* Created Date: 06-11-2023
* Purpose: Batch Insert of records to avoid Apex limits - usually Error Logs
*/

global class RecordBatchUpserter implements Database.batchable<sObject>{
    global List<sObject> myList;   
    global Boolean withLogging;
    global RecordBatchUpserter(List<sObject> objList, Boolean logging){
        myList = objList;
        withLogging = logging;
    }    
    global List<sObject> start(Database.BatchableContext bc) {
        return myList;
    }
    global void execute(Database.BatchableContext bc, List<sObject> scope){
        if(withLogging){
            List<ErrorLogging__c> errorLogs = new List<ErrorLogging__c>();
            Integer i = 0;
            for (Database.UpsertResult result : Database.upsert(scope, false)) {
                if (!result.isSuccess()) {
                    for (Database.Error err : result.getErrors()) {
                        errorLogs.add(new ErrorLogging__c( Error__c = err.getStatusCode() + ': ' + err.getMessage() + ', Fields: ' + String.join(err.getFields(), ', '), ProcessName__c = 'B2BProductPriceCalcCstBatch.execute()' ));
                    }
                }
                i++;
            }
            if(!errorLogs.isEmpty()){
                insert errorLogs;
            }
        } else {
            Database.upsert(scope, false);
        }
    }
    global void finish(Database.BatchableContext bc){
        // do nothing or notify the technical team
    }   
}