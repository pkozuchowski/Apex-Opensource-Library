import {LightningElement, wire, track} from 'lwc';
import {getRecord} from 'lightning/uiRecordApi';

export default class Preview extends LightningElement {
    @track account;
    @track opportunity;
    readOnly = false;
    labelOverrides = {
        "Name": "Client Name",
    }

    condition = false;
    value = '1';

    handleSwitch() {
        try {

            // this.condition = !this.condition;
            // this.refs.recordForm.setCustomValidityForField('Website', 'This field is required');
        } catch (e) {
            console.log(e.message);
        }
    }

    edit() {
        this.readOnly = !this.readOnly;
    }

    options = [
        {label: 'Option 1', value: '1'},
        {label: 'Option 2', value: '2'},
        {label: 'Option 3', value: '3'},
        {label: 'Option 4', value: '4'}
    ];

    handleChange(ev) {
        this.value = ev.detail.value;
    }

    @wire(getRecord, {recordId: '006KM0000033FC6YAM', layoutTypes: 'Full'})
    getAccount({error, data}) {
        if (data) {
            console.log('account', data);
            let record = {};
            for (let field in data.fields) {
                record[field] = data.fields[field].value;
            }
            this.opportunity = JSON.parse(JSON.stringify(record));
        }
    }

    @wire(getRecord, {recordId: '001KM00000Kko2AYAR', layoutTypes: 'Full'})
    getOpportunity({error, data}) {
        if (data) {
            let record = {};
            for (let field in data.fields) {
                record[field] = data.fields[field].value;
            }
            this.account = JSON.parse(JSON.stringify(record));
        }
    }

    onRecordChange(ev) {
        ev.preventDefault();
        ev.stopPropagation();
        try {
            this.account = Object.assign(this.account, ev.detail.value);
        } catch (e) {
            console.log(e, e.message, e.detail);
        }
    }

    onOpportunityChange(ev) {
        ev.preventDefault();
        ev.stopPropagation();
        try {
            this.account = {...this.account, ...ev.detail};
        } catch (e) {
            console.log(e, e.message, e.detail);
        }
    }
}