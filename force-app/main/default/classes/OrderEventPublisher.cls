/**
 * Service class for publishing OrderStatusEvent__e platform events.
 * Intended use: called from Order record-triggered Flows, Apex triggers,
 * or external REST integrations via @RestResource.
 *
 * Returns a result object so callers can surface publish errors without
 * letting an uncaught exception kill the parent transaction.
 */
public with sharing class OrderEventPublisher {

    public class PublishResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String  eventUuid;
        @AuraEnabled public String  errorMessage;
    }

    /**
     * Publish a single order status change event.
     * @InvocableMethod makes this callable from Flow.
     */
    @InvocableMethod(
        label       = 'Publish Order Status Event'
        description = 'Publishes an OrderStatusEvent__e to notify downstream subscribers of a status change.'
        category    = 'Platform Events'
    )
    public static List<PublishResult> publishFromFlow(List<OrderEventRequest> requests) {
        List<PublishResult> results = new List<PublishResult>();
        List<OrderStatusEvent__e> events = new List<OrderStatusEvent__e>();

        for (OrderEventRequest req : requests) {
            events.add(new OrderStatusEvent__e(
                OrderId__c        = req.orderId,
                OrderNumber__c    = req.orderNumber,
                PreviousStatus__c = req.previousStatus,
                NewStatus__c      = req.newStatus,
                SourceSystem__c   = req.sourceSystem,
                CustomerId__c     = req.customerId
            ));
        }

        List<Database.SaveResult> saveResults = EventBus.publish(events);

        for (Database.SaveResult sr : saveResults) {
            PublishResult pr = new PublishResult();
            pr.success = sr.isSuccess();
            if (!sr.isSuccess()) {
                String errs = '';
                for (Database.Error err : sr.getErrors()) {
                    errs += err.getMessage() + '; ';
                }
                pr.errorMessage = errs;
            }
            results.add(pr);
        }
        return results;
    }

    /**
     * Bulk publish for Apex callers — returns number of successfully published events.
     */
    public static Integer publishBulk(List<OrderStatusEvent__e> events) {
        List<Database.SaveResult> results = EventBus.publish(events);
        Integer successCount = 0;
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) successCount++;
        }
        return successCount;
    }

    public class OrderEventRequest {
        @InvocableVariable(label='Order Id'           required=true)  public String orderId;
        @InvocableVariable(label='Order Number'       required=false) public String orderNumber;
        @InvocableVariable(label='Previous Status'    required=false) public String previousStatus;
        @InvocableVariable(label='New Status'         required=true)  public String newStatus;
        @InvocableVariable(label='Source System'      required=false) public String sourceSystem;
        @InvocableVariable(label='Customer Id'        required=false) public String customerId;
    }
}
