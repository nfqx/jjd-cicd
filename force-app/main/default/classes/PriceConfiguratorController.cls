public without sharing class PriceConfiguratorController {

    private static final Pricebook2 STANDARD_PRICEBOOK_COPY = [SELECT Id FROM Pricebook2 WHERE Name = 'J.J. Darboven Webshop Price Book' LIMIT 1];
    private static final List<String> EDIT_STATUSES = new List<String>{'Draft'};
    private static final Map<Integer, String> MAX_WARNING_MAP = new Map<Integer, String>{
        1 => 'VL',
        2 => 'NVL',
        3 => 'NVL',
        4 => 'Vorstand'
    };

    @AuraEnabled(cacheable=false)
    public static String createOffer(
        String opportunityId,
        String quoteId,
        Map<String, Object> params,
        Map<String, Object> machineParams,
        String numTypes,
        String initialEquipmentData,
        String conditionProductData,
        Boolean machineSurchargeCalculation,
        Boolean hasMachineData,
        String machinesData,
        String specialMachinesData,
        String industry,
        Boolean showSimulation,
        Boolean showRefund,
        String machineOfferQuoteId,
        Boolean isDependentChainMember
    ){
        try{
            Opportunity opp = null;
            if(quoteId != null){
                Quote oq = [SELECT Id, Status, Opportunity.Id, Opportunity.Name FROM Quote WHERE Id = : quoteId];
                opp = oq.Opportunity;
                quoteId = EDIT_STATUSES.contains(oq.Status) ? quoteId : null;
            } else {
                opp = [SELECT Id, Name FROM Opportunity WHERE Id = : opportunityId];
            }
            if(opp != null){
                List<OpportunityContactRole> contactRoles = [SELECT Id, ContactId FROM OpportunityContactRole WHERE IsPrimary = TRUE AND OpportunityId = : opp.Id];
                Map<String, NumTypesWrapper> numTypesMap = (Map<String, NumTypesWrapper>) System.JSON.deserialize(numTypes, Map<String, NumTypesWrapper>.class);
                List<InitialEquipmentWrapper> initialEquipmentWrappers = (List<InitialEquipmentWrapper>) System.JSON.deserialize(initialEquipmentData, List<InitialEquipmentWrapper>.class);
                List<ConditionProductWrapper> conditionProductWrappers = (List<ConditionProductWrapper>) System.JSON.deserialize(conditionProductData, List<ConditionProductWrapper>.class);
                /*List<MachineConfiguratorController.MachineAndAccessoireWrapper> machinesWrapper = null;
                List<MachineConfiguratorController.MachineAndAccessoireWrapper> specialMachinesWrapper = null;
                if(hasMachineData){
                    machinesWrapper = (List<MachineConfiguratorController.MachineAndAccessoireWrapper>) System.JSON.deserialize(machinesData, List<MachineConfiguratorController.MachineAndAccessoireWrapper>.class);
                    specialMachinesWrapper = (List<MachineConfiguratorController.MachineAndAccessoireWrapper>) System.JSON.deserialize(specialMachinesData, List<MachineConfiguratorController.MachineAndAccessoireWrapper>.class);
                }*/
                // Retrieve products
                Set<String> productSet = new Set<String>();
                Set<String> productSetInitialOnly = new Set<String>();
                Map<Id, List<Product2>> productSubgroupMap = new Map<Id, List<Product2>>();
                //List<Konditionsblatt_Helper__c> conditionHelpersToInsert = new List<Konditionsblatt_Helper__c>();
                Set<Id> conditionHelpersToInsertSet = new Set<Id>();
                for(InitialEquipmentWrapper wrapper : initialEquipmentWrappers){
                    if(String.isNotBlank(wrapper.product)){
                        productSet.add(String.valueOf(wrapper.product));
                        productSetInitialOnly.add(String.valueOf(wrapper.product));
                    }
                }
                for(ConditionProductWrapper wrapper : conditionProductWrappers){
                    if(String.isNotBlank(wrapper.product)){
                        productSet.add(String.valueOf(wrapper.product));
                    }
                }
                for(Product2 prod : [SELECT Id, ProductSubgroup__c, ProductSubgroup__r.GenerateConditionsSheet__c, /*Minimum_Price__c,*/ LowestConditionForSalesAreaManager__c, LowestConditionForSalesManager__c FROM Product2 WHERE ProductSubgroup__c IN : productSet AND (ProductClass = 'VariationParent' OR ProductClass = 'Simple') AND IsActive = TRUE ORDER BY Name]){
                    List<Product2> products = productSubgroupMap.containsKey(prod.ProductSubgroup__c) ? productSubgroupMap.get(prod.ProductSubgroup__c) : new List<Product2>();
                    products.add(prod);
                    productSubgroupMap.put(prod.ProductSubgroup__c, products);
                }
                
                Map<Id, PricebookEntry> standardPricebookEntries = new Map<Id, PricebookEntry>();
                for(PricebookEntry pbe : [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE IsActive = TRUE AND Pricebook2Id = : STANDARD_PRICEBOOK_COPY.Id AND (Product2.ProductClass = 'VariationParent' OR Product2.ProductClass = 'Simple' OR Product2.Name LIKE 'Produkt-Untergruppe:%')]){
                    standardPricebookEntries.put(pbe.Product2Id, pbe);
                }
                // Quote Creation
                Quote newQuote = new Quote(
                    OpportunityId = opp.Id,
                    OwnerId = UserInfo.getUserId(),
                    Name = opp.Name + ' Quote ' + System.today().format(),
                    Status = 'Draft'
                );
                newQuote.Lifetime__c = params.containsKey('runtimeMonths') ? Integer.valueOf(String.valueOf(params.get('runtimeMonths'))) : null;
                //newQuote.ValidFrom__c = params.containsKey('validFrom') ? Date.valueOf(String.valueOf(params.get('validFrom'))) : null;
                newQuote.Pricebook2Id = STANDARD_PRICEBOOK_COPY.Id;
                newQuote.AdditionalAgreements__c = String.valueOf(params.get('showAdditionalAgreements')) == 'true';
                newQuote.DishSales__c = String.valueOf(params.get('tableware')) == 'true';
                /*
                newQuote.Leihgestellung_angeboten__c = String.valueOf(params.get('showAdditionalAgreements')) == 'true' && String.valueOf(params.get('additionalFrameLease')) == 'true';
                newQuote.OfferTasting__c = String.valueOf(params.get('showAdditionalAgreements')) == 'true' && String.valueOf(params.get('additionalOfferTasting')) == 'true';
                newQuote.OfferFinancing__c = String.valueOf(params.get('showAdditionalAgreements')) == 'true' && String.valueOf(params.get('additionalOfferFinancing')) == 'true';
                newQuote.OfferTraining__c = String.valueOf(params.get('showAdditionalAgreements')) == 'true' && String.valueOf(params.get('additionalOfferTraining')) == 'true';
                newQuote.Leihgestellung_Details__c = String.valueOf(params.get('showAdditionalAgreements')) == 'true' && String.valueOf(params.get('additionalFrameLease')) == 'true' ? String.valueOf(params.get('additionalFrameLeaseText')) : null;
                */
                newQuote.OtherAdditionalAggreeementsSpecified__c = String.valueOf(params.get('showAdditionalAgreements')) == 'true' && String.valueOf(params.get('additionalOther')) == 'true';
                newQuote.OtherAdditionalAggreeementsDetails__c = String.valueOf(params.get('showAdditionalAgreements')) == 'true' && String.valueOf(params.get('additionalOther')) == 'true' ? String.valueOf(params.get('additionalOtherText')) : null;
                // CRM-1524
                newQuote.QualityCheck__c = String.valueOf(params.get('showAdditionalAgreements')) == 'true' && String.valueOf(params.get('additionalQualityVisit')) == 'true';
                newQuote.Interval__c = newQuote.QualityCheck__c ? String.valueOf(params.get('additionalQualityVisitInterval')) : null;
                newQuote.InitialReview__c = newQuote.QualityCheck__c ? Date.valueOf(String.valueOf(params.get('additionalQualityVisitInitial'))) : null;
                newQuote.ProfessionalSetupRequested__c = newQuote.QualityCheck__c ? String.valueOf(params.get('additionalQualityVisitSettingRequested')) == 'true' : false;
                // CRM-1524 End
                if(!isDependentChainMember){
                    newQuote.PurchaseQuantityCoffee__c = numTypesMap.containsKey('coffee') ? numTypesMap.get('coffee').quantities : null;
                    newQuote.PurchaseQuantityTea__c = numTypesMap.containsKey('tea') ? numTypesMap.get('tea').quantities : null;
                    newQuote.PurchaseQuantityHotChoc__c = numTypesMap.containsKey('cocoa') ? numTypesMap.get('cocoa').quantities : null;
                    newQuote.PurchaseQuantityOther__c = numTypesMap.containsKey('other') ? numTypesMap.get('other').quantities : null;
                    //newQuote.InheritedCoffeeVolumeCommitmentKg__c = null;
                    //newQuote.InheritedTeaVolumeCommitmentEur__c = null;
                    //newQuote.InheritedCocoaVolumeCommitmentKg__c = null;
                    //newQuote.InheritedOtherGoodsVolumeCommitmentEur__c = null;
                } else {
                    newQuote.PurchaseQuantityCoffee__c = numTypesMap.containsKey('coffee') ? numTypesMap.get('coffee').quantities : null;
                    newQuote.PurchaseQuantityTea__c = numTypesMap.containsKey('tea') ? numTypesMap.get('tea').quantities : null;
                    newQuote.PurchaseQuantityHotChoc__c = numTypesMap.containsKey('cocoa') ? numTypesMap.get('cocoa').quantities : null;
                    newQuote.PurchaseQuantityOther__c = numTypesMap.containsKey('other') ? numTypesMap.get('other').quantities : null;
                    //newQuote.InheritedCoffeeVolumeCommitmentKg__c = numTypesMap.containsKey('coffeeInherit') ? numTypesMap.get('coffeeInherit').quantities : null;
                    //newQuote.InheritedTeaVolumeCommitmentEur__c = numTypesMap.containsKey('teaInherit') ? numTypesMap.get('teaInherit').quantities : null;
                    //newQuote.InheritedCocoaVolumeCommitmentKg__c = numTypesMap.containsKey('cocoaInherit') ? numTypesMap.get('cocoaInherit').quantities : null;
                    //newQuote.InheritedOtherGoodsVolumeCommitmentEur__c = numTypesMap.containsKey('otherInherit') ? numTypesMap.get('otherInherit').quantities : null;
                }
                newQuote.PurchaseQuantityCoffeeStatistical__c = numTypesMap.containsKey( 'coffee' ) ? numTypesMap.get('coffee').quantities : null;
                newQuote.PurchaseQuantityTeaStatistical__c = numTypesMap.containsKey('tea') ? numTypesMap.get('tea').quantities : null;
                newQuote.PurchaseQuantityHotChocStatistical__c = numTypesMap.containsKey( 'cocoa' ) ? numTypesMap.get('cocoa').quantities : null;
                newQuote.PurchaseQuantityOtherStatistical__c = numTypesMap.containsKey( 'other' ) ? numTypesMap.get('other').quantities : null;

                newQuote.NrOfDifferentCoffeePreps__c = numTypesMap.containsKey('coffee') ? numTypesMap.get('coffee').selection : null;
                newQuote.NrOfDifferentTeaProducts__c = numTypesMap.containsKey('tea') ? numTypesMap.get('tea').selection : null;
                newQuote.NrOfDifferentHotChocProducts__c = numTypesMap.containsKey('cocoa') ? numTypesMap.get('cocoa').selection : null;
                newQuote.NrOfDifferentOtherProducts__c = numTypesMap.containsKey('other') ? numTypesMap.get('other').selection : null;

                newQuote.BrandDisplayTable__c = params.containsKey('hasOfferOnTable') ? String.valueOf(params.get('hasOfferOnTable')) == System.Label.GeneralYes : false;
                newQuote.BrandDisplayLocation__c = params.containsKey('hasOfferInProperty') ? String.valueOf(params.get('hasOfferInProperty')) == System.Label.GeneralYes : false;
                newQuote.BrandDisplayMenu__c = params.containsKey('hasMenuLogo') ? String.valueOf(params.get('hasMenuLogo')) == System.Label.GeneralYes : false;
                newQuote.DigitalWayOfOrdering__c = params.containsKey('hasDigitalRequired') ? String.valueOf(params.get('hasDigitalRequired')) == System.Label.GeneralYes : false;
                newQuote.SalesCategory__c = industry;
                newQuote.SimulatedDiscount__c = params.containsKey('discount') && String.valueOf(params.get('discount')) != '0' ? String.valueOf(params.get('discount')) : null;                    
                newQuote.DiscountSimulatedDiscount__c = params.containsKey('simRebateDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('simRebateDiscountTotal'))) : null;
                newQuote.Simulation__c = false;
                newQuote.SimulatedGrowthInPercent__c = null;
                newQuote.SimulatedGrowthInSales__c = null;
                newQuote.DiscountSimulatedGrowth__c = null;
                if(showSimulation == true){
                    newQuote.Simulation__c = true;
                    newQuote.SimulatedGrowthInPercent__c = params.containsKey('growthPercent') && String.valueOf(params.get('growthPercent')) != '0' ? String.valueOf(params.get('growthPercent')) : null;
                    newQuote.SimulatedGrowthInSales__c = params.containsKey('simulatedRevenue') && String.valueOf(params.get('simulatedRevenue')) != '0' ? String.valueOf(params.get('simulatedRevenue')) : null; 
                    newQuote.DiscountSimulatedGrowth__c = params.containsKey('simGrowthDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('simGrowthDiscountTotal'))) : null;
                } 
                Boolean coffeeRefundSet = false;
                Boolean teaRefundSet = false;
                newQuote.Refund__c = false;
                newQuote.CoffeeRefundType__c = null;
                newQuote.TeaRefundType__c = null;
                newQuote.CoffeeRefundBasis__c = null;
                newQuote.WKZCoffeeOneTimeTotalRuntime__c = null;
                newQuote.WKZCoffeeOneTimeRuntimeMonths__c = null;
                newQuote.WKZCoffeeOneTimeBonus__c = null;
                newQuote.WKZCoffeeAnnualBonus__c = null;
                newQuote.TeaRefundBasis__c = null;
                newQuote.WKZTeaOneTimeTotalRuntime__c = null;
                newQuote.WKZTeaOneTimeRuntimeMonths__c = null;
                newQuote.WKZTeaOneTimeBonus__c = null;
                newQuote.WKZTeaAnnualBonus__c = null;
                if(showRefund == true){
                    newQuote.Refund__c = true;
                    newQuote.CoffeeRefundType__c = params.containsKey('coffeeRefundType') && params.get('coffeeRefundType') != null ? String.valueOf(params.get('coffeeRefundType')) : null;
                    newQuote.TeaRefundType__c = params.containsKey('teaRefundType') && params.get('teaRefundType') != null ? String.valueOf(params.get('teaRefundType')) : null;
                    if(String.isNotBlank(newQuote.CoffeeRefundType__c)){
                        coffeeRefundSet = true;
                        newQuote.CoffeeRefundBasis__c = params.containsKey('coffeeRefundLevel') ? Integer.valueOf(String.valueOf(params.get('coffeeRefundLevel'))) : null;
                        newQuote.WKZCoffeeOneTimeTotalRuntime__c = params.containsKey('coffeeWkzOneTimeAmount') ? Integer.valueOf(String.valueOf(params.get('coffeeWkzOneTimeAmount'))) : null;
                        newQuote.WKZCoffeeOneTimeRuntimeMonths__c = params.containsKey('coffeeWkzRuntime') ? Integer.valueOf(String.valueOf(params.get('coffeeWkzRuntime'))) : null;
                        newQuote.WKZCoffeeOneTimeBonus__c = params.containsKey('coffeeWkzOneTimeRefund') ? Integer.valueOf(String.valueOf(params.get('coffeeWkzOneTimeRefund'))) : null;
                        newQuote.WKZCoffeeAnnualBonus__c = params.containsKey('coffeeWkzAnnualRefund') ? Integer.valueOf(String.valueOf(params.get('coffeeWkzAnnualRefund'))) : null;
                    }
                    if(String.isNotBlank(newQuote.TeaRefundType__c)){
                        teaRefundSet = true;
                        newQuote.TeaRefundBasis__c = params.containsKey('teaRefundLevel') ? Integer.valueOf(String.valueOf(params.get('teaRefundLevel'))) : null;
                        newQuote.WKZTeaOneTimeTotalRuntime__c = params.containsKey('teaWkzOneTimeAmount') ? Integer.valueOf(String.valueOf(params.get('teaWkzOneTimeAmount'))) : null;
                        newQuote.WKZTeaOneTimeRuntimeMonths__c = params.containsKey('teaWkzRuntime') ? Integer.valueOf(String.valueOf(params.get('teaWkzRuntime'))) : null;
                        newQuote.WKZTeaOneTimeBonus__c = params.containsKey('teaWkzOneTimeRefund') ? Integer.valueOf(String.valueOf(params.get('teaWkzOneTimeRefund'))) : null;
                        newQuote.WKZTeaAnnualBonus__c = params.containsKey('teaWkzAnnualRefund') ? Integer.valueOf(String.valueOf(params.get('teaWkzAnnualRefund'))) : null;
                    }
                }
                newQuote.ApprovalLevel__c = params.containsKey('maxWarning') && MAX_WARNING_MAP.containsKey(Integer.valueOf(params.get('maxWarning'))) ? MAX_WARNING_MAP.get(Integer.valueOf(params.get('maxWarning'))) : null;
                newQuote.CoffeeSurcharge__c = params.containsKey('kgChargeCalculated') ? Decimal.valueOf(String.valueOf(params.get('kgChargeCalculated'))) : null;
                newQuote.HighestPossibleTeaDiscount__c = params.containsKey('maxTeaDiscount') ? Decimal.valueOf(String.valueOf(params.get('maxTeaDiscount'))) : null;
                newQuote.GrantedTeaDiscount__c = params.containsKey('totalTeaDiscount') ? Decimal.valueOf(String.valueOf(params.get('totalTeaDiscount'))) : null;
                if(!isDependentChainMember){
                    newQuote.DiscountPurchaseQuantityCoffee__c = params.containsKey('coffeeQuantityDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('coffeeQuantityDiscountTotal'))) : null;
                    newQuote.DiscountPurchaseQuantityOther__c = params.containsKey('otherQuantityDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('otherQuantityDiscountTotal'))) : null;
                    newQuote.DiscountPurchaseQuantityTea__c = params.containsKey('teaQuantityDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('teaQuantityDiscountTotal'))) : null;
                    newQuote.DiscountPurchaseQuantityHotChocolate__c = params.containsKey('cocoaQuantityDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('cocoaQuantityDiscountTotal'))) : null;
                    //newQuote.InheritedCoffeeVolumeDiscountPct__c = params.containsKey('coffeeQuantityDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('coffeeQuantityDiscountTotal'))) : null;
                    //newQuote.InheritedOtherGoodsVolumeDiscountPct__c = params.containsKey('otherQuantityDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('otherQuantityDiscountTotal'))) : null;
                    //newQuote.InheritedTeaVolumeCommitmentEur__c = params.containsKey('teaQuantityDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('teaQuantityDiscountTotal'))) : null;
                    //newQuote.InheritedCocoaVolumeDiscountPct__c = params.containsKey('cocoaQuantityDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('cocoaQuantityDiscountTotal'))) : null;
                } else {
                    newQuote.DiscountPurchaseQuantityCoffee__c = null;
                    newQuote.DiscountPurchaseQuantityOther__c = null;
                    newQuote.DiscountPurchaseQuantityTea__c = null;
                    newQuote.DiscountPurchaseQuantityHotChocolate__c = null;
                    //newQuote.InheritedCoffeeVolumeDiscountPct__c = params.containsKey('coffeeQuantityDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('coffeeQuantityDiscountTotal'))) : null;
                    //newQuote.InheritedOtherGoodsVolumeDiscountPct__c = params.containsKey('otherQuantityDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('otherQuantityDiscountTotal'))) : null;
                    //newQuote.InheritedTeaVolumeCommitmentEur__c = params.containsKey('teaQuantityDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('teaQuantityDiscountTotal'))) : null;
                    //newQuote.InheritedCocoaVolumeDiscountPct__c = params.containsKey('cocoaQuantityDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('cocoaQuantityDiscountTotal'))) : null;
                }
                newQuote.DiscountDigitalOrdering__c = params.containsKey('brandingDigitalDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('brandingDigitalDiscountTotal'))) : null;
                newQuote.DiscountBaseDiscountCoffee__c = params.containsKey('coffeeBaseDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('coffeeBaseDiscountTotal'))) : null;
                newQuote.DiscountBaseDiscountOther__c = params.containsKey('otherBaseDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('otherBaseDiscountTotal'))) : null;
                newQuote.DiscountBaseDiscountTea__c = params.containsKey('teaBaseDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('teaBaseDiscountTotal'))) : null;
                newQuote.DiscountBaseDiscountHotChocolate__c = params.containsKey('cocoaBaseDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('cocoaBaseDiscountTotal'))) : null;
                newQuote.DiscountIndexCondition__c = params.containsKey('baseConditionDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('baseConditionDiscountTotal'))) : null;
                newQuote.DiscountBrandRepresentationTable__c = params.containsKey('brandingTableDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('brandingTableDiscountTotal'))) : null;
                newQuote.DiscountBrandRepresentationOnSite__c = params.containsKey('brandingPropertyDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('brandingPropertyDiscountTotal'))) : null;
                newQuote.DiscountBrandRepresentationMenu__c = params.containsKey('brandingMenuDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('brandingMenuDiscountTotal'))) : null;
                newQuote.DiscountVariousCoffeeAccessories__c = params.containsKey('coffeeSelectionDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('coffeeSelectionDiscountTotal'))) : null;
                newQuote.DiscountVariousMiscellaneousItems__c = params.containsKey('otherSelectionDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('otherSelectionDiscountTotal'))) : null;
                newQuote.DiscountVariousTeaItems__c = params.containsKey('teaSelectionDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('teaSelectionDiscountTotal'))) : null;
                newQuote.DiscountVariousDrinkingChocolates__c = params.containsKey('cocoaSelectionDiscountTotal') ? Decimal.valueOf(String.valueOf(params.get('cocoaSelectionDiscountTotal'))) : null;
                newQuote.TypeOfChain__c = params.containsKey('customerType') && String.valueOf(params.get('customerType')) != 'none' ? String.valueOf(params.get('customerType')) : null;
                newQuote.TotalAmountMaschine__c = null;
                newQuote.ContactId = null;
                /*if(hasMachineData ){
                    Decimal machineTotal = 0;
                    for(MachineConfiguratorController.MachineAndAccessoireWrapper wrapper : machinesWrapper){
                        if(wrapper.id != null && wrapper.rowTotal != null){
                            machineTotal += wrapper.rowTotal;
                        }
                    }
                    for(MachineConfiguratorController.MachineAndAccessoireWrapper wrapper : specialMachinesWrapper){
                        if(wrapper.rowTotal != null){
                            machineTotal += wrapper.rowTotal;
                        }
                    }
                    newQuote.TotalAmountMaschine__c = machineTotal;
                }*/
                if(!contactRoles.isEmpty()){
                    newQuote.ContactId = contactRoles[0].ContactId;
                }
                Database.DMLOptions dml = new Database.DMLOptions();
                dml.allowFieldTruncation = true;
                Database.SaveResult sr = null;
                if(String.isNotBlank(quoteId)){
                    newQuote.Id = quoteId;
                    sr = Database.update(newQuote, dml);
                } else {
                    sr = Database.insert(newQuote, dml);
                }
                if(sr.isSuccess() && newQuote.Id != null){
                    try {
                        if(String.isNotBlank(quoteId)){
                            delete [SELECT Id FROM QuoteLineItem WHERE QuoteId = : quoteId];
                            //delete [SELECT Id FROM Erstausstattung__c WHERE Angebot__c = : quoteId];
                            //delete [SELECT Id FROM Konditionsblatt_Helper__c WHERE Angebot__c = : quoteId];
                        }  
                        if(String.isNotBlank(quoteId) && String.isNotBlank(machineOfferQuoteId) && !hasMachineData){
                            delete [SELECT Id FROM Quote WHERE Id = : machineOfferQuoteId];
                            machineOfferQuoteId = null;
                        }
                        // Quote Line Item Creation
                        Map<Id, QuoteLineItem> quoteLineItems = new Map<Id, QuoteLineItem>();
                        /*Map<Id, Erstausstattung__c> initialEquipmentRecords = new Map<Id, Erstausstattung__c>();
                        for(InitialEquipmentWrapper wrapper : initialEquipmentWrappers){
                            if(String.isNotBlank(wrapper.product)){
                                if(!initialEquipmentRecords.containsKey(wrapper.product) || initialEquipmentRecords.get(wrapper.product).Preis__c > wrapper.previewPrice){
                                    if(standardPricebookEntries.containsKey(wrapper.product)){
                                        initialEquipmentRecords.put(wrapper.product, new Erstausstattung__c(
                                            Angebot__c = newQuote.Id,
                                            Produkt__c = wrapper.product,
                                            Menge__c = wrapper.quantity,
                                            Preis__c = wrapper.previewPrice,
                                            F_r_Erstbestellung_markiert__c = wrapper.markForInitialOrder ==  'true' || wrapper.markForInitialOrder == System.Label.GeneralYes,
                                            GrantedTeaDiscount__c = wrapper.teaDiscount
                                        ));
                                    }
                                }
                            }
                        }*/
                        for(ConditionProductWrapper wrapper : conditionProductWrappers){
                            if(String.isNotBlank(wrapper.product)){
                                if(!productSubgroupMap.containsKey(wrapper.product)){
                                    // Product
                                    if(standardPricebookEntries.containsKey(wrapper.product)){
                                        if(!quoteLineItems.containsKey(wrapper.product) || quoteLineItems.get(wrapper.product).UnitPrice > wrapper.offerPrice){
                                            quoteLineItems.put(wrapper.product, new QuoteLineItem(
                                                QuoteId = newQuote.Id,
                                                Product2Id = wrapper.product,
                                                Quantity = 1,
                                                UnitPrice = wrapper.offerPrice,
                                                DiscountInPercent__c = (wrapper.rebate ?? 0) * 100, // Use Custom Field as otherwise price calculation might be distraught!
                                                CustomListPrice__c = wrapper.basePrice,
                                                CustomTotalPrice__c = wrapper.offerPrice,
                                                SpecialDiscount__c = wrapper.specialRebate,
                                                SpecialDiscountInPercent__c = wrapper.specialRebatePercent,
                                                //Aufschlag_Gesamt_alt__c = wrapper.totalAddition,
                                                ProductGroup__c = wrapper.productGroup,
                                                ProductSubgroup__c = wrapper.productSubgroup,
                                                AppliedMachineSurcharge__c = machineSurchargeCalculation && wrapper.productGroup == 'Röstkaffee' ? (params.containsKey('coffeeSurchargeMachine') ? Decimal.valueOf(String.valueOf(params.get('coffeeSurchargeMachine'))) : null) : null,
                                                //Set_as_configuration__c = true,
                                                //R_ckverg_tung_Rabatt_in__c = (coffeeRefundSet && wrapper.productGroup == 'Röstkaffee') || (teaRefundSet && wrapper.productGroup == 'Tee') ? wrapper.refundPercent : null,
                                                //R_ckverg_tung_Rabatt_in_Euro__c  = (coffeeRefundSet && wrapper.productGroup == 'Röstkaffee') || (teaRefundSet && wrapper.productGroup == 'Tee') ? wrapper.refundAmount : null,
                                                ApprovalLevel__c = MAX_WARNING_MAP.containsKey(wrapper.warningLevel) ? MAX_WARNING_MAP.get(wrapper.warningLevel) : null,
                                                AppliedCoffeeSurcharge__c = wrapper.productGroup == 'Röstkaffee' ? wrapper.coffeeKgCharge : 0,
                                                PricebookEntryId = standardPricebookEntries.get(wrapper.product).Id,
                                                IsSubgroup__c = FALSE,
                                                IndividualCondition__c = wrapper.individualCondition
                                            ));
                                        }
                                    }
                                } else{
                                    // Subgroup
                                    if(standardPricebookEntries.containsKey(wrapper.product)){
                                        if(!quoteLineItems.containsKey(wrapper.product)){
                                            // Subgroup itself
                                            quoteLineItems.put(wrapper.product, new QuoteLineItem(
                                                QuoteId = newQuote.Id,
                                                Product2Id = wrapper.product,
                                                Quantity = 1,
                                                UnitPrice = wrapper.offerPrice,
                                                Discount = (wrapper.rebate ?? 0) * 100, // Percent field
                                                CustomListPrice__c = wrapper.basePrice,
                                                CustomTotalPrice__c = wrapper.offerPrice,
                                                SpecialDiscount__c = wrapper.specialRebate,
                                                SpecialDiscountInPercent__c = wrapper.specialRebatePercent,
                                                //Aufschlag_Gesamt_alt__c = wrapper.totalAddition,
                                                ProductGroup__c = wrapper.productGroup,
                                                ProductSubgroup__c = wrapper.productSubgroup,
                                                AppliedMachineSurcharge__c = machineSurchargeCalculation && wrapper.productGroup == 'Röstkaffee' ? (params.containsKey('coffeeSurchargeMachine') ? Decimal.valueOf(String.valueOf(params.get('coffeeSurchargeMachine'))) : null) : null,
                                                //Set_as_configuration__c = true,
                                                //R_ckverg_tung_Rabatt_in__c = (coffeeRefundSet && wrapper.productGroup == 'Röstkaffee') || (teaRefundSet && wrapper.productGroup == 'Tee') ?  wrapper.refundPercent : null,
                                                //R_ckverg_tung_Rabatt_in_Euro__c  = (coffeeRefundSet && wrapper.productGroup == 'Röstkaffee') || (teaRefundSet && wrapper.productGroup == 'Tee') ?  wrapper.refundAmount : null,
                                                ApprovalLevel__c = MAX_WARNING_MAP.containsKey(wrapper.warningLevel) ? MAX_WARNING_MAP.get(wrapper.warningLevel) : null,
                                                AppliedCoffeeSurcharge__c = wrapper.productGroup == 'Röstkaffee' ? wrapper.coffeeKgCharge : 0,
                                                PricebookEntryId = standardPricebookEntries.get(wrapper.product).Id,
                                                IsSubgroup__c = TRUE
                                            ));
                                        }
                                    }
                                }
                            }
                        }
                        /*if(!initialEquipmentRecords.isEmpty()){
                            insert initialEquipmentRecords.values();
                        }*/
                        if(!quoteLineItems.isEmpty()){
                            insert quoteLineItems.values();
                        }            
                        for(ConditionProductWrapper wrapper : conditionProductWrappers){
                            if(String.isNotBlank(wrapper.product)){
                                if(productSubgroupMap.containsKey(wrapper.product) && quoteLineItems.containsKey(wrapper.product)){
                                    // Subgroup child items
                                    for(Product2 prod : productSubgroupMap.get(wrapper.product)){
                                        if(prod.ProductSubgroup__r.GenerateConditionsSheet__c){
                                            //if(!conditionHelpersToInsertSet.contains(prod.Id) && !quoteLineItems.containsKey(prod.Id)){
                                            if(!quoteLineItems.containsKey(prod.Id)){
                                                Decimal skonto = newQuote.DiscountSimulatedDiscount__c == null ? 0 : newQuote.DiscountSimulatedDiscount__c / 100;
                                                if(wrapper.offerPrice != null && wrapper.offerPrice > 0){
                                                    // Unified Price
                                                    /*conditionHelpersToInsert.add(new Konditionsblatt_Helper__c(
                                                        Angebot__c = newQuote.Id,
                                                        Produkt__c = prod.Id,
                                                        Preis__c = wrapper.offerPrice,
                                                        Preis_abzgl_Skonto__c =  wrapper.offerPrice - (wrapper.offerPrice * skonto),
                                                        QuoteLineItem__c = quoteLineItems.get(wrapper.product).Id
                                                    ));
                                                    conditionHelpersToInsertSet.add(prod.Id);*/
                                                } else {
                                                    // Non Unified Price
                                                    if(standardPricebookEntries.containsKey(prod.Id) && standardPricebookEntries.get(prod.Id).UnitPrice != null){
                                                        Decimal prodListPrice = standardPricebookEntries.get(prod.Id).UnitPrice;
                                                        Decimal preDiscount = (wrapper.coffeeBaseDiscount + wrapper.teaBaseDiscount + wrapper.cocoaBaseDiscount + wrapper.otherBaseDiscount ) / 100;
                                                        if(wrapper.productGroup == 'Röstkaffee'){
                                                            preDiscount += (wrapper.baseConditionDiscount / 100);
                                                        }
                                                        Decimal coffeeCharge = wrapper.productGroup == 'Röstkaffee' ? wrapper.coffeeKgCharge : 0;
                                                        Decimal rebate = wrapper.rebate != null ? wrapper.rebate : 0;
                                                        Decimal calcPriceOne =  (prodListPrice - (prodListPrice * preDiscount));
                                                        Decimal calcPrice = (calcPriceOne - (calcPriceOne * rebate)) + coffeeCharge;
                                                        /*conditionHelpersToInsert.add(new Konditionsblatt_Helper__c(
                                                            Angebot__c = newQuote.Id,
                                                            Produkt__c = prod.Id,
                                                            Preis__c = calcPrice,
                                                            Preis_abzgl_Skonto__c =  calcPrice - (calcPrice * skonto)
                                                        ));
                                                        conditionHelpersToInsertSet.add(prod.Id);*/
                                                    }
                                                } 
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        /*if(!conditionHelpersToInsert.isEmpty()){
                            insert conditionHelpersToInsert;
                        }
                        if(hasMachineData){
                            if(machinesData != null && !machineParams.isEmpty()){
                                String recordId = MachineConfiguratorController.createOffer(opportunityId, machinesData, specialMachinesData, machineParams, machineOfferQuoteId, machineSurchargeCalculation);
                                newQuote.LinkedMachineOffer__c = recordId;
                                update newQuote;
                            }
                        }*/
                        return newQuote.Id;
                    } catch(Exception e){
                        delete newQuote;
                        System.debug('Error: ' + e.getMessage().replace('n\'t', 'n not'));
                        return 'Error: ' + e.getMessage().replace('n\'t', 'n not');
                    }
                } else {
                    insert new ErrorLogging__c(
                        Error__c = sr.getErrors()[0].getMessage().replace('n\'t', 'n not'),
                        RecordIDs__c = opportunityId,
                        ProcessName__c = 'PriceConfiguratorController.createOffer()'
                    );
                    System.debug('Error: ' + sr.getErrors()[0].getMessage().replace('n\'t', 'n not'));
                    return 'Error: ' + sr.getErrors()[0].getMessage().replace('n\'t', 'n not');
                }
            } else {
                insert new ErrorLogging__c(
                    Error__c = 'Error: No Opportunity',
                    RecordIDs__c = opportunityId,
                    ProcessName__c = 'PriceConfiguratorController.createOffer()'
                );
                return 'Error: No Opportunity';
            }
        } catch(Exception e){
            insert new ErrorLogging__c(
                Error__c = e.getMessage(),
                RecordIDs__c = opportunityId,
                ProcessName__c = 'PriceConfiguratorController.createOffer()'
            );
            return 'Error: ' + e.getMessage().replace('n\'t', 'n not');
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Map<String, Decimal>> getAuxiliaryTables(String opportunityId){
        try{
            Map<String, Map<String, Decimal>> returnMap = new Map<String, Map<String, Decimal>>{
                'simulationAndGrowth' => new Map<String, Decimal>(),
                'industryProductSubgroup' => new Map<String, Decimal>(),
                'discount' => new Map<String, Decimal>(),
                'volumeCoffee' => new Map<String, Decimal>(),
                'volumeTea' => new Map<String, Decimal>(),
                'volumeCocoa' => new Map<String, Decimal>(),
                'volumeOther' => new Map<String, Decimal>(),
                'assortmentCoffee' => new Map<String, Decimal>{'value' => 0},
                'assortmentTea' => new Map<String, Decimal>(),
                'assortmentCocoa' => new Map<String, Decimal>(),
                'assortmentOther' => new Map<String, Decimal>(),
                'digital' => new Map<String, Decimal>(),
                'branding' => new Map<String, Decimal>(),
                'maxTeaDiscount' => new Map<String, Decimal>()
            };
            for(Price_Calculation__mdt mdt : [SELECT Id, Type__c, of_Articles__c, of_different_coffe_of_e_preparations__c, Branding_Location_presentation__c, Branding_Menu_Logo__c, Branding_Table_presentation__c, Digital_ordering__c,
                Discount__c, Growth_Percentage__c, Growth_Revenue__c, Industry__c, Product_Group__c, Skonto__c, Volume_in__c, Volume_in_kg__c FROM Price_Calculation__mdt WHERE Type__c != NULL 
                ORDER BY of_different_coffe_of_e_preparations__c, of_Articles__c, Volume_in_kg__c, Volume_in__c]){
                    if(mdt.Type__c == 'Bestellweg'){
                        if(mdt.Digital_ordering__c){
                            returnMap.get('digital').put(System.Label.GeneralYes, mdt.Discount__c);
                        }
                    } else if(mdt.Type__c == 'Grundrabatt'){
                        if(String.isNotBlank(mdt.Industry__c) && String.isNotBlank(mdt.Product_Group__c)){
                            returnMap.get('industryProductSubgroup').put(mdt.Industry__c + mdt.Product_Group__c, mdt.Discount__c);
                        }
                    } else if(mdt.Type__c == 'Markensichtbarkeit'){
                        if(mdt.Branding_Table_presentation__c){
                            returnMap.get('branding').put('offerOnTable', mdt.Discount__c);
                        } else if(mdt.Branding_Menu_Logo__c){
                            returnMap.get('branding').put('menuLogo', mdt.Discount__c);
                        } else if(mdt.Branding_Location_presentation__c){
                            returnMap.get('branding').put('offerInProperty', mdt.Discount__c);
                        }
                    } else if(mdt.Type__c == 'Maximaler Teerabatt'){
                        returnMap.get('maxTeaDiscount').put('value', mdt.Discount__c);
                    } else if(mdt.Type__c == 'Skonto'){
                        if(String.isNotBlank(mdt.Skonto__c)){
                            returnMap.get('discount').put(mdt.Skonto__c, mdt.Discount__c);
                        }
                    } else if(mdt.Type__c == 'Sortiment'){
                        if(String.isNotBlank(mdt.Product_Group__c)){
                            if(mdt.Product_Group__c == 'Röstkaffee' && mdt.of_different_coffe_of_e_preparations__c != null){
                                returnMap.get('assortmentCoffee').put(String.valueOf(mdt.of_different_coffe_of_e_preparations__c), mdt.Discount__c);
                            } else if(mdt.Product_Group__c == 'Tee' && mdt.of_Articles__c != null){
                                returnMap.get('assortmentTea').put(String.valueOf(mdt.of_Articles__c), mdt.Discount__c);
                            } else if(mdt.Product_Group__c == 'Trinkschokolade' && mdt.of_Articles__c != null){
                                returnMap.get('assortmentCocoa').put(String.valueOf(mdt.of_Articles__c), mdt.Discount__c);
                            } else if(mdt.Product_Group__c == 'Sonstiges' && mdt.of_Articles__c != null){
                                returnMap.get('assortmentOther').put(String.valueOf(mdt.of_Articles__c), mdt.Discount__c);
                            } 
                        }
                    } else if(mdt.Type__c == 'Volumen'){
                        if(String.isNotBlank(mdt.Product_Group__c)){
                            if(mdt.Product_Group__c == 'Röstkaffee' && mdt.Volume_in_kg__c != null){
                                returnMap.get('volumeCoffee').put(String.valueOf(mdt.Volume_in_kg__c), mdt.Discount__c);
                            } else if(mdt.Product_Group__c == 'Tee' && mdt.Volume_in__c != null){
                                returnMap.get('volumeTea').put(String.valueOf(mdt.Volume_in__c), mdt.Discount__c);
                            } else if(mdt.Product_Group__c == 'Trinkschokolade' && mdt.Volume_in_kg__c != null){
                                returnMap.get('volumeCocoa').put(String.valueOf(mdt.Volume_in_kg__c), mdt.Discount__c);
                            } else if(mdt.Product_Group__c == 'Sonstiges' && mdt.Volume_in__c != null){
                                returnMap.get('volumeOther').put(String.valueOf(mdt.Volume_in__c), mdt.Discount__c);
                            } 
                        }
                    } else if(mdt.Type__c == 'Wachstum'){
                        if(mdt.Growth_Revenue__c != null && mdt.Growth_Percentage__c != null){
                            returnMap.get('simulationAndGrowth').put(String.valueOf(mdt.Growth_Revenue__c) + String.valueOf(mdt.Growth_Percentage__c), mdt.Discount__c);
                        }
                    }  
            }
            return returnMap;
        } catch(Exception e){
            insert new ErrorLogging__c(
                Error__c = e.getMessage(),
                RecordIDs__c = opportunityId,
                ProcessName__c = 'PriceConfiguratorController.getAuxiliaryTables()'
            );
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getSubgroupCount(List<Id> standardPricebookEntriesIds, String recordId){
        try{
            Map<String, Integer> returnMap = new Map<String, Integer>();
            for(AggregateResult ar : [SELECT ProductSubgroup__c, Count(ID) cnt FROM Product2 WHERE IsActive = TRUE AND Id IN : standardPricebookEntriesIds AND (ProductClass = 'VariationParent' OR ProductClass = 'Simple') GROUP BY ProductSubgroup__c ]){
                returnMap.put(String.valueOf(ar.get('ProductSubgroup__c')), Integer.valueOf(ar.get('cnt')));
            }
            return returnMap;
        } catch(Exception e){
            insert new ErrorLogging__c(
                Error__c = e.getMessage(),
                RecordIDs__c = recordId,
                ProcessName__c = 'PriceConfiguratorController.getSubgroupCount()'
            );
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<Id, Decimal> getStandardPricebookEntries(String recordId){
        try{
            Map<Id, Decimal> standardPricebookEntries = new Map<Id, Decimal>();
            for(PricebookEntry pbe : [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE IsActive = TRUE AND Pricebook2Id = : STANDARD_PRICEBOOK_COPY.Id AND (Product2.ProductClass = 'VariationParent' OR Product2.ProductClass = 'Simple' OR Product2.Name LIKE 'Produkt-Untergruppe:%' OR Product2.IsMaschine__c = TRUE)]){
                standardPricebookEntries.put(pbe.Product2Id, pbe.UnitPrice);
            }
            return standardPricebookEntries;
        } catch(Exception e){
            insert new ErrorLogging__c(
                Error__c = e.getMessage(),
                RecordIDs__c = recordId,
                ProcessName__c = 'PriceConfiguratorController.getStandardPricebookEntries()'
            );
            return null;
        }
    }

    @AuraEnabled(cacheable=false)
    public static QuoteAndInheritWrapper preloadQuoteData(String quoteId){
        Quote q = [SELECT Id, Name, OpportunityId, Opportunity.Name, OwnerId, Status, Pricebook2Id, //ValidFrom__c,
            DishSales__c, OtherAdditionalAggreeementsSpecified__c, PurchaseQuantityCoffeeStatistical__c, PurchaseQuantityTeaStatistical__c,
            OtherAdditionalAggreeementsDetails__c, QualityCheck__c, PurchaseQuantityHotChocStatistical__c, PurchaseQuantityOtherStatistical__c,
            Interval__c , InitialReview__c, ProfessionalSetupRequested__c, PurchaseQuantityCoffee__c, PurchaseQuantityTea__c,
            PurchaseQuantityHotChoc__c, PurchaseQuantityOther__c, NrOfDifferentCoffeePreps__c, NrOfDifferentTeaProducts__c,
            NrOfDifferentHotChocProducts__c, NrOfDifferentOtherProducts__c, BrandDisplayTable__c, BrandDisplayLocation__c, 
            BrandDisplayMenu__c, AdditionalAgreements__c, DigitalWayOfOrdering__c,
            SimulatedDiscount__c,
            //Leihgestellung_angeboten__c, Leihgestellung_Details__c, OfferTasting__c, OfferTraining__c, OfferFinancing__c,
            //Simulation__c, Refund__c, Simuliertes_GrowthPercent__c, Simuliertes_GrowthRevenue__c, R_ckverg_tung_Kaffee_Typ__c, R_ckverg_tung_Tee_Typ__c,
            //R_ckverg_tung_Kaffee_Grundlage__c,  R_ckverg_tung_Tee_Grundlage__c, WKZCoffeeOneTimeTotalRuntime__c, WKZCoffeeOneTimeRuntimeMonths__c, 
            //WKZ_Kaffee_Einm_Verg_tung__c, WKZ_Kaffee_J_hrl_Verg_tung__c, WKZTeaOneTimeTotalRuntime__c, WKZCoffeeOneTimeRuntimeMonths__c, WKZTeaOneTimeBonus__c,
            //WKZTeaAnnualBonus__c,
            DiscountIndexCondition__c, LinkedMachineOffer__c, Lifetime__c,
            (SELECT Id, Product2Id, Product2.Name, Product2.QuoteName__c, Quantity, UnitPrice, CustomListPrice__c, CustomTotalPrice__c, SpecialDiscount__c, 
            SpecialDiscountInPercent__c, ProductGroup__c, ProductSubgroup__c, AppliedMachineSurcharge__c, IndividualCondition__c,
            //Set_as_configuration__c, Aufschlag_Gesamt_alt__c, R_ckverg_tung_Rabatt_in__c, R_ckverg_tung_Rabatt_in_Euro__c, Product2.Minimum_Price__c
            Product2.LowestConditionForSalesAreaManager__c, Product2.LowestConditionForSalesManager__c,
            Product2.ExemptFromSurcharges__c, PricebookEntryId, IsSubgroup__c FROM QuoteLineItems WHERE Product2.IsActive = TRUE)
            /*(SELECT Id, Angebot__c, Produkt__c, Produkt__r.PreviewPrice__c, Produkt__r.Name, Produkt__r.QuoteName__c, Menge__c, Preis__c, F_r_Erstbestellung_markiert__c, GrantedTeaDiscount__c FROM Erstausstattungen__r
            WHERE Produkt__r.IsActive = TRUE)*/
            FROM Quote WHERE Id = : quoteId] ;
        if(String.isNotBlank(q.LinkedMachineOffer__c)){
            /*Quote mq = [SELECT Id, Maschine_AnzahlungInPercentMaschine__c, Maschine_Laufzeit_in_Monaten__c, Maschine_Aufschlagsberechnung__c,
                (SELECT Id, Product2.BrandWebshop__r.Name, Product2Id, Product2.Name, Product2.NotDiscountable__c, ParentMachine__c, Product2.Description, MachineType__c, Quantity, UnitPrice, CustomListPrice__c, CustomTotalPrice__c, Discount, Discount_Regular__c, Discount_Special__c FROM QuoteLineItems)
                FROM Quote WHERE Id = : q.LinkedMachineOffer__c];
            q.LinkedMachineOffer__r = mq;*/
        }
        return new QuoteAndInheritWrapper(q);
    }

    @AuraEnabled(cacheable=false)
    public static QuotePreloadWrapper checkIfNewCustomerLite(String opportunityId){
        try{
            List<Opportunity> oppList = [SELECT Id, AccountId, Account.ConditionChainHead__c, Account.SalesCategory__c, Account.IsChainMember__c, Account.IsTopAccountCondition__c FROM Opportunity WHERE Id = : opportunityId AND AccountId != NULL];
            Integer resultNo = 0; // 0 = existingCustomer, 1 = newCustomer, 2 = newCustomerWithInherited 
            String customerType = 'none'; // Einkaufsgesellschaft KANN, Einkaufsgesellschaft MUSS, Kette
            String industry = null;
            Boolean isChainMember = false; 
            Boolean isTopAccountCondition = false;
            PriceConfigurationSet__c preloadChild = null;
            PriceConfigurationSet__c preloadParent = null;
            Boolean hasOwnConfig = false;
            if(!oppList.isEmpty()){
                Id accountId = oppList[0].AccountId;
                industry = oppList[0].Account.SalesCategory__c;
                isChainMember = oppList[0].Account.IsChainMember__c; 
                isTopAccountCondition = oppList[0].Account.IsTopAccountCondition__c;
                List<PriceConfigurationSet__c> parentCustData = new List<PriceConfigurationSet__c>();
                List<PriceConfigurationSet__c> existingCustData = [SELECT Id, ParentType__c, Account__c, Account__r.ConditionChainHead__c, ActiveDate__c, Active__c, AssortmentCocoaCount__c, AssortmentOtherCount__c,
                 AssortmentRoastCoffeeCount__c, AssortmentTeaCount__c, VolumeCocoaQty__c, VolumeOtherQty__c,  VolumeRoastCoffeeQty__c, VolumeTeaQty__c
                 FROM PriceConfigurationSet__c WHERE Active__c = TRUE AND Account__c = : oppList[0].AccountId ORDER BY CreatedDate DESC];
                if(!existingCustData.isEmpty() && existingCustData[0].Account__r.ConditionChainHead__c != null){
                    parentCustData = [SELECT Id, ParentType__c, Account__c, ActiveDate__c, Active__c, AssortmentCocoaCount__c, AssortmentOtherCount__c,
                 AssortmentRoastCoffeeCount__c, AssortmentTeaCount__c, VolumeCocoaQty__c, VolumeOtherQty__c,  VolumeRoastCoffeeQty__c, VolumeTeaQty__c
                    FROM PriceConfigurationSet__c WHERE Active__c = TRUE AND Account__c = : existingCustData[0].Account__r.ConditionChainHead__c];
                }
                if(existingCustData.isEmpty()){
                    resultNo = 1;
                } else {
                    preloadChild = existingCustData[0];
                    if(String.isNotBlank(preloadChild.ParentType__c)){
                        customerType = preloadChild.ParentType__c;
                    }
                    if(!parentCustData.isEmpty()){
                        resultNo = 2;
                        preloadParent = parentCustData[0];
                        if(String.isBlank(customerType) && String.isNotBlank(preloadParent.ParentType__c)){
                            customerType = preloadParent.ParentType__c;
                        }
                        if(String.isNotBlank(preloadParent.Account__r.SalesCategory__c)){
                            industry = preloadParent.Account__r.SalesCategory__c;
                        }
                    } else {
                        hasOwnConfig = true;
                    }
                }
            }
            return new QuotePreloadWrapper(String.valueOf(resultNo), hasOwnConfig, industry, preloadChild, preloadParent, isChainMember, isTopAccountCondition);
        } catch(Exception e){
            insert new ErrorLogging__c(
                Error__c = e.getMessage(),
                RecordIDs__c = opportunityId,
                ProcessName__c = 'PriceConfiguratorController.checkIfNewCustomerLite()'
            );
            return null;
        }
    }

    @AuraEnabled(cacheable=false)
    public static PriceConfigWrapper checkIfNewCustomer(String opportunityId){
        try{
            List<Opportunity> oppList = [SELECT Id, AccountId, Account.ConditionChainHead__c, Account.SalesCategory__c, Account.IsChainMember__c, Account.IsTopAccountCondition__c FROM Opportunity WHERE Id = : opportunityId AND AccountId != NULL];
            Integer resultNo = 0; // 0 = existingCustomer, 1 = newCustomer, 2 = newCustomerWithInherited 
            Decimal maxTeaDiscount = 0;
            String accountId = null;
            String industry = null;
            PriceConfigurationSet__c preloadChild = null;
            PriceConfigurationSet__c preloadParent = null;
            String customerType = 'none'; // Einkaufsgesellschaft KANN, Einkaufsgesellschaft MUSS, Kette
            Boolean isChainMember = false; 
            Boolean isTopAccountCondition = false;
            if(!oppList.isEmpty()){
                accountId = oppList[0].AccountId;
                industry = oppList[0].Account.SalesCategory__c;
                isChainMember = oppList[0].Account.IsChainMember__c; 
                isTopAccountCondition = oppList[0].Account.IsTopAccountCondition__c;
                List<PriceConfigurationSet__c> parentCustData = new List<PriceConfigurationSet__c>();
                List<PriceConfigurationSet__c> existingCustData = [SELECT Id, ParentType__c, Account__c, ActiveDate__c, Active__c, AssortmentCocoaCount__c, AssortmentOtherCount__c,
                 AssortmentRoastCoffeeCount__c, AssortmentTeaCount__c, BrandVisibilityLocation__c, BrandVisibilityMenu__c, BrandVisibilityTable__c, CashDiscountType__c, CashDiscount__c, ConditionSetStartDate__c, 
                 ProfessionalAdjustmentRequested__c, IndexDiscountPct__c, RentalDetails__c, RentalOffered__c, Opportunity__c, QualityCheckFirstVisitDate__c, 
                 QualityCheckInterval__c, QualityCheckAgreed__c, OtherAdditionalAgreementsDetails__c, OtherAdditionalAgreementsSet__c, VolumeCocoaQty__c, VolumeOtherQty__c, 
                 VolumeRoastCoffeeQty__c, VolumeTeaQty__c, WKZCoffeeOneTimeRuntimeMonths__c, WKZCoffeeOneTimeBonus__c, WKZCoffeeAnnualBonus__c, WKZTeaOneTimeTotalRuntime__c, 
                 WKZTeaOneTimeRuntimeMonths__c, WKZTeaOneTimeBonus__c, WKZTeaAnnualBonus__c, SugarPrintOffered__c, SugarPrintDetails__c, OrderChannelDigital__c
                 FROM PriceConfigurationSet__c WHERE Active__c = TRUE AND Account__c = : oppList[0].AccountId ORDER BY CreatedDate DESC];
                if(!existingCustData.isEmpty() && oppList[0].Account.ConditionChainHead__c != null){
                    parentCustData = [SELECT Id, ParentType__c, Account__r.SalesCategory__c, Account__c, ActiveDate__c, Active__c, AssortmentCocoaCount__c, AssortmentOtherCount__c,
                    AssortmentRoastCoffeeCount__c, AssortmentTeaCount__c, BrandVisibilityLocation__c, BrandVisibilityMenu__c, BrandVisibilityTable__c, CashDiscountType__c, CashDiscount__c, ConditionSetStartDate__c, 
                    ProfessionalAdjustmentRequested__c, IndexDiscountPct__c, RentalDetails__c, RentalOffered__c, Opportunity__c, QualityCheckFirstVisitDate__c, 
                    QualityCheckInterval__c, QualityCheckAgreed__c, OtherAdditionalAgreementsDetails__c, OtherAdditionalAgreementsSet__c, VolumeCocoaQty__c, VolumeOtherQty__c, 
                    VolumeRoastCoffeeQty__c, VolumeTeaQty__c, WKZCoffeeOneTimeRuntimeMonths__c, WKZCoffeeOneTimeBonus__c, WKZCoffeeAnnualBonus__c, WKZTeaOneTimeTotalRuntime__c, 
                    WKZTeaOneTimeRuntimeMonths__c, WKZTeaOneTimeBonus__c, WKZTeaAnnualBonus__c, SugarPrintOffered__c, SugarPrintDetails__c, OrderChannelDigital__c
                    FROM PriceConfigurationSet__c WHERE Active__c = TRUE AND Account__c = : oppList[0].Account.ConditionChainHead__c];
                }
                if(existingCustData.isEmpty()){
                    resultNo = 1;
                } else {
                    preloadChild = existingCustData[0];
                    if(String.isNotBlank(preloadChild.ParentType__c)){
                        customerType = preloadChild.ParentType__c;
                    }
                    if(!parentCustData.isEmpty()){
                        resultNo = 2;
                        preloadParent = parentCustData[0];
                        if(String.isBlank(customerType) && String.isNotBlank(preloadParent.ParentType__c)){
                            customerType = preloadParent.ParentType__c;
                        }
                        if(String.isNotBlank(preloadParent.Account__r.SalesCategory__c)){
                            industry = preloadParent.Account__r.SalesCategory__c;
                        }
                    }
                }
                List<Price_Calculation__mdt> mdtList = [SELECT Id, Discount__c FROM Price_Calculation__mdt WHERE Type__c = 'Maximaler Teerabatt' AND Discount__c != NULL];
                if(!mdtList.isEmpty()){
                    maxTeaDiscount = mdtList[0].Discount__c;
                }
            }
            PriceConfigWrapper returnWrapper = new PriceConfigWrapper(resultNo, preloadChild, preloadParent, accountId, industry, maxTeaDiscount, customerType, isChainMember, isTopAccountCondition);
            return returnWrapper;
        } catch(Exception e){
            insert new ErrorLogging__c(
                Error__c = e.getMessage(),
                RecordIDs__c = opportunityId,
                ProcessName__c = 'PriceConfiguratorController.checkIfNewCustomer()'
            );
            return null;
        }
    }

    public class OptionWithPriceWrapper{
        @AuraEnabled public Boolean isSubgroup;
        @AuraEnabled public Boolean isGroup;
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String groupName;
        @AuraEnabled public String subgroupName;
        @AuraEnabled public Decimal price;
        public OptionWithPriceWrapper(String label, String groupName, String subgroupName, String value, Decimal price){
            this.label = label;
            this.value = value;
            this.isSubgroup = label.startsWith('Produkt-Untergruppe:');
            this.isGroup = label.startsWith('Produktgruppe:');
            this.groupName = this.isGroup ? (String.isNotBlank(label) ? label.replace('Produktgruppe: ', '') : '') : (String.isNotBlank(groupName) ? groupName.replace('Produktgruppe: ', '') : '');
            this.subgroupName = this.isSubgroup ? (String.isNotBlank(label) ? label.replace('Produkt-Untergruppe: ', '') : '') : (String.isNotBlank(subgroupName) ? subgroupName.replace('Produkt-Untergruppe: ', '') : '');
            this.price = price;
        }
    }

    public class NumTypesWrapper{
        @AuraEnabled public String label;
        @AuraEnabled public Integer selection;
        @AuraEnabled public Integer selected;
        @AuraEnabled public Integer quantities;
    }

    public class InitialEquipmentWrapper{
        @AuraEnabled public Integer rownumber;
        @AuraEnabled public String product;
        @AuraEnabled public Decimal previewPrice;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal sum;
        @AuraEnabled public String markForInitialOrder;
        @AuraEnabled public Decimal teaDiscount;
        @AuraEnabled public Decimal teaDiscountPercent;
        @AuraEnabled public String productGroup;
        @AuraEnabled public String productSubgroup;
        @AuraEnabled public String productName;
        @AuraEnabled public Boolean isSubgroup;
    }

    public class QuoteAndInheritWrapper{
        @AuraEnabled public Quote quote;
        @AuraEnabled public Id OpportunityId;
        //@AuraEnabled public PriceConfigurationSet__c inherit;
        public QuoteAndInheritWrapper(Quote quote) { //, PriceConfigurationSet__c inherit){
            this.quote = quote;
            this.opportunityId = quote.OpportunityId;
            //this.inherit = inherit;
        }
    }

    public class ConditionProductWrapper{
        @AuraEnabled public Integer rownumber;
        @AuraEnabled public String producttype;
        @AuraEnabled public String product;
        @AuraEnabled public String productName;
        @AuraEnabled public String productGroup;
        @AuraEnabled public String productSubgroup;
        @AuraEnabled public Decimal basePrice;
        @AuraEnabled public Decimal basePricePre;
        @AuraEnabled public Decimal rebate;
        @AuraEnabled public Decimal offerPrice;
        @AuraEnabled public Decimal simulationPrice;
        @AuraEnabled public Decimal basePriceDisplay;
        @AuraEnabled public Decimal rebateDisplay;
        @AuraEnabled public Decimal offerPriceDisplay;
        @AuraEnabled public Decimal simulationPriceDisplay;
        @AuraEnabled public Decimal specialRebate;
        @AuraEnabled public Decimal specialRebatePercent;
        @AuraEnabled public Decimal refundAmount;
        @AuraEnabled public Decimal refundPercent;
        @AuraEnabled public Decimal totalAddition;
        @AuraEnabled public Integer warningLevel;
        @AuraEnabled public Boolean freeFromSurcharge;
        @AuraEnabled public Decimal lowestConditionSalesAreaManager;
        @AuraEnabled public Decimal lowestConditionSalesManager;
        @AuraEnabled public Decimal minimumPrice;
        @AuraEnabled public Decimal coffeeKgCharge;
        @AuraEnabled public Decimal coffeeQuantityDiscount;
        @AuraEnabled public Decimal coffeeSelectionDiscount;
        @AuraEnabled public Decimal teaQuantityDiscount;
        @AuraEnabled public Decimal teaSelectionDiscount;
        @AuraEnabled public Decimal cocoaQuantityDiscount;
        @AuraEnabled public Decimal cocoaSelectionDiscount;
        @AuraEnabled public Decimal otherQuantityDiscount;
        @AuraEnabled public Decimal otherSelectionDiscount;
        @AuraEnabled public Decimal brandingTableDiscount;
        @AuraEnabled public Decimal brandingMenuDiscount;
        @AuraEnabled public Decimal brandingPropertyDiscount;
        @AuraEnabled public Decimal brandingDigitalDiscount;
        @AuraEnabled public Decimal simRebateDiscount;
        @AuraEnabled public Decimal simRefundDiscount;
        @AuraEnabled public Decimal simGrowthDiscount;
        @AuraEnabled public Decimal coffeeBaseDiscount;
        @AuraEnabled public Decimal teaBaseDiscount;
        @AuraEnabled public Decimal cocoaBaseDiscount;
        @AuraEnabled public Decimal otherBaseDiscount;
        @AuraEnabled public Decimal baseConditionDiscount;
        @AuraEnabled public Decimal productBasedDiscount;
        @AuraEnabled public Boolean subgroupHasPrice;
        @AuraEnabled public Boolean individualCondition;
        public ConditionProductWrapper(
            Integer rownumber,
            String producttype,
            String product,
            String productName,
            String productGroup,
            String productSubgroup,
            Decimal basePricePre,
            Decimal rebate,
            Decimal offerPrice,
            Decimal simulationPrice,
            Decimal specialRebate,
            Decimal specialRebatePercent,
            Decimal refundAmount,
            Decimal refundPercent,
            Decimal totalAddition,
            Decimal lowestConditionSalesAreaManager,
            Decimal lowestConditionSalesManager,
            Decimal minimumPrice,
            Boolean freeFromSurcharge,
            Boolean individualCondition
            
        ){
            this.rownumber = rownumber;
            this.producttype = producttype;
            this.product = product;
            this.productName = productName;
            this.productGroup = productGroup;
            this.productSubgroup = productSubgroup;
            this.basePricePre = basePricePre;
            this.rebate = rebate;
            this.offerPrice = offerPrice;
            this.simulationPrice = simulationPrice;
            this.basePriceDisplay = basePrice != null ? basePrice.setScale(2) : 0;
            this.rebateDisplay = rebate != null ? rebate.setScale(2) : 0;
            this.offerPriceDisplay = offerPrice != null ? offerPrice.setScale(2) : 0;
            this.simulationPriceDisplay = simulationPrice != null ? simulationPrice.setScale(2) : 0;
            this.specialRebate = specialRebate;
            this.specialRebatePercent = specialRebatePercent;
            this.refundAmount = refundAmount;
            this.refundPercent = refundPercent;
            this.totalAddition = totalAddition;
            this.warningLevel = 0;
            this.freeFromSurcharge = freeFromSurcharge;
            this.lowestConditionSalesAreaManager = lowestConditionSalesAreaManager;
            this.lowestConditionSalesManager = lowestConditionSalesManager;
            this.minimumPrice = minimumPrice;
            this.coffeeKgCharge = 0;
            this.coffeeQuantityDiscount = 0;
            this.coffeeSelectionDiscount = 0;
            this.teaQuantityDiscount = 0;
            this.teaSelectionDiscount = 0;
            this.cocoaQuantityDiscount = 0;
            this.cocoaSelectionDiscount = 0;
            this.otherQuantityDiscount = 0;
            this.otherSelectionDiscount = 0;
            this.brandingTableDiscount = 0;
            this.brandingMenuDiscount = 0;
            this.brandingPropertyDiscount = 0;
            this.brandingDigitalDiscount = 0;
            this.simRebateDiscount = 0;
            this.simRefundDiscount = 0;
            this.simGrowthDiscount = 0;
            this.coffeeBaseDiscount = 0;
            this.teaBaseDiscount = 0;
            this.cocoaBaseDiscount = 0;
            this.otherBaseDiscount = 0;
            this.baseConditionDiscount = 0;
            this.subgroupHasPrice = false;
            this.individualCondition = individualCondition;
        }
    }

    public class QuotePreloadWrapper{
        @AuraEnabled public String newCustomer;
        @AuraEnabled public Boolean hasOwnConfiguration;
        @AuraEnabled public String industry;
        @AuraEnabled public PriceConfigurationSet__c preloadChild;
        @AuraEnabled public PriceConfigurationSet__c preloadParent;
        @AuraEnabled public Boolean isChainMember {get;set;}
        @AuraEnabled public Boolean isTopAccountCondition {get;set;}
        public QuotePreloadWrapper(String newCustomer, Boolean hasOwnConfiguration, String industry, PriceConfigurationSet__c preloadChild, PriceConfigurationSet__c preloadParent, Boolean isChainMember, Boolean isTopAccountCondition){
            this.newCustomer = newCustomer;
            this.hasOwnConfiguration = hasOwnConfiguration;
            this.industry = industry;
            this.preloadChild = preloadChild;
            this.preloadParent = preloadParent;
            this.isChainMember = isChainMember;
            this.isTopAccountCondition = isTopAccountCondition;
        }
    }

    public class PriceConfigWrapper{
        @AuraEnabled public List<ConditionProductWrapper> conditionProductDataPre;
        @AuraEnabled public Integer resultNo;
        @AuraEnabled public Decimal indexDiscount;
        @AuraEnabled public Decimal maxTeaDiscount;
        @AuraEnabled public Map<String, Integer> preloadNum;
        @AuraEnabled public Map<String, Integer> preloadQuantities;
        @AuraEnabled public Map<String, Integer> preloadNumInherit;
        @AuraEnabled public Map<String, Integer> preloadQuantitiesInherit;
        @AuraEnabled public Map<String, String> preloadSimulation;
        @AuraEnabled public Map<String, String> preloadAgreements;
        @AuraEnabled public Map<String, Boolean> preloadAgreementsBool;
        @AuraEnabled public Map<String, String> preloadBool;
        @AuraEnabled public String accountId;
        @AuraEnabled public String industry;
        @AuraEnabled public String customerType;
        @AuraEnabled public Boolean hasOwnConfiguration;
        @AuraEnabled public Boolean isChainMember {get;set;}
        @AuraEnabled public Boolean isTopAccountCondition {get;set;}
        public PriceConfigWrapper(Integer resultNo, PriceConfigurationSet__c preloadChild, PriceConfigurationSet__c preloadParent, String accountId, String industry, Decimal maxTeaDiscount, String customerType, Boolean isChainMember, Boolean isTopAccountCondition){
            this.hasOwnConfiguration = preloadParent == null;
            this.resultNo = resultNo;
            this.customerType = customerType;
            this.industry = industry;
            this.indexDiscount = 0;
            this.isChainMember = isChainMember;
            this.isTopAccountCondition = isTopAccountCondition;
            this.conditionProductDataPre = new List<ConditionProductWrapper>();
            this.preloadNum = new Map<String, Integer>{
                'Röstkaffee' => 0,
                'Tee' => 0,
                'Trinkschokolade' => 0,
                'Sonstiges' => 0
            };
            this.preloadQuantities = new Map<String, Integer>{
                'Röstkaffee' => 0,
                'Tee' => 0,
                'Trinkschokolade' => 0,
                'Sonstiges' => 0
            };
            this.preloadNumInherit = new Map<String, Integer>{
                'Röstkaffee' => null,
                'Tee' => null,
                'Trinkschokolade' => null,
                'Sonstiges' => null
            };
            this.preloadQuantitiesInherit = new Map<String, Integer>{
                'Röstkaffee' => null,
                'Tee' => null,
                'Trinkschokolade' => null,
                'Sonstiges' => null
            };
            this.preloadSimulation = new Map<String, String>{
                'skonto' => '0',
                'growthPercent' => '0',
                'growthRevenue' => '0'
            };
            this.preloadAgreementsBool = new Map<String, Boolean>{
                'load' => false,
                'frame' => false,
                'tasting' => false,
                'financing' => false,
                'training' => false,
                'other' => false,
                'quality' => false,
                'qualitySetting' => false
            };
            this.preloadAgreements = new Map<String, String>{
                'frame' => null,
                'other' => null,
                'qualityInterval' => null,
                'qualityInitial' => null
            };
            this.preloadBool = new Map<String, String>{
                'digitalRequired' => System.Label.GeneralNo,
                'offerOnTable' => System.Label.GeneralNo,
                'menuLogo' => System.Label.GeneralNo,
                'offerInProperty' => System.Label.GeneralNo,
                'showSimulation' => System.Label.GeneralNo,
                'showRefund' => System.Label.GeneralNo,
                'individual' => System.Label.GeneralAllItems // System.Label.GeneralIndividual
            };
            this.accountId = accountId;
            this.industry = industry;
            this.maxTeaDiscount = maxTeaDiscount;
            this.conditionProductDataPre = new List<ConditionProductWrapper>(); 
            // Preload Data
            List<AccountConditions__c> accountConditionsPreload = [SELECT Id,
            IndexDiscountPct__c, AssCocoaCount__c, 
            AssOtherProductsCount__c, AssRoastedCoffeeCount__c, 
            AssTeaCount__c, BrandVisibilityLocation__c, 
            BrandVisibilityMenu__c, OrderChannel__c,
            BrandVisibilityTable__c, CashDiscountType__c, CashDiscount__c, 
            InhVolumeCocoaQty__c, InhVolumeOtherProductsQty__c,
            InhVolumeRoastedCoffeeQty__c, InhVolumeTeaQty__c,
            HeadOfConditionChainConditions__c, HeadOfConditionChainConditions__r.AssCocoaCount__c, HeadOfConditionChainConditions__r.AssOtherProductsCount__c, 
            HeadOfConditionChainConditions__r.AssRoastedCoffeeCount__c, HeadOfConditionChainConditions__r.AssTeaCount__c, 
            HeadOfConditionChainConditions__r.BrandVisibilityLocation__c, HeadOfConditionChainConditions__r.BrandVisibilityMenu__c, HeadOfConditionChainConditions__r.OrderChannel__c, 
            HeadOfConditionChainConditions__r.BrandVisibilityTable__c, HeadOfConditionChainConditions__r.CashDiscountType__c, HeadOfConditionChainConditions__r.CashDiscount__c, 
            HeadOfConditionChainConditions__r.InhVolumeCocoaQty__c, HeadOfConditionChainConditions__r.InhVolumeOtherProductsQty__c, HeadOfConditionChainConditions__r.InhVolumeRoastedCoffeeQty__c, 
            HeadOfConditionChainConditions__r.InhVolumeTeaQty__c,
            ParentAccountConditions__c, ParentAccountConditions__r.AssCocoaCount__c, ParentAccountConditions__r.AssOtherProductsCount__c, 
            ParentAccountConditions__r.AssRoastedCoffeeCount__c, ParentAccountConditions__r.AssTeaCount__c, 
            ParentAccountConditions__r.BrandVisibilityLocation__c, ParentAccountConditions__r.BrandVisibilityMenu__c, ParentAccountConditions__r.OrderChannel__c, 
            ParentAccountConditions__r.BrandVisibilityTable__c, ParentAccountConditions__r.CashDiscountType__c, ParentAccountConditions__r.CashDiscount__c, 
            ParentAccountConditions__r.InhVolumeCocoaQty__c, ParentAccountConditions__r.InhVolumeOtherProductsQty__c, ParentAccountConditions__r.InhVolumeRoastedCoffeeQty__c, 
            ParentAccountConditions__r.InhVolumeTeaQty__c,
            (SELECT IndividualCondition__c, OverallSurcharge__c, Product__c, Product__r.ExemptFromSurcharges__c, Product__r.LowestConditionForVending__c, Product__r.Name, Product__r.ProductGroup__r.Name, Product__r.ProductSubgroup__r.Name, Product__r.LowestConditionForSalesAreaManager__c, Product__r.LowestConditionForSalesManager__c, RefundDiscountInEuro__c, SpecialDiscountInE__c, SpecialDiscountInPct__c, RefundDiscountInPercent__c FROM Product_Conditions__r WHERE Active__c = TRUE AND Product__r.IsActive = TRUE)
            FROM AccountConditions__c
            WHERE ApplicableAccount__c = : accountId
            AND Active__c = TRUE
            ORDER BY ValidFrom__c DESC LIMIT 1];
            if(!accountConditionsPreload.isEmpty()){
                AccountConditions__c validConditionBase = accountConditionsPreload[0];
                List<ProductCondition__c> validProductsBase = validConditionBase.Product_Conditions__r;
                AccountConditions__c validConditionTypeOne = validConditionBase;
                List<ProductCondition__c> validProductsBaseTypeOne = validConditionBase.Product_Conditions__r;
                AccountConditions__c validConditionTypeTwo = validConditionBase;
                List<ProductCondition__c> validProductsBaseTypeTwo = validConditionBase.Product_Conditions__r;
                if(validConditionBase.HeadOfConditionChainConditions__c != null){
                    validConditionTypeOne = validConditionBase.ParentAccountConditions__r;
                    validProductsBaseTypeOne = [SELECT IndividualCondition__c, Product__c, Product__r.Name, Product__r.ProductGroup__r.Name, Product__r.ProductSubgroup__r.Name, SpecialDiscountInE__c, SpecialDiscountInPct__c FROM ProductCondition__c WHERE Active__c = TRUE AND Product__r.IsActive = TRUE AND AccountCondition__c = : validConditionBase.HeadOfConditionChainConditions__c];
                }
                if(validConditionBase.ParentAccountConditions__c != null){
                    validConditionTypeTwo = validConditionBase.ParentAccountConditions__r;
                    validProductsBaseTypeTwo = [SELECT IndividualCondition__c, Product__c, Product__r.Name, Product__r.ProductGroup__r.Name, Product__r.ProductSubgroup__r.Name, SpecialDiscountInE__c, SpecialDiscountInPct__c FROM ProductCondition__c WHERE Active__c = TRUE AND Product__r.IsActive = TRUE AND AccountCondition__c = : validConditionBase.ParentAccountConditions__c];
                }
                // Mapping
                this.indexDiscount = validConditionBase.IndexDiscountPct__c;

                this.preloadNum.put('Röstkaffee', validConditionBase.AssRoastedCoffeeCount__c != null ? Integer.valueOf(validConditionBase.AssRoastedCoffeeCount__c) : 0);
                this.preloadNum.put('Tee', validConditionBase.AssTeaCount__c != null ? Integer.valueOf(validConditionBase.AssTeaCount__c) : 0);
                this.preloadNum.put('Trinkschokolade', validConditionBase.AssCocoaCount__c != null ? Integer.valueOf(validConditionBase.AssCocoaCount__c) : 0);
                this.preloadNum.put('Sonstiges', validConditionBase.AssRoastedCoffeeCount__c != null ? Integer.valueOf(validConditionBase.AssRoastedCoffeeCount__c) : 0);
                this.preloadQuantities.put('Röstkaffee', validConditionBase.InhVolumeRoastedCoffeeQty__c != null ? Integer.valueOf(validConditionBase.InhVolumeRoastedCoffeeQty__c) : 0);
                this.preloadQuantities.put('Tee', validConditionBase.InhVolumeTeaQty__c != null ? Integer.valueOf(validConditionBase.InhVolumeTeaQty__c) : 0);
                this.preloadQuantities.put('Trinkschokolade', validConditionBase.InhVolumeCocoaQty__c != null ? Integer.valueOf(validConditionBase.InhVolumeCocoaQty__c) : 0);
                this.preloadQuantities.put('Sonstiges', validConditionBase.InhVolumeOtherProductsQty__c != null ? Integer.valueOf(validConditionBase.InhVolumeOtherProductsQty__c) : 0);
                
                this.preloadNumInherit.put('Röstkaffee', validConditionTypeOne.AssRoastedCoffeeCount__c != null ? Integer.valueOf(validConditionTypeOne.AssRoastedCoffeeCount__c) : 0);
                this.preloadNumInherit.put('Tee', validConditionTypeOne.AssTeaCount__c != null ? Integer.valueOf(validConditionTypeOne.AssTeaCount__c) : 0);
                this.preloadNumInherit.put('Trinkschokolade', validConditionTypeOne.AssCocoaCount__c != null ? Integer.valueOf(validConditionTypeOne.AssCocoaCount__c) : 0);
                this.preloadNumInherit.put('Sonstiges', validConditionTypeOne.AssOtherProductsCount__c != null ? Integer.valueOf(validConditionTypeOne.AssOtherProductsCount__c) : 0);
                this.preloadQuantitiesInherit.put('Röstkaffee', validConditionTypeOne.InhVolumeRoastedCoffeeQty__c != null ? Integer.valueOf(validConditionTypeOne.InhVolumeRoastedCoffeeQty__c) : 0);
                this.preloadQuantitiesInherit.put('Tee', validConditionTypeOne.InhVolumeTeaQty__c != null ? Integer.valueOf(validConditionTypeOne.InhVolumeTeaQty__c) : 0);
                this.preloadQuantitiesInherit.put('Trinkschokolade', validConditionTypeOne.InhVolumeCocoaQty__c != null ? Integer.valueOf(validConditionTypeOne.InhVolumeCocoaQty__c) : 0);
                this.preloadQuantitiesInherit.put('Sonstiges', validConditionTypeOne.InhVolumeOtherProductsQty__c != null ? Integer.valueOf(validConditionTypeOne.InhVolumeOtherProductsQty__c) : 0);

                //this.preloadSimulation.put('skonto', 0);
                //this.preloadSimulation.put('growthPercent', 0);
                //this.preloadSimulation.put('growthRevenue', 0);
                
                //this.preloadAgreementsBool.put('load', false);
                //this.preloadAgreementsBool.put('frame', false);
                //this.preloadAgreementsBool.put('tasting', false);
                //this.preloadAgreementsBool.put('financing', false);
                //this.preloadAgreementsBool.put('training', false);
                //this.preloadAgreementsBool.put('other', false);
                //this.preloadAgreementsBool.put('quality', false);
                //this.preloadAgreementsBool.put('qualitySetting', false);
                
                //this.preloadAgreements.put('frame', validConditionTypeOne.AssRoastedCoffeeCount__c != null ? Integer.valueOf(validConditionTypeOne.AssRoastedCoffeeCount__c) : 0);
                //this.preloadAgreements.put('other', validConditionTypeOne.AssRoastedCoffeeCount__c != null ? Integer.valueOf(validConditionTypeOne.AssRoastedCoffeeCount__c) : 0);
                //this.preloadAgreements.put('qualityInterval', validConditionTypeOne.AssRoastedCoffeeCount__c != null ? Integer.valueOf(validConditionTypeOne.AssRoastedCoffeeCount__c) : 0);
                //this.preloadAgreements.put('qualityInitial', validConditionTypeOne.AssRoastedCoffeeCount__c != null ? Integer.valueOf(validConditionTypeOne.AssRoastedCoffeeCount__c) : 0);
                
                this.preloadBool.put('digitalRequired', validConditionTypeOne.OrderChannel__c == 'Digital Order' ? System.Label.GeneralYes : System.Label.GeneralNo);
                this.preloadBool.put('offerOnTable', validConditionTypeOne.BrandVisibilityTable__c ? System.Label.GeneralYes : System.Label.GeneralNo);
                this.preloadBool.put('menuLogo', validConditionTypeOne.BrandVisibilityMenu__c ? System.Label.GeneralYes : System.Label.GeneralNo);
                this.preloadBool.put('offerInProperty', validConditionTypeOne.BrandVisibilityLocation__c ? System.Label.GeneralYes : System.Label.GeneralNo);
                //this.preloadBool.put('showSimulation', System.Label.GeneralNo);
                //this.preloadBool.put('showRefund', System.Label.GeneralNo;
                //this.preloadBool.put('individual', System.Label.GeneralNo);
                
                // Product Mapping
                Integer i = 1;
                for(ProductCondition__c pcp : validProductsBase){
                    this.conditionProductDataPre.add(new ConditionProductWrapper(
                        i,
                        String.isNotBlank(pcp.Product__r.Name) && pcp.Product__r.Name.startsWith('Produkt-Untergruppe: ') ? System.Label.GeneralSubgroup : System.Label.GeneralProduct,
                        pcp.Product__c,
                        pcp.Product__r.Name,
                        String.isNotBlank(pcp.Product__r.ProductGroup__r.Name) ? pcp.Product__r.ProductGroup__r.Name.replace('Produktgruppe: ', '') : '',
                        String.isNotBlank(pcp.Product__r.ProductSubgroup__r.Name) ? pcp.Product__r.ProductSubgroup__r.Name.replace('Produkt-Untergruppe: ', '') : '',
                        null,
                        null,
                        null,
                        null,
                        pcp.SpecialDiscountInPct__c ?? 0,
                        pcp.SpecialDiscountInE__c ?? 0,
                        pcp.RefundDiscountInEuro__c ?? 0,
                        pcp.RefundDiscountInPercent__c ?? 0,
                        pcp.OverallSurcharge__c ?? 0,
                        pcp.Product__r.LowestConditionForSalesAreaManager__c  ?? 0,
                        pcp.Product__r.LowestConditionForSalesManager__c ?? 0,
                        pcp.Product__r.LowestConditionForVending__c ?? 0,
                        pcp.Product__r.ExemptFromSurcharges__c,
                        pcp.IndividualCondition__c
                    ));
                    i++;
                }
            }
        }
    }
}