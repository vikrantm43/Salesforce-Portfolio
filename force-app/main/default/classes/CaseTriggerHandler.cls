public with sharing class CaseTriggerHandler extends TriggerHandler {

    private List<Case> newRecords;
    private List<Case> oldRecords;
    private Map<Id, Case> newMap;
    private Map<Id, Case> oldMap;

    public CaseTriggerHandler() {
        this.newRecords = (List<Case>) Trigger.new;
        this.oldRecords = (List<Case>) Trigger.old;
        this.newMap     = (Map<Id, Case>) Trigger.newMap;
        this.oldMap     = (Map<Id, Case>) Trigger.oldMap;
    }

    protected override void beforeInsert() {
        CaseService.setDefaultPriority(newRecords);
    }

    protected override void afterInsert() {
        CaseService.createFollowUpTask(newRecords);
    }

    protected override void afterUpdate() {
        List<Case> statusChangedCases = new List<Case>();
        for (Case c : newRecords) {
            if (c.Status != oldMap.get(c.Id).Status && c.Status == 'Closed') {
                statusChangedCases.add(c);
            }
        }
        if (!statusChangedCases.isEmpty()) {
            CaseService.sendClosureNotification(statusChangedCases);
        }
    }
}
