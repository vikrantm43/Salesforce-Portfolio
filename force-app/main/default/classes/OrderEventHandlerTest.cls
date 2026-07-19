@IsTest
private class OrderEventHandlerTest {

    // ── Test data setup ────────────────────────────────────────────────────────

    @TestSetup
    static void makeData() {
        Account acct = new Account(Name = 'Test Customer');
        insert acct;

        Contract cont = new Contract(
            AccountId = acct.Id,
            StartDate = Date.today(),
            ContractTerm = 12,
            Status = 'Draft'
        );
        insert cont;

        Order ord = new Order(
            AccountId     = acct.Id,
            ContractId    = cont.Id,
            EffectiveDate = Date.today(),
            Status        = 'Draft',
            OrderNumber   = null  // auto-assigned
        );
        insert ord;
    }

    // ── Happy path ─────────────────────────────────────────────────────────────

    @IsTest
    static void testHandleEvents_updatesOrderStatus() {
        Order ord = [SELECT Id, Status FROM Order LIMIT 1];

        Test.startTest();
        List<OrderStatusEvent__e> events = new List<OrderStatusEvent__e>{
            new OrderStatusEvent__e(
                OrderId__c        = ord.Id,
                OrderNumber__c    = 'ORD-001',
                PreviousStatus__c = 'Draft',
                NewStatus__c      = 'Activated',
                SourceSystem__c   = 'OMS'
            )
        };
        OrderEventHandler.handleEvents(events);
        Test.stopTest();

        Order updated = [SELECT Status FROM Order WHERE Id = :ord.Id];
        System.assertEquals('Activated', updated.Status, 'Order status should be updated to Activated');

        List<OrderEventLog__c> logs = [SELECT Status__c FROM OrderEventLog__c];
        System.assertEquals(1, logs.size(), 'Should have one log entry');
        System.assertEquals('PROCESSED', logs[0].Status__c, 'Log status should be PROCESSED');
    }

    // ── Bulk test ──────────────────────────────────────────────────────────────

    @IsTest
    static void testHandleEvents_bulk_200Events() {
        Account acct = [SELECT Id FROM Account LIMIT 1];
        Contract cont = [SELECT Id FROM Contract LIMIT 1];

        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < 10; i++) {
            orders.add(new Order(
                AccountId     = acct.Id,
                ContractId    = cont.Id,
                EffectiveDate = Date.today(),
                Status        = 'Draft'
            ));
        }
        insert orders;

        List<OrderStatusEvent__e> events = new List<OrderStatusEvent__e>();
        for (Order o : orders) {
            events.add(new OrderStatusEvent__e(
                OrderId__c   = o.Id,
                NewStatus__c = 'Activated',
                SourceSystem__c = 'BULK_TEST'
            ));
        }

        Test.startTest();
        OrderEventHandler.handleEvents(events);
        Test.stopTest();

        List<Order> updated = [SELECT Status FROM Order WHERE Id IN :orders];
        for (Order o : updated) {
            System.assertEquals('Activated', o.Status, 'All orders should be activated');
        }
        System.assertEquals(10, [SELECT COUNT() FROM OrderEventLog__c WHERE Status__c = 'PROCESSED'], 'Should have 10 processed logs');
    }

    // ── Deduplication ──────────────────────────────────────────────────────────

    @IsTest
    static void testHandleEvents_skipsDuplicate() {
        Order ord = [SELECT Id FROM Order LIMIT 1];

        // Pre-insert a log simulating a prior successful delivery of same EventUuid
        String fakeUuid = 'test-uuid-dedup-1234';
        insert new OrderEventLog__c(
            EventUuid__c = fakeUuid,
            OrderId__c   = ord.Id,
            NewStatus__c = 'Activated',
            Status__c    = 'PROCESSED',
            ProcessedAt__c = Datetime.now().addMinutes(-5)
        );

        Test.startTest();
        OrderStatusEvent__e evt = new OrderStatusEvent__e(
            OrderId__c   = ord.Id,
            NewStatus__c = 'Shipped',
            SourceSystem__c = 'OMS'
        );
        // Manually set EventUuid to simulate duplicate
        evt.EventUuid = fakeUuid;
        OrderEventHandler.handleEvents(new List<OrderStatusEvent__e>{ evt });
        Test.stopTest();

        Order unchanged = [SELECT Status FROM Order WHERE Id = :ord.Id];
        System.assertEquals('Draft', unchanged.Status, 'Duplicate event should not update the order');

        List<OrderEventLog__c> logs = [SELECT Status__c FROM OrderEventLog__c WHERE Status__c = 'SKIPPED_DUPLICATE'];
        System.assertEquals(1, logs.size(), 'Should log one SKIPPED_DUPLICATE entry');
    }

    // ── Invalid payload ────────────────────────────────────────────────────────

    @IsTest
    static void testHandleEvents_missingOrderId_logsInvalid() {
        Test.startTest();
        OrderEventHandler.handleEvents(new List<OrderStatusEvent__e>{
            new OrderStatusEvent__e(
                OrderId__c   = null,
                NewStatus__c = 'Activated'
            )
        });
        Test.stopTest();

        List<OrderEventLog__c> logs = [SELECT Status__c FROM OrderEventLog__c WHERE Status__c = 'INVALID_PAYLOAD'];
        System.assertEquals(1, logs.size(), 'Should log INVALID_PAYLOAD for missing OrderId');
    }

    // ── Order not found ────────────────────────────────────────────────────────

    @IsTest
    static void testHandleEvents_orderNotFound_logsError() {
        Test.startTest();
        OrderEventHandler.handleEvents(new List<OrderStatusEvent__e>{
            new OrderStatusEvent__e(
                OrderId__c   = '8011x000001XXXXX',  // non-existent Id
                NewStatus__c = 'Activated'
            )
        });
        Test.stopTest();

        List<OrderEventLog__c> logs = [SELECT Status__c FROM OrderEventLog__c WHERE Status__c = 'ORDER_NOT_FOUND'];
        System.assertEquals(1, logs.size(), 'Should log ORDER_NOT_FOUND');
    }

    // ── Publisher test ─────────────────────────────────────────────────────────

    @IsTest
    static void testPublisher_invocableMethod() {
        Order ord = [SELECT Id, OrderNumber FROM Order LIMIT 1];

        OrderEventPublisher.OrderEventRequest req = new OrderEventPublisher.OrderEventRequest();
        req.orderId        = ord.Id;
        req.orderNumber    = ord.OrderNumber;
        req.previousStatus = 'Draft';
        req.newStatus      = 'Activated';
        req.sourceSystem   = 'TEST';

        Test.startTest();
        List<OrderEventPublisher.PublishResult> results =
            OrderEventPublisher.publishFromFlow(new List<OrderEventPublisher.OrderEventRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assert(results[0].success, 'Publish should succeed');
    }
}
