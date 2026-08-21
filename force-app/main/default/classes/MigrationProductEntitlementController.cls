public with sharing class MigrationProductEntitlementController {

    @AuraEnabled
    public static void startMigration() {
        Database.executeBatch(
            new MigrationProductEntitlementJob(),
            3
        );
    }

}