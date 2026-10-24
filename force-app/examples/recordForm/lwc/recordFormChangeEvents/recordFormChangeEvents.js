import { LightningElement, track } from "lwc";

export default class RecordFormChangeEvents extends LightningElement {
    @track account = {};
    lastChange = "Edit a field to see the change event payload.";

    handleRecordChange(event) {
        Object.assign(this.account, event.detail.value);
        this.lastChange = JSON.stringify(event.detail.value, null, 2);
    }
}
