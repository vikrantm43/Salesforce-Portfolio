@IsTest
private class AccountDashboardControllerTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        List<Case> cases = new List<Case>();
        cases.add(new Case(AccountId = acc.Id, Status = 'New', Subject = 'Open Case 1'));
        cases.add(new Case(AccountId = acc.Id, Status = 'New', Subject = 'Open Case 2'));
        cases.add(new Case(AccountId = acc.Id, Status = 'Closed', Subject = 'Closed Case'));
        insert cases;

        List<Opportunity> opps = new List<Opportunity>();
        opps.add(new Opportunity(AccountId = acc.Id, Name = 'Opp 1', StageName = 'Prospecting', CloseDate = Date.today().addDays(30)));
        insert opps;
    }

    @IsTest
    static void testGetAccountKPIs_returnsCorrectCounts() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Map<String, Object> result = AccountDashboardController.getAccountKPIs(acc.Id);
        Test.stopTest();

        System.assertEquals(2, result.get('openCases'), 'Should return 2 open cases');
        System.assertEquals(1, result.get('openOpportunities'), 'Should return 1 open opportunity');
    }

    @IsTest
    static void testGetAccountKPIs_nullAccountId_throwsException() {
        Test.startTest();
        try {
            AccountDashboardController.getAccountKPIs(null);
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null);
        }
        Test.stopTest();
    }
}
