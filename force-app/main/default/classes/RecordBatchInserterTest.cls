/*
* Created by: Stanley Yin
* Created Date: 06-11-2023
* Purpose: Test Class for RecordBatchInserter
*/

@isTest
private class RecordBatchInserterTest{

    @isTest
    static void testBatchInsert(){
        List<Account> accts = new List<Account>();
        accts.add(new Account(Name = 'test'));
        Test.startTest();
            Database.executeBatch(new RecordBatchInserter(accts), 1);
        Test.stopTest();
        Assert.areEqual([SELECT Id FROM Account WHERE Name = 'test'].size(), 1);
    }    
}