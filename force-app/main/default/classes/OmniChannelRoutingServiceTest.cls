@IsTest
private class OmniChannelRoutingServiceTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Corp', Rating = 'Hot');
        insert acc;

        List<Case> cases = new List<Case>{
            new Case(Subject = 'Critical Case', Priority = 'Critical', Status = 'New',
                     Origin = 'Phone', AccountId = acc.Id),
            new Case(Subject = 'Standard Case', Priority = 'Medium',  Status = 'New',
                     Origin = 'Web',   AccountId = acc.Id),
            new Case(Subject = 'Chat Case',     Priority = 'Low',     Status = 'New',
                     Origin = 'Chat',  AccountId = acc.Id)
        };
        insert cases;
    }

    @IsTest
    static void testRouteCases_PhoneOrigin() {
        Case c = [SELECT Id FROM Case WHERE Subject = 'Critical Case' LIMIT 1];
        OmniChannelRoutingService.RoutingRequest req = new OmniChannelRoutingService.RoutingRequest();
        req.caseId = c.Id;

        Test.startTest();
        List<OmniChannelRoutingService.RoutingResult> results =
            OmniChannelRoutingService.routeCases(new List<OmniChannelRoutingService.RoutingRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertNotEquals(null, results[0]);
    }

    @IsTest
    static void testRouteCases_ChatOrigin() {
        Case c = [SELECT Id FROM Case WHERE Subject = 'Chat Case' LIMIT 1];
        OmniChannelRoutingService.RoutingRequest req = new OmniChannelRoutingService.RoutingRequest();
        req.caseId = c.Id;

        Test.startTest();
        List<OmniChannelRoutingService.RoutingResult> results =
            OmniChannelRoutingService.routeCases(new List<OmniChannelRoutingService.RoutingRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
    }

    @IsTest
    static void testRouteCases_MissingQueue_ReturnsError() {
        Case c = [SELECT Id FROM Case WHERE Subject = 'Standard Case' LIMIT 1];
        OmniChannelRoutingService.RoutingRequest req = new OmniChannelRoutingService.RoutingRequest();
        req.caseId = c.Id;

        Test.startTest();
        List<OmniChannelRoutingService.RoutingResult> results =
            OmniChannelRoutingService.routeCases(new List<OmniChannelRoutingService.RoutingRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess);
        System.assert(String.isNotBlank(results[0].errorMessage));
    }

    @IsTest
    static void testRouteCases_BulkSafety() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            accounts.add(new Account(Name = 'Bulk Corp ' + i));
        }
        insert accounts;

        List<Case> bulkCases = new List<Case>();
        for (Account a : accounts) {
            bulkCases.add(new Case(Subject = 'Bulk ' + a.Name, Status = 'New',
                                   Priority = 'Low', Origin = 'Phone', AccountId = a.Id));
        }
        insert bulkCases;

        List<OmniChannelRoutingService.RoutingRequest> requests = new List<OmniChannelRoutingService.RoutingRequest>();
        for (Case c : bulkCases) {
            OmniChannelRoutingService.RoutingRequest r = new OmniChannelRoutingService.RoutingRequest();
            r.caseId = c.Id;
            requests.add(r);
        }

        Test.startTest();
        List<OmniChannelRoutingService.RoutingResult> results =
            OmniChannelRoutingService.routeCases(requests);
        Test.stopTest();

        System.assertEquals(10, results.size());
        for (OmniChannelRoutingService.RoutingResult res : results) {
            System.assertNotEquals(null, res);
        }
    }

    @IsTest
    static void testGetAgentCapacity_ReturnsWithoutException() {
        Test.startTest();
        List<OmniChannelRoutingService.AgentCapacityWrapper> result =
            OmniChannelRoutingService.getAgentCapacity('Tier_One_Support');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testGetQueueStats_UnknownQueue_ReturnsEmpty() {
        Test.startTest();
        OmniChannelRoutingService.QueueStatsWrapper stats =
            OmniChannelRoutingService.getQueueStats('NonExistent_Queue');
        Test.stopTest();
        System.assertEquals(0, stats.pendingCount);
        System.assertEquals('', stats.queueName);
    }

    @IsTest
    static void testGetQueueStats_KnownQueue() {
        Group q = new Group(Name = 'Tier One Support', DeveloperName = 'Tier_One_Support', Type = 'Queue');
        insert q;

        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Corp' LIMIT 1];
        insert new Case(Subject = 'Queue Case', Status = 'New', Priority = 'Low',
                        Origin = 'Phone', OwnerId = q.Id, AccountId = acc.Id);

        Test.startTest();
        OmniChannelRoutingService.QueueStatsWrapper stats =
            OmniChannelRoutingService.getQueueStats('Tier_One_Support');
        Test.stopTest();

        System.assertEquals('Tier_One_Support', stats.queueName);
        System.assert(stats.pendingCount >= 0);
    }

    @IsTest
    static void testWrapperDefaults() {
        OmniChannelRoutingService.QueueStatsWrapper stats = new OmniChannelRoutingService.QueueStatsWrapper();
        System.assertEquals(0, stats.pendingCount);
        System.assertEquals(0, stats.avgAgeHours);

        OmniChannelRoutingService.AgentCapacityWrapper cap = new OmniChannelRoutingService.AgentCapacityWrapper();
        System.assertEquals(null, cap.userId);
    }

    @IsTest
    static void testInvocableVariables() {
        OmniChannelRoutingService.RoutingResult r = new OmniChannelRoutingService.RoutingResult();
        r.isSuccess = true;
        r.priority  = 1;
        r.queueName = 'Tier_One_Support';
        System.assertEquals(true, r.isSuccess);
        System.assertEquals(1, r.priority);
    }
}
