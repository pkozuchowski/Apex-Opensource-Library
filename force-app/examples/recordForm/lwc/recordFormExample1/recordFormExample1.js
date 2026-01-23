import {LightningElement, wire, track} from 'lwc';
import {getRecord} from 'lightning/uiRecordApi';
import {getObjectInfo} from "lightning/uiObjectInfoApi";

export default class Preview extends LightningElement {
    @track account;
    @track opportunity;
    show = "123"
    readOnly = false;
    labelOverrides = {
        "Name": "Client Name",
    }
    density = "comfy";

    nameAttributes = {
        Salutation: {
            required: true
        }
    }

    condition = false;
    value = '1';

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
        let reportValidity = this.refs.recordForm.reportValidityForField('Type');
        console.log('reportValidity', JSON.stringify(reportValidity, null, 2));
    }

    doSomething() {
        this.show = "test"
    }

    handleChange(ev) {
        this.value = ev.detail.value;
    }

    @wire(getObjectInfo, {objectApiName: 'Lead'})
    describeObjectInfo({err, data}) {
        if (data) {
            console.log('this.lead', data);
        } else if (err) {
            console.error('Error fetching object info', err);
        }
    };

    @wire(getRecord, {recordId: '001KM00000KlMXkYAN', layoutTypes: 'Full'})
    getAccount({error, data}) {
        if (data) {
            let record = {};
            for (let field in data.fields) {
                record[field] = data.fields[field].value;
            }
            record.Id = data.id;
            this.account = JSON.parse(JSON.stringify(record));
        }
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
}