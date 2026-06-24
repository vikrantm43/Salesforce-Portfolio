import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { subscribe, MessageContext } from 'lightning/messageService';
import ACCOUNT_SELECTED_CHANNEL from '@salesforce/messageChannel/AccountSelected__c';
import getAccountKPIs from '@salesforce/apex/AccountDashboardController.getAccountKPIs';

const ACCOUNT_FIELDS = ['Account.Name', 'Account.Industry', 'Account.AnnualRevenue', 'Account.OwnerId'];

export default class AccountDashboard extends LightningElement {
    @api recordId;
    @track kpis = {};
    @track isLoading = true;
    @track error;

    subscription = null;

    @wire(MessageContext) messageContext;

    @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
    account;

    @wire(getAccountKPIs, { accountId: '$recordId' })
    wiredKPIs({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.kpis = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body?.message || 'Error loading KPIs';
        }
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    subscribeToMessageChannel() {
        if (this.subscription) return;
        this.subscription = subscribe(this.messageContext, ACCOUNT_SELECTED_CHANNEL, (message) => {
            this.handleAccountSelected(message);
        });
    }

    handleAccountSelected(message) {
        this.recordId = message.accountId;
        this.isLoading = true;
    }

    get accountName() {
        return getFieldValue(this.account.data, 'Account.Name');
    }

    get openCasesCount() {
        return this.kpis.openCases ?? 0;
    }

    get openOpportunitiesCount() {
        return this.kpis.openOpportunities ?? 0;
    }

    get npsScore() {
        return this.kpis.npsScore ?? 'N/A';
    }

    get npsClass() {
        const score = this.kpis.npsScore;
        if (score >= 8) return 'kpi-card kpi-good';
        if (score >= 6) return 'kpi-card kpi-neutral';
        return 'kpi-card kpi-bad';
    }

    get hasError() {
        return !!this.error;
    }
}
