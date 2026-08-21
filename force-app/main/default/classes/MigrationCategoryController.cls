public with sharing class MigrationCategoryController {

    @AuraEnabled
    public static void startMigration(){

        Database.executeBatch(
            new MigrationBatchProductCategory(),
            200
        );
    }
}