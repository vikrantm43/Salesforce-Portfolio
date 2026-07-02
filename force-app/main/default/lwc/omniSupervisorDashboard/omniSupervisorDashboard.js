import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getAgentCapacity from '@salesforce/apex/OmniChannelRoutingService.getAgentCapacity';
import getQueueStats    from '@salesforce/apex/OmniChannelRoutingService.getQueueStats';

const QUEUE_OPTIONS = [
    { label: 'Tier 1 – Support',    value: 'Tier_One_Support'      },
    { label: 'Tier 2 – Escalation', value: 'Tier_Two_Escalation'   }
];

const AGENT_COLUMNS = [
    { label: 'Agent',             fieldName: 'agentName',          type: 'text'    },
    { label: 'Status',            fieldName: 'statusLabel',        type: 'text',
      cellAttributes: { class: { fieldName: 'statusClass' } } },
    { label: 'Active',            fieldName: 'activeInteractions', type: 'number'  },
    { label: 'Capacity',          fieldName: 'configuredCapacity', type: 'number'  },
    { label: 'Available',         fieldName: 'availableCapacity',  type: 'number',
      cellAttributes: { class: { fieldName: 'availClass' } } }
];

export default class OmniSupervisorDashboard extends LightningElement {

    @track selectedQueue  = 'Tier_One_Support';
    @track isRefreshing   = false;

    queueOptions  = QUEUE_OPTIONS;
    agentColumns  = AGENT_COLUMNS;

    _wiredAgents;
    _wiredStats;

    // ─── Wired data ───────────────────────────────────────────────────────────

    @wire(getAgentCapacity, { queueDeveloperName: '$selectedQueue' })
    wiredAgents(result) {
        this._wiredAgents = result;
        if (result.error) {
            this._showError('Failed to load agent capacity', result.error);
        }
    }

    @wire(getQueueStats, { queueDeveloperName: '$selectedQueue' })
    wiredStats(result) {
        this._wiredStats = result;
        if (result.error) {
            this._showError('Failed to load queue stats', result.error);
        }
    }

    // ─── Handlers ─────────────────────────────────────────────────────────────

    handleQueueChange(event) {
        this.selectedQueue = event.detail.value;
    }

    async handleRefresh() {
        this.isRefreshing = true;
        try {
            await Promise.all([
                refreshApex(this._wiredAgents),
                refreshApex(this._wiredStats)
            ]);
        } finally {
            this.isRefreshing = false;
        }
    }

    // ─── Getters ──────────────────────────────────────────────────────────────

    get agents() {
        const raw = this._wiredAgents?.data ?? [];
        return raw.map(a => ({
            ...a,
            statusClass: a.isAway ? 'slds-badge slds-badge_lightest' : 'slds-badge slds-badge_success',
            availClass:  a.availableCapacity === 0 ? 'slds-text-color_error' : 'slds-text-color_success'
        }));
    }

    get stats() {
        return this._wiredStats?.data ?? {};
    }

    get pendingCount()   { return this.stats.pendingCount  ?? 0; }
    get avgAge()         { return this.stats.avgAgeHours   != null ? this.stats.avgAgeHours.toFixed(1) : '—'; }
    get maxAge()         { return this.stats.maxAgeHours   != null ? this.stats.maxAgeHours.toFixed(1) : '—'; }

    get totalAgents()    { return this.agents.length; }
    get availableAgents(){ return this.agents.filter(a => !a.isAway && a.availableCapacity > 0).length; }
    get awayAgents()     { return this.agents.filter(a =>  a.isAway).length; }
    get fullAgents()     { return this.agents.filter(a => !a.isAway && a.availableCapacity === 0).length; }

    get isLoading()      { return !this._wiredAgents?.data && !this._wiredAgents?.error; }
    get hasAgents()      { return this.agents.length > 0; }

    get pendingBadgeClass() {
        if (this.pendingCount > 20) return 'kpi-card kpi-bad';
        if (this.pendingCount > 10) return 'kpi-card kpi-neutral';
        return 'kpi-card kpi-good';
    }

    get queueLabel() {
        const opt = this.queueOptions.find(o => o.value === this.selectedQueue);
        return opt ? opt.label : this.selectedQueue;
    }

    // ─── Private ──────────────────────────────────────────────────────────────

    _showError(title, error) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message: error?.body?.message ?? 'Unknown error',
            variant: 'error'
        }));
    }
}
