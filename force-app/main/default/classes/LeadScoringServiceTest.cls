@IsTest
private class LeadScoringServiceTest {

    @TestSetup
    static void setup() {
        List<Lead> leads = new List<Lead>{
            new Lead(FirstName = 'High', LastName = 'Score', Company = 'TechCorp',
                     Industry = 'Technology', Title = 'CEO', NumberOfEmployees = 15000,
                     Email = 'high@techcorp.com', Phone = '555-1234',
                     Website = 'https://techcorp.com', AnnualRevenue = 5000000,
                     LeadSource = 'Partner Referral', Status = 'Open - Not Contacted'),
            new Lead(FirstName = 'Low', LastName = 'Score', Company = 'SmallBiz',
                     Industry = 'Other', Title = 'Intern', NumberOfEmployees = 5,
                     Status = 'Open - Not Contacted')
        };
        insert leads;
    }

    @IsTest
    static void testHighScoreLead_getsGradeA() {
        Lead l = [SELECT Id FROM Lead WHERE LastName = 'Score' AND FirstName = 'High' LIMIT 1];

        Test.startTest();
        List<LeadScoringService.LeadScoreResult> results =
            LeadScoringService.scoreLeads(new List<Id>{ l.Id });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('A', results[0].grade, 'High-profile lead should get grade A');
        System.assert(results[0].score >= 80, 'Score should be 80+');
    }

    @IsTest
    static void testLowScoreLead_getsGradeD() {
        Lead l = [SELECT Id FROM Lead WHERE LastName = 'Score' AND FirstName = 'Low' LIMIT 1];

        Test.startTest();
        List<LeadScoringService.LeadScoreResult> results =
            LeadScoringService.scoreLeads(new List<Id>{ l.Id });
        Test.stopTest();

        System.assertEquals('D', results[0].grade, 'Low-profile lead should get grade D');
    }

    @IsTest
    static void testScoreIsPersistedOnLead() {
        Lead l = [SELECT Id FROM Lead WHERE LastName = 'Score' AND FirstName = 'High' LIMIT 1];

        Test.startTest();
        LeadScoringService.scoreLeads(new List<Id>{ l.Id });
        Test.stopTest();

        Lead updated = [SELECT Lead_Score__c, Lead_Grade__c FROM Lead WHERE Id = :l.Id];
        System.assertNotEquals(null, updated.Lead_Score__c, 'Score should be persisted');
        System.assertNotEquals(null, updated.Lead_Grade__c, 'Grade should be persisted');
    }
}
