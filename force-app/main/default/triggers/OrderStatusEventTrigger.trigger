/**
 * Single trigger for OrderStatusEvent__e — delegates all logic to OrderEventHandler.
 * Follows the one-trigger-per-object / handler pattern from the Apex Trigger Framework
 * (see force-app/main/default/triggers/TriggerFramework).
 */
trigger OrderStatusEventTrigger on OrderStatusEvent__e (after insert) {
    OrderEventHandler.handleEvents(Trigger.new);
}
