// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import {api, LightningElement, track, wire} from "lwc";
import {getObjectInfo, getPicklistValuesByRecordType} from "lightning/uiObjectInfoApi";
import {createRecord, getRecord, notifyRecordUpdateAvailable, updateRecord} from "lightning/uiRecordApi";
import {
    getCompoundFields,
    getErrorMessage,
    getFieldsToRetrieve,
    getFlatRecord,
    getUpdatableFields,
    overrideFieldLabels,
    validate
} from "./recordFormUtils";

import {gql, graphql} from "lightning/graphql";
// Use bellow for offline capabilities
// import {gql, graphql} from 'lightning/uiGraphQLApi';
import LightningConfirm from "lightning/confirm";
import Toast from "lightning/toast";

// SObjectType filter is not supported
const RECORD_TYPE_QUERY = gql`
    query getRecordType($developerName: String) {
        uiapi {
            query {
                RecordType(where: { DeveloperName: { eq: $developerName } }) {
                    edges {
                        node {
                            Id
                            SobjectType {
                                value
                            }
                        }
                    }
                }
            }
        }
    }
`;

/**
 * Lightning Web Component form a wrapper that handles record wiring, field setup,
 * validation, and create/update submission for a given SObject and record type.
 */
export default class RecordForm extends LightningElement {
    /**Object API Name*/
    @api recordId;
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
    _recordTypeIdInitialized = false;
    _optionalFields = [];
    computedOptionalFields = [];
    isSubmitting = false;
    _recordTypeIdFromRecord;
    _recordTypeIdFromName;
    _resolvedRecordTypeName;

    /**Hides the Cancel/Save footer, which is shown by default.*/
    @api hideFooter = false;

    /**Skips the "discard unsaved changes?" confirmation dialog on Cancel.*/
    @api disableConfirmDiscard = false;

    @track
    formAttributes = {
        density        : "comfy",
        designSystem   : "lightning",
        isPersonAccount: false,
        inlineEdit     : true,
        editMode       : false
    };

    /**
     * API Name of the object to display.
     * @type {string}
     */
    @api
    get objectApiName() {
        return this._objectApiName;
    }

    set objectApiName(value) {
        this._objectApiName = value;
        this.recalculateOptionalFields();
    }

    /**
     * Form density variant.
     * Accepted values: comfy, compact.
     * @type {string}
     */
    @api
    get density() {
        return this.formAttributes.density;
    }

    set density(value) {
        this.formAttributes.density = value;
    }

    /**
     * Whether the record is a Person Account. Controls whether the `Name` field renders
     * as a compound Person Name (Salutation/FirstName/LastName) field.
     * @type {boolean}
     */
    @api
    get isPersonAccount() {
        return this.formAttributes.isPersonAccount;
    }

    set isPersonAccount(value) {
        this.formAttributes.isPersonAccount = value;
    }

    /**
     * When true (the default), editable fields show a pencil icon while the form is
     * in view mode; clicking it switches the whole form into edit mode.
     * @type {boolean}
     */
    @api
    get inlineEdit() {
        return this.formAttributes.inlineEdit;
    }

    set inlineEdit(value) {
        this.formAttributes.inlineEdit = value;
    }

    /**
     * Current edit mode of the form, independent of `inlineEdit`. Defaults to false
     * (view mode); set to true (e.g. if you don't want `inlineEdit`'s pencil icons)
     * to start the form already editable. Can be switched programmatically from
     * outside the form, by clicking a pencil icon (when `inlineEdit` is on), or via
     * the Cancel/Save footer.
     * @type {boolean}
     */
    @api
    get editMode() {
        return this.formAttributes.editMode;
    }

    set editMode(value) {
        this.setEditMode(value);
    }

    setEditMode(value) {
        const nextValue = Boolean(value);
        const previousValue = this.formAttributes.editMode;
        if (nextValue && !previousValue) {
            this._editModeSnapshot = {...this._record};
        }
        this.formAttributes.editMode = nextValue;
        if (previousValue !== nextValue) {
            const callback = nextValue ? "onEnterEditMode" : "onEnterViewMode";
            this.getConnectedFields().forEach((field) => field[callback]?.());
            if (this.isConnected) {
                this.dispatchEvent(
                    new CustomEvent("editmodechange", {
                        detail  : {editMode: nextValue},
                        bubbles : true,
                        composed: true
                    })
                );
            }
        }
    }

    /**
     * Extra fields to retrieve from the record in addition to the fields rendered by
     * child field components. Accepts short field names (qualified with `objectApiName`)
     * or fully qualified names, e.g. `["Industry", "Account.AnnualRevenue"]`.
     * @type {Array<string>}
     */
    @api
    get optionalFields() {
        return this._optionalFields;
    }

    set optionalFields(value) {
        this._optionalFields = (typeof value === "string" ? value.split(",") : (value ?? []))
            .map((field) => field.trim())
            .filter(Boolean);
        this.recalculateOptionalFields();
    }

    /**
     * Plain record object keyed by the field API name.
     * @type {Object}
     */
    @api
    get record() {
        return this._record;
    }

    set record(value) {
        this.setRecord(value);
    }

    setRecord(value) {
        this._record = value ?? {};
        if (!this._recordTypeIdInitialized) {
            this.resolveRecordTypeId();
            this._recordTypeIdInitialized = Boolean(this.recordTypeId);
        }
        if (this.recordTypeId && this._record.RecordTypeId !== this.recordTypeId) {
            this._record = {...this._record, RecordTypeId: this.recordTypeId};
        }
        this.getConnectedFields().forEach((field) => (field.record = this._record));
    }

    getConnectedFields() {
        this.fields = this.fields.filter((field) => field.isConnected !== false);
        return this.fields;
    }

    handleFieldChange(ev) {
        const changedFields = ev.detail?.value;
        if (!changedFields || typeof changedFields !== "object" || Array.isArray(changedFields)) {
            return;
        }

        ev.stopPropagation();
        this.dispatchRecordChange({...this._record, ...changedFields});
    }

    dispatchRecordChange(value) {
        this.setRecord(value);
        this.dispatchEvent(
            new CustomEvent("change", {
                detail  : {value: {...this._record}},
                bubbles : true,
                composed: true
            })
        );
    }

    recalculateOptionalFields() {
        const recordTypeField = this.objectApiName ? [`${this.objectApiName}.RecordTypeId`] : [];
        const extraFields = this._optionalFields.map((field) => {
            return field.includes(".") ? field : `${this.objectApiName}.${field}`;
        });
        const derivedFields =
            this.objectInfo
                ? this.getConnectedFields().flatMap(({field}) => {
                    const fieldInfo = this.objectInfo.fields[field];
                    return fieldInfo
                        ? getFieldsToRetrieve(this.objectInfo, fieldInfo, field, this.isPersonAccount)
                        : [];
                })
                : [];

        const next = [...new Set([...recordTypeField, ...extraFields, ...derivedFields])];
        const current = this.computedOptionalFields;

        // Avoid reassigning (and so refetching the wire) when the field set is unchanged.
        if (next.length !== current.length || next.some((field, i) => field !== current[i])) {
            this.computedOptionalFields = next;
        }
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
     * Whether object metadata and picklist values are ready to render the form.
     * @type {boolean}
     */
    get isLoaded() {
        return this.objectInfo && this.picklistValues;
    }

    /**
     * Report validity for a single field component.
     * @param {string} field Field API name.
     * @returns {boolean|undefined} - true if valid, false if invalid, undefined if not connected.
     */
    @api
    reportValidityForField(field) {
        return this.getConnectedFields()
            .find((cmp) => cmp.field === field)
            ?.reportValidity();
    }

    /**
     * Set a custom validation message for a single field component.
     * @param {string} field Field API name.
     * @param {string} message Custom message to display.
     * @returns {void}
     */
    @api
    setCustomValidityForField(field, message) {
        this.getConnectedFields()
            .find((cmp) => cmp.field === field)
            ?.setCustomValidity(message);
    }

    /**
     * Check validity for a single field component.
     * @param {string} field Field API name.
     * @returns {boolean|undefined} - true if valid, false if invalid, undefined if not connected.
     */
    @api
    checkValidityForField(field) {
        return this.getConnectedFields()
            .find((cmp) => cmp.field === field)
            ?.checkValidity();
    }

    /**
     * Report validity for all connected fields.
     * @returns {boolean}
     */
    @api reportValidity() {
        return validate(this.getConnectedFields(), (field) => field?.reportValidity());
    }

    /**
     * Check validity for all connected fields.
     * @returns {boolean}
     */
    @api checkValidity() {
        return validate(this.getConnectedFields(), (field) => field?.checkValidity());
    }

    /**
     * Whether the record has changed since edit mode was last entered.
     * Returns false if edit mode was never entered (nothing to compare against).
     * @returns {boolean}
     */
    @api isDirty() {
        if (!this._editModeSnapshot) {
            return false;
        }
        const keys = new Set([...Object.keys(this._editModeSnapshot), ...Object.keys(this._record)]);
        for (const key of keys) {
            if (this._editModeSnapshot[key] !== this._record[key]) {
                return true;
            }
        }
        return false;
    }

    async handleFooterSave(ev) {
        ev.preventDefault();
        ev.stopPropagation();
        await this.submit(ev);
    }

    /**
     * Submit the form by creating or updating the record.
     * Dispatches a `change` event with `detail.value` containing the full flat record.
     * @param {Event} ev Optional submit event to cancel.
     * @returns {Promise<Object>} The saved flat record.
     */
    @api async submit(ev) {
        ev?.preventDefault();
        ev?.stopPropagation();

        try {
            if (this.isSubmitting || !this.reportValidity().valid) {
                return undefined;
            }

            this.isSubmitting = true;
            this.spinner = true;
            await this.runBeforeSubmit();
            const isCreate = !this.record?.Id;
            const fieldsToUpdate = getUpdatableFields(
                this.record,
                this.objectInfo,
                isCreate,
                this.isPersonAccount,
                this.recordTypeId
            );

            const recordInput = {
                fields: fieldsToUpdate,
                ...(isCreate ? {apiName: this.objectApiName} : {})
            };

            const action = isCreate ? createRecord : updateRecord;
            const result = await action(recordInput);
            const flatRecord = getFlatRecord(result);

            this.dispatchRecordChange(flatRecord);
            await notifyRecordUpdateAvailable([{recordId: result.id}]);
            try {
                await this.runAfterSubmit({data: flatRecord});
            } finally {
                this.setEditMode(false);
                this._editModeSnapshot = undefined;
            }
            return flatRecord;
        } catch (err) {
            console.error(err?.message ?? err);
            Toast.show(
                {
                    label  : "Save failed",
                    message: getErrorMessage(err),
                    variant: "error"
                },
                this
            );
            throw err;
        } finally {
            this.spinner = false;
            this.isSubmitting = false;
        }
    }

    async runBeforeSubmit() {
        const fields = this.getConnectedFields().filter((field) => typeof field.onBeforeSubmit === "function");
        await Promise.all(fields.map((field) => field.onBeforeSubmit()));
    }

    async runAfterSubmit({data}) {
        const fields = this.getConnectedFields().filter((field) => typeof field.onAfterSubmit === "function");
        await Promise.all(fields.map((field) => field.onAfterSubmit({data})));
    }

    @wire(getObjectInfo, {objectApiName: "$objectApiName"})
    describeObjectInfo({error, data}) {
        if (data) {
            this.objectInfo = JSON.parse(JSON.stringify(data));
            this.resolveRecordTypeId();
            this.setRecord(this.record);
            this.recalculateOptionalFields();
            overrideFieldLabels(this.labelOverrides, this.objectInfo);
        } else if (error) {
            console.error("Error fetching object info", error.message);
        }
    }

    @wire(graphql, {
        query    : RECORD_TYPE_QUERY,
        variables: "$recordTypeVariables"
    })
    fetchRecordType({data, errors}) {
        if (data) {
            const recordType = data.uiapi.query.RecordType.edges.find(
                (rt) => rt.node.SobjectType.value === this.objectApiName
            );
            this._resolvedRecordTypeName = this.recordTypeName;
            this._recordTypeIdFromName = recordType?.node?.Id ?? this.objectInfo?.defaultRecordTypeId;
            const previousRecordTypeId = this.record?.RecordTypeId;
            this.resolveRecordTypeId();

            if (this.recordTypeId && this.record && previousRecordTypeId !== this.recordTypeId) {
                this.dispatchRecordChange({...this.record, RecordTypeId: this.recordTypeId});
            }
        } else if (errors) {
            console.error(`Error fetching record type ${this.objectApiName}.${this.recordTypeName}`, errors);
        }
    }

    get recordTypeVariables() {
        return this.recordTypeName ? {developerName: this.recordTypeName} : undefined;
    }

    @wire(getPicklistValuesByRecordType, {
        objectApiName: "$objectApiName",
        recordTypeId : "$recordTypeId"
    })
    describePicklistValues({error, data}) {
        if (data) {
            this.picklistValues = JSON.parse(JSON.stringify(data.picklistFieldValues));
            this.spinner = false;
        } else if (error) {
            console.error("Error fetching picklist values", error.message);
        }
    }

    /**
     * Resolves the record type in priority order: named type, current record type,
     * then the object's default. A named type remains unresolved until GraphQL returns.
     */
    resolveRecordTypeId() {
        if (this.recordTypeName) {
            this.recordTypeId =
                this._resolvedRecordTypeName === this.recordTypeName ? this._recordTypeIdFromName : undefined;
        } else if (this.recordId) {
            this.recordTypeId = this._recordTypeIdFromRecord || this.record?.RecordTypeId;
        } else {
            this.recordTypeId = this.record?.RecordTypeId ?? this.objectInfo?.defaultRecordTypeId;
        }
    }

    @wire(getRecord, {recordId: "$recordId", fields: [], optionalFields: "$computedOptionalFields"})
    fetchRecord({error, data}) {
        if (data) {
            const serverRecord = Object.assign(getFlatRecord(data), this.record);
            const snapshot = this._editModeSnapshot;

            // Keep unsaved edits: a refetch (e.g. triggered by newly connected fields)
            // must not overwrite values the user changed since entering edit mode.
            if (snapshot) {
                for (const key of Object.keys(this._record)) {
                    if (this._record[key] !== snapshot[key]) {
                        serverRecord[key] = this._record[key];
                    }
                }
            }

            this._recordTypeIdFromRecord = data.recordTypeId;
            this.resolveRecordTypeId();
            if (this.recordTypeId) {
                serverRecord.RecordTypeId = this.recordTypeId;
            } else if (this.recordTypeName) {
                delete serverRecord.RecordTypeId;
            }

            this.dispatchRecordChange(serverRecord);
        } else if (error) {
            console.error("Error fetching record", error?.message, error);
        }
    }

    onFieldConnected(ev) {
        try {
            ev.preventDefault();
            ev.stopPropagation();

            if (ev.target.connectField) {
                this.getConnectedFields();
                if (!this.fields.includes(ev.target)) {
                    this.fields.push(ev.target);
                }
                const fieldName = ev.target.field;
                const fieldInfo = this.objectInfo.fields[fieldName];

                this.recalculateOptionalFields();

                ev.target.record = this._record;
                ev.target.formAttributes = this.formAttributes;
                ev.target.connectField({
                    fieldInfo,
                    objectInfo              : this.objectInfo,
                    recordTypePicklistValues: this.picklistValues,
                    formAttributes          : this.formAttributes,
                    disconnectFn            : this.onFieldDisconnected.bind(this)
                });
                if (this.formAttributes.editMode) {
                    ev.target.onEnterEditMode?.();
                }
            }
        } catch (e) {
            console.error("recordForm.onFieldConnected", ev.target.field, e.message, e.stack);
        }
    }

    onFieldDisconnected(fieldApiName) {
        if (typeof fieldApiName !== "string" || !fieldApiName) {
            return;
        }

        // If there are still connected fields for this API name, do not remove it from the record.
        const connectedFieldNames = new Set(this.getConnectedFields().map((field) => field.field));
        if (connectedFieldNames.has(fieldApiName)) {
            return;
        }

        const updatedRecord = {...this._record};
        delete updatedRecord[fieldApiName];

        const isCompoundField = this.objectInfo?.fields?.[fieldApiName]?.compound;
        if (isCompoundField) {
            for (const field of getCompoundFields(this.objectInfo, fieldApiName, connectedFieldNames)) {
                delete updatedRecord[field];
            }
        }

        this.dispatchRecordChange(updatedRecord);
        this.dispatchEvent(new CustomEvent("fielddisconnected", {detail: {field: fieldApiName}}));
    }

    /**
     * Handles keydown events on the form.
     * Escape key cancels edit mode.
     * @param {KeyboardEvent} ev - The keydown event.
     */
    async handleKeyDown(ev) {
        if (!this.formAttributes.editMode) {
            return;
        }
        if (ev.key === "Escape") {
            ev.preventDefault();
            await this.cancelEdit();
        }
    }

    onFieldEdit(ev) {
        ev.preventDefault();
        ev.stopPropagation();
        this.setEditMode(true);
    }

    async handleFooterCancel(ev) {
        ev.preventDefault();
        ev.stopPropagation();
        await this.cancelEdit();
    }

    /**
     * Reverts fields to their edit-mode-entry values and exits edit mode. If dirty
     * and `disableConfirmDiscard` is not set, asks for confirmation first.
     * @returns {Promise<void>}
     */
    async cancelEdit() {
        if (!this.disableConfirmDiscard && this.isDirty()) {
            const confirmed = await LightningConfirm.open({
                label  : "Discard Changes?",
                message: "You have unsaved changes. Are you sure you want to discard them?",
                theme  : "warning"
            });
            if (!confirmed) {
                return;
            }
        }

        if (this._editModeSnapshot) {
            this.dispatchRecordChange({...this._editModeSnapshot});
        }
        this.setEditMode(false);
        this._editModeSnapshot = undefined;
    }
}
