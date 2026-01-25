import {LightningElement, track} from 'lwc';

export default class RecordFormRecordId extends LightningElement {
    @track opportunity = {};

    onOpportunityChange(ev) {
        Object.assign(this.opportunity, ev.detail.value);
    }
}