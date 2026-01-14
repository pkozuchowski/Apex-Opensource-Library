// SPDX-License-Identifier: MIT
// Copyright 2026 Piotr Kożuchowski
import {api, LightningElement, track, wire} from 'lwc';
import {getObjectInfo, getPicklistValuesByRecordType} from "lightning/uiObjectInfoApi";

const MASTER_RECORD_TYPE = "012000000000000AAA";

export default class RecordForm extends LightningElement {
    /**Object API Name*/
    @api objectApiName;
    @api formClass;

    /**Record Type Developer Name*/
    @api recordType;

    /**Accepted Values: comfy, compact*/
    @api density = "comfy";

    /** Map<Field, Label> of label overrides*/
    @api labelOverrides;
    @api designSystem = "lightning";
    fields = [];
    loading = true;
    objectInfo;
    picklistValues;
    recordTypeId;
    _readOnly = false;
    _record = {};


    @api
    get readOnly() {return this._readOnly;}

    set readOnly(value) {this.setValues('_readOnly', value);}

    /**Plain Record {fieldName, fieldValue}*/
    @api
    get record() {return this._record;}

    set record(value) {this.setValues('record', value);}


    setValues(property, value) {
        this[`_${property}`] = value;
        this.fields.forEach(field => field[property] = value);
    }


    @api
    reportValidityForField(field) {
        this.fields.find(cmp => cmp.field === field)?.reportValidity();
    }

    @api
    setCustomValidityForField(field, message) {
        this.fields.find(cmp => cmp.field === field)?.setCustomValidity(message);
    }

    @api
    checkValidityForField(field) {
        this.fields.find(cmp => cmp.field === field)?.checkValidity();
    }

    @api reportValidity() {
        return this.validate(field => field?.reportValidity())
    }

    @api checkValidity() {
        return this.validate(field => field?.checkValidity())
    }

    validate(method) {
        let result = {valid: true, fields: {}};
        this.fields.forEach(field => {
            const validity = method(this.fields[field]);
            result.valid = result.valid && (validity ?? true);
            result.fields[field] = validity;
        });
        return result;
    }

    get formClasses() {
        return `slds-form ${this.formClass}`;
    }

    @wire(getObjectInfo, {objectApiName: '$objectApiName'})
    describeObjectInfo({err, data}) {
        if (data) {
            console.log('this.getObjectInfo', data);
            this.objectInfo = JSON.parse(JSON.stringify(data));
            this.getRecordTypeId(data);
            this.overrideFieldLabels();
        } else if (err) {
            console.error('Error fetching object info', err);
        }
    };

    getRecordTypeId(data) {
        if (this.recordType) {
            const recordTypeInfos = data.recordTypeInfos;
            this.recordTypeId = Object.values(recordTypeInfos)
                .find(rti => rti.name === this.recordType)?.recordTypeId;
        }
        this.recordTypeId = this.recordTypeId || data.defaultRecordTypeId || MASTER_RECORD_TYPE;
    }

    overrideFieldLabels() {
        if (this.labelOverrides) {
            for (let field in this.labelOverrides) {
                this.objectInfo.fields[field].label = this.labelOverrides[field];
            }
        }
    }

    @wire(getPicklistValuesByRecordType, {
        objectApiName: "$objectApiName",
        recordTypeId : "$recordTypeId",
    })
    describePicklistValues({err, data}) {
        if (data) {
            this.picklistValues = JSON.parse(JSON.stringify(data.picklistFieldValues));
            this.loading = false;
        } else if (err) {
            console.error('Error fetching picklist values', err);
        }
    };

    onFormFieldConnected(ev) {
        ev.preventDefault();
        ev.stopPropagation();
        console.log('form field connected', ev.target.field, ev.target, ev.detail);

        if (ev.target.connectField) {
            ev.target.connectField(
                this.getConnectFieldPayload(ev)
            );
        }
    }

    onFieldConnected(ev) {
        try {
            ev.preventDefault();
            ev.stopPropagation();
            let field = this.objectInfo.fields[ev.target.field];
            console.log('field connected', ev.target.field, ev.target, ev.detail);
            if (ev.target.connectField) {
                this.fields.push(ev.target);
                ev.target.record = this._record;
                ev.target.formReadOnly = this.readOnly;
                ev.target.formVariant = this.density === "compact" ? "label-inline" : "label-stacked";
                ev.target.designSystem = this.designSystem;

                ev.target.connectField(
                    this.getConnectFieldPayload(ev)
                );
            }
        } catch (e) {
            console.log('recordForm.onFieldConnected', e.message, e.stack);
        }
    }

    getConnectFieldPayload(ev) {
        return {
            fieldInfo               : this.objectInfo.fields[ev.target.field],
            objectInfo              : this.objectInfo,
            recordTypePicklistValues: this.picklistValues
        };
    }
}