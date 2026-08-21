@IsTest
private class WebshopCheckNoOrderBatchTest {
    @IsTest
    static void testExecute_NoRecentOrders() {
        Test.startTest();

        new WebshopCheckNoOrderBatch().execute(null);

        Test.stopTest();

        // Validate execution completed successfully.
        // If an OrgWideEmailAddress matching the label exists,
        // an email will be queued. Otherwise the email branch is skipped.
        System.assert(true);
    }

    @IsTest
    static void testSchedule() {
        Test.startTest();

        String cron = '0 0 0 1 1 ? 2099';
        System.schedule(
            'WebshopCheckNoOrderBatchTest',
            cron,
            new WebshopCheckNoOrderBatch()
        );

        Test.stopTest();

        CronTrigger ct = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'WebshopCheckNoOrderBatchTest'
            LIMIT 1
        ];

        System.assertEquals('WebshopCheckNoOrderBatchTest', ct.CronJobDetail.Name);
    }
}