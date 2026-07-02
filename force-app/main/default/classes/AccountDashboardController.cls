public with sharing class AccountDashboardController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getAccountKPIs(Id accountId) {
        if (accountId == null) {
            throw new AuraHandledException('Account ID is required.');
        }

        Map<String, Object> kpis = new Map<String, Object>();

        kpis.put('openCases', [
            SELECT COUNT() FROM Case
            WHERE AccountId = :accountId AND IsClosed = false
        ]);

        kpis.put('openOpportunities', [
            SELECT COUNT() FROM Opportunity
            WHERE AccountId = :accountId AND IsClosed = false
        ]);

        AggregateResult[] caseAgeResult = [
            SELECT COUNT(Id) closedCount
            FROM Case
            WHERE AccountId = :accountId
            AND IsClosed = true
            AND ClosedDate = LAST_N_DAYS:90
        ];

        if (!caseAgeResult.isEmpty() && caseAgeResult[0].get('closedCount') != null) {
            kpis.put('npsScore', (Integer) caseAgeResult[0].get('closedCount'));
        } else {
            kpis.put('npsScore', null);
        }

        return kpis;
    }
}
