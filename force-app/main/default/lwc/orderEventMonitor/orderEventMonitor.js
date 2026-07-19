import { LightningElement, track } from 'lwc';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';

const CHANNEL = '/event/OrderStatusEvent__e';
const MAX_EVENTS = 50;

const STATUS_ICON = {
    Activated: 'utility:success',
    Shipped:   'utility:truck',
    Delivered: 'utility:check',
    Cancelled: 'utility:error',
    Draft:     'utility:edit'
};

export default class OrderEventMonitor extends LightningElement {
    @track events        = [];
    @track isConnected   = false;
    @track statusMessage = 'Disconnected';
    @track filterStatus  = '';

    subscription = {};

    statusOptions = [
        { label: 'All Statuses', value: '' },
        { label: 'Activated',    value: 'Activated' },
        { label: 'Shipped',      value: 'Shipped' },
        { label: 'Delivered',    value: 'Delivered' },
        { label: 'Cancelled',    value: 'Cancelled' }
    ];

    get filteredEvents() {
        if (!this.filterStatus) return this.events;
        return this.events.filter(e => e.newStatus === this.filterStatus);
    }

    get connectLabel() {
        return this.isConnected ? 'Disconnect' : 'Connect';
    }

    get connectVariant() {
        return this.isConnected ? 'destructive' : 'success';
    }

    get connectedBadge() {
        return this.isConnected ? 'slds-badge slds-badge_success' : 'slds-badge';
    }

    connectedCallback() {
        onError(error => {
            console.error('empApi error:', JSON.stringify(error));
            this.statusMessage = 'Error: ' + (error.message || JSON.stringify(error));
            this.isConnected = false;
        });
    }

    disconnectedCallback() {
        this.handleDisconnect();
    }

    handleToggleConnect() {
        if (this.isConnected) {
            this.handleDisconnect();
        } else {
            this.handleConnect();
        }
    }

    handleConnect() {
        // Subscribe from tip — we only want new events while the component is open.
        // For replay, pass a specific replayId or -2 for all stored events.
        const replayId = -1;

        subscribe(CHANNEL, replayId, (event) => {
            this.handleEvent(event);
        }).then(subscription => {
            this.subscription = subscription;
            this.isConnected  = true;
            this.statusMessage = 'Listening on ' + CHANNEL;
        }).catch(err => {
            this.statusMessage = 'Subscribe failed: ' + JSON.stringify(err);
        });
    }

    handleDisconnect() {
        if (!this.subscription?.id) return;
        unsubscribe(this.subscription, () => {
            this.isConnected   = false;
            this.statusMessage = 'Disconnected';
            this.subscription  = {};
        });
    }

    handleEvent(event) {
        const payload = event.data.payload;
        const newEntry = {
            id:             event.data.event.replayId,
            replayId:       event.data.event.replayId,
            eventUuid:      event.data.event.EventUuid || '—',
            orderId:        payload.OrderId__c,
            orderNumber:    payload.OrderNumber__c || '—',
            newStatus:      payload.NewStatus__c,
            previousStatus: payload.PreviousStatus__c || '—',
            sourceSystem:   payload.SourceSystem__c || '—',
            customerId:     payload.CustomerId__c || '—',
            receivedAt:     new Date().toLocaleTimeString(),
            icon:           STATUS_ICON[payload.NewStatus__c] || 'utility:event',
            rowClass:       payload.NewStatus__c === 'Cancelled'
                                ? 'slds-theme_error'
                                : payload.NewStatus__c === 'Delivered'
                                    ? 'slds-theme_success'
                                    : ''
        };

        // Prepend newest events, cap at MAX_EVENTS
        this.events = [newEntry, ...this.events].slice(0, MAX_EVENTS);
    }

    handleFilterChange(event) {
        this.filterStatus = event.detail.value;
    }

    handleClear() {
        this.events = [];
    }
}
