public without sharing class ReturnOrderTriggerHandler {

    // Gate for outbound create (JJD-28): the ReturnOrder is sent to SAP only once it reaches this
    // status (label/API "Gesendet"), so header + line items + partners are complete. Mirrors
    // OrderTriggerHandler ('Ready for Transmission to ERP'). Final status to use is open question K.
    private static final String STATUS_READY_TO_SEND = 'Gesendet';

    public static void handleAfterInsert(List<ReturnOrder> newRecords) {
        pushReturnOrderCreates(newRecords, null);
    }

    public static void handleAfterUpdate(List<ReturnOrder> newRecords, Map<Id, ReturnOrder> oldRecordsMap) {
        pushReturnOrderCreates(newRecords, oldRecordsMap);
        pushBillingReleases(newRecords, oldRecordsMap);
    }

    // JJD-28 — push a ReturnOrder to SAP for creation only when it reaches STATUS_READY_TO_SEND
    // (gate, like Order), it has no ERP number yet, and the change is not an ERP write-back echo.
    private static void pushReturnOrderCreates(List<ReturnOrder> returnOrders, Map<Id, ReturnOrder> oldMap) {
        Set<Id> erpUpdatedRecords = oldMap == null
            ? new Set<Id>()
            : ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(returnOrders, oldMap);

        Set<Id> toCreate = new Set<Id>();
        for (ReturnOrder ro : returnOrders) {
            if (ro.Status == STATUS_READY_TO_SEND
                    && String.isBlank(ro.ERPReturnOrderNumber__c)
                    && !erpUpdatedRecords.contains(ro.Id)) {
                toCreate.add(ro.Id);
            }
        }
        if (toCreate.isEmpty()) {
            return;
        }
        ReturnOrderSyncService.pushReturnOrderCreate(toCreate);
    }

    // JJD-26 — detect billing release (BillingBlocked__c true -> false) and push to MuleSoft.
    // Guards: skip records changed only by the ERP write-back (ERPLastSyncAt__c) to avoid echo,
    // and require ERPReturnOrderNumber__c (the return must already exist in SAP).
    private static void pushBillingReleases(List<ReturnOrder> returnOrders, Map<Id, ReturnOrder> oldMap) {
        Set<Id> erpUpdatedRecords = ERPSyncRecursionPrevention.checkERPFieldOnlyUpdate(
            returnOrders,
            oldMap
        );

        Set<Id> releasedReturnOrders = new Set<Id>();

        for (ReturnOrder returnOrder : returnOrders) {
            ReturnOrder oldReturnOrder = oldMap.get(returnOrder.Id);

            Boolean billingReleased = oldReturnOrder != null
                && oldReturnOrder.BillingBlocked__c == true
                && returnOrder.BillingBlocked__c == false;

            if (billingReleased
                    && !erpUpdatedRecords.contains(returnOrder.Id)
                    && String.isNotBlank(returnOrder.ERPReturnOrderNumber__c)) {
                releasedReturnOrders.add(returnOrder.Id);
            }
        }

        if (releasedReturnOrders.isEmpty()) {
            return;
        }

        ReturnOrderSyncService.pushBillingReleases(releasedReturnOrders);
    }
}