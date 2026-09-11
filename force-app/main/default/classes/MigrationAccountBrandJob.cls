public class MigrationAccountBrandJob implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {

    public Map<String, Id> activeBrands = new Map<String, Id>();
    public Database.QueryLocator start(Database.BatchableContext bc){

        for(WebshopBrand__c brand : [SELECT Id, Name FROM WebshopBrand__c WHERE AssortmentExtensionEnabled__c = TRUE]){
            this.activeBrands.put(brand.Name, brand.Id);
        }
        return Database.getQueryLocator([
            SELECT Id, ERPCustomerNumber__c, (SELECT Id, Brand__r.Name FROM AccountBrandAssignments__r)
            FROM Account
            WHERE ERPCustomerNumber__c != NULL
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope){

        List<Account> accounts = (List<Account>)scope;
        Set<String> identifiers = new Set<String>();
        Map<Id, Set<String>> existingBrandsByAcc = new Map<Id, Set<String>>();

        for(Account ac : accounts){
            identifiers.add(ac.ERPCustomerNumber__c);
            Set<String> innerSet = new Set<String>();
            for(AccountBrandAssignment__c aba : ac.AccountBrandAssignments__r){
                innerSet.add(aba.Brand__r.Name);
            }
            existingBrandsByAcc.put(ac.Id, innerSet);
        }

        if(identifiers.isEmpty()) return;

        Map<String, Set<String>> accountToBrands = new Map<String, Set<String>>();

        Set<String> brandNames = this.activeBrands.keySet();
        for(Object rowPre : SourceOrgApi.query(
            'SELECT Id, Brand__c, Brand__r.Name, Account__r.AccountNumber ' + 
            'FROM AccountBrandAssignment__c WHERE Account.AccountNumber IN (\'' +
            String.join(new List<String>(identifiers), '\',\'') + '\') AND Brand__r.Name IN (\'' +
            String.join(new List<String>(brandNames), '\',\'') + '\')'
        )){
            Map<String,Object> row = (Map<String,Object>)rowPre;
            Map<String,Object> acc = (Map<String,Object>) row.get('Account');
            Map<String,Object> brd = (Map<String,Object>) row.get('Brand__r');
            String accountNumber = (String)acc.get('AccountNumber');
            String brandName = (String)brd.get('Name');
            if(accountNumber == null) continue;
            Set<String> innerSet = accountToBrands.containsKey(accountNumber) ? accountToBrands.get(accountNumber) : new Set<String>();
            innerSet.add(brandName);
            accountToBrands.put(accountNumber, innerSet);
        }

        List<AccountBrandAssignment__c> abaToInsert = new List<AccountBrandAssignment__c>();
        for(Account ac : accounts){
            Set<String> existingBrands = existingBrandsByAcc.containsKey(ac.Id) ? existingBrandsByAcc.get(ac.Id) : new Set<String>();
            if(accountToBrands.containsKey(ac.ERPCustomerNumber__c)){
                for(String newBrand : accountToBrands.get(ac.ERPCustomerNumber__c)){
                    if(!existingBrands.contains(newBrand) && this.activeBrands.containsKey(newBrand)){
                        abaToInsert.add(new AccountBrandAssignment__c(
                            Account__c = ac.Id,
                            Brand__c = this.activeBrands.get(newBrand)
                        ));
                    }
                }
            }
        }
        if(!abaToInsert.isEmpty()){
            Database.insert(abaToInsert, false);
        }
    }

    public void finish(Database.BatchableContext bc){
        // Do nothing
    }
}