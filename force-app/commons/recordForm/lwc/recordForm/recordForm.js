// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import {api, LightningElement, track, wire} from 'lwc';
import {getObjectInfo, getPicklistValuesByRecordType} from "lightning/uiObjectInfoApi";
import {createRecord, getRecord, notifyRecordUpdateAvailable, updateRecord} from 'lightning/uiRecordApi';
import {getFieldsToRetrieve, getFlatRecord, getUpdatableFields, overrideFieldLabels, validate} from "./recordFormUtils";


import {gql, graphql} from 'lightning/graphql';
// Use bellow for offline capabilities
// import {gql, graphql} from 'lightning/uiGraphQLApi';

const MASTER_RECORD_TYPE = "012000000000000AAA";
// SObjectType filter is not supported
const RECORD_TYPE_QUERY = gql`
    query getRecordType($developerName: String) {
        uiapi {
            query {
                RecordType(
                    where: {
                        DeveloperName: {eq: $developerName}
                    }
                ) {
                    edges {
                        node {
                            Id,
                            DeveloperName {value}
                            SobjectType {value}
                        }
                    }
                }
            }
        }
    }
`;

/**
 * Lightning Web Component form wrapper that handles record wiring, field setup,
 * validation, and create/update submission for a given SObject and record type.
 */
export default class RecordForm extends LightningElement {
    /**Object API Name*/
    @api recordId;
    @api objectApiName;
    @api formClass;

    /**Record Type Developer Name*/
    @api recordTypeName;

    /** Map<Field, Label> of label overrides*/
    @api labelOverrides;
    /**Design system variant used by child fields.*/
    @api designSystem = "lightning";
    fields = [];
    spinner = true;
    objectInfo;
    picklistValues;
    recordTypeId;
    _record = {};
    _optionalFields = [];
    _derivedFields = [];
    computedOptionalFields = [];

    /**Hides the Cancel/Save footer, which is shown by default.*/
    @api hideFooter = false;

    @track
    formAttributes = {
        density        : "comfy",
        designSystem   : "lightning",
        isPersonAccount: false,
        inlineEdit     : true,
        editMode       : false
    }

    /**
     * Form density variant.
     * Accepted values: comfy, compact.
     * @type {string}
     */
    @api
    get density() {return this.formAttributes.density;}

    set density(value) {this.formAttributes.density = value;}

    /**
     * Whether the record is a Person Account. Controls whether the `Name` field renders
     * as a compound Person Name (Salutation/FirstName/LastName) field.
     * @type {boolean}
     */
    @api
    get isPersonAccount() {return this.formAttributes.isPersonAccount;}

    set isPersonAccount(value) {this.formAttributes.isPersonAccount = value;}

    /**
     * When true (the default), editable fields show a pencil icon while the form is
     * in view mode; clicking it switches the whole form into edit mode.
     * @type {boolean}
     */
    @api
    get inlineEdit() {return this.formAttributes.inlineEdit;}

    set inlineEdit(value) {this.formAttributes.inlineEdit = value;}

    /**
     * Current edit mode of the form, independent of `inlineEdit`. Defaults to false
     * (view mode); set to true (e.g. if you don't want `inlineEdit`'s pencil icons)
     * to start the form already editable. Can be switched programmatically from
     * outside the form, by clicking a pencil icon (when `inlineEdit` is on), or via
     * the Cancel/Save footer.
     * @type {boolean}
     */
    @api
    get editMode() {return this.formAttributes.editMode;}

    set editMode(value) {
        if (value && !this.formAttributes.editMode) {
            this._editModeSnapshot = {...this._record};
        }
        this.formAttributes.editMode = value;
    }

    /**
     * Extra fields to retrieve from the record in addition to the fields rendered by
     * child field components. Accepts short field names (qualified with `objectApiName`)
     * or fully qualified names, e.g. `["Industry", "Account.AnnualRevenue"]`.
     * @type {Array<string>}
     */
    @api
    get optionalFields() {return this._optionalFields;}

    set optionalFields(value) {
        this._optionalFields = typeof value === 'string' ?
            value.split(',') : value ?? [];
        this.recalculateOptionalFields();
    }

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

    recalculateOptionalFields() {
        const extraFields = this._optionalFields.map(
            field => field.includes('.') ? field : `${this.objectApiName}.${field}`
        );
        this.computedOptionalFields = [...new Set([...extraFields, ...this._derivedFields])];
    }

    get formClasses() {
        return `slds-form ${this.formClass}`;
    }

    /**
     * Whether the Cancel/Save footer should be rendered - shown whenever the form is
     * in edit mode.
     * @type {boolean}
     */
    get showFormFooter() {
        return !this.hideFooter && this.formAttributes.editMode;
    }

    /**
     * Form loads successfully when all required components are connected and picklist values are available.
     * @type {boolean}
     */
    get isLoaded() {
        return this.objectInfo
            && this.picklistValues
            && this.record;
    }

    /**
     * Report validity for a single field component.
     * @param {string} field Field API name.
     * @returns {boolean|undefined} - true if valid, false if invalid, undefined if not connected.
     */
    @api
    reportValidityForField(field) {
        this.fields.filter(cmp => cmp.field === field)
            .forEach(cmp => cmp.reportValidity());
    }

    /**
     * Set a custom validation message for a single field component.
     * @param {string} field Field API name.
     * @param {string} message Custom message to display.
     * @returns {void}
     */
    @api
    setCustomValidityForField(field, message) {
        this.fields.filter(cmp => cmp.field === field)
            .forEach(cmp => cmp.setCustomValidity(message));
    }

    /**
     * Check validity for a single field component.
     * @param {string} field Field API name.
     * @returns {boolean|undefined} - true if valid, false if invalid, undefined if not connected.
     */
    @api
    checkValidityForField(field) {
        this.fields.filter(cmp => cmp.field === field)
            .forEach(cmp => cmp.checkValidity());
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
            this.formAttributes.editMode = false;

            return flatRecord;
        } catch (err) {
            console.error(err?.message ?? err);
            throw err;
        } finally {
            this.spinner = false;
        }
    }

    @wire(getObjectInfo, {objectApiName: '$objectApiName'})
    describeObjectInfo({error, data}) {
        if (data) {
            this.objectInfo = JSON.parse(JSON.stringify(data));
            if (!this.recordTypeName) {
                this.recordTypeId = data.defaultRecordTypeId;
            }
            overrideFieldLabels(this.labelOverrides, this.objectInfo);
        } else if (error) {
            console.error('Error fetching object info', error.message);
        }
    };

    @wire(graphql, {
        query    : RECORD_TYPE_QUERY,
        variables: '$recordTypeVariables'
    })
    fetchRecordType({data, errors}) {
        if (data) {
            const recordType = data.uiapi.query.RecordType.edges.find(
                rt => rt.node.SobjectType.value === this.objectApiName
            );
            this.recordTypeId = recordType?.node?.Id ?? MASTER_RECORD_TYPE;
        } else if (errors) {
            console.log(`Error fetching record type ${this.objectApiName}.${this.recordTypeName}`, errors);
        }
    }

    get recordTypeVariables() {
        return this.recordTypeName ?
            {developerName: this.recordTypeName}
            : undefined;
    }

    @wire(getPicklistValuesByRecordType, {
        objectApiName: "$objectApiName",
        recordTypeId : "$recordTypeId",
    })
    describePicklistValues({error, data}) {
        if (data) {
            this.picklistValues = JSON.parse(JSON.stringify(data.picklistFieldValues));
            this.spinner = false;
        } else if (error) {
            console.error('Error fetching picklist values', error.message);
        }
    };

    onFieldConnected(ev) {
        try {
            ev.preventDefault();
            ev.stopPropagation();

            if (ev.target.connectField) {
                this.fields.push(ev.target);
                const fieldName = ev.target.field;
                const fieldInfo = this.objectInfo.fields[fieldName];

                this._derivedFields = [
                    ...this._derivedFields,
                    ...getFieldsToRetrieve(this.objectInfo, fieldInfo, fieldName)
                ];
                this.recalculateOptionalFields();

                ev.target.record = this._record;
                ev.target.formAttributes = this.formAttributes;
                ev.target.connectField(
                    {
                        fieldInfo,
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

    onFieldEdit(ev) {
        ev.preventDefault();
        ev.stopPropagation();
        this.editMode = true;
    }

    handleFooterCancel(ev) {
        ev.preventDefault();
        ev.stopPropagation();
        if (this._editModeSnapshot) {
            this.dispatchEvent(new CustomEvent('change', {
                detail: {value: {...this._editModeSnapshot}}
            }));
        }
        this.formAttributes.editMode = false;
    }

    handleFooterSave(ev) {
        ev.preventDefault();
        ev.stopPropagation();
        this.submit();
    }

    @wire(getRecord, {recordId: "$recordId", fields: [], optionalFields: '$computedOptionalFields'})
    fetchRecord({error, data}) {
        if (data) {
            if (data.recordTypeId) {
                this.recordTypeId = data.recordTypeId;
            }

            this.dispatchEvent(new CustomEvent('change', {
                detail: {
                    value: Object.assign(getFlatRecord(data), this.record)
                }
            }));
        } else if (error) {
            console.error('Error fetching record', error?.message, error);
        }
    }
}