public with sharing class MigrationImageController {

    @AuraEnabled
    public static void startMigration() {
        Database.executeBatch(
            new MigrationProductImagesBatch(),
            1
        );
    }

}