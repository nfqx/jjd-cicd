public without sharing class OrderTriggerHandler {

    public static void handleAfterInsert(List<Order> newRecords) {
        pushReadyForTransmissionERPOrders(newRecords);
    }

    public static void handleAfterUpdate(List<Order> newRecords) {
        pushReadyForTransmissionERPOrders(newRecords);
    }

    private static void pushReadyForTransmissionERPOrders(List<Order> orders) {
        Set<Id> readyForTransmissionOrders = new Set<Id>();

        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
            (List<Order>)Trigger.new,
            (Map<Id, Order>)Trigger.oldMap
        );

        for (Order order : orders) {
            if (order.Status == 'Ready for Transmission to ERP' && !erpUpdatedRecords.contains(order.Id)) {
                readyForTransmissionOrders.add(
                    order.Id
                );
            }
        }

        if (readyForTransmissionOrders.isEmpty()) {
            return;
        }

        OrderSyncService.pushOrders(
            readyForTransmissionOrders
        );
    }
}