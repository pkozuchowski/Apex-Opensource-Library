import {LightningElement, wire, track} from 'lwc';
import {getRecord} from 'lightning/uiRecordApi';

export default class Preview extends LightningElement {
    @track account;
    @track opportunity;
    readOnly = false;
    labelOverrides = {
        "Name": "Client Name",
    }
    variant = "comfy";
    options = [
        {value: 'comfy', label: 'comfy'},
        {value: 'compact', label: 'compact'}
    ];

    onRadioCahnge(ev) {
        this.variant = ev.detail.value;
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

    reportValidity() {
        this.refs.recordForm.reportValidity();
    }

    handleChange(ev) {
        this.value = ev.detail.value;
    }

    // @wire(getRecord, {recordId: '006KM0000033FC6YAM', layoutTypes: 'Full'})
    // getAccount({error, data}) {
    //     if (data) {
    //         console.log('account', data);
    //         let record = {};
    //         for (let field in data.fields) {
    //             record[field] = data.fields[field].value;
    //         }
    //         this.opportunity = JSON.parse(JSON.stringify(record));
    //     }
    // }

    @wire(getRecord, {recordId: '001KM00000Kko2AYAR', layoutTypes: 'Full'})
    getAccount({error, data}) {
        if (data) {
            setTimeout(() => {


                let record = {};
                for (let field in data.fields) {
                    record[field] = data.fields[field].value;
                }
                this.account = record;
            }, 1000);
        }
    }

    onRecordChange(ev) {
        ev.preventDefault();
        ev.stopPropagation();
        try {
            this.account = Object.assign(this.account, ev.detail.value);
            console.log('this.onRecordChange', JSON.stringify(ev.detail.value, null, 2));
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