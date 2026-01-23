// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import {api, LightningElement, track, wire} from 'lwc';
import {getObjectInfo, getPicklistValuesByRecordType} from "lightning/uiObjectInfoApi";
import {createRecord, notifyRecordUpdateAvailable, updateRecord} from 'lightning/uiRecordApi';
import {getFlatRecord, getRecordTypeId, getUpdatableFields, overrideFieldLabels, validate} from "./recordFormUtils";

export default class RecordForm extends LightningElement {
    /**Object API Name*/
    @api objectApiName;
    @api formClass;

    /**Record Type Developer Name*/
    @api recordTypeName;

    /** Map<Field, Label> of label overrides*/
    @api labelOverrides;
    @api designSystem = "lightning";
    fields = [];
    loaded = false;
    spinner = true;
    objectInfo;
    picklistValues;
    recordTypeId;
    _record = {};

    @track
    formAttributes = {
        density     : "comfy",
        readOnly    : false,
        designSystem: "lightning"
    }


    @api
    get readOnly() {return this.formAttributes.readOnly;}

    set readOnly(value) {this.formAttributes.readOnly = value;}

    /**Accepted Values: comfy, compact*/
    @api
    get density() {return this.formAttributes.density;}

    set density(value) {this.formAttributes.density = value;}

    /**Plain Record {fieldName, fieldValue}*/
    @api
    get record() {return this._record;}

    set record(value) {this.setValues('record', value);}

    setValues(property, value) {
        this[`_${property}`] = value;
        this.fields.forEach(field => field[property] = value);
    }

    get formClasses() {
        return `slds-form ${this.formClass}`;
    }

    @api
    reportValidityForField(field) {
        return this.fields.find(cmp => cmp.field === field)?.reportValidity();
    }

    @api
    setCustomValidityForField(field, message) {
        return this.fields.find(cmp => cmp.field === field)?.setCustomValidity(message);
    }

    @api
    checkValidityForField(field) {
        return this.fields.find(cmp => cmp.field === field)?.checkValidity();
    }

    @api reportValidity() {
        return validate(this.fields, field => field?.reportValidity())
    }

    @api checkValidity() {
        return validate(this.fields, field => field?.checkValidity())
    }

    @api async submit(ev) {
        ev?.preventDefault();
        ev?.stopPropagation();
        this.spinner = true;
        try {
            const isCreate = !this.record?.Id;
            const fieldsToUpdate = getUpdatableFields(this.record, this.objectInfo, isCreate);

            const recordInput = {
                fields: fieldsToUpdate,
                ...(isCreate ? {apiName: this.objectApiName} : {})
            };

            const action = isCreate ? createRecord : updateRecord;
            const result = await action(recordInput);
            const flatRecord = getFlatRecord(result);

            this.dispatchEvent(new CustomEvent('change', {
                detail: {value: flatRecord}
            }));
            notifyRecordUpdateAvailable([{recordId: result.id}]);

            return flatRecord;
        } catch (err) {
            console.error(err?.message ?? err);
            throw err;
        } finally {
            this.spinner = false;
        }
    }

    @wire(getObjectInfo, {objectApiName: '$objectApiName'})
    describeObjectInfo({err, data}) {
        if (data) {
            this.objectInfo = JSON.parse(JSON.stringify(data));
            this.recordTypeId = getRecordTypeId(this.recordTypeName, data);
            overrideFieldLabels(this.labelOverrides, this.objectInfo);
        } else if (err) {
            console.error('Error fetching object info', err);
        }
    };

    @wire(getPicklistValuesByRecordType, {
        objectApiName: "$objectApiName",
        recordTypeId : "$recordTypeId",
    })
    describePicklistValues({err, data}) {
        if (data) {
            this.picklistValues = JSON.parse(JSON.stringify(data.picklistFieldValues));
            this.loaded = true;
            this.spinner = false;
        } else if (err) {
            console.error('Error fetching picklist values', err);
        }
    };

    onFieldConnected(ev) {
        try {
            ev.preventDefault();
            ev.stopPropagation();

            if (ev.target.connectField) {
                this.fields.push(ev.target);
                ev.target.record = this._record;
                ev.target.formAttributes = this.formAttributes;
                ev.target.connectField(
                    {
                        fieldInfo               : this.objectInfo.fields[ev.target.field],
                        objectInfo              : this.objectInfo,
                        recordTypePicklistValues: this.picklistValues,
                        formAttributes          : this.formAttributes
                    }
                );
            }
        } catch (e) {
            console.error('recordForm.onFieldConnected', e.message);
        }
    }
}