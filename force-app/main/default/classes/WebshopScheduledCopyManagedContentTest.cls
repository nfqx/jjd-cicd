@isTest
private class WebshopScheduledCopyManagedContentTest {
    
    @isTest
    static void testExecuteSchedulable() {
        // Test the execute method of Schedulable
        Test.startTest();
        String jobId = System.schedule('Test Scheduled Job', '0 0 * * * ?', new WebshopScheduledCopyManagedContent());
        Test.stopTest();
        
        // Verify the job was scheduled
        CronTrigger ct = [SELECT Id, CronJobDetail.Name, State FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals('Test Scheduled Job', ct.CronJobDetail.Name);
    }
    
    @isTest(SeeAllData = TRUE)
    static void testBatchableExecution() {
        // Run the batch job to test the Batchable start, execute, and finish methods
        Test.startTest();
        
        // Instantiate and execute the batch class
        WebshopScheduledCopyManagedContent batchJob = new WebshopScheduledCopyManagedContent(false);
        Database.executeBatch(batchJob, 100);
        
        Test.stopTest();
    }
}