import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getEscalatedCases from '@salesforce/apex/CaseEscalationController.getEscalatedCases';
import reassignCase from '@salesforce/apex/CaseEscalationController.reassignCase';

export default class CaseEscalationDashboard extends NavigationMixin(LightningElement) {
    @track cases = [];
    @track isLoading = true;
    @track selectedCaseId;
    @track showReassignModal = false;
    @track newOwnerId;

    wiredResult;

    columns = [
        { label: 'Case #',    fieldName: 'CaseNumber',    type: 'text' },
        { label: 'Subject',   fieldName: 'Subject',       type: 'text' },
        { label: 'Account',   fieldName: 'AccountName',   type: 'text' },
        { label: 'Priority',  fieldName: 'Priority',      type: 'text',
          cellAttributes: { class: { fieldName: 'priorityClass' } } },
        { label: 'Status',    fieldName: 'Status',        type: 'text' },
        { label: 'Age (hrs)', fieldName: 'AgeHours',      type: 'number' },
        { label: 'Owner',     fieldName: 'OwnerName',     type: 'text' },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'View Case',   name: 'view'     },
                    { label: 'Reassign',    name: 'reassign' },
                    { label: 'Escalate',    name: 'escalate' }
                ]
            }
        }
    ];

    @wire(getEscalatedCases)
    wiredCases(result) {
        this.wiredResult = result;
        this.isLoading = false;
        if (result.data) {
            this.cases = result.data;
        }
    }

    handleRowAction(event) {
        const action = event.detail.action.name;
        const row    = event.detail.row;

        switch (action) {
            case 'view':
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: { recordId: row.Id, actionName: 'view' }
                });
                break;
            case 'reassign':
                this.selectedCaseId = row.Id;
                this.showReassignModal = true;
                break;
            case 'escalate':
                this.escalateCase(row.Id);
                break;
        }
    }

    handleOwnerChange(event) {
        this.newOwnerId = event.detail.value[0];
    }

    async handleReassignConfirm() {
        if (!this.newOwnerId) return;
        try {
            await reassignCase({ caseId: this.selectedCaseId, newOwnerId: this.newOwnerId });
            this.showReassignModal = false;
            this.dispatchEvent(new ShowToastEvent({ title: 'Reassigned', variant: 'success' }));
            await refreshApex(this.wiredResult);
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error', message: e.body?.message, variant: 'error'
            }));
        }
    }

    handleReassignCancel() {
        this.showReassignModal = false;
        this.selectedCaseId = null;
        this.newOwnerId = null;
    }

    escalateCase(caseId) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Escalation triggered',
            message: `Case ${caseId} escalated to management queue.`,
            variant: 'warning'
        }));
    }

    get totalEscalated() { return this.cases.length; }
    get criticalCount()  { return this.cases.filter(c => c.Priority === 'Critical').length; }
    get highCount()      { return this.cases.filter(c => c.Priority === 'High').length; }
}
