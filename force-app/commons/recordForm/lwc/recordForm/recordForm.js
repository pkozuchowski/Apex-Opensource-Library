// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import {api, LightningElement, track, wire} from 'lwc';
import {getObjectInfo, getPicklistValuesByRecordType} from "lightning/uiObjectInfoApi";
import {createRecord, notifyRecordUpdateAvailable, updateRecord} from 'lightning/uiRecordApi';
import {getFlatRecord, getRecordTypeId, getUpdatableFields, overrideFieldLabels, validate} from "./recordFormUtils";

/**
 * Lightning Web Component form wrapper that handles record wiring, field setup,
 * validation, and create/update submission for a given SObject and record type.
 */
export default class RecordForm extends LightningElement {
    /**Object API Name*/
    @api objectApiName;
    @api formClass;

    /**Record Type Developer Name*/
    @api recordTypeName;

    /** Map<Field, Label> of label overrides*/
    @api labelOverrides;
    /**Design system variant used by child fields.*/
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


    /**
     * Whether the form fields should be read-only.
     * @type {boolean}
     */
    @api
    get readOnly() {return this.formAttributes.readOnly;}

    set readOnly(value) {this.formAttributes.readOnly = value;}

    /**
     * Form density variant.
     * Accepted values: comfy, compact.
     * @type {string}
     */
    @api
    get density() {return this.formAttributes.density;}

    set density(value) {this.formAttributes.density = value;}

    /**
     * Plain record object keyed by field API name.
     * @type {Object}
     */
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

    /**
     * Report validity for a single field component.
     * @param {string} field Field API name.
     * @returns {boolean|undefined} - true if valid, false if invalid, undefined if not connected.
     */
    @api
    reportValidityForField(field) {
        return this.fields.find(cmp => cmp.field === field)?.reportValidity();
    }

    /**
     * Set a custom validation message for a single field component.
     * @param {string} field Field API name.
     * @param {string} message Custom message to display.
     * @returns {void}
     */
    @api
    setCustomValidityForField(field, message) {
        return this.fields.find(cmp => cmp.field === field)?.setCustomValidity(message);
    }

    /**
     * Check validity for a single field component.
     * @param {string} field Field API name.
     * @returns {boolean|undefined} - true if valid, false if invalid, undefined if not connected.
     */
    @api
    checkValidityForField(field) {
        return this.fields.find(cmp => cmp.field === field)?.checkValidity();
    }

    /**
     * Report validity for all connected fields.
     * @returns {boolean}
     */
    @api reportValidity() {
        return validate(this.fields, field => field?.reportValidity())
    }

    /**
     * Check validity for all connected fields.
     * @returns {boolean}
     */
    @api checkValidity() {
        return validate(this.fields, field => field?.checkValidity())
    }

    /**
     * Submit the form by creating or updating the record.
     * Dispatches a `change` event with `detail.value` containing the flat record.
     * @param {Event} ev Optional submit event to cancel.
     * @returns {Promise<Object>} The saved flat record.
     */
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
            console.log('describeObjectInfo', data);
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
            console.log('describePicklistValues', data);
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