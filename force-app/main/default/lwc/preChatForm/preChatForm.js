import { LightningElement, track } from 'lwc';

export default class PreChatForm extends LightningElement {

    @track formData = {
        firstName: '',
        lastName: '',
        email: '',
        caseNumber: '',
        issueCategory: '',
        description: ''
    };

    @track errors = {};
    @track isSubmitting = false;

    categoryOptions = [
        { label: 'Technical Issue', value: 'Technical' },
        { label: 'Billing & Account', value: 'Billing' },
        { label: 'Product Question', value: 'Question' },
        { label: 'Feature Request', value: 'Enhancement' }
    ];

    handleInputChange(event) {
        const field = event.target.dataset.field;
        this.formData[field] = event.target.value;
        if (this.errors[field]) {
            delete this.errors[field];
            this.errors = { ...this.errors };
        }
    }

    validate() {
        const errs = {};
        if (!this.formData.firstName?.trim()) errs.firstName = 'First name is required.';
        if (!this.formData.lastName?.trim())  errs.lastName  = 'Last name is required.';
        if (!this.formData.email?.match(/^[^\s@]+@[^\s@]+\.[^\s@]+$/)) errs.email = 'Valid email is required.';
        if (!this.formData.issueCategory) errs.issueCategory = 'Please select an issue category.';
        this.errors = errs;
        return Object.keys(errs).length === 0;
    }

    handleSubmit() {
        if (!this.validate()) return;

        this.isSubmitting = true;

        const prechatFields = {
            'FirstName':       this.formData.firstName,
            'LastName':        this.formData.lastName,
            'Email':           this.formData.email,
            'Case_Number__c':  this.formData.caseNumber,
            'Issue_Category__c': this.formData.issueCategory,
            'Description':     this.formData.description
        };

        // Pass structured data to MIAW pre-chat API
        const event = new CustomEvent('prechatsubmit', {
            detail: { prechatFields },
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(event);
    }

    get isFirstNameInvalid() { return !!this.errors.firstName; }
    get isLastNameInvalid()  { return !!this.errors.lastName;  }
    get isEmailInvalid()     { return !!this.errors.email;     }
    get isCategoryInvalid()  { return !!this.errors.issueCategory; }
}
