public without sharing class OrderItemTriggerHandler {
    public static void calculateOrderShippingCosts(List<OrderItem> newRecords){
        List<String> orderIds = CollectionUtils.generateStringListFromSObjectList(newRecords, 'OrderId', true, true);
        List<String> shippingProductCodes = System.Label.ShippingProductCodes.split(',');

        List<Order> ordersToUpdate = new List<Order>();
        Map<String, Decimal> shippingsPerOrder = new Map<String, Decimal>();
        for(AggregateResult ar : [SELECT OrderId, SUM(TotalPrice) total FROM OrderItem WHERE OrderId IN : orderIds AND Product2.ProductCode IN : shippingProductCodes GROUP BY OrderId]){
            shippingsPerOrder.put(String.valueOf(ar.get('OrderId')), (Decimal) ar.get('total'));
        }
        for(String orderId : orderIds){
            ordersToUpdate.add(new Order(
                Id = orderId,
                ShippingCosts__c = shippingsPerOrder.containsKey(orderId) ? shippingsPerOrder.get(orderId) : 0
            ));
        }
        if(!ordersToUpdate.isEmpty()){
            update ordersToUpdate;
        }
    }
}