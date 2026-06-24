/**
 * Batch job that auto-closes cases in "Pending Customer" status
 * if no customer response received within the configured SLA window.
 * Scheduled nightly via CaseAutoCloseScheduler.
 */
public class CaseAutoCloseBatch implements Database.Batchable<SObject>, Database.Stateful {

    private static final Integer DEFAULT_PENDING_DAYS = 7;
    private Integer closedCount = 0;

    public Database.QueryLocator start(Database.BatchableContext ctx) {
        Integer pendingDays = getPendingDaysConfig();
        Datetime cutoff = Datetime.now().addDays(-pendingDays);

        return Database.getQueryLocator([
            SELECT Id, Status, OwnerId, Subject
            FROM Case
            WHERE Status = 'Pending Customer'
            AND LastModifiedDate < :cutoff
            AND IsClosed = false
        ]);
    }

    public void execute(Database.BatchableContext ctx, List<Case> cases) {
        List<Case> toClose = new List<Case>();
        List<CaseComment> comments = new List<CaseComment>();

        for (Case c : cases) {
            toClose.add(new Case(
                Id     = c.Id,
                Status = 'Closed',
                Case_Close_Reason__c = 'Auto-Closed: No customer response'
            ));
            comments.add(new CaseComment(
                ParentId    = c.Id,
                CommentBody = 'This case has been automatically closed due to no customer response '
                            + 'within the configured SLA window. Please reopen if assistance is still required.',
                IsPublished = true
            ));
        }

        if (!toClose.isEmpty()) {
            Database.SaveResult[] results = Database.update(toClose, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) closedCount++;
            }
            insert comments;
        }
    }

    public void finish(Database.BatchableContext ctx) {
        if (closedCount > 0) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{ getNotificationEmail() });
            mail.setSubject('Auto-Close Batch Completed');
            mail.setPlainTextBody('Auto-close batch completed. Cases closed: ' + closedCount);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        }
    }

    private Integer getPendingDaysConfig() {
        Auto_Close_Config__mdt config = Auto_Close_Config__mdt.getInstance('Default');
        return config != null ? Integer.valueOf(config.Pending_Days__c) : DEFAULT_PENDING_DAYS;
    }

    private String getNotificationEmail() {
        Auto_Close_Config__mdt config = Auto_Close_Config__mdt.getInstance('Default');
        return config?.Notification_Email__c ?? UserInfo.getUserEmail();
    }
}
