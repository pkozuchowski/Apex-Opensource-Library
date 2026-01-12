// SPDX-License-Identifier: MIT
// Copyright 2026 Piotr Kożuchowski
import {api, LightningElement, track} from 'lwc';
import {getFieldHandler} from "./fieldCtrls";
import emptyTemplate from './recordFormField.html';

const OPT_NONE = {label: '--None--', value: ''};
export default class RecordFormField extends LightningElement {
    @api field;
    @api label;
    @api options;
    /*Array of picklist values to present (['A', 'B', 'C'])*/
    @api optionsFilter;
    @api type;
    @api readOnly;
    @api disabled;
    @api required;
    @api variant;
    @api record;
    @track formParams;
    controllerName;
    fieldInfo;
    fieldCtrl;
    picklistValues;

    connectedCallback() {
        this.dispatchEvent(new CustomEvent('fieldconnected', {bubbles: true}));
    }

    @api
    reportValidity() {
        return this.refs.input.reportValidity?.() ?? true;
    }

    @api
    setCustomValidity(message) {
        return this.refs.input.setCustomValidity?.(message);
    }

    @api
    checkValidity() {
        return this.refs.input.checkValidity?.() ?? true;
    }

    @api connectField(objectInfo, picklistValues, formParams) {
        try {
            this.formParams = formParams;
            this.fieldInfo = objectInfo.fields[this.field];
            this.controllerName = this.fieldInfo.controllerName;
            this.picklistValues = picklistValues[this.field];
            this.fieldCtrl = getFieldHandler(this);
        } catch (e) {
            console.error('error.connectField', e.message);
        }
    }

    get inputProps() {
        try {
            return this.fieldCtrl.props(this);
        } catch (e) {
            console.error('error.inputProps', e.message, e.stack);
        }
    }

    get fieldValue() {
        return this.record ? this.record[this.field] : null;
    }

    get controllerValue() {
        return this.record ? this.record[this.controllerName] : null;
    }

    get classes() {
        return this.fieldCtrl?.classes(this);
    }

    get isReadOnly() {
        return this.readOnly || this.formParams?.readOnly;
    }

    /*TODO: Clear Dependant picklist when master changes*/
    get picklistOptions() {
        let options;
        if (this.options) {
            options = this.options;

        } else if (this.controllerName) {
            let controller = this.picklistValues.controllerValues[this.controllerValue];
            options = [
                OPT_NONE,
                ...this.picklistValues.values
                    .filter((item) => item.validFor.indexOf(controller) > -1)
                    .map(({label, value}) => ({label, value}))
            ];

        } else {
            options = [
                OPT_NONE,
                ...this.picklistValues.values
            ];
        }

        if (this.optionsFilter?.length > 0 && options.length > 1) {
            options = options.filter(option => this.optionsFilter.includes(option.value));
        }
        return options;
    }

    render() {
        return this.fieldCtrl?.render(this) || emptyTemplate;
    }

    handleChange(event) {
        event.preventDefault();
        event.stopPropagation();
        this.dispatchEvent(new CustomEvent('change', {
            detail : {
                field: this.field,
                value: this.fieldCtrl.outputValue(event)
            },
            bubbles: true,
        }));
    }
}