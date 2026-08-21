/*
* Created by: Stanley Yin
* Created Date: 06-11-2023
* Purpose: Batch Insert of records to avoid Apex limits - usually Error Logs
*/

global class RecordBatchDeleter implements Database.batchable<sObject>{
    global String queryString;   
    global RecordBatchDeleter(String qString){
        queryString = qString;
    }    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.queryString);
    }
    global void execute(Database.BatchableContext bc, List<sObject> scope){
        Database.delete(scope, false);
    }
    global void finish(Database.BatchableContext bc){
        // do nothing or notify the technical team
    }   
}