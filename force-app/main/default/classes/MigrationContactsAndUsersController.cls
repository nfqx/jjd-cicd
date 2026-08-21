public with sharing class MigrationContactsAndUsersController {
    @AuraEnabled
    public static void startMigration(){
        Database.executeBatch(
            new MigrationContactJob(),
            50
        );

    }
}