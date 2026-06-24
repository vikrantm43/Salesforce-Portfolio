public with sharing class CaseEscalationController {

    private static final Integer ESCALATION_AGE_HOURS = 4;

    @AuraEnabled(cacheable=true)
    public static List<CaseWrapper> getEscalatedCases() {
        Datetime threshold = Datetime.now().addHours(-ESCALATION_AGE_HOURS);

        List<Case> cases = [
            SELECT Id, CaseNumber, Subject, Status, Priority,
                   Account.Name, OwnerId, Owner.Name,
                   CreatedDate, IsEscalated
            FROM Case
            WHERE IsClosed = false
            AND (IsEscalated = true OR (CreatedDate < :threshold AND Priority IN ('Critical', 'High')))
            ORDER BY Priority, CreatedDate ASC
            LIMIT 100
        ];

        List<CaseWrapper> result = new List<CaseWrapper>();
        for (Case c : cases) {
            result.add(new CaseWrapper(c));
        }
        return result;
    }

    @AuraEnabled
    public static void reassignCase(Id caseId, Id newOwnerId) {
        if (caseId == null || newOwnerId == null) {
            throw new AuraHandledException('Case ID and new owner are required.');
        }
        try {
            update new Case(Id = caseId, OwnerId = newOwnerId);
        } catch (DmlException e) {
            throw new AuraHandledException(e.getDmlMessage(0));
        }
    }

    public class CaseWrapper {
        @AuraEnabled public Id     Id;
        @AuraEnabled public String CaseNumber;
        @AuraEnabled public String Subject;
        @AuraEnabled public String Status;
        @AuraEnabled public String Priority;
        @AuraEnabled public String AccountName;
        @AuraEnabled public String OwnerName;
        @AuraEnabled public Integer AgeHours;
        @AuraEnabled public Boolean IsEscalated;
        @AuraEnabled public String priorityClass;

        public CaseWrapper(Case c) {
            this.Id          = c.Id;
            this.CaseNumber  = c.CaseNumber;
            this.Subject     = c.Subject;
            this.Status      = c.Status;
            this.Priority    = c.Priority;
            this.AccountName = c.Account?.Name;
            this.OwnerName   = c.Owner?.Name;
            this.IsEscalated = c.IsEscalated;
            this.AgeHours    = Integer.valueOf(
                (Datetime.now().getTime() - c.CreatedDate.getTime()) / 3600000
            );
            this.priorityClass = c.Priority == 'Critical' ? 'slds-text-color_error'
                               : c.Priority == 'High'     ? 'slds-text-color_warning'
                               : '';
        }
    }
}
