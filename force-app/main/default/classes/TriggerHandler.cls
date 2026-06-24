public virtual class TriggerHandler {

    private static Set<String> bypassedHandlers = new Set<String>();

    @TestVisible
    protected TriggerContext context;

    public TriggerHandler() {
        this.context = getCurrentContext();
    }

    public void run() {
        if (!validateRun()) return;

        switch on this.context {
            when BEFORE_INSERT  { beforeInsert(); }
            when BEFORE_UPDATE  { beforeUpdate(); }
            when BEFORE_DELETE  { beforeDelete(); }
            when AFTER_INSERT   { afterInsert(); }
            when AFTER_UPDATE   { afterUpdate(); }
            when AFTER_DELETE   { afterDelete(); }
            when AFTER_UNDELETE { afterUndelete(); }
        }
    }

    private Boolean validateRun() {
        if (bypassedHandlers.contains(getHandlerName())) return false;
        if (!Trigger.isExecuting) return false;
        return true;
    }

    private TriggerContext getCurrentContext() {
        if (Trigger.isExecuting) {
            if      (Trigger.isBefore && Trigger.isInsert)  return TriggerContext.BEFORE_INSERT;
            else if (Trigger.isBefore && Trigger.isUpdate)  return TriggerContext.BEFORE_UPDATE;
            else if (Trigger.isBefore && Trigger.isDelete)  return TriggerContext.BEFORE_DELETE;
            else if (Trigger.isAfter  && Trigger.isInsert)  return TriggerContext.AFTER_INSERT;
            else if (Trigger.isAfter  && Trigger.isUpdate)  return TriggerContext.AFTER_UPDATE;
            else if (Trigger.isAfter  && Trigger.isDelete)  return TriggerContext.AFTER_DELETE;
            else if (Trigger.isAfter  && Trigger.isUndelete) return TriggerContext.AFTER_UNDELETE;
        }
        return null;
    }

    private String getHandlerName() {
        return String.valueOf(this).substring(0, String.valueOf(this).indexOf(':'));
    }

    public static void bypass(String handlerName) {
        bypassedHandlers.add(handlerName);
    }

    public static void clearBypass(String handlerName) {
        bypassedHandlers.remove(handlerName);
    }

    public static Boolean isBypassed(String handlerName) {
        return bypassedHandlers.contains(handlerName);
    }

    protected virtual void beforeInsert()  {}
    protected virtual void beforeUpdate()  {}
    protected virtual void beforeDelete()  {}
    protected virtual void afterInsert()   {}
    protected virtual void afterUpdate()   {}
    protected virtual void afterDelete()   {}
    protected virtual void afterUndelete() {}

    public enum TriggerContext {
        BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,
        AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, AFTER_UNDELETE
    }
}
