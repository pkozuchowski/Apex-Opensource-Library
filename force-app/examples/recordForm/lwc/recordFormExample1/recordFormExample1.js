import {LightningElement, wire, track} from 'lwc';
import {getRecord} from 'lightning/uiRecordApi';
import {getObjectInfo} from "lightning/uiObjectInfoApi";

export default class Preview extends LightningElement {
    @track account = {};
    @track opportunity;
    show = "123"
    readOnly = false;
    labelOverrides = {
        "Name": "Client Name",
    }
    density = "comfy";

    condition = false;

    edit() {
        this.readOnly = !this.readOnly;
    }

    changeDensity() {
        this.density = this.density === "compact" ? "comfy" : "compact";
    }

    reportValidity() {
        let reportValidity = this.refs.recordForm.reportValidity();
        console.log('reportValidity', JSON.stringify(reportValidity, null, 2));
    }

    reportValidityWebsite() {
        let reportValidity = this.refs.recordForm.reportValidityForField('Website');
        console.log('reportValidity', JSON.stringify(reportValidity, null, 2));
    }


    onRecordChange(ev) {
        ev.preventDefault();
        ev.stopPropagation();
        try {
            Object.assign(this.account, ev.detail.value);
            console.log('this.handleChange', JSON.stringify(ev.detail.value, null, 2));
        } catch (e) {
            console.log(e, e.message, e.detail);
        }
    }

    showFields = true;

    showExtraFields() {
        this.showFields = !this.showFields;
    }

    handleValidate() {
        this.refs.recordForm.setCustomValidityForField('Name', 'Invalid value');
        this.refs.recordForm.setCustomValidityForField('Website', 'Invalid value');
        this.refs.recordForm.reportValidityForField('Website');
        this.refs.recordForm.reportValidity();
    }
}