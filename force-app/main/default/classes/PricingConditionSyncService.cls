public without sharing class PricingConditionSyncService {

    public static final String CLOSED_WON_STAGE = 'Closed Won';

    @TestVisible
    private static Boolean useTestMock = Test.isRunningTest();

    private static final String DEBUG_PREFIX = '[PricingConditionSync]';

    private static final List<String> QUOTE_DISCOUNT_FIELDS = new List<String>{
        'DiscountBaseDiscountCoffee__c',
        'DiscountBaseDiscountTea__c',
        'DiscountBaseDiscountHotChocolate__c',
        'DiscountBaseDiscountOther__c',
        'DiscountPurchaseQuantityCoffee__c',
        'DiscountPurchaseQuantityTea__c',
        'DiscountPurchaseQuantityHotChocolate__c',
        'DiscountPurchaseQuantityOther__c',
        'DiscountVariousCoffeeAccessories__c',
        'DiscountVariousTeaItems__c',
        'DiscountVariousDrinkingChocolates__c',
        'DiscountVariousMiscellaneousItems__c',
        'DiscountIndexCondition__c',
        'DiscountBrandRepresentationTable__c',
        'DiscountBrandRepresentationOnSite__c',
        'DiscountBrandRepresentationMenu__c',
        'DiscountDigitalOrdering__c'
    };

    public static void publishForClosedWonOpportunities(Map<Id, Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunities) {
        if (newOpportunities == null || newOpportunities.isEmpty()) {
            return;
        }

        List<ClosedWonPair> pairs = new List<ClosedWonPair>();
        for (Id oppId : newOpportunities.keySet()) {
            Opportunity newOpp = newOpportunities.get(oppId);
            if (newOpp.AccountId == null) {
                continue;
            }
            Boolean justClosedWon = CLOSED_WON_STAGE.equals(newOpp.StageName)
                && (oldOpportunities == null
                    || !CLOSED_WON_STAGE.equals(oldOpportunities.get(oppId).StageName));
            if (justClosedWon) {
                pairs.add(new ClosedWonPair(oppId, newOpp.AccountId));
            }
        }

        if (pairs.isEmpty()) {
            return;
        }

        List<PricingConditionSync__e> events = buildPricingConditionSyncEvents(pairs);
        if (!events.isEmpty()) {
            publishEvents(events);
        }
    }

    @TestVisible
    private static List<PricingConditionSync__e> buildPricingConditionSyncEvents(List<ClosedWonPair> pairs) {
        List<PricingConditionSync__e> events = new List<PricingConditionSync__e>();

        Set<Id> accountIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        for (ClosedWonPair p : pairs) {
            accountIds.add(p.accountId);
            opportunityIds.add(p.opportunityId);
        }

        List<Account> applicableAccounts = getApplicableAccounts(accountIds);
        if (applicableAccounts.isEmpty()) {
            return events;
        }

        Map<Id, Account> accountById = new Map<Id, Account>();
        for (Account a : applicableAccounts) {
            accountById.put(a.Id, a);
        }

        Map<Id, Quote> latestQuoteByOpportunityId = getLatestQuoteByOpportunityId(opportunityIds);

        Set<Id> quoteIds = new Set<Id>();
        for (Quote q : latestQuoteByOpportunityId.values()) {
            quoteIds.add(q.Id);
        }
        Map<Id, List<QuoteLineItem>> quoteLineItemsByQuoteId = getQuoteLineItemsByQuoteId(quoteIds);

        for (ClosedWonPair p : pairs) {
            if (!accountById.containsKey(p.accountId)) {
                continue;
            }
            Account applAccount = accountById.get(p.accountId);
            Quote quote = latestQuoteByOpportunityId.get(p.opportunityId);
            List<QuoteLineItem> qlis = (quote != null) ? quoteLineItemsByQuoteId.get(quote.Id) : null;

            String payloadJson = buildPayloadJson(
                applAccount,
                p.opportunityId,
                quote,
                qlis
            );
            events.add(
                new PricingConditionSync__e(
                    OpportunityId__c = p.opportunityId != null ? String.valueOf(p.opportunityId) : null,
                    AccountId__c = String.valueOf(p.accountId),
                    PayloadJson__c = payloadJson
                )
            );
        }

        return events;
    }

    @TestVisible
    private static List<Account> getApplicableAccounts(Set<Id> accountIds) {
        return [
            SELECT Id, DistributionChannel__c, SalesOrganization__c, ShippingCondition__c,
                   ERPCustomerNumber__c, CurrencyIsoCode, SalesCategory__c
            FROM Account
            WHERE Id IN :accountIds
        ];
    }

    @TestVisible
    private static Map<Id, Quote> getLatestQuoteByOpportunityId(Set<Id> opportunityIds) {
        Map<Id, Quote> result = new Map<Id, Quote>();
        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return result;
        }
        List<Quote> quotes = [
            SELECT Id, OpportunityId, QuoteNumber, Name, LastModifiedDate,
                   DiscountBaseDiscountCoffee__c, DiscountBaseDiscountTea__c,
                   DiscountBaseDiscountHotChocolate__c, DiscountBaseDiscountOther__c,
                   DiscountPurchaseQuantityCoffee__c, DiscountPurchaseQuantityTea__c,
                   DiscountPurchaseQuantityHotChocolate__c, DiscountPurchaseQuantityOther__c,
                   DiscountVariousCoffeeAccessories__c, DiscountVariousTeaItems__c,
                   DiscountVariousDrinkingChocolates__c, DiscountVariousMiscellaneousItems__c,
                   DiscountIndexCondition__c,
                   DiscountBrandRepresentationTable__c, DiscountBrandRepresentationOnSite__c,
                   DiscountBrandRepresentationMenu__c, DiscountDigitalOrdering__c
            FROM Quote
            WHERE OpportunityId IN :opportunityIds
            ORDER BY LastModifiedDate DESC
        ];
        for (Quote q : quotes) {
            if (!result.containsKey(q.OpportunityId)) {
                result.put(q.OpportunityId, q);
            }
        }
        return result;
    }

    @TestVisible
    private static Map<Id, List<QuoteLineItem>> getQuoteLineItemsByQuoteId(Set<Id> quoteIds) {
        Map<Id, List<QuoteLineItem>> result = new Map<Id, List<QuoteLineItem>>();
        if (quoteIds == null || quoteIds.isEmpty()) {
            return result;
        }
        List<QuoteLineItem> qlis = [
            SELECT Id, QuoteId, Product2Id, Product2.ProductCode, SpecialDiscount__c
            FROM QuoteLineItem
            WHERE QuoteId IN :quoteIds
        ];
        for (QuoteLineItem qli : qlis) {
            if (!result.containsKey(qli.QuoteId)) {
                result.put(qli.QuoteId, new List<QuoteLineItem>());
            }
            result.get(qli.QuoteId).add(qli);
        }
        return result;
    }

    @TestVisible
    private static String buildPayloadJson(
        Account applAccount,
        Id opportunityId,
        Quote quote,
        List<QuoteLineItem> quoteLineItems
    ) {
        Map<String, Object> root = new Map<String, Object>();
        root.put('opportunityId', opportunityId != null ? String.valueOf(opportunityId) : null);
        root.put('applicableAccount', buildApplicableAccountMap(applAccount));
        root.put('quote', buildQuoteMap(quote));
        root.put('quoteLineItems', buildQuoteLineItemMaps(quoteLineItems));
        return JSON.serialize(root);
    }

    @TestVisible
    private static Map<String, Object> buildApplicableAccountMap(Account a) {
        Map<String, Object> m = new Map<String, Object>();
        m.put('distributionChannel', a.DistributionChannel__c);
        m.put('salesOrganization', a.SalesOrganization__c);
        m.put('shippingCondition', a.ShippingCondition__c);
        m.put('erpCustomerNumber', a.ERPCustomerNumber__c);
        m.put('currencyIsoCode', a.CurrencyIsoCode);
        m.put('salesCategory', a.SalesCategory__c);
        return m;
    }

    @TestVisible
    private static Map<String, Object> buildQuoteMap(Quote quote) {
        Map<String, Object> m = new Map<String, Object>();
        if (quote == null) {
            return m;
        }
        m.put('id', String.valueOf(quote.Id));
        m.put('quoteNumber', quote.QuoteNumber);
        m.put('name', quote.Name);
        for (String fieldApi : QUOTE_DISCOUNT_FIELDS) {
            Object val = quote.get(fieldApi);
            if (val != null) {
                m.put(fieldApi, val);
            }
        }
        return m;
    }

    @TestVisible
    private static List<Map<String, Object>> buildQuoteLineItemMaps(List<QuoteLineItem> qlis) {
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        if (qlis == null || qlis.isEmpty()) {
            return rows;
        }
        for (QuoteLineItem qli : qlis) {
            Map<String, Object> row = new Map<String, Object>();
            row.put('id', String.valueOf(qli.Id));
            row.put('productId', qli.Product2Id != null ? String.valueOf(qli.Product2Id) : null);
            row.put('productCode', qli.Product2 != null ? qli.Product2.ProductCode : null);
            if (qli.SpecialDiscount__c != null) {
                row.put('specialDiscountInE', qli.SpecialDiscount__c);
            }
            rows.add(row);
        }
        return rows;
    }

    @TestVisible
    private static void publishEvents(List<PricingConditionSync__e> events) {
        if (useTestMock) {
            PricingConditionSyncServiceTest.mockEventBusPublish(events);
        } else {
            EventBus.publish(events);
        }
    }

    @TestVisible
    private class ClosedWonPair {
        @TestVisible Id opportunityId;
        @TestVisible Id accountId;
        @TestVisible
        ClosedWonPair(Id oppId, Id accId) {
            opportunityId = oppId;
            accountId = accId;
        }
    }
}