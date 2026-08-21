public with sharing class MigrationPuKController {

    @AuraEnabled
    public static void startMigration() {
        Database.executeBatch(
            new MigrationProductForPuKBatch(),
            10
        );
    }

}