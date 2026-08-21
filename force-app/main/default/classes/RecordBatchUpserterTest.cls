/*
* Created by: Stanley Yin
* Created Date: 06-11-2023
* Purpose: Test Class for RecordBatchUpserter
*/

@isTest
private class RecordBatchUpserterTest{

    @isTest
    static void testBatchUpsert(){
        List<Account> accts = new List<Account>();
        accts.add(new Account(Name = 'test'));
        Test.startTest();
            Database.executeBatch(new RecordBatchUpserter(accts, true), 1);
        Test.stopTest();
        Assert.areEqual([SELECT Id FROM Account WHERE Name = 'test'].size(), 1);
    }    
}