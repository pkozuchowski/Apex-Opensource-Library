import { LightningElement, track } from "lwc";

export default class RecordFormChangeEvents extends LightningElement {
    @track account = {};

    handleRecordChange(event) {
        this.account = event.detail.value;
    }
}
