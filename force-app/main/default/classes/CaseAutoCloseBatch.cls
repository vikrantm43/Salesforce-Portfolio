public class CaseAutoCloseBatch implements Database.Batchable<SObject>, Database.Stateful {

    private static final Integer DEFAULT_PENDING_DAYS = 7;
    private Integer closedCount = 0;

    public Database.QueryLocator start(Database.BatchableContext ctx) {
        Datetime cutoff = Datetime.now().addDays(-DEFAULT_PENDING_DAYS);

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
                Status = 'Closed'
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
            mail.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
            mail.setSubject('Auto-Close Batch Completed');
            mail.setPlainTextBody('Auto-close batch completed. Cases closed: ' + closedCount);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        }
    }
}
