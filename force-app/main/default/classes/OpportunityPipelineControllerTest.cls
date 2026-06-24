@IsTest
private class OpportunityPipelineControllerTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Pipeline Test Account');
        insert acc;

        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(Name = 'Deal A', AccountId = acc.Id, StageName = 'Prospecting',
                            CloseDate = Date.today().addDays(30), Amount = 50000),
            new Opportunity(Name = 'Deal B', AccountId = acc.Id, StageName = 'Qualification',
                            CloseDate = Date.today().addDays(60), Amount = 120000)
        };
        insert opps;
    }

    @IsTest
    static void testGetPipelineData_returnsOpenOpps() {
        Test.startTest();
        List<OpportunityPipelineController.OpportunityWrapper> result =
            OpportunityPipelineController.getPipelineData();
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Should return open opportunities');
        System.assertNotEquals(null, result[0].FormattedAmount, 'FormattedAmount should not be null');
    }

    @IsTest
    static void testUpdateOpportunityStage_updatesCorrectly() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Deal A' LIMIT 1];

        Test.startTest();
        OpportunityPipelineController.updateOpportunityStage(opp.Id, 'Needs Analysis');
        Test.stopTest();

        Opportunity updated = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Needs Analysis', updated.StageName);
    }

    @IsTest
    static void testUpdateOpportunityStage_nullId_throwsException() {
        Test.startTest();
        try {
            OpportunityPipelineController.updateOpportunityStage(null, 'Prospecting');
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null);
        }
        Test.stopTest();
    }
}
