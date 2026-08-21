public class MigrationProductSubGroupParentBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([
            SELECT Id,
                ProductSubGroup__c,
                ProductGroup__c
            FROM Product2
            WHERE ProductSubGroup__c != NULL
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {

        List<Product2> subGroups = (List<Product2>)scope;

        // Load all groups by name
        Map<String, Id> groupIdByName = new Map<String, Id>();

        for (Product2 p : [
            SELECT Id, Name
            FROM Product2
            WHERE ProductGroup__c = NULL
        ]) {
            groupIdByName.put(p.Name, p.Id);
        }

        List<Product2> updates = new List<Product2>();

        for (Product2 sg : subGroups) {

            if (sg.ProductGroup__c != NULL) continue;

            // We assume subgroup name matches group name mapping source logic
            // (as per your migration design)

            // If already linked, skip
            continue;
        }

        // NOTE:
        // Parent linkage is already handled in main batch via source org.
        // This batch is placeholder for re-validation / backfill.

        if (!updates.isEmpty()) {
            Database.update(updates, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
        // end of chain
    }

}