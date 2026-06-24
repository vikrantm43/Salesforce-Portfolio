public with sharing class OpportunityPipelineController {

    @AuraEnabled(cacheable=true)
    public static List<OpportunityWrapper> getPipelineData() {
        List<Opportunity> opps = [
            SELECT Id, Name, StageName, Amount, CloseDate, Probability,
                   Account.Name, OwnerId, Owner.Name
            FROM Opportunity
            WHERE IsClosed = false
            AND OwnerId IN (SELECT Id FROM User WHERE IsActive = true)
            ORDER BY Amount DESC NULLS LAST
            LIMIT 200
        ];

        List<OpportunityWrapper> result = new List<OpportunityWrapper>();
        for (Opportunity o : opps) {
            result.add(new OpportunityWrapper(o));
        }
        return result;
    }

    @AuraEnabled
    public static void updateOpportunityStage(Id oppId, String newStage) {
        if (oppId == null || String.isBlank(newStage)) {
            throw new AuraHandledException('Opportunity ID and stage are required.');
        }

        Opportunity opp = new Opportunity(Id = oppId, StageName = newStage);

        try {
            update opp;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getDmlMessage(0));
        }
    }

    public class OpportunityWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String StageName;
        @AuraEnabled public Decimal Amount;
        @AuraEnabled public String FormattedAmount;
        @AuraEnabled public String FormattedCloseDate;
        @AuraEnabled public Decimal Probability;
        @AuraEnabled public AccountRef Account;
        @AuraEnabled public String OwnerName;

        public OpportunityWrapper(Opportunity o) {
            this.Id               = o.Id;
            this.Name             = o.Name;
            this.StageName        = o.StageName;
            this.Amount           = o.Amount;
            this.FormattedAmount  = o.Amount != null
                ? '$' + String.valueOf(o.Amount.setScale(0).format())
                : 'N/A';
            this.FormattedCloseDate = o.CloseDate != null
                ? o.CloseDate.format()
                : '';
            this.Probability      = o.Probability;
            this.Account          = new AccountRef(o.Account?.Name);
            this.OwnerName        = o.Owner?.Name;
        }
    }

    public class AccountRef {
        @AuraEnabled public String Name;
        public AccountRef(String name) { this.Name = name; }
    }
}
