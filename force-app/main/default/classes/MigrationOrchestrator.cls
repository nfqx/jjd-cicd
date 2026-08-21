public with sharing class MigrationOrchestrator {

    @AuraEnabled
    public static void startMigration(){
        Database.executeBatch(new MigrationProductBrandMappingJob(), 200);
    }
}