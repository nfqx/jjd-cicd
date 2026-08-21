/*
* Created by: Stanley Yin
* Created Date: 06-11-2023
* Purpose: Test Class for RecordBatchDeleter
*/

@isTest
private class RecordBatchDeleterTest{

    @isTest
    static void testBatchDelete(){
        List<Account> accts = new List<Account>();
        accts.add(new Account(Name = 'test'));
        insert accts;
        Test.startTest();
            Database.executeBatch(new RecordBatchDeleter('SELECT Id FROM Account'), 1);
        Test.stopTest();
        Assert.areEqual([SELECT Id FROM Account].size(), 0);
    }    
}