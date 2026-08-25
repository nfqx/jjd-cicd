public with sharing class MigrationAccountController {

    @AuraEnabled
    public static void startMigration() {
        Database.executeBatch(
            new MigrationAccountJob(),
            100
        );
    }

}