public without sharing class QuoteInstallmentPurchasePlanController {
    @AuraEnabled(cacheable=false)
    public static String findAndConnectLatestQuote(String quoteId){
        try {
            Quote qOld = [SELECT Id, AccountId FROM Quote WHERE Id = : quoteId];
            List<Quote> ql = [SELECT Id FROM Quote 
                WHERE Opportunity.StageName = 'Closed Won' AND AccountId = : qOld.AccountId AND IsMachineOffer__c = FALSE ORDER BY Opportunity.CreatedDate DESC LIMIT 1];
            if(!ql.isEmpty()){
                Quote q = new Quote(Id = quoteId, PriceConfiguratorQuote__c = ql[0].Id);
                update q;
                return 'success';
            } else {
                Quote q = new Quote(Id = quoteId, PriceConfiguratorQuote__c = null);
                update q;
                return 'success';
            }
        } catch(Exception e){
            return e.getMessage();
        }
    }

    @AuraEnabled(cacheable=false)
    public static void handleSaveAccountQuote(String contactId, String quoteId, String accountId, Map<String, String> contactData, Map<String, String> quoteData, Map<String, String> accountData){
        if(contactId != null && contactData != null && !contactData.isEmpty()){
            Contact c = new Contact(Id = contactId);
            Map<String, String> fieldTypeMap = getFieldTypeMap('Contact');
            for(String fieldName : contactData.keySet()){
                String lowerFieldName = fieldName.toLowerCase();
                if(fieldTypeMap.containsKey(lowerFieldName)){
                    if(fieldTypeMap.get(lowerFieldName) == 'date'){
                        c.put(fieldName, Date.valueOf(contactData.get(fieldName)));
                    } else if(fieldTypeMap.get(lowerFieldName) == 'datetime'){
                        c.put(fieldName, DateTime.valueOf(contactData.get(fieldName)));
                    } else if(fieldTypeMap.get(lowerFieldName) == 'numeric'){
                        c.put(fieldName, Decimal.valueOf(contactData.get(fieldName)));
                    } else if(fieldTypeMap.get(lowerFieldName) == 'boolean'){
                        c.put(fieldName, String.valueOf(contactData.get(fieldName)) == 'true');
                    } else {
                        c.put(fieldName, String.valueOf(contactData.get(fieldName)));
                    }
                } else if(fieldName.endsWith('__s')){
                    c.put(fieldName, String.valueOf(contactData.get(fieldName)));
                }
            }
            update c;
        }
        if(quoteId != null && quoteData != null && !quoteData.isEmpty()){
            Quote q = new Quote(Id = quoteId);
            Map<String, String> fieldTypeMap = getFieldTypeMap('Quote');
            for(String fieldName : quoteData.keySet()){
                String lowerFieldName = fieldName.toLowerCase();
                if(fieldTypeMap.containsKey(lowerFieldName)){
                    if(fieldTypeMap.get(lowerFieldName) == 'date'){
                        q.put(fieldName, Date.valueOf(quoteData.get(fieldName)));
                    } else if(fieldTypeMap.get(lowerFieldName) == 'datetime'){
                        q.put(fieldName, DateTime.valueOf(quoteData.get(fieldName)));
                    } else if(fieldTypeMap.get(lowerFieldName) == 'numeric'){
                        q.put(fieldName, Decimal.valueOf(quoteData.get(fieldName)));
                    } else if(fieldTypeMap.get(lowerFieldName) == 'boolean'){
                        q.put(fieldName, String.valueOf(quoteData.get(fieldName)) == 'true');
                    } else {
                        q.put(fieldName, String.valueOf(quoteData.get(fieldName)));
                    }
                }
            }
            update q;
        }
        if(accountId != null && accountData != null && !accountData.isEmpty()){
            Account ac = new Account(Id = accountId);
            Map<String, String> fieldTypeMap = getFieldTypeMap('Account');
            for(String fieldName : accountData.keySet()){
                String lowerFieldName = fieldName.toLowerCase();
                if(fieldTypeMap.containsKey(lowerFieldName)){
                    if(fieldTypeMap.get(lowerFieldName) == 'date'){
                        ac.put(fieldName, Date.valueOf(accountData.get(fieldName)));
                    } else if(fieldTypeMap.get(lowerFieldName) == 'datetime'){
                        ac.put(fieldName, DateTime.valueOf(accountData.get(fieldName)));
                    } else if(fieldTypeMap.get(lowerFieldName) == 'numeric'){
                        ac.put(fieldName, Decimal.valueOf(accountData.get(fieldName)));
                    } else if(fieldTypeMap.get(lowerFieldName) == 'boolean'){
                        ac.put(fieldName, String.valueOf(accountData.get(fieldName)) == 'true');
                    } else {
                        ac.put(fieldName, String.valueOf(accountData.get(fieldName)));
                    }
                }
            }
            update ac;
        }
    }

    private static Map<String, String> getFieldTypeMap(String sobjectName) {
        Map<String, String> result = new Map<String, String>();

        Schema.SObjectType objType = Schema.getGlobalDescribe().get(sobjectName);
        if (objType == null) return result;

        Map<String, Schema.SObjectField> fields = objType.getDescribe().fields.getMap();

        for (String fieldName : fields.keySet()) {
            Schema.DisplayType dt = fields.get(fieldName).getDescribe().getType();
            String simpleType;

            switch on dt {
                when Date           { simpleType = 'date'; }
                when DateTime       { simpleType = 'datetime'; }
                when Double,
                    Integer,
                    Long,
                    Currency,
                    Percent         { simpleType = 'numeric'; }
                when Boolean        { simpleType = 'boolean'; }
                when else           { simpleType = 'string'; }
            }

            result.put(fieldName, simpleType);
        }
        return result;
    }

    @AuraEnabled(cacheable=false)
    public static QuoteWrapper getData(String quoteId){
        Quote q = [SELECT Id, OpportunityId, ContactId, AccountId,
            Contact.MachineSelfEmployedSince__c, Contact.MachinePrivateAddress__c, Contact.Birthdate, Contact.FirstName, Contact.LastName,
            Account.Name, Account.ShippingStreet, Account.ShippingCity, Account.ShippingPostalCode, Account.CreatedDate, Account.AccountNumber, 
            Account.ChainType__c, 
            //Account.SalesQuantityLYTotal__c, Account.SalesQuantityCYToday__c, 
            MachineLocation__c,
            Account.MachineCrefoIndex__c,
            Account.MachineCeditLimit__c, 
            MachineTotalFinancingAmount__c,
            MachineRuntimeInMonths__c, MachineDepositMustBePaidUntil__c,
            MachineProducerDiscountTotalInEuro__c, MachineMonthlyRateInEuro__c, MachineCustomerDiscountTotalInEuro__c,
            MachineFinalRateInEuro__c, MachineRoasterDiscountTotalInEuro__c, 
            MachineInterestRates__c, 
            MachineRentalAgreementEuroPerKG__c,
            MachineFinancingChargePerKG__c,
            InstPurchaseAgreementValidUntil__c,
            MachineNotesOnTheContract__c,
            MachineMerchandiseAccountBalance__c, MachineMachineAccountBalance__c, MachineTotalMachineValues__c, 
            MachineSalesExpectationCoffee__c, MachineSalesExpectationCoffeeperYear__c, MachineNetRevenueCurrentYear__c, MachineNetRevenueLastYear__c, 
            MachineDownpaymentBeforeOrAfterOrder__c, MachineDirectDebitCollectionDay1or15__c, InterestOnOutstandingPrice__c,
            MachineRecommendationMachineTeam__c,
            PriceConfiguratorQuote__c
        FROM Quote WHERE Id = : quoteId];
        String profileName = [SELECT Id, Profile.Name FROM User WHERE Id = : UserInfo.getUserId()].Profile?.Name;
        QuoteWrapper wrapper = new QuoteWrapper(q, q.AccountId != null ? q.Account : null, q.ContactId != null ? q.Contact : null, profileName);
        return wrapper;
    }

    public class ProductWrapper{
        @AuraEnabled public Id id {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public Decimal vkPriceCustomer {get; set;}
        @AuraEnabled public Decimal vlPrice {get; set;}
        @AuraEnabled public Decimal rvInPercent {get; set;}
        @AuraEnabled public Decimal rvInPercentDisplay {get; set;}
        @AuraEnabled public Decimal rvInEuro {get; set;}
        @AuraEnabled public Decimal wkzEuroPerKg {get; set;}
        @AuraEnabled public Decimal rentalContactEuroPerKg {get; set;}
        @AuraEnabled public Decimal financingEuroPerKg {get; set;}
        @AuraEnabled public Decimal netSalePrice {get; set;}
        @AuraEnabled public Decimal vsPrice {get; set;}
        @AuraEnabled public Decimal winLossEuroPerKg {get; set;}
        public ProductWrapper(Id id, String name, Decimal vkPriceCustomer, Decimal vlPrice, Decimal rvInPercent, Decimal rvInEuro, Decimal wkzEuroPerKg, Decimal rentalContactEuroPerKg, Decimal financingEuroPerKg, Decimal vsPrice){
            this.id = id;
            this.name = name;
            this.vkPriceCustomer = vkPriceCustomer;
            this.vlPrice = vlPrice;
            this.rvInPercent = rvInPercent;
            this.rvInPercentDisplay = rvInPercent != null ? rvInPercent / 100 : null;
            this.rvInEuro = rvInEuro;
            this.wkzEuroPerKg = wkzEuroPerKg;
            this.rentalContactEuroPerKg = rentalContactEuroPerKg;
            this.financingEuroPerKg = financingEuroPerKg;
            this.netSalePrice = (this.vkPriceCustomer ?? 0) - ( (((this.vkPriceCustomer ?? 0) * (this.rvInPercent ?? 0)) / 100) + (this.rvInEuro ?? 0) + (this.wkzEuroPerKg ?? 0) + (this.rentalContactEuroPerKg ?? 0) + (this.financingEuroPerKg ?? 0) );
            this.vsPrice = vsPrice;
            this.winLossEuroPerKg = (this.netSalePrice ?? 0) - (this.vsPrice ?? 0);
        }
    }

    public class QuoteWrapper{
        @AuraEnabled public Id groupId {get; set;}
        @AuraEnabled public Account accountData {get; set;}
        @AuraEnabled public Contact contactData {get; set;}
        @AuraEnabled public Quote quoteData {get; set;}
        @AuraEnabled public Boolean hasPriceConfiguratorQuote {get; set;}
        @AuraEnabled public Boolean isGLOnly {get; set;}
        @AuraEnabled public Boolean isAdminOrGL {get; set;}
        @AuraEnabled public Boolean isAdminOrMachineTeam {get; set;}
        @AuraEnabled public Boolean hasAccount {get; set;}
        @AuraEnabled public Boolean hasContact {get; set;}
        @AuraEnabled public List<ProductWrapper> products {get; set;}
        @AuraEnabled public Decimal salesQuantityLY {get; set;}
        @AuraEnabled public Decimal salesQuantityCY {get; set;}
        public QuoteWrapper(Quote q, Account ac, Contact con, String profileName){
            this.quoteData = q;
            this.accountData = ac;
            this.contactData = con;
            this.hasPriceConfiguratorQuote = q.PriceConfiguratorQuote__c != null;
            this.hasAccount = ac != null;
            this.hasContact = con != null;
            this.salesQuantityLY = 0;
            this.salesQuantityCY = 0;
            this.isGLOnly = (String.isBlank(profileName) || !profileName.endsWith('dministrator')) && FeatureManagement.checkPermission('QuoteInstallmentGLFields') && !FeatureManagement.checkPermission('QuoteInstallmentMachineTeamFields');
            this.isAdminOrGL = (String.isNotBlank(profileName) && profileName.endsWith('dministrator')) || FeatureManagement.checkPermission('QuoteInstallmentGLFields');
            this.isAdminOrMachineTeam = (String.isNotBlank(profileName) && profileName.endsWith('dministrator')) || FeatureManagement.checkPermission('QuoteInstallmentMachineTeamFields');
            List<ProductWrapper> productWrappers = new List<ProductWrapper>();
            if(this.hasPriceConfiguratorQuote){
                for(Quote nonMachineQuote : [SELECT Id, MachineRentalAgreementEuroPerKG__c,
                    WKZCoffeeOneTimeRuntimeMonths__c, WKZCoffeeOneTimeBonus__c,
                    WKZCoffeeAnnualBonus__c, WKZCoffeeOneTimeTotalRuntime__c,
                    (SELECT Id, Product2Id, Product2.LowestConditionForSalesAreaManager__c, Product2.PreviewPrice__c, Product2.Name, UnitPrice, RefundDiscountInPercent__c, RefundDiscountInEuro__c FROM QuoteLineItems WHERE (NOT Product2.Name  LIKE 'Produkt-Untergruppe%') AND Product2.ProductGroup__r.Name LIKE '%Röstkaffee'),
                    (SELECT Id, Product__r.ProductGroup__r.Name, Product__c, Product__r.LowestConditionForSalesAreaManager__c, Product__r.PreviewPrice__c, Product__r.Name, Price__c, Quote__c, QuoteLineItem__c, QuoteLineItem__r.RefundDiscountInPercent__c, QuoteLineItem__r.RefundDiscountInEuro__c FROM ConditionOverviewHelpers__r WHERE Product__r.ProductGroup__r.Name LIKE '%Röstkaffee')        
                FROM Quote WHERE Id = : q.PriceConfiguratorQuote__c]){
                    productWrappers = processProductWrappers(q, productWrappers, nonMachineQuote);
                }
            } else {
                for(Quote nonMachineQuote : [SELECT Id, MachineRentalAgreementEuroPerKG__c,
                    WKZCoffeeOneTimeRuntimeMonths__c, WKZCoffeeOneTimeBonus__c,
                    WKZCoffeeAnnualBonus__c, WKZCoffeeOneTimeTotalRuntime__c,
                    (SELECT Id, Product2Id, Product2.LowestConditionForSalesAreaManager__c, Product2.PreviewPrice__c, Product2.Name, UnitPrice, RefundDiscountInPercent__c, RefundDiscountInEuro__c FROM QuoteLineItems WHERE (NOT Product2.Name  LIKE 'Produkt-Untergruppe%') AND Product2.ProductGroup__r.Name LIKE '%Röstkaffee'),
                    (SELECT Id, Product__r.ProductGroup__r.Name, Product__c, Product__r.LowestConditionForSalesAreaManager__c, Product__r.PreviewPrice__c, Product__r.Name, Price__c, Quote__c, QuoteLineItem__c, QuoteLineItem__r.RefundDiscountInPercent__c, QuoteLineItem__r.RefundDiscountInEuro__c FROM ConditionOverviewHelpers__r WHERE Product__r.ProductGroup__r.Name LIKE '%Röstkaffee')        
                FROM Quote 
                WHERE Opportunity.StageName = 'Closed Won' AND AccountId = : q.AccountId AND IsMachineOffer__c = FALSE ORDER BY Opportunity.CreatedDate DESC
                LIMIT 1]){
                    productWrappers = processProductWrappers(q, productWrappers, nonMachineQuote);
                    q.PriceConfiguratorQuote__c = nonMachineQuote.Id;
                    update q;
                }
            }
            /*if(this.hasAccount){
                List<BoughtProductGroupsC__c> groups = [SELECT Id, Name, SalesQuantityLYTotal__c, SalesQuantityCYToday__c FROM BoughtProductGroupsC__c WHERE ProductClass__c = 'RÖSTKAFFEE' AND CustomerReferenceID__c = : ac.Id];
                if(!groups.isEmpty()){
                    this.salesQuantityLY = groups[0].SalesQuantityLYTotal__c;
                    this.salesQuantityCY = groups[0].SalesQuantityCYToday__c;
                }
            }*/
            this.products = productWrappers;
        }
    }

    private static List<ProductWrapper> processProductWrappers(Quote q, List<ProductWrapper> productWrappers, Quote nonMachineQuote){
        // WKZ: ((WKZ annual/12) * Runtime Months) / Absatzmenge) + (WKZ einmal / Absatzmenge)
        Decimal wkz = 0;
        if(nonMachineQuote.WKZCoffeeOneTimeTotalRuntime__c != null){
            Decimal amount = (Decimal) nonMachineQuote.WKZCoffeeOneTimeTotalRuntime__c;
            Decimal onetime = (Decimal) nonMachineQuote.WKZCoffeeOneTimeBonus__c ?? 0;
            Decimal annual = (Decimal) nonMachineQuote.WKZCoffeeAnnualBonus__c ?? 0;
            Decimal runtime = (Decimal) nonMachineQuote.WKZCoffeeOneTimeRuntimeMonths__c ?? 0;
            wkz = ((((annual / 12) * runtime) / amount) + (onetime / amount)).setScale(2);
        }

        for(QuoteLineItem qli : nonMachineQuote.QuoteLineItems){
            productWrappers.add(new ProductWrapper(qli.Product2Id, qli.Product2.Name, qli.UnitPrice, qli.Product2.LowestConditionForSalesAreaManager__c, qli.RefundDiscountInPercent__c ?? 0, qli.RefundDiscountInEuro__c ?? 0, wkz, q.MachineRentalAgreementEuroPerKG__c, q.MachineFinancingChargePerKG__c, qli.Product2.PreviewPrice__c));
        }
        for(ConditionOverviewHelper__c helper : nonMachineQuote.ConditionOverviewHelpers__r){
            productWrappers.add(new ProductWrapper(helper.Product__c, helper.Product__r.Name, helper.Price__c, helper.Product__r.LowestConditionForSalesAreaManager__c, helper.QuoteLineItem__r.RefundDiscountInPercent__c ?? 0, helper.QuoteLineItem__r.RefundDiscountInEuro__c, wkz, q.MachineRentalAgreementEuroPerKG__c, q.MachineFinancingChargePerKG__c, helper.Product__r.PreviewPrice__c));
        }
        return productWrappers;
    }
}