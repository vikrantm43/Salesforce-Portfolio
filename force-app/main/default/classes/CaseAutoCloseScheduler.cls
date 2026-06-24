public class CaseAutoCloseScheduler implements Schedulable {
    public void execute(SchedulableContext ctx) {
        Database.executeBatch(new CaseAutoCloseBatch(), 200);
    }

    // Schedule: every night at 2am
    // System.schedule('Case Auto-Close Nightly', '0 0 2 * * ?', new CaseAutoCloseScheduler());
}
