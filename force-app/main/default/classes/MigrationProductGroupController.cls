public with sharing class MigrationProductGroupController {
    @AuraEnabled
    public static void startMigration(){
        Database.executeBatch(
            new MigrationProductGroupLoadJob(),
            50
        );
    }
}