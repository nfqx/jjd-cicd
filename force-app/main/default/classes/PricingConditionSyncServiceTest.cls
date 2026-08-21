@IsTest
public class PricingConditionSyncServiceTest {

    public static Integer pricingConditionSyncEventsCount = 0;
    public static List<PricingConditionSync__e> capturedEvents = new List<PricingConditionSync__e>();

    @TestSetup
    static void setup() {
        Account acc = new Account(
            Name = 'Pricing Test Account',
            ERPCustomerNumber__c = '712708',
            DistributionChannel__c = '20',
            SalesOrganization__c = '1100',
            ShippingCondition__c = 'KP',
            CurrencyIsoCode = 'EUR',
            SalesCategory__c = 'Vending'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Pricing Sync Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;
    }

    public static void mockEventBusPublish(List<SObject> events) {
        if (events == null || events.isEmpty()) return;
        for (SObject e : events) {
            if (e instanceof PricingConditionSync__e) {
                pricingConditionSyncEventsCount++;
                capturedEvents.add((PricingConditionSync__e) e);
            }
        }
    }

    @IsTest
    static void publishForClosedWonOpportunities_shouldPublishEvent_whenStageBecomesClosedWon() {
        //Having
        Opportunity opp = [SELECT Id, StageName, AccountId FROM Opportunity LIMIT 1];

        //When
        Test.startTest();
        opp.StageName = 'Closed Won';
        update opp;
        Test.stopTest();

        //Then
        System.assertEquals(1, pricingConditionSyncEventsCount,
            'Should publish exactly one PricingConditionSync__e when stage becomes Closed Won');
    }

    @IsTest
    static void publishForClosedWonOpportunities_shouldNotPublish_whenStageIsNotClosedWon() {
        //Having
        Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        opp.StageName = 'Angebotsphase';
        update opp;
        pricingConditionSyncEventsCount = 0;

        //When
        Test.startTest();
        opp.StageName = 'Angebot verschickt';
        update opp;
        Test.stopTest();

        //Then
        System.assertEquals(0, pricingConditionSyncEventsCount, 'Should not publish when stage is not Closed Won');
    }

    @IsTest
    static void publishForClosedWonOpportunities_shouldNotPublish_whenNewOpportunityIsNotClosedWon() {
        //Having
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity newOpp = new Opportunity(
            Name = 'New Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(14),
            AccountId = acc.Id
        );

        //When
        Test.startTest();
        insert newOpp;
        Test.stopTest();

        //Then
        System.assertEquals(0, pricingConditionSyncEventsCount, 'Should not publish when new opportunity is not Closed Won');
    }

    @IsTest
    static void publishForClosedWonOpportunities_shouldHandleNullAndEmptyMaps() {
        //Having
        // (no preconditions)

        //When
        Test.startTest();
        PricingConditionSyncService.publishForClosedWonOpportunities(null, null);
        PricingConditionSyncService.publishForClosedWonOpportunities(new Map<Id, Opportunity>(), null);
        Test.stopTest();

        //Then
        System.assertEquals(0, pricingConditionSyncEventsCount, 'Should handle null/empty maps');
    }

    @IsTest
    static void publishForClosedWonOpportunities_shouldPublishWithoutQuote_whenOpportunityHasNoQuote() {
        //Having
        Opportunity opp = [SELECT Id, StageName, AccountId FROM Opportunity LIMIT 1];

        //When
        Test.startTest();
        opp.StageName = 'Closed Won';
        update opp;
        Test.stopTest();

        //Then
        System.assertEquals(1, pricingConditionSyncEventsCount,
            'Should still publish event even when no Quote exists for the opportunity');
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(capturedEvents[0].PayloadJson__c);
        Map<String, Object> quoteMap = (Map<String, Object>) root.get('quote');
        System.assertEquals(0, quoteMap.size(), 'Quote section should be empty when no quote exists');
        List<Object> qlis = (List<Object>) root.get('quoteLineItems');
        System.assertEquals(0, qlis.size(), 'Quote line items should be empty when no quote exists');
    }

    @IsTest
    static void getApplicableAccounts_shouldReturnSelectedFields_whenAccountExists() {
        //Having
        Account acc = [SELECT Id FROM Account LIMIT 1];

        //When
        Test.startTest();
        List<Account> result = PricingConditionSyncService.getApplicableAccounts(new Set<Id>{ acc.Id });
        Test.stopTest();

        //Then
        System.assertEquals(1, result.size(), 'Should return the seeded account');
        System.assertEquals('712708', result[0].ERPCustomerNumber__c);
        System.assertEquals('20', result[0].DistributionChannel__c);
        System.assertEquals('Vending', result[0].SalesCategory__c);
    }

    @IsTest
    static void getApplicableAccounts_shouldReturnEmpty_whenNoIdsMatch() {
        //Having
        Set<Id> noIds = new Set<Id>();

        //When
        Test.startTest();
        List<Account> result = PricingConditionSyncService.getApplicableAccounts(noIds);
        Test.stopTest();

        //Then
        System.assertEquals(0, result.size(), 'Empty input should yield empty result');
    }

    @IsTest
    static void getLatestQuoteByOpportunityId_shouldReturnMostRecentQuotePerOpportunity() {
        //Having
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Quote older = new Quote(Name = 'Older', OpportunityId = opp.Id);
        Quote newer = new Quote(Name = 'Newer', OpportunityId = opp.Id);
        insert new List<Quote>{ older, newer };

        //When
        Test.startTest();
        Map<Id, Quote> result = PricingConditionSyncService.getLatestQuoteByOpportunityId(new Set<Id>{ opp.Id });
        Test.stopTest();

        //Then
        System.assertEquals(1, result.size(), 'Should produce one entry per opportunity');
        System.assertNotEquals(null, result.get(opp.Id), 'Should include a quote for the opportunity');
    }

    @IsTest
    static void getLatestQuoteByOpportunityId_shouldReturnEmpty_whenInputIsEmpty() {
        //Having
        Set<Id> empty = new Set<Id>();

        //When
        Test.startTest();
        Map<Id, Quote> result = PricingConditionSyncService.getLatestQuoteByOpportunityId(empty);
        Test.stopTest();

        //Then
        System.assertEquals(0, result.size(), 'Empty input should yield empty map');
    }

    @IsTest
    static void getQuoteLineItemsByQuoteId_shouldReturnEmpty_whenInputIsEmpty() {
        //Having
        Set<Id> empty = new Set<Id>();

        //When
        Test.startTest();
        Map<Id, List<QuoteLineItem>> result = PricingConditionSyncService.getQuoteLineItemsByQuoteId(empty);
        Test.stopTest();

        //Then
        System.assertEquals(0, result.size(), 'Empty input should yield empty map');
    }

    @IsTest
    static void buildApplicableAccountMap_shouldMapAllAccountFieldsIncludingSalesCategory() {
        //Having
        Account a = new Account(
            DistributionChannel__c = '20',
            SalesOrganization__c = '1100',
            ShippingCondition__c = 'KP',
            ERPCustomerNumber__c = '712708',
            CurrencyIsoCode = 'EUR',
            SalesCategory__c = 'Vending'
        );

        //When
        Map<String, Object> m = PricingConditionSyncService.buildApplicableAccountMap(a);

        //Then
        System.assertEquals('20', m.get('distributionChannel'));
        System.assertEquals('1100', m.get('salesOrganization'));
        System.assertEquals('KP', m.get('shippingCondition'));
        System.assertEquals('712708', m.get('erpCustomerNumber'));
        System.assertEquals('EUR', m.get('currencyIsoCode'));
        System.assertEquals('Vending', m.get('salesCategory'));
    }

    @IsTest
    static void buildQuoteMap_shouldReturnEmpty_whenQuoteIsNull() {
        //Having
        Quote q = null;

        //When
        Map<String, Object> m = PricingConditionSyncService.buildQuoteMap(q);

        //Then
        System.assertEquals(0, m.size(), 'Null quote should produce empty map');
    }

    @IsTest
    static void buildQuoteMap_shouldEmitOnlyNonNullDiscountFields() {
        //Having
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Quote q = new Quote(
            Name = 'Sample Quote',
            OpportunityId = opp.Id,
            DiscountBaseDiscountCoffee__c = 5,
            DiscountBaseDiscountTea__c = 10,
            DiscountVariousTeaItems__c = 20
        );
        insert q;
        q = [
            SELECT Id, QuoteNumber, Name,
                   DiscountBaseDiscountCoffee__c, DiscountBaseDiscountTea__c,
                   DiscountBaseDiscountHotChocolate__c, DiscountBaseDiscountOther__c,
                   DiscountPurchaseQuantityCoffee__c, DiscountPurchaseQuantityTea__c,
                   DiscountPurchaseQuantityHotChocolate__c, DiscountPurchaseQuantityOther__c,
                   DiscountVariousCoffeeAccessories__c, DiscountVariousTeaItems__c,
                   DiscountVariousDrinkingChocolates__c, DiscountVariousMiscellaneousItems__c,
                   DiscountIndexCondition__c,
                   DiscountBrandRepresentationTable__c, DiscountBrandRepresentationOnSite__c,
                   DiscountBrandRepresentationMenu__c, DiscountDigitalOrdering__c
            FROM Quote WHERE Id = :q.Id
        ];

        //When
        Map<String, Object> m = PricingConditionSyncService.buildQuoteMap(q);

        //Then
        System.assertEquals(String.valueOf(q.Id), m.get('id'));
        System.assertEquals(q.QuoteNumber, m.get('quoteNumber'));
        System.assertEquals('Sample Quote', m.get('name'));
        System.assertEquals(5, m.get('DiscountBaseDiscountCoffee__c'));
        System.assertEquals(10, m.get('DiscountBaseDiscountTea__c'));
        System.assertEquals(20, m.get('DiscountVariousTeaItems__c'));
        System.assert(!m.containsKey('DiscountBaseDiscountHotChocolate__c'),
            'Null discount fields must not appear in the map');
        System.assert(!m.containsKey('DiscountDigitalOrdering__c'),
            'Null discount fields must not appear in the map');
    }

    @IsTest
    static void buildQuoteLineItemMaps_shouldReturnEmpty_whenInputIsNullOrEmpty() {
        //Having
        List<QuoteLineItem> empty = new List<QuoteLineItem>();

        //When
        List<Map<String, Object>> nullResult = PricingConditionSyncService.buildQuoteLineItemMaps(null);
        List<Map<String, Object>> emptyResult = PricingConditionSyncService.buildQuoteLineItemMaps(empty);

        //Then
        System.assertEquals(0, nullResult.size());
        System.assertEquals(0, emptyResult.size());
    }

    @IsTest
    static void buildPayloadJson_shouldEmitExpectedKeysAndOmitProductConditionsAndAccountCondition() {
        //Having
        Account acc = [SELECT Id, DistributionChannel__c, SalesOrganization__c, ShippingCondition__c,
                              ERPCustomerNumber__c, CurrencyIsoCode, SalesCategory__c FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        //When
        String payload = PricingConditionSyncService.buildPayloadJson(acc, opp.Id, null, null);

        //Then
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(payload);
        System.assertEquals(String.valueOf(opp.Id), root.get('opportunityId'));
        System.assert(root.containsKey('applicableAccount'), 'applicableAccount should be present');
        System.assert(root.containsKey('quote'), 'quote should be present');
        System.assert(root.containsKey('quoteLineItems'), 'quoteLineItems should be present');
        System.assert(!root.containsKey('productConditions'),
            'productConditions must not appear in payload');
        System.assert(!root.containsKey('accountCondition'),
            'accountCondition must not appear in payload');
    }

    @IsTest
    static void publishEvents_shouldRouteThroughMock_whenRunningTests() {
        //Having
        pricingConditionSyncEventsCount = 0;
        capturedEvents = new List<PricingConditionSync__e>();
        List<PricingConditionSync__e> events = new List<PricingConditionSync__e>{
            new PricingConditionSync__e(
                OpportunityId__c = 'X', AccountId__c = 'Y', PayloadJson__c = '{}'
            )
        };

        //When
        Test.startTest();
        PricingConditionSyncService.publishEvents(events);
        Test.stopTest();

        //Then
        System.assertEquals(1, pricingConditionSyncEventsCount,
            'Mock should receive published events when useTestMock is true');
    }

    @IsTest
    static void buildPricingConditionSyncEvents_shouldReturnEmpty_whenNoApplicableAccount() {
        //Having
        Id fakeAccId = '001000000000000AAA';
        Id fakeOppId = '006000000000000AAA';
        PricingConditionSyncService.ClosedWonPair pair =
            new PricingConditionSyncService.ClosedWonPair(fakeOppId, fakeAccId);

        //When
        Test.startTest();
        List<PricingConditionSync__e> result =
            PricingConditionSyncService.buildPricingConditionSyncEvents(
                new List<PricingConditionSyncService.ClosedWonPair>{ pair }
            );
        Test.stopTest();

        //Then
        System.assertEquals(0, result.size(),
            'Should return no events when no applicable account exists');
    }

    @IsTest
    static void publishForClosedWonOpportunities_shouldEmitFullPayload_withQuoteAndQuoteLineItems() {
        //Having
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];

        Product2 prod = new Product2(Name = 'Test Coffee', ProductCode = 'COFFEE-001', IsActive = true);
        insert prod;

        Id stdPbId = Test.getStandardPricebookId();
        PricebookEntry stdPbe = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id = prod.Id,
            UnitPrice = 25,
            IsActive = true
        );
        insert stdPbe;

        Quote q = new Quote(
            Name = 'PricingSync Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = stdPbId,
            DiscountBaseDiscountCoffee__c = 5,
            DiscountBaseDiscountTea__c = 10,
            DiscountVariousTeaItems__c = 20,
            DiscountBrandRepresentationTable__c = 1,
            DiscountIndexCondition__c = 3
        );
        insert q;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            Product2Id = prod.Id,
            PricebookEntryId = stdPbe.Id,
            Quantity = 2,
            UnitPrice = 25,
            SpecialDiscount__c = 14
        );
        insert qli;

        pricingConditionSyncEventsCount = 0;
        capturedEvents = new List<PricingConditionSync__e>();

        //When
        Test.startTest();
        opp.StageName = 'Closed Won';
        update opp;
        Test.stopTest();

        //Then
        System.assertEquals(1, pricingConditionSyncEventsCount,
            'Should publish exactly one event');
        PricingConditionSync__e event = capturedEvents[0];
        System.assertEquals(String.valueOf(opp.Id), event.OpportunityId__c);
        System.assertEquals(String.valueOf(acc.Id), event.AccountId__c);

        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(event.PayloadJson__c);
        System.assertEquals(String.valueOf(opp.Id), root.get('opportunityId'));
        System.assert(!root.containsKey('productConditions'), 'Payload must not contain productConditions');
        System.assert(!root.containsKey('accountCondition'), 'Payload must not contain accountCondition');

        Map<String, Object> applicableAccount = (Map<String, Object>) root.get('applicableAccount');
        System.assertEquals('712708', applicableAccount.get('erpCustomerNumber'));
        System.assertEquals('20', applicableAccount.get('distributionChannel'));
        System.assertEquals('1100', applicableAccount.get('salesOrganization'));
        System.assertEquals('KP', applicableAccount.get('shippingCondition'));
        System.assertEquals('EUR', applicableAccount.get('currencyIsoCode'));
        System.assertEquals('Vending', applicableAccount.get('salesCategory'));

        Map<String, Object> quoteMap = (Map<String, Object>) root.get('quote');
        System.assertEquals(String.valueOf(q.Id), quoteMap.get('id'));
        System.assertEquals('PricingSync Quote', quoteMap.get('name'));
        System.assertEquals(5, quoteMap.get('DiscountBaseDiscountCoffee__c'));
        System.assertEquals(10, quoteMap.get('DiscountBaseDiscountTea__c'));
        System.assertEquals(20, quoteMap.get('DiscountVariousTeaItems__c'));
        System.assertEquals(1, quoteMap.get('DiscountBrandRepresentationTable__c'));
        System.assertEquals(3, quoteMap.get('DiscountIndexCondition__c'));
        System.assert(!quoteMap.containsKey('DiscountBaseDiscountOther__c'),
            'Null discount fields must not appear');

        List<Object> qlis = (List<Object>) root.get('quoteLineItems');
        System.assertEquals(1, qlis.size(), 'One quote line item expected');
        Map<String, Object> qliMap = (Map<String, Object>) qlis[0];
        System.assertEquals(String.valueOf(qli.Id), qliMap.get('id'));
        System.assertEquals(String.valueOf(prod.Id), qliMap.get('productId'));
        System.assertEquals('COFFEE-001', qliMap.get('productCode'));
        System.assertEquals(14, qliMap.get('specialDiscountInE'));
    }
}