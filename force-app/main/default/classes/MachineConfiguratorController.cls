public without sharing class MachineConfiguratorController {
    private static final Pricebook2 STANDARD_PRICEBOOK_COPY = [SELECT Id FROM Pricebook2 WHERE Name = : System.Label.WebshopDoNotTranslateStandardPriceBookCopyForQuotes ORDER BY CreatedDate LIMIT 1];
    
    @AuraEnabled(cacheable=false)
    public static Opportunity getOppInfo(String opportunityId){
        return [SELECT Id, Name, Account.Name FROM Opportunity WHERE Id = : opportunityId];
    }
    
    @AuraEnabled(cacheable=false)
    public static List<OptionWrapper> getBrandsDropdown(){
        List<OptionWrapper> returnList = new List<OptionWrapper>{new OptionWrapper()};
        for(WebshopBrand__c brand : [SELECT Id, Name FROM WebshopBrand__c WHERE IsMachineBrand__c = TRUE ]){
            returnList.add(new OptionWrapper(brand.Name, brand.Id));
        }
        return returnList;
    }

    @AuraEnabled(cacheable=true)
    public static Map<Id, Decimal> getStandardPricebookEntries(){
        Map<Id, Decimal> standardPricebookEntries = new Map<Id, Decimal>();
        for(PricebookEntry pbe : [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Pricebook2Id = : STANDARD_PRICEBOOK_COPY.Id AND Product2.ProductGroup__r.Name = 'Maschine']){
            standardPricebookEntries.put(pbe.Product2Id, pbe.UnitPrice);
        }
        return standardPricebookEntries;
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, List<MachineAndAccessoireSuperiorWrapper>> getAccessoiresByMachine(String brandId, String productSeries, String machineId, Map<String, Decimal> standardPricebookEntries, List<String> selectedItems){
        Map<String, List<MachineAndAccessoireSuperiorWrapper>> returnMap = new Map<String, List<MachineAndAccessoireSuperiorWrapper>>{
            'components' => new List<MachineAndAccessoireSuperiorWrapper>(),
            'accessories' => new List<MachineAndAccessoireSuperiorWrapper>()
        };
        Map<String, MachineAndAccessoireSuperiorWrapper> innerMap = new Map<String, MachineAndAccessoireSuperiorWrapper>();
        for(Product2 prod : [SELECT Id, Name, MachineProductSeries__c, ProductGroup__r.Name, ProductSubGroup__r.Name, Description, NotDiscountable__c, BrandWebshop__r.Name, BrandWebshop__r.MaximalDiscount1__c,  BrandWebshop__r.MaximalDiscount2__c, SecondDiscountPossible__c, DiscountCorrespondsToBaseDevice__c
                                FROM Product2 
                                WHERE ProductGroup__r.Name = 'Maschine' AND ProductSubGroup__r.Name = 'Basiskomponente' AND BrandWebshop__c = : brandId AND MachineProductSeries__c = : productSeries
                                AND IsActive = TRUE AND Id IN : standardPricebookEntries.keySet()]){
            MachineAndAccessoireSuperiorWrapper superiorWrapper = returnMap.get('components').isEmpty() ? new MachineAndAccessoireSuperiorWrapper('components', new List<MachineAndAccessoireWrapper>(), new List<String>()) : returnMap.get('components')[0];
            if(selectedItems.contains(prod.Id)){
                superiorWrapper.selectedItems.add(prod.Id);
            }
            superiorWrapper.records.add(new MachineAndAccessoireWrapper(prod.Id, prod.MachineProductSeries__c, brandId, machineId, prod.Name, prod.Description, standardPricebookEntries.get(prod.Id), !prod.NotDiscountable__c, prod.BrandWebshop__r.Name, prod.BrandWebshop__r.MaximalDiscount1__c, prod.BrandWebshop__r.MaximalDiscount2__c, prod.SecondDiscountPossible__c, prod.DiscountCorrespondsToBaseDevice__c, false));
            returnMap.put('components', new List<MachineAndAccessoireSuperiorWrapper>{superiorWrapper});
        }
        for(Product2 prod : [SELECT Id, Name, MachineProductSeries__c, ProductGroup__r.Name, ProductSubGroup__r.Name, Description, NotDiscountable__c, BrandWebshop__r.Name, BrandWebshop__r.MaximalDiscount1__c,  BrandWebshop__r.MaximalDiscount2__c, SecondDiscountPossible__c, DiscountCorrespondsToBaseDevice__c
                                FROM Product2 
                                WHERE ProductGroup__r.Name = 'Maschine' AND ProductSubGroup__r.Name = 'Zubehör' AND BrandWebshop__c = : brandId AND MachineProductSeries__c != null
                                AND IsActive = TRUE AND Id IN : standardPricebookEntries.keySet()]){
            MachineAndAccessoireSuperiorWrapper superiorWrapper = innerMap.containsKey(prod.MachineProductSeries__c) ? innerMap.get(prod.MachineProductSeries__c) : new MachineAndAccessoireSuperiorWrapper(prod.MachineProductSeries__c, new List<MachineAndAccessoireWrapper>(), new List<String>());
            if(selectedItems.contains(prod.Id)){
                superiorWrapper.selectedItems.add(prod.Id);
            }
            superiorWrapper.records.add(new MachineAndAccessoireWrapper(prod.Id, prod.MachineProductSeries__c, brandId, machineId, prod.Name, prod.Description, standardPricebookEntries.get(prod.Id), !prod.NotDiscountable__c, prod.BrandWebshop__r.Name, prod.BrandWebshop__r.MaximalDiscount1__c, prod.BrandWebshop__r.MaximalDiscount2__c, prod.SecondDiscountPossible__c, prod.DiscountCorrespondsToBaseDevice__c, false));
            innerMap.put(prod.MachineProductSeries__c, superiorWrapper);
        }
        for(String innerMapKey : innerMap.keySet()){
            returnMap.get('accessories').add(innerMap.get(innerMapKey));
        }
        return returnMap;
    }

    @AuraEnabled(cacheable=false)
    public static List<MachineAndAccessoireWrapper> getProductsByBrand(String brandId, Map<String, Decimal> standardPricebookEntries){
        List<MachineAndAccessoireWrapper> returnList = new List<MachineAndAccessoireWrapper>{};
        for(Product2 prod : [SELECT Id, Name, MachineProductSeries__c, ProductGroup__r.Name, ProductSubGroup__r.Name, Description, NotDiscountable__c, BrandWebshop__r.Name, BrandWebshop__r.MaximalDiscount1__c,  BrandWebshop__r.MaximalDiscount2__c, SecondDiscountPossible__c, DiscountCorrespondsToBaseDevice__c
                                FROM Product2 
                                WHERE ProductGroup__r.Name = 'Maschine' AND ProductSubGroup__r.Name = 'Basisgerät' AND BrandWebshop__c = : brandId AND MachineProductSeries__c != null
                                AND IsActive = TRUE AND Id IN : standardPricebookEntries.keySet()]){
            returnList.add(new MachineAndAccessoireWrapper(prod.Id, prod.MachineProductSeries__c, brandId, null, prod.Name, prod.Description, standardPricebookEntries.get(prod.Id), !prod.NotDiscountable__c, prod.BrandWebshop__r.Name, prod.BrandWebshop__r.MaximalDiscount1__c, prod.BrandWebshop__r.MaximalDiscount2__c, prod.SecondDiscountPossible__c, prod.DiscountCorrespondsToBaseDevice__c, false));
        }
        return returnList;
    }

    public class PrefillObject{
        @AuraEnabled public List<MachineAndAccessoireWrapper> machines { get; set; }
        @AuraEnabled public List<MachineAndAccessoireWrapper> specialMachines { get; set; }
        @AuraEnabled public Map<String, Decimal> params { get; set; }
        @AuraEnabled public Decimal additionalDiscountBaseMachine { get; set; }
        @AuraEnabled public Decimal additionalDiscountBaseComponent { get; set; }
        @AuraEnabled public Decimal additionalDiscountAccessories { get; set; }
        @AuraEnabled public Decimal temporaryDiscountBaseMachine { get; set; }
        @AuraEnabled public Decimal temporaryDiscountBaseComponent { get; set; }
        @AuraEnabled public Decimal temporaryDiscountAccessories { get; set; }
        @AuraEnabled public Decimal specialMachinesPurchasePrice { get; set; }
        @AuraEnabled public Decimal machineMaxDiscount { get; set; }
        @AuraEnabled public String discountViolationReason { get; set; }
        @AuraEnabled public String downPaymentViolationReason { get; set; }
        @AuraEnabled public Id discountViolationCampaign { get; set; }
        @AuraEnabled public Id opportunityId { get; set; }
        public PrefillObject(){
            this.machines = new List<MachineAndAccessoireWrapper>();
            this.specialMachines = new List<MachineAndAccessoireWrapper>();
            this.params = new Map<String, Decimal>();
        }
    }

    @AuraEnabled(cacheable=false)
    public static PrefillObject getPrefillFromQuote(Id quoteId){
        PrefillObject returnObj = new PrefillObject();
        returnObj.specialMachinesPurchasePrice = null;
        returnObj.machineMaxDiscount = null;
        Map<Id, MachineAndAccessoireWrapper> machineMap = new Map<Id, MachineAndAccessoireWrapper>();
        Integer index = 1;
        for(QuoteLineItem qli : [SELECT Id, Product2Id, Product2.Name, MachineDescription__c, product2.MachineProductSeries__c, 
        Product2.BrandWebshop__c, Product2.BrandWebshop__r.Name, Quantity, ListPrice__c, UnitPrice, Discount__c, SpecialDiscount__c, 
        SpecialMachinePurchasePrice__c
        FROM QuoteLineItem WHERE QuoteId = : quoteId AND MachineType__c = : 'Special machine']){
            returnObj.specialMachines.add(new MachineAndAccessoireWrapper(
                index,
                qli.Product2Id, 
                qli.Product2.MachineProductSeries__c, 
                qli.Product2.BrandWebshop__c, 
                null, // Base Device ID
                qli.OfferPositionName__c, 
                qli.MachineDescription__c, 
                qli.UnitPrice, 
                false, // not discountable
                qli.Product2.BrandWebshop__r != null ? qli.Product2.BrandWebshop__r.Name : null, 
                null, // Max Discount 1
                null, // Max Discount 2
                true, // Second Discount Possible
                false, // Corresponds to Base Device
                qli.Quantity,
                qli.Discount__c,
                qli.SpecialDiscount__c,
                false
            ));
            returnObj.specialMachinesPurchasePrice = qli.SpecialMachinePurchasePrice__c;
            index++;
        }
        for(QuoteLineItem qli : [SELECT Id, Product2Id, Product2.DiscountCorrespondsToBaseDevice__c, Product2.SecondDiscountPossible__c, 
        Product2.BrandWebshop__r.MaximalDiscount1__c, Product2.BrandWebshop__r.MaximalDiscount2__c, Product2.NotDiscountable__c, Product2.Name, 
        Product2.MachineProductSeries__c, Product2.BrandWebshop__c, Product2.BrandWebshop__r.Name, Quantity, ListPrice__c, Discount__c, 
        SpecialDiscount__c FROM QuoteLineItem WHERE QuoteId = : quoteId AND MachineType__c = : 'Machine']){
            machineMap.put(qli.Id, new MachineAndAccessoireWrapper(
                index,
                qli.Product2Id, 
                qli.Product2.MachineProductSeries__c, 
                qli.Product2.BrandWebshop__c, 
                null, // Base Device ID
                qli.Product2.Name, 
                null, 
                qli.ListPrice__c, 
                !qli.Product2.NotDiscountable__c, // not discountable
                qli.Product2.BrandWebshop__r != null ? qli.Product2.BrandWebshop__r.Name : null, 
                qli.Product2.BrandWebshop__r != null ? qli.Product2.BrandWebshop__r.MaximalDiscount1__c : null, // Max Discount 1
                qli.Product2.BrandWebshop__r != null ? qli.Product2.BrandWebshop__r.MaximalDiscount2__c : null, // Max Discount 2
                qli.Product2.SecondDiscountPossible__c, // Second Discount Possible
                qli.Product2.DiscountCorrespondsToBaseDevice__c, // Corresponds to Base Device
                qli.Quantity,
                qli.Discount__c,
                qli.SpecialDiscount__c,
                false
            ));
            returnObj.machineMaxDiscount = qli.Product2.BrandWebshop__r != null ? qli.Product2.BrandWebshop__r.MaximalDiscount1__c : null;
            index++;
        }
        for(QuoteLineItem qli : [SELECT Id, ParentMachineQL__c, Product2Id, Product2.DiscountCorrespondsToBaseDevice__c, Product2.SecondDiscountPossible__c, 
        Product2.BrandWebshop__r.MaximalDiscount1__c, Product2.BrandWebshop__r.MaximalDiscount2__c, Product2.NotDiscountable__c, Product2.Name, IsComponent__c,
        Product2.MachineProductSeries__c, Product2.BrandWebshop__c, Product2.BrandWebshop__r.Name, Quantity, ListPrice__c, Discount__c, SpecialDiscount__c 
        FROM QuoteLineItem WHERE QuoteId = : quoteId AND MachineType__c = : 'Accessoire' AND ParentMachineQL__c != NULL]){
            if(machineMap.containsKey(qli.ParentMachineQL__c)){
                machineMap.get(qli.ParentMachineQL__c).accessoires.add(new MachineAndAccessoireWrapper(
                    qli.Product2Id, 
                    qli.Product2.MachineProductSeries__c, 
                    qli.Product2.BrandWebshop__c, 
                    null, // Base Device ID
                    qli.Product2.Name, 
                    null, 
                    qli.ListPrice__c, 
                    !qli.Product2.NotDiscountable__c, // not discountable
                    qli.Product2.BrandWebshop__r.Name, 
                    qli.Product2.BrandWebshop__r != null ? qli.Product2.BrandWebshop__r.MaximalDiscount1__c : null, // Max Discount 1
                    qli.Product2.BrandWebshop__r != null ? qli.Product2.BrandWebshop__r.MaximalDiscount2__c : null, // Max Discount 2
                    qli.Product2.SecondDiscountPossible__c, // Second Discount Possible
                    qli.Product2.DiscountCorrespondsToBaseDevice__c, // Corresponds to Base Device
                    qli.Quantity,
                    qli.Discount__c,
                    qli.SpecialDiscount__c,
                    qli.IsComponent__c
                ));
                machineMap.get(qli.ParentMachineQL__c).hasAccessoires = true;
            }
        }
        returnObj.machines = machineMap.values();
        Quote q = [SELECT Id, OpportunityId, MachineDownpaymentPercent__c, MachineRuntimeInMonths__c, 
        AdditionalDiscountOnAccessories__c, AdditionalDiscounOnBaseComponent__c, AdditionalDiscountOnBaseMachine__c,
        TemporaryDiscountOnAccessories__c, TemporaryDiscountOnBaseComponent__c, TemporaryDiscountOnBaseMachine__c,
        ReasonForDiscountViolation__c, ReasonForDownPaymentViolation__c FROM Quote WHERE Id = : quoteId];
        returnObj.discountViolationReason = q.ReasonForDiscountViolation__c;
        returnObj.downPaymentViolationReason = q.ReasonForDownPaymentViolation__c;

        returnObj.additionalDiscountBaseMachine = q.AdditionalDiscountOnBaseMachine__c;
        returnObj.additionalDiscountBaseComponent = q.AdditionalDiscounOnBaseComponent__c;
        returnObj.additionalDiscountAccessories = q.AdditionalDiscountOnAccessories__c;
        returnObj.temporaryDiscountBaseMachine = q.TemporaryDiscountOnBaseMachine__c;
        returnObj.temporaryDiscountBaseComponent = q.TemporaryDiscountOnBaseComponent__c;
        returnObj.temporaryDiscountAccessories = q.TemporaryDiscountOnAccessories__c;

        returnObj.opportunityId = q.OpportunityId;
        returnObj.params.put('downpaymentPercent', q.MachineDownpaymentPercent__c);
        returnObj.params.put('runtimeInMonths', q.MachineRuntimeInMonths__c);
        return returnObj;
    }

    @AuraEnabled(cacheable=false)
    public static String createOffer(
        String opportunityId,
        String machines,
        String specialMachines,
        Map<String, Object> params,
        String existingQuoteId,
        Boolean surchargeCalculation,
        Decimal additionalDiscountBaseMachine,
        Decimal additionalDiscountBaseComponent,
        Decimal additionalDiscountAccessories,
        Decimal temporaryDiscountBaseMachine,
        Decimal temporaryDiscountBaseComponent,
        Decimal temporaryDiscountAccessories,
        Decimal specialMachinesPurchasePrice
    ){
        try{
            Opportunity opp = [SELECT FIELDS(STANDARD) FROM Opportunity WHERE Id = : opportunityId LIMIT 1];
            if(params.containsKey('discountViolationCampaign')){
                opp.CampaignId = String.valueOf(params.get('discountViolationCampaign'));
                update opp;
            }
            List<OpportunityContactRole> contactRoles = [SELECT Id, ContactId FROM OpportunityContactRole WHERE IsPrimary = TRUE AND OpportunityId = : opportunityId];
            Map<Id, PricebookEntry> standardPricebookEntries = new Map<Id, PricebookEntry>();
            for(PricebookEntry pbe : [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Pricebook2Id = : STANDARD_PRICEBOOK_COPY.Id AND Product2.ProductGroup__r.Name = 'Maschine']){
                standardPricebookEntries.put(pbe.Product2Id, pbe);
            }
            List<MachineAndAccessoireWrapper> machinesWrapper = (List<MachineAndAccessoireWrapper>) System.JSON.deserialize(machines, List<MachineAndAccessoireWrapper>.class);
            List<MachineAndAccessoireWrapper> specialMachinesWrapper = (List<MachineAndAccessoireWrapper>) System.JSON.deserialize(specialMachines, List<MachineAndAccessoireWrapper>.class);
            // Quote Creation
            Quote newQuote = new Quote(
                OpportunityId = opportunityId,
                OwnerId = UserInfo.getUserId(),
                Name = opp.Name + ' Quote ' + System.today().format(),
                Status = 'Draft',
                IsMachineOffer__c = true,
                Pricebook2Id = STANDARD_PRICEBOOK_COPY.Id, 
                MachineSurchargeCalculation__c = surchargeCalculation,
                AdditionalDiscountOnBaseMachine__c = additionalDiscountBaseMachine,
                AdditionalDiscounOnBaseComponent__c = additionalDiscountBaseComponent,
                AdditionalDiscountOnAccessories__c = additionalDiscountAccessories,
                TemporaryDiscountOnBaseMachine__c = temporaryDiscountBaseMachine,
                TemporaryDiscountOnBaseComponent__c = temporaryDiscountBaseComponent,
                TemporaryDiscountOnAccessories__c = temporaryDiscountAccessories,
                ExpirationDate = params.containsKey('offerValidUntil') ? Date.valueOf(String.valueOf(params.get('offerValidUntil'))) : null,
                ReasonForDiscountViolation__c = params.containsKey('hasAccessoireDiscountViolation') && String.valueOf(params.get('hasAccessoireDiscountViolation')) == 'true' && params.containsKey('discountViolationReason') ? String.valueOf(params.get('discountViolationReason')) : null,
                ReasonForDownPaymentViolation__c = params.containsKey('downPaymentViolationReason') ? String.valueOf(params.get('downPaymentViolationReason')) : null,
                MachineGrossAmount__c = params.containsKey('totalGrossAmount') ? Decimal.valueOf(String.valueOf(params.get('totalGrossAmount'))) : null,
                MachineTotalAmountIncludingTax__c = params.containsKey('vatAmount') ? Decimal.valueOf(String.valueOf(params.get('vatAmount'))) : null,
                MachineNetAmount__c = params.containsKey('totalNetAmount') ? Decimal.valueOf(String.valueOf(params.get('totalNetAmount'))) : null,
                MachineDownpaymentPercent__c = params.containsKey('downpaymentPercent') ? Integer.valueOf(String.valueOf(params.get('downpaymentPercent'))) : null,
                MachineTotalAmountMinusDownpayment__c = params.containsKey('downpaymentAmount') ? Decimal.valueOf(String.valueOf(params.get('downpaymentAmount'))) : null,
                MachineTotalFinancingAmount__c = params.containsKey('financingAmount') ? Decimal.valueOf(String.valueOf(params.get('financingAmount'))) : null,
                MachineRuntimeInMonths__c = params.containsKey('runtimeInMonths') ? Integer.valueOf(String.valueOf(params.get('runtimeInMonths'))) : null,
                MachineMonthlyRateInEuro__c = params.containsKey('monthlyRateAmount') ? Decimal.valueOf(String.valueOf(params.get('monthlyRateAmount'))) : null,
                MachineFinalRateInEuro__c = params.containsKey('finalMonthlyRateAmount') ? Decimal.valueOf(String.valueOf(params.get('finalMonthlyRateAmount'))) : null,
                MachineCustomerDiscountTotalInEuro__c = params.containsKey('totalDiscount') ? Decimal.valueOf(String.valueOf(params.get('totalDiscount'))) : null,
                MachineCustomerDiscountTotalPercent__c = params.containsKey('totalDiscountPercent') ? Decimal.valueOf(String.valueOf(params.get('totalDiscountPercent'))) : null,
                MachineProducerDiscountTotalInEuro__c = params.containsKey('totalProducerDiscount') ? Decimal.valueOf(String.valueOf(params.get('totalProducerDiscount'))) : null,
                MachineProducerDiscountTotalPercent__c = params.containsKey('totalProducerDiscountPercent') ? Decimal.valueOf(String.valueOf(params.get('totalProducerDiscountPercent'))) : null,
                MachineRoasterDiscountTotalInEuro__c = params.containsKey('totalRoasterDiscount') ? Decimal.valueOf(String.valueOf(params.get('totalRoasterDiscount'))) : null
            );
            if(!contactRoles.isEmpty()){
                newQuote.ContactId = contactRoles[0].ContactId;
            }
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.allowFieldTruncation = true;
            Database.SaveResult sr = null;
            if(String.isNotBlank(existingQuoteId)){
                newQuote.Id = existingQuoteId;
                sr = Database.update(newQuote, dml);
            } else {
                sr = Database.insert(newQuote, dml);
            }
            if(sr.isSuccess() && newQuote.Id != null){
                if(newQuote.ContactId != null){
                    List<SignatureEntitlement__c> ubList = [SELECT Id FROM SignatureEntitlement__c WHERE Contact__c = : newQuote.ContactId AND Quote__c = : newQuote.Id LIMIT 1];
                    if(!ubList.isEmpty()){
                        SignatureEntitlement__c ub = ubList[0];
                        ub.MainContactPerson__c  = true;
                        update ub;
                    } else {
                        SignatureEntitlement__c  ub = new SignatureEntitlement__c (
                            Contact__c = newQuote.ContactId,
                            Quote__c = newQuote.Id,
                            MainContactPerson__c  = true
                        );
                        insert ub;
                    }
                }
                if(String.isNotBlank(existingQuoteId)){
                    delete [SELECT Id FROM QuoteLineItem WHERE QuoteId = : existingQuoteId];
                }  
                // Quote Line Item Creation
                Map<Integer, QuoteLineItem> quoteLineItems = new Map<Integer, QuoteLineItem>();
                List<QuoteLineItem> quoteLineItemsAccessoires = new List<QuoteLineItem>();
                List<QuoteLineItem> specialQuoteLineItems = new List<QuoteLineItem>();
                if(!specialMachinesWrapper.isEmpty()){
                    List<Product2> specialMachinesProducts = [SELECT Id FROM Product2 WHERE IsActive = TRUE AND Name = 'Sondermaschine'];
                    if(!specialMachinesProducts.isEmpty() && standardPricebookEntries.containsKey(specialMachinesProducts[0].Id)){
                        for(MachineAndAccessoireWrapper machineWrapper : specialMachinesWrapper){
                            specialQuoteLineItems.add(new QuoteLineItem(
                                QuoteId = newQuote.Id,
                                Product2Id = specialMachinesProducts[0].Id,
                                Quantity = machineWrapper.quantity,
                                Quantity__c = machineWrapper.quantity,
                                MachineDescription__c = machineWrapper.description,
                                UnitPrice = machineWrapper.salePrice,
                                ListPrice__c = machineWrapper.specialMachinePrice,
                                TotalPrice__c = machineWrapper.rowTotal,
                                Discount = (machineWrapper.discount ?? 0) + (machineWrapper.specialDiscount ?? 0),
                                Discount__c = machineWrapper.discount,
                                SpecialDiscount__c = machineWrapper.specialDiscount,
                                PricebookEntryId = standardPricebookEntries.get(specialMachinesProducts[0].Id).Id,
                                MachineType__c = 'Special machine',
                                OfferPositionName__c = machineWrapper.title,
                                SpecialMachinePurchasePrice__c = specialMachinesPurchasePrice
                            ));
                        }
                    }
                }
                for(MachineAndAccessoireWrapper machineWrapper : machinesWrapper){
                    if(String.isNotBlank(machineWrapper.id)){
                        if(standardPricebookEntries.containsKey(machineWrapper.id)){
                            quoteLineItems.put(machineWrapper.index, new QuoteLineItem(
                                QuoteId = newQuote.Id,
                                Product2Id = machineWrapper.id,
                                Quantity = machineWrapper.quantity,
                                Quantity__c = machineWrapper.quantity,
                                UnitPrice = machineWrapper.salePrice,
                                ListPrice__c = machineWrapper.price,
                                TotalPrice__c = machineWrapper.rowTotal,
                                Discount = (machineWrapper.discount ?? 0) + (machineWrapper.specialDiscount ?? 0),
                                Discount__c = machineWrapper.discount,
                                SpecialDiscount__c = machineWrapper.specialDiscount,
                                PricebookEntryId = standardPricebookEntries.get(machineWrapper.id).Id,
                                MachineType__c = 'Machine',
                                ParentMachine__c = machineWrapper.id
                            ));
                        }
                    }
                }
                if(!quoteLineItems.isEmpty()){
                    insert quoteLineItems.values();
                }
                
                for(MachineAndAccessoireWrapper machineWrapper : machinesWrapper){
                    for(MachineAndAccessoireWrapper wrapper : machineWrapper.accessoires){
                        if(String.isNotBlank(wrapper.id) && standardPricebookEntries.containsKey(wrapper.id)){
                            quoteLineItemsAccessoires.add(new QuoteLineItem(
                                QuoteId = newQuote.Id,
                                Product2Id = wrapper.id,
                                Quantity = wrapper.quantity,
                                Quantity__c = wrapper.quantity,
                                UnitPrice = wrapper.salePrice,
                                ListPrice__c = wrapper.price,
                                TotalPrice__c = wrapper.rowTotal,
                                Discount = (wrapper.discount ?? 0) + (wrapper.specialDiscount ?? 0),
                                Discount__c = wrapper.discount,
                                SpecialDiscount__c = wrapper.specialDiscount,
                                PricebookEntryId = standardPricebookEntries.get(wrapper.id).Id,
                                MachineType__c = 'Accessoire',
                                ParentMachine__c = machineWrapper.id,
                                ParentMachineQL__c = quoteLineItems.get(machineWrapper.index).Id,
                                IsComponent__c = wrapper.isComponent
                            ));
                        }
                    }
                }
                if(!quoteLineItemsAccessoires.isEmpty()){
                    insert quoteLineItemsAccessoires;
                }
                if(!specialQuoteLineItems.isEmpty()){
                    insert specialQuoteLineItems;
                }
                return newQuote.Id;
            } else {
                insert new ErrorLogging__c(
                    Error__c = 'Error: Quote not created',
                    RecordIDs__c = opportunityId,
                    ProcessName__c = 'MachineConfiguratorController.createOffer()'
                );
                return 'Error: No Opportunity';
            }
        } catch(Exception e){
            System.debug(e);
            insert new ErrorLogging__c(
                Error__c = e.getMessage(),
                RecordIDs__c = opportunityId,
                ProcessName__c = 'MachineConfiguratorController.createOffer()'
            );
        }
        return null;
    }

    
    @InvocableMethod(label='Cancel Quote Approvals' 
                        description='Cancels all standard approval processes for the given Quote IDs'
                        category='Quote')
    public static void cancelQuoteApprovals(List<List<Id>> quoteIds) {
        System.debug(quoteIds);
        List<Id> realQuoteIds = new List<Id>();
        if (quoteIds == null || quoteIds.isEmpty() || quoteIds[0].isEmpty()) {
            return;
        }
        for(List<Id> quoteIdsInner : quoteIds){
            realQuoteIds.addAll(quoteIdsInner);
        }
        
        try {
            // Get all active process instances for the quotes
            List<ProcessInstance> activeProcesses = [
                SELECT Id, Status, TargetObjectId 
                FROM ProcessInstance 
                WHERE TargetObjectId IN :realQuoteIds 
                AND Status = 'Pending'
            ];            
            if (activeProcesses.isEmpty()) {
                return;
            }            
            // Get process instance steps to create workitem approvals
            List<ProcessInstanceWorkitem> workItems = [
                SELECT Id
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstanceId IN :activeProcesses AND ActorId != null
            ];

            if (workItems.isEmpty()) {
                return;
            }
            List<Approval.ProcessWorkitemRequest> approvalRequests = new List<Approval.ProcessWorkitemRequest>();
            
            for (ProcessInstanceWorkitem workItem : workItems) {
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setWorkitemId(workItem.Id);
                req.setAction('Removed'); // This action cancels the approval process
                req.setComments('Approval process cancelled via automated process');
                approvalRequests.add(req);
            }
            List<Approval.ProcessResult> results = Approval.process(approvalRequests);
            for (Integer i = 0; i < results.size(); i++) {
                Approval.ProcessResult result = results[i];
                if (!result.isSuccess()) {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Error: ' + error.getMessage());
                    }
                }
            }
            
        } catch (Exception e) {
            System.debug('Exception occurred while cancelling quote approvals: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    }
    public class MachineAndAccessoireSuperiorWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public String nameAlt;
        @AuraEnabled public List<MachineAndAccessoireWrapper> records;
        @AuraEnabled public List<String> selectedItems;
        public MachineAndAccessoireSuperiorWrapper(String name, List<MachineAndAccessoireWrapper> records, List<String> selectedItems){
            this.name = name;
            this.nameAlt = name.replaceAll('[^a-zA-Z0-9]', '');
            this.records = records;
            this.selectedItems = selectedItems;
        }
    }

    public class MachineAndAccessoireWrapper{
        @AuraEnabled public Integer index;
        @AuraEnabled public String id;
        @AuraEnabled public String baseDeviceId;
        @AuraEnabled public String description;
        @AuraEnabled public String sObjectType;
        @AuraEnabled public String icon;
        @AuraEnabled public String productSeries;
        @AuraEnabled public String brandId;
        @AuraEnabled public Decimal price;
        @AuraEnabled public Decimal specialMachinePrice;
        @AuraEnabled public String title;
        @AuraEnabled public String subtitle;
        @AuraEnabled public Boolean discountable;
        @AuraEnabled public Boolean isBaseDevice;
        @AuraEnabled public Integer quantity;
        @AuraEnabled public Decimal discount;
        @AuraEnabled public Decimal specialDiscount;
        @AuraEnabled public Decimal salePrice;
        @AuraEnabled public Decimal rowTotal;
        @AuraEnabled public Decimal maxDiscountOne;
        @AuraEnabled public Decimal maxDiscountTwo;
        @AuraEnabled public Boolean hasMaxDiscountOne;
        @AuraEnabled public Boolean hasMaxDiscountOneViolation;
        @AuraEnabled public String maxDiscountOneString;
        @AuraEnabled public Boolean hasMaxDiscountTwo;
        @AuraEnabled public Boolean hasMaxDiscountTwoViolation;
        @AuraEnabled public String maxDiscountTwoString;
        @AuraEnabled public Boolean secondDiscountPossible;
        @AuraEnabled public Boolean discountCorrespondsToBaseDevice;
        @AuraEnabled public Boolean hasAccessoires;
        @AuraEnabled public List<MachineAndAccessoireWrapper> accessoires;
        @AuraEnabled public Map<String, List<MachineAndAccessoireWrapper>> accessoiresPre;
        @AuraEnabled public List<MachineAndAccessoireWrapper> components;
        @AuraEnabled public Boolean isComponent;
        public MachineAndAccessoireWrapper(Integer index, String id, String productSeries, String brandId, String baseDeviceId, String title, String description, Decimal price, Boolean discountable, String subtitle, Decimal maxDiscountOne, Decimal maxDiscountTwo, Boolean secondDiscountPossible, Boolean discountCorrespondsToBaseDevice, Decimal quantity, Decimal discount, Decimal specialDiscount, Boolean isComponent){
            this(id, productSeries, brandId, baseDeviceId, title, description, price, discountable, subtitle, maxDiscountOne, maxDiscountTwo, secondDiscountPossible, discountCorrespondsToBaseDevice, isComponent);
            this.quantity = Integer.valueOf(quantity);
            this.discount = discount;
            this.specialDiscount = specialDiscount;
            this.index = index;
        }
        public MachineAndAccessoireWrapper(String id, String productSeries, String brandId, String baseDeviceId, String title, String description, Decimal price, Boolean discountable, String subtitle, Decimal maxDiscountOne, Decimal maxDiscountTwo, Boolean secondDiscountPossible, Boolean discountCorrespondsToBaseDevice, Decimal quantity, Decimal discount, Decimal specialDiscount, Boolean isComponent){
            this(id, productSeries, brandId, baseDeviceId, title, description, price, discountable, subtitle, maxDiscountOne, maxDiscountTwo, secondDiscountPossible, discountCorrespondsToBaseDevice, isComponent);
            this.quantity = Integer.valueOf(quantity);
            this.discount = discount;
            this.specialDiscount = specialDiscount;
        }

        public MachineAndAccessoireWrapper(Integer index, String id, String productSeries, String brandId, String baseDeviceId, String title, String description, Decimal price, Boolean discountable, String subtitle, Decimal maxDiscountOne, Decimal maxDiscountTwo, Boolean secondDiscountPossible, Boolean discountCorrespondsToBaseDevice, Boolean isComponent){
            this(id, productSeries, brandId, baseDeviceId, title, description, price, discountable, subtitle, maxDiscountOne, maxDiscountTwo, secondDiscountPossible, discountCorrespondsToBaseDevice, isComponent);
            this.index = index;
        }

        public MachineAndAccessoireWrapper(String id, String productSeries, String brandId, String baseDeviceId, String title, String description, Decimal price, Boolean discountable, String subtitle, Decimal maxDiscountOne, Decimal maxDiscountTwo, Boolean secondDiscountPossible, Boolean discountCorrespondsToBaseDevice, Boolean isComponent){
            this.id = id;
            this.baseDeviceId = baseDeviceId;
            this.isBaseDevice = String.isNotBlank(this.baseDeviceId);
            this.title = title;
            this.description = description;
            this.price = price;
            this.productSeries = productSeries;
            this.brandId = brandId;
            this.discountable = discountable;
            this.icon = 'standard:product';
            this.sObjectType = 'Product2';
            this.subtitle = subtitle; // Brand Name
            this.quantity = 1;
            this.discount = 0;
            this.specialDiscount = 0;
            this.salePrice = price;
            this.rowTotal = price;
            this.maxDiscountOne = maxDiscountOne;
            this.maxDiscountTwo = maxDiscountTwo;
            this.hasMaxDiscountOne = this.maxDiscountOne != null;
            this.maxDiscountOneString = String.format(System.Label.MachineConfiguratorMaxDiscount, new List<String>{subtitle ?? '', String.valueOf(this.maxDiscountOne)});
            this.maxDiscountTwoString = String.format(System.Label.MachineConfiguratorMaxDiscount, new List<String>{subtitle ?? '', String.valueOf(this.maxDiscountTwo)});
            this.hasMaxDiscountTwo = this.maxDiscountTwo != null;
            this.secondDiscountPossible = secondDiscountPossible;
            this.discountCorrespondsToBaseDevice = discountCorrespondsToBaseDevice;
            this.hasMaxDiscountOneViolation = false;
            this.hasMaxDiscountTwoViolation = false;
            this.hasAccessoires = false;
            this.accessoiresPre = new Map<String, List<MachineAndAccessoireWrapper>>();
            this.accessoires = new List<MachineAndAccessoireWrapper>();
            this.isComponent = isComponent;
        }
    }

    public class OptionWrapper{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        
        public OptionWrapper(){
            this.value = '-';
            this.label = '-';
        }
        
        public OptionWrapper(String label, String value){
            this.label = label;
            this.value = value;
        }
    }

}