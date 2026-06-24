@IsTest
private class CaseEscalationControllerTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Escalation Test Account');
        insert acc;

        List<Case> cases = new List<Case>{
            new Case(AccountId = acc.Id, Subject = 'Critical Issue',
                     Priority = 'Critical', Status = 'New', IsEscalated = true),
            new Case(AccountId = acc.Id, Subject = 'High Issue',
                     Priority = 'High', Status = 'Working', IsEscalated = false),
            new Case(AccountId = acc.Id, Subject = 'Closed Case',
                     Priority = 'High', Status = 'Closed', IsEscalated = false)
        };
        insert cases;
    }

    @IsTest
    static void testGetEscalatedCases_excludesClosedCases() {
        Test.startTest();
        List<CaseEscalationController.CaseWrapper> result =
            CaseEscalationController.getEscalatedCases();
        Test.stopTest();

        for (CaseEscalationController.CaseWrapper c : result) {
            System.assertNotEquals('Closed', c.Status, 'Closed cases should be excluded');
        }
    }

    @IsTest
    static void testReassignCase_updatesOwner() {
        Case c = [SELECT Id FROM Case WHERE Subject = 'Critical Issue' LIMIT 1];
        User u = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name = 'System Administrator' LIMIT 1];

        Test.startTest();
        CaseEscalationController.reassignCase(c.Id, u.Id);
        Test.stopTest();

        Case updated = [SELECT OwnerId FROM Case WHERE Id = :c.Id];
        System.assertEquals(u.Id, updated.OwnerId);
    }

    @IsTest
    static void testReassignCase_nullArgs_throwsException() {
        Test.startTest();
        try {
            CaseEscalationController.reassignCase(null, null);
            System.assert(false, 'Expected exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null);
        }
        Test.stopTest();
    }
}
