import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getPipelineData from '@salesforce/apex/OpportunityPipelineController.getPipelineData';
import updateOpportunityStage from '@salesforce/apex/OpportunityPipelineController.updateOpportunityStage';

const STAGES = [
    'Prospecting',
    'Qualification',
    'Needs Analysis',
    'Value Proposition',
    'Id. Decision Makers',
    'Perception Analysis',
    'Proposal/Price Quote',
    'Negotiation/Review',
    'Closed Won',
    'Closed Lost'
];

export default class OpportunityPipeline extends NavigationMixin(LightningElement) {
    @track pipelineByStage = {};
    @track isLoading = true;
    @track draggedOppId;
    @track draggedFromStage;

    wiredResult;

    @wire(getPipelineData)
    wiredPipeline(result) {
        this.wiredResult = result;
        this.isLoading = false;
        if (result.data) {
            this.pipelineByStage = this.groupByStage(result.data);
        }
    }

    groupByStage(opps) {
        const grouped = {};
        STAGES.forEach(s => grouped[s] = { label: s, opps: [], total: 0 });
        opps.forEach(opp => {
            if (grouped[opp.StageName]) {
                grouped[opp.StageName].opps.push(opp);
                grouped[opp.StageName].total += opp.Amount || 0;
            }
        });
        return grouped;
    }

    get stages() {
        return STAGES.map(s => ({
            name: s,
            label: s,
            opps: this.pipelineByStage[s]?.opps || [],
            total: this.formatCurrency(this.pipelineByStage[s]?.total || 0),
            count: this.pipelineByStage[s]?.opps?.length || 0
        }));
    }

    formatCurrency(value) {
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(value);
    }

    handleDragStart(event) {
        this.draggedOppId    = event.currentTarget.dataset.id;
        this.draggedFromStage = event.currentTarget.dataset.stage;
        event.dataTransfer.effectAllowed = 'move';
    }

    handleDragOver(event) {
        event.preventDefault();
        event.dataTransfer.dropEffect = 'move';
        event.currentTarget.classList.add('drag-over');
    }

    handleDragLeave(event) {
        event.currentTarget.classList.remove('drag-over');
    }

    handleDrop(event) {
        event.preventDefault();
        event.currentTarget.classList.remove('drag-over');
        const targetStage = event.currentTarget.dataset.stage;
        if (targetStage && targetStage !== this.draggedFromStage) {
            this.moveOpportunity(this.draggedOppId, targetStage);
        }
    }

    async moveOpportunity(oppId, newStage) {
        this.isLoading = true;
        try {
            await updateOpportunityStage({ oppId, newStage });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Stage Updated',
                message: `Opportunity moved to ${newStage}`,
                variant: 'success'
            }));
            await refreshApex(this.wiredResult);
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Update Failed',
                message: e.body?.message,
                variant: 'error'
            }));
        } finally {
            this.isLoading = false;
        }
    }

    handleOppClick(event) {
        const oppId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: oppId, actionName: 'view' }
        });
    }
}
