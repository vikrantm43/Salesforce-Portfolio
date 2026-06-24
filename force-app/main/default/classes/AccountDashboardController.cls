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

        List<AggregateResult> npsResult = [
            SELECT AVG(NPS_Score__c) avgNps
            FROM Case
            WHERE AccountId = :accountId
            AND NPS_Score__c != null
            AND CreatedDate = LAST_N_DAYS:90
        ];

        if (!npsResult.isEmpty() && npsResult[0].get('avgNps') != null) {
            kpis.put('npsScore', ((Decimal) npsResult[0].get('avgNps')).setScale(1));
        } else {
            kpis.put('npsScore', null);
        }

        return kpis;
    }
}
