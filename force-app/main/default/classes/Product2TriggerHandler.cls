public without sharing class Product2TriggerHandler {
    public static void setAlternativeName(List<Product2> newRecords, Map<Id, Product2> oldRecordsMap) {
        for(Product2 prod : newRecords){
            Product2 oldProd = oldRecordsMap.get(prod.Id);
            if(prod.Name != oldProd.Name && String.isBlank(prod.AlternativeName__c) && String.isNotBlank(oldProd.Name)){
                prod.AlternativeName__c = oldProd.Name;
            }
        }
    }

    public static void setMachinePrice(List<Product2> newRecords, Map<Id, Product2> oldRecordsMap) {
        ID pb2Id = Test.isRunningTest() ? Test.getStandardPricebookId() : [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE].Id;
        Id pb2copyId = Test.isRunningTest() ? Test.getStandardPricebookId() : [SELECT Id FROM Pricebook2 WHERE Name = : System.Label.WebshopDoNotTranslateInternalListpricePricebookName AND IsStandard = FALSE ORDER BY CreatedDate LIMIT 1].Id;

        Map<Id, PricebookEntry> standardEntriesMap = new Map<Id, PricebookEntry>();
        Map<Id, PricebookEntry> customEntriesMap = new Map<Id, PricebookEntry>();
        List<Product2> productsToUpdate = new List<Product2>();

        for(PricebookEntry pbe : [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = : pb2Id AND Product2Id IN : newRecords]){
            standardEntriesMap.put(pbe.Product2Id, pbe);
        }
        for(PricebookEntry pbe : [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = : pb2copyId AND Product2Id IN : newRecords]){
            customEntriesMap.put(pbe.Product2Id, pbe);
        }

        for(Product2 prod : newRecords){
            if(
                prod.MachinePrice__c != null && 
                (
                    oldRecordsMap == null ||
                    (oldRecordsMap.get(prod.Id).MachinePrice__c == null)
                )
            ){
                if(!standardEntriesMap.containsKey(prod.Id)){
                    PricebookEntry entryForProduct = new PricebookEntry();
                    entryForProduct.Pricebook2Id = pb2Id;
                    entryForProduct.Product2Id = prod.Id;
                    entryForProduct.UnitPrice = prod.MachinePrice__c;
                    entryForProduct.IsActive = TRUE;
                    standardEntriesMap.put(prod.Id, entryForProduct);
                } else {
                    PricebookEntry entryForProduct = standardEntriesMap.get(prod.Id);
                    entryForProduct.UnitPrice = prod.MachinePrice__c;
                    entryForProduct.IsActive = TRUE;
                    standardEntriesMap.put(prod.Id, entryForProduct);
                }

                if(!customEntriesMap.containsKey(prod.Id)){
                    PricebookEntry cstEntryForProduct = new PricebookEntry();
                    cstEntryForProduct.Pricebook2Id = pb2copyId;
                    cstEntryForProduct.Product2Id = prod.Id;
                    cstEntryForProduct.UnitPrice = prod.MachinePrice__c;
                    cstEntryForProduct.IsActive = TRUE;
                    customEntriesMap.put(prod.Id, cstEntryForProduct);
                } else {
                    PricebookEntry cstEntryForProduct = customEntriesMap.get(prod.Id);
                    cstEntryForProduct.UnitPrice = prod.MachinePrice__c;
                    cstEntryForProduct.IsActive = TRUE;
                    customEntriesMap.put(prod.Id, cstEntryForProduct);
                }

                productsToUpdate.add(new Product2(Id = prod.Id, MachinePrice__c = null));
            }
        }

        if(!standardEntriesMap.isEmpty()){
            upsert standardEntriesMap.values();
        }
        if(!customEntriesMap.isEmpty()){
            upsert customEntriesMap.values();
        }
        if(!productsToUpdate.isEmpty()){
            update productsToUpdate;
        }
    }

    public static void brandAutoFill(List<Product2> newRecords) {
        Map<String, Id> brandNames = new Map<String, Id>();
        for (WebshopBrand__c brand : [SELECT Name, Id FROM WebshopBrand__c WHERE IsMachineBrand__c = TRUE]) {
            brandNames.put(brand.Name, brand.Id);
        }

        List<Product2> unmatchedProducts = new List<Product2>();

        for (Product2 product : newRecords) {
            if (product.isMaschine__c == true) {
                Boolean matched = false;
                for (String brandName : brandNames.keySet()) {
                    if (product.Name.startsWith(brandName)) {
                        product.BrandWebshop__c = brandNames.get(brandName);
                        matched = true;
                        break; 
                    }
                }
                if (!matched) {
                    unmatchedProducts.add(product);
                }
            }
        }
    }

}