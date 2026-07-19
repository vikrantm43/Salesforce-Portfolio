/**
 * Bulkified trigger handler for OrderStatusEvent__e.
 *
 * Design decisions:
 *  - EventUuid deduplication prevents double-processing on at-least-once re-delivery.
 *  - Partition key = OrderId__c so per-order ordering is guaranteed within a partition.
 *  - All DML is performed in bulk; no per-event callouts or SOQL inside loops.
 *  - Failed events are logged to OrderEventLog__c rather than thrown, preserving
 *    subscriber health (subscriber won't be suspended from retries).
 */
public with sharing class OrderEventHandler {

    public static void handleEvents(List<OrderStatusEvent__e> events) {
        List<Order> ordersToUpdate   = new List<Order>();
        List<OrderEventLog__c> logs  = new List<OrderEventLog__c>();
        Set<String> processedUuids   = getProcessedUuids(events);

        Map<Id, Order> ordersById = fetchOrders(events);

        for (OrderStatusEvent__e evt : events) {
            // Skip duplicates — at-least-once delivery means the same EventUuid can arrive twice
            if (processedUuids.contains(evt.EventUuid)) {
                logs.add(buildLog(evt, 'SKIPPED_DUPLICATE', null));
                continue;
            }

            if (String.isBlank(evt.OrderId__c)) {
                logs.add(buildLog(evt, 'INVALID_PAYLOAD', 'OrderId__c is required'));
                continue;
            }

            Order ord = ordersById.get(Id.valueOf(evt.OrderId__c));
            if (ord == null) {
                logs.add(buildLog(evt, 'ORDER_NOT_FOUND', 'No Order record for Id: ' + evt.OrderId__c));
                continue;
            }

            ord.Status = evt.NewStatus__c;
            ordersToUpdate.add(ord);
            logs.add(buildLog(evt, 'PROCESSED', null));
        }

        if (!ordersToUpdate.isEmpty()) {
            List<Database.SaveResult> results = Database.update(ordersToUpdate, false);
            handleDmlResults(results, ordersToUpdate, logs);
        }

        if (!logs.isEmpty()) {
            Database.insert(logs, false);
        }
    }

    // ── Private helpers ────────────────────────────────────────────────────────

    private static Set<String> getProcessedUuids(List<OrderStatusEvent__e> events) {
        Set<String> uuids = new Set<String>();
        Integer cutoffMinutes = 30;
        Datetime cutoff = Datetime.now().addMinutes(-cutoffMinutes);

        Set<String> incomingUuids = new Set<String>();
        for (OrderStatusEvent__e e : events) {
            if (String.isNotBlank(e.EventUuid)) incomingUuids.add(e.EventUuid);
        }

        // Check which of these UUIDs were already successfully processed recently
        for (OrderEventLog__c existing : [
            SELECT EventUuid__c FROM OrderEventLog__c
            WHERE EventUuid__c IN :incomingUuids
            AND   Status__c    = 'PROCESSED'
            AND   CreatedDate  >= :cutoff
            WITH  SECURITY_ENFORCED
        ]) {
            uuids.add(existing.EventUuid__c);
        }
        return uuids;
    }

    private static Map<Id, Order> fetchOrders(List<OrderStatusEvent__e> events) {
        Set<Id> orderIds = new Set<Id>();
        for (OrderStatusEvent__e e : events) {
            if (String.isNotBlank(e.OrderId__c)) {
                try { orderIds.add(Id.valueOf(e.OrderId__c)); } catch (Exception ex) {}
            }
        }
        Map<Id, Order> result = new Map<Id, Order>();
        if (orderIds.isEmpty()) return result;

        for (Order o : [
            SELECT Id, Status, OrderNumber, AccountId
            FROM   Order
            WHERE  Id IN :orderIds
            WITH   SECURITY_ENFORCED
        ]) {
            result.put(o.Id, o);
        }
        return result;
    }

    private static void handleDmlResults(
        List<Database.SaveResult> results,
        List<Order> orders,
        List<OrderEventLog__c> logs
    ) {
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                String errors = '';
                for (Database.Error err : results[i].getErrors()) {
                    errors += err.getMessage() + '; ';
                }
                // Find and update the log entry for this order
                for (OrderEventLog__c log : logs) {
                    if (log.OrderId__c == orders[i].Id && log.Status__c == 'PROCESSED') {
                        log.Status__c       = 'DML_ERROR';
                        log.ErrorMessage__c = errors;
                        break;
                    }
                }
            }
        }
    }

    private static OrderEventLog__c buildLog(
        OrderStatusEvent__e evt,
        String status,
        String errorMessage
    ) {
        return new OrderEventLog__c(
            EventUuid__c    = evt.EventUuid,
            ReplayId__c     = evt.ReplayId,
            OrderId__c      = evt.OrderId__c,
            OrderNumber__c  = evt.OrderNumber__c,
            NewStatus__c    = evt.NewStatus__c,
            PreviousStatus__c = evt.PreviousStatus__c,
            SourceSystem__c = evt.SourceSystem__c,
            Status__c       = status,
            ErrorMessage__c = errorMessage,
            ProcessedAt__c  = Datetime.now()
        );
    }
}
