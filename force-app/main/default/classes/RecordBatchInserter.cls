/*
* Created by: Stanley Yin
* Created Date: 06-11-2023
* Purpose: Batch Insert of records to avoid Apex limits - usually Error Logs
*/

global class RecordBatchInserter implements Database.batchable<sObject>{
    global List<sObject> myList;    
    global RecordBatchInserter(List<sObject> objList){
        this.myList = objList;
    }    
    global List<sObject> start(Database.BatchableContext bc) {
        return this.myList;
    }
    global void execute(Database.BatchableContext bc, List<sObject> scope){
        Database.insert(scope, false);
    }
    global void finish(Database.BatchableContext bc){
        // do nothing or notify the technical team
    }   
}