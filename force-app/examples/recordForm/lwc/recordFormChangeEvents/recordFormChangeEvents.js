import { LightningElement, track } from "lwc";

export default class RecordFormChangeEvents extends LightningElement {
    @track account = {};
    lastChange = "Edit a field to see the change event payload.";

    get accountJson() {
        return JSON.stringify(this.account, null, 2);
    }

    handleRecordChange(event) {
        Object.assign(this.account, event.detail.value);
        this.lastChange = JSON.stringify(event.detail.value, null, 2);
    }
}
