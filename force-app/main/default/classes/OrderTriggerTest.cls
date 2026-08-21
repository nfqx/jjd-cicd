@isTest
public class OrderTriggerTest {
    public static List<Account> createTestAccounts(Integer count) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i, LetterCampaignBonusUsed__c = false));
        }
        insert accounts;
        return accounts;
    }

    public static List<Order> createTestOrders(List<Account> accounts, String status, Boolean modifiedCreatedDate) {
        List<Order> orders = new List<Order>();
        for (Account acc : accounts) {
            Order o = new Order(AccountId = acc.Id, Status = status, EffectiveDate = Date.today());
            if(modifiedCreatedDate){
                o.CreatedDate = Date.today().addDays(-2);
                o.LastModifiedDate = Date.today().addDays(-2);
            }
            orders.add(o);
        }
        insert orders;
        return orders;
    }

    public static List<OrderItem> createOrderItems(List<Order> orders, Boolean isFreeItem) {
        List<OrderItem> items = new List<OrderItem>();
        Product2 prod = new Product2(
        	Name='Test Product',
            Tenant__c = '001'
        );
        insert prod;
        for (Order order : orders) {
            items.add(new OrderItem(OrderId = order.Id, FreeReason__c = isFreeItem ? System.Label.LetterCampaignFreeReason : '', Product2Id = prod.Id, Quantity = 1, UnitPrice = Decimal.valueOf(System.Label.LetterCampaignBonusSecondStageThreshold) + 1, ListPrice = Decimal.valueOf(System.Label.LetterCampaignBonusSecondStageThreshold) + 1));
        }
        insert items;
        return items;
    }


    @isTest
    static void testOrderActivationWithUnusedBonus() {
        List<Account> accounts = createTestAccounts(1);
        List<Order> orders = createTestOrders(accounts, 'Draft', false);
        List<OrderItem> items = createOrderItems(orders, true);

        Test.startTest();
        // Simulate order activation
        for (Order ord : orders) {
            ord.Status = OrderTriggerHandler.ACTIVATED_STATUS;
        }
        update orders;
        Test.stopTest();

        // Verify Account Bonus Usage
        Account updatedAccount = [SELECT LetterCampaignBonusUsed__c FROM Account WHERE Id = :accounts[0].Id];
        System.assert(updatedAccount.LetterCampaignBonusUsed__c, 'The letter campaign bonus should be marked as used.');
    }

    @isTest
    static void testOrderActivationWithUsedBonus() {
        List<Account> accounts = createTestAccounts(1);
        accounts[0].LetterCampaignBonusUsed__c = true;
        update accounts;

        List<Order> orders = createTestOrders(accounts, 'Draft', false);
        List<OrderItem> items = createOrderItems(orders, true);

        Test.startTest();
        // Simulate order activation
        for (Order ord : orders) {
            ord.Status = OrderTriggerHandler.ACTIVATED_STATUS;
            try {
                update ord;
            } catch (DmlException e) {
                System.assert(e.getMessage().contains(OrderTriggerHandler.LETTER_BONUS_ERROR), 'Expected an error when bonus is already used');
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testNonActivatedOrder() {
        List<Account> accounts = createTestAccounts(1);
        List<Order> orders = createTestOrders(accounts, 'Draft', false);
        List<OrderItem> items = createOrderItems(orders, true);

        Test.startTest();
        update orders; // No status change to 'Activated'
        Test.stopTest();

        // Verify that no changes have been made to accounts
        Account refreshedAccount = [SELECT LetterCampaignBonusUsed__c FROM Account WHERE Id = :accounts[0].Id];
        System.assert(!refreshedAccount.LetterCampaignBonusUsed__c, 'No changes should be made to the account.');
    }
}