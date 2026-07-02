public with sharing class OmniChannelRoutingService {

    private static final String TIER_ONE_QUEUE   = 'Tier_One_Support';
    private static final String TIER_TWO_QUEUE   = 'Tier_Two_Escalation';
    private static final Integer VIP_PRIORITY     = 1;
    private static final Integer STANDARD_PRIORITY = 5;

    // ─── Entry point called by Record-Triggered Flow or Trigger ───────────────

    @InvocableMethod(label='Route Case via Omnichannel' description='Assigns a PendingServiceRouting record for the given case based on priority and skills')
    public static List<RoutingResult> routeCases(List<RoutingRequest> requests) {
        List<RoutingResult> results = new List<RoutingResult>();
        for (RoutingRequest req : requests) {
            results.add(routeCase(req));
        }
        return results;
    }

    private static RoutingResult routeCase(RoutingRequest req) {
        RoutingResult result = new RoutingResult();
        try {
            Case c = queryCaseWithAccount(req.caseId);
            RoutingContext ctx = buildContext(c);

            Id queueId = resolveQueue(ctx);
            Integer priority = resolvePriority(ctx);

            PendingServiceRouting psr = buildPSR(c.Id, queueId, priority, ctx.channelName);
            insert psr;

            if (ctx.requiresSkill) {
                attachSkillRequirements(psr.Id, ctx.requiredSkills);
            }

            result.psrId       = psr.Id;
            result.queueName   = ctx.isEscalation ? TIER_TWO_QUEUE : TIER_ONE_QUEUE;
            result.priority    = priority;
            result.isSuccess   = true;
        } catch (Exception e) {
            result.isSuccess     = false;
            result.errorMessage  = e.getMessage();
        }
        return result;
    }

    // ─── Routing logic ────────────────────────────────────────────────────────

    private static RoutingContext buildContext(Case c) {
        RoutingContext ctx     = new RoutingContext();
        ctx.isVip              = c.Account?.Customer_Tier__c == 'VIP';
        ctx.isEscalation       = c.Priority == 'Critical' || c.IsEscalated;
        ctx.channelName        = resolveChannelName(c.Origin);
        ctx.requiredSkills     = resolveSkills(c);
        ctx.requiresSkill      = !ctx.requiredSkills.isEmpty();
        return ctx;
    }

    private static Id resolveQueue(RoutingContext ctx) {
        String queueName = ctx.isEscalation ? TIER_TWO_QUEUE : TIER_ONE_QUEUE;
        List<Group> queues = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :queueName LIMIT 1];
        if (queues.isEmpty()) {
            throw new RoutingException('Queue not found: ' + queueName);
        }
        return queues[0].Id;
    }

    private static Integer resolvePriority(RoutingContext ctx) {
        if (ctx.isVip || ctx.isEscalation) return VIP_PRIORITY;
        return STANDARD_PRIORITY;
    }

    private static String resolveChannelName(String origin) {
        if (origin == 'Chat' || origin == 'Web')  return 'ChatServiceChannel';
        return 'CaseServiceChannel';
    }

    private static List<String> resolveSkills(Case c) {
        List<String> skills = new List<String>();
        if (c.Type__c == 'Technical')     skills.add('Technical_Support');
        if (c.Type__c == 'Billing')       skills.add('Billing_Specialist');
        if (c.Language__c == 'French')    skills.add('French_Language');
        if (c.Language__c == 'Spanish')   skills.add('Spanish_Language');
        return skills;
    }

    private static PendingServiceRouting buildPSR(Id caseId, Id queueId, Integer priority, String channelName) {
        return new PendingServiceRouting(
            WorkItemId          = caseId,
            RoutingModel        = 'SkillsBased',
            RoutingPriority     = priority,
            ServiceChannelId    = getChannelId(channelName),
            PreferredUserId     = null,
            IsReadyForRouting   = true
        );
    }

    private static Id getChannelId(String channelName) {
        List<ServiceChannel> channels = [SELECT Id FROM ServiceChannel WHERE DeveloperName = :channelName LIMIT 1];
        if (channels.isEmpty()) {
            throw new RoutingException('ServiceChannel not found: ' + channelName);
        }
        return channels[0].Id;
    }

    private static void attachSkillRequirements(Id psrId, List<String> skillNames) {
        List<SkillRequirement> requirements = new List<SkillRequirement>();
        List<Skill> skills = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName IN :skillNames];

        for (Skill s : skills) {
            requirements.add(new SkillRequirement(
                RelatedRecordId  = psrId,
                SkillId          = s.Id,
                SkillLevel       = 5.0
            ));
        }
        if (!requirements.isEmpty()) insert requirements;
    }

    private static Case queryCaseWithAccount(Id caseId) {
        return [
            SELECT Id, Subject, Priority, Status, IsEscalated, Origin,
                   Type__c, Language__c, AccountId, Account.Customer_Tier__c
            FROM   Case
            WHERE  Id = :caseId
            LIMIT  1
        ];
    }

    // ─── Supervisor capacity query (consumed by omniSupervisorDashboard LWC) ──

    @AuraEnabled(cacheable=true)
    public static List<AgentCapacityWrapper> getAgentCapacity(String queueDeveloperName) {
        List<AgentCapacityWrapper> capacities = new List<AgentCapacityWrapper>();

        List<UserServicePresence> presences = [
            SELECT Id, UserId, User.Name, User.SmallPhotoUrl,
                   ServicePresenceStatus.MasterLabel, IsAway,
                   ActiveInteractionsCount, ConfiguredCapacity
            FROM   UserServicePresence
            WHERE  IsCurrentState = true
            ORDER BY User.Name
            LIMIT  200
        ];

        for (UserServicePresence usp : presences) {
            AgentCapacityWrapper w = new AgentCapacityWrapper();
            w.userId               = usp.UserId;
            w.agentName            = usp.User.Name;
            w.photoUrl             = usp.User.SmallPhotoUrl;
            w.statusLabel          = usp.ServicePresenceStatus.MasterLabel;
            w.isAway               = usp.IsAway;
            w.activeInteractions   = usp.ActiveInteractionsCount;
            w.configuredCapacity   = usp.ConfiguredCapacity;
            w.availableCapacity    = usp.ConfiguredCapacity - usp.ActiveInteractionsCount;
            capacities.add(w);
        }
        return capacities;
    }

    @AuraEnabled(cacheable=true)
    public static QueueStatsWrapper getQueueStats(String queueDeveloperName) {
        QueueStatsWrapper stats = new QueueStatsWrapper();

        List<Group> queues = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :queueDeveloperName LIMIT 1];
        if (queues.isEmpty()) return stats;

        Id queueId = queues[0].Id;

        stats.pendingCount = [
            SELECT COUNT() FROM Case
            WHERE  OwnerId = :queueId AND Status NOT IN ('Closed','Resolved')
        ];

        AggregateResult[] agg = [
            SELECT AVG(AgeHours__c) avgAge, MAX(AgeHours__c) maxAge
            FROM   Case
            WHERE  OwnerId = :queueId AND Status NOT IN ('Closed','Resolved')
        ];
        if (!agg.isEmpty()) {
            stats.avgAgeHours = (Decimal) agg[0].get('avgAge');
            stats.maxAgeHours = (Decimal) agg[0].get('maxAge');
        }

        stats.queueName = queueDeveloperName;
        return stats;
    }

    // ─── Inner types ──────────────────────────────────────────────────────────

    public class RoutingContext {
        public Boolean isVip;
        public Boolean isEscalation;
        public Boolean requiresSkill;
        public String  channelName;
        public List<String> requiredSkills;
    }

    public class RoutingRequest {
        @InvocableVariable(required=true label='Case Id')
        public Id caseId;
    }

    public class RoutingResult {
        @InvocableVariable public Id      psrId;
        @InvocableVariable public String  queueName;
        @InvocableVariable public Integer priority;
        @InvocableVariable public Boolean isSuccess;
        @InvocableVariable public String  errorMessage;
    }

    public class AgentCapacityWrapper {
        @AuraEnabled public Id      userId;
        @AuraEnabled public String  agentName;
        @AuraEnabled public String  photoUrl;
        @AuraEnabled public String  statusLabel;
        @AuraEnabled public Boolean isAway;
        @AuraEnabled public Integer activeInteractions;
        @AuraEnabled public Integer configuredCapacity;
        @AuraEnabled public Integer availableCapacity;
    }

    public class QueueStatsWrapper {
        @AuraEnabled public String  queueName       = '';
        @AuraEnabled public Integer pendingCount     = 0;
        @AuraEnabled public Decimal avgAgeHours      = 0;
        @AuraEnabled public Decimal maxAgeHours      = 0;
    }

    public class RoutingException extends Exception {}
}
