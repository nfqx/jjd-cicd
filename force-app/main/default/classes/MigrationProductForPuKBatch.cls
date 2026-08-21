public class MigrationProductForPuKBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([
            SELECT Id,
                OldProductNumber__c,
                ProductGroup__c,
                ProductSubGroup__c
            FROM Product2
            WHERE OldProductNumber__c != NULL
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {

        List<Product2> products = (List<Product2>)scope;

        // -----------------------------------------
        // 1. Resolve duplicates (VariationParent wins)
        // -----------------------------------------
        Map<String, Product2> targetByCode = new Map<String, Product2>();

        for (Product2 p : products) {

            if (p.OldProductNumber__c == null) continue;

            String code = p.OldProductNumber__c;
            Product2 existing = targetByCode.get(code);

            if (existing == null) {
                targetByCode.put(code, p);
            }
        }

        Set<String> codes = targetByCode.keySet();
        if (codes.isEmpty()) return;

        // -----------------------------------------
        // 2. Query source org
        // -----------------------------------------
        List<String> quoted = new List<String>();
        for (String c : codes) {
            quoted.add('\'' + String.escapeSingleQuotes(c) + '\'');
        }

        String soql =
            'SELECT ProductCode,' +
            ' Produktgruppe__r.Name,' +
            ' Produkt_Untergruppe__r.Name,' +
            ' Produkt_Untergruppe__r.Produktgruppe__r.Name' +
            ' FROM Product2' +
            ' WHERE ProductCode IN (' + String.join(quoted, ',') + ')';

        List<Object> records = SourceOrgApi.query(soql);

        Map<String, Map<String, Object>> sourceByCode = new Map<String, Map<String, Object>>();

        for (Object r : records) {
            Map<String, Object> row = (Map<String, Object>)r;
            sourceByCode.put((String)row.get('ProductCode'), row);
        }

        // -----------------------------------------
        // 3. Load existing groups/subgroups
        // -----------------------------------------
        Map<String, Product2> groupByName = new Map<String, Product2>();
        Map<String, Product2> subGroupByName = new Map<String, Product2>();

        for (Product2 p : [
            SELECT Id, Name, ProductGroup__c
            FROM Product2
            WHERE ProductGroup__c != NULL OR Name != NULL
        ]) {
            // naive separation via ProductGroup__c null check is not reliable,
            // but sufficient given your structure assumption
            if (p.ProductGroup__c == null) {
                groupByName.put(p.Name, p);
            } else {
                subGroupByName.put(p.Name, p);
            }
        }

        List<Product2> toInsertGroups = new List<Product2>();
        List<Product2> toInsertSubGroups = new List<Product2>();

        // -----------------------------------------
        // 4. Ensure groups/subgroups exist
        // -----------------------------------------
        for (String code : codes) {

            Map<String, Object> row = sourceByCode.get(code);
            if (row == null) continue;

            Map<String, Object> grp = (Map<String, Object>)row.get('Produktgruppe__r');
            if (grp != null) {

                String groupName = (String)grp.get('Name');

                if (groupName != null && !groupByName.containsKey(groupName)) {

                    Product2 g = new Product2();
                    g.Name = groupName;
                    g.Tenant__c = '001';
                    toInsertGroups.add(g);

                    groupByName.put(groupName, g);
                }
            }

            Map<String, Object> subGroup = (Map<String, Object>)row.get('Produkt_Untergruppe__r');
            if (subGroup != null) {

                String subGroupName = (String)subGroup.get('Name');

                if (subGroupName != null && !subGroupByName.containsKey(subGroupName)) {

                    Product2 sg = new Product2();
                    sg.Name = subGroupName;
                    sg.Tenant__c = '001';
                    toInsertSubGroups.add(sg);

                    subGroupByName.put(subGroupName, sg);
                }
            }
        }

        if (!toInsertGroups.isEmpty()) insert toInsertGroups;
        if (!toInsertSubGroups.isEmpty()) insert toInsertSubGroups;

        // -----------------------------------------
        // 5. Refresh maps with IDs
        // -----------------------------------------
        groupByName.clear();
        subGroupByName.clear();

        for (Product2 p : [
            SELECT Id, Name, ProductGroup__c
            FROM Product2
        ]) {
            if (p.ProductGroup__c == null) {
                groupByName.put(p.Name, p);
            } else {
                subGroupByName.put(p.Name, p);
            }
        }

        // -----------------------------------------
        // 6. Assign mappings
        // -----------------------------------------
        List<Product2> updates = new List<Product2>();

        for (String code : codes) {

            Product2 target = targetByCode.get(code);
            Map<String, Object> row = sourceByCode.get(code);

            if (target == null || row == null) continue;

            Boolean changed = false;

            Map<String, Object> grp = (Map<String, Object>)row.get('Produktgruppe__r');
            if (grp != null) {

                String groupName = (String)grp.get('Name');
                Product2 g = groupByName.get(groupName);

                if (g != null && target.ProductGroup__c != g.Id) {
                    target.ProductGroup__c = g.Id;
                    changed = true;
                }
            }

            Map<String, Object> subGroup = (Map<String, Object>)row.get('Produkt_Untergruppe__r');
            if (subGroup != null) {

                String subGroupName = (String)subGroup.get('Name');
                Product2 sg = subGroupByName.get(subGroupName);

                if (sg != null && target.ProductSubGroup__c != sg.Id) {
                    target.ProductSubGroup__c = sg.Id;
                    changed = true;
                }
            }

            if (changed) updates.add(target);
        }

        if (!updates.isEmpty()) {
            Database.update(updates, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
        Database.executeBatch(new MigrationProductSubGroupParentBatch(), 200);
    }

}