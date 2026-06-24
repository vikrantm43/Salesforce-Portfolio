import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import CASE_SLA_FIELD from '@salesforce/schema/Case.SlaStartDate';
import CASE_SLA_EXIT from '@salesforce/schema/Case.SlaExitDate';
import CASE_STATUS from '@salesforce/schema/Case.Status';

const CASE_FIELDS = [CASE_SLA_FIELD, CASE_SLA_EXIT, CASE_STATUS];
const TICK_INTERVAL = 60000; // refresh every minute

export default class SlaTimerBar extends LightningElement {
    @api recordId;
    @track remainingLabel = '';
    @track progressPercent = 0;
    @track barClass = 'sla-bar sla-green';
    @track isBreached = false;
    @track isClosed = false;

    _interval;

    @wire(getRecord, { recordId: '$recordId', fields: CASE_FIELDS })
    caseRecord({ data, error }) {
        if (data) {
            this.computeSla(data);
            this.startTicker();
        }
    }

    computeSla(data) {
        const status = getFieldValue(data, CASE_STATUS);
        this.isClosed = ['Closed', 'Resolved'].includes(status);
        if (this.isClosed) return;

        const start = getFieldValue(data, CASE_SLA_FIELD);
        const exit  = getFieldValue(data, CASE_SLA_EXIT);
        if (!start || !exit) {
            this.remainingLabel = 'SLA not configured';
            return;
        }

        const now        = Date.now();
        const startMs    = new Date(start).getTime();
        const exitMs     = new Date(exit).getTime();
        const totalMs    = exitMs - startMs;
        const elapsedMs  = now - startMs;
        const remainMs   = exitMs - now;

        this.isBreached      = now > exitMs;
        this.progressPercent = Math.min(100, Math.round((elapsedMs / totalMs) * 100));
        this.remainingLabel  = this.isBreached
            ? 'SLA Breached — ' + this.formatDuration(Math.abs(remainMs)) + ' ago'
            : this.formatDuration(remainMs) + ' remaining';

        if (this.isBreached)             this.barClass = 'sla-bar sla-red';
        else if (this.progressPercent >= 75) this.barClass = 'sla-bar sla-amber';
        else                             this.barClass = 'sla-bar sla-green';
    }

    formatDuration(ms) {
        const totalMin = Math.floor(ms / 60000);
        const hours    = Math.floor(totalMin / 60);
        const mins     = totalMin % 60;
        if (hours > 0) return `${hours}h ${mins}m`;
        return `${mins}m`;
    }

    startTicker() {
        if (this._interval) clearInterval(this._interval);
        this._interval = setInterval(() => {
            if (this.caseRecord?.data) this.computeSla(this.caseRecord.data);
        }, TICK_INTERVAL);
    }

    disconnectedCallback() {
        if (this._interval) clearInterval(this._interval);
    }

    get progressStyle() {
        return `width: ${this.progressPercent}%`;
    }

    get showSla() {
        return !this.isClosed;
    }
}
