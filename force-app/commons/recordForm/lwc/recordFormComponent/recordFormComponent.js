// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import {api, LightningElement} from "lwc";

export default class RecordFormComponent extends LightningElement {
    static renderMode = "light";

    @api field;
    @api record;
    @api fieldLevelHelp;
    @api readOnly;
    @api disabled;
    @api required;
    @api variant;
    @api designSystem;
    @api formAttributes = {};
    controllerName;
    updateable;
    disconnectFn;

    connectedCallback() {
        this.dispatchEvent(
            new CustomEvent("fieldconnected", {
                detail  : {},
                bubbles : true,
                composed: true
            })
        );
    }

    disconnectedCallback() {
        if (this.disconnectFn) {
            this.disconnectFn(this.field);
        }
    }

    /**
     * Initialize field metadata and retain the callback used when this field disconnects.
     * @param {Object} context Field and object metadata supplied by Record Form.
     * @returns {void}
     */
    @api
    connectField({fieldInfo, objectInfo, disconnectFn}) {
        try {
            this.label = this.label ?? fieldInfo?.label;
            this.fieldLevelHelp = fieldInfo?.inlineHelpText; // eslint-disable-line @lwc/lwc/no-api-reassignments
            this.controllerName = fieldInfo?.controllerName;
            this.required = this.required ?? fieldInfo?.required; // eslint-disable-line @lwc/lwc/no-api-reassignments
            this.disconnectFn = disconnectFn;
            this.updateable =
                fieldInfo?.updateable ||
                (fieldInfo?.compound &&
                    Object.values(objectInfo?.fields ?? {}).some(
                        (field) => field.compoundFieldName === fieldInfo?.apiName && field.updateable
                    ));
        } catch (e) {
            console.error("connectField Cmp", fieldInfo, e.message, e.stack);
        }
    }

    /**
     * Called when Record Form enters edit mode, including when a field connects in edit mode.
     * Override to perform edit-mode setup.
     * @returns {void}
     */
    @api
    onEnterEditMode() {}

    /**
     * Called when Record Form returns to view mode.
     * Override to perform view-mode cleanup.
     * @returns {void}
     */
    @api
    onEnterViewMode() {}

    /**
     * Called and awaited after validation succeeds but before Record Form saves.
     * Reject to prevent the save.
     * @returns {Promise<void>|void}
     */
    @api
    onBeforeSubmit() {}

    /**
     * Called and awaited after a successful save, before Record Form returns to view mode.
     * Override to perform post-save work; overrides receive `{data}` with the saved flat record.
     * @returns {Promise<void>|void}
     */
    @api
    onAfterSubmit() {}

    /**
     * Report the validity of the component's input.
     * @returns {boolean} Whether the input is valid; true if no input is available.
     */
    @api
    reportValidity() {
        return this.refs?.input?.reportValidity?.() ?? true;
    }

    /**
     * Set a custom validation message on the component's input.
     * @param {string} message Message to display when the input is invalid.
     * @returns {void}
     */
    @api
    setCustomValidity(message) {
        return this.refs?.input?.setCustomValidity?.(message);
    }

    /**
     * Check the validity of the component's input.
     * @returns {boolean} Whether the input is valid; true if no input is available.
     */
    @api
    checkValidity() {
        return this.refs?.input?.checkValidity?.() ?? true;
    }

    handleFieldChange(event) {
        try {
            event.preventDefault();
            event.stopPropagation();
            this.dispatchEvent(
                new CustomEvent("change", {
                    detail : {
                        value: this.getEventValue(event)
                    },
                    bubbles: true
                })
            );
        } catch (e) {
            console.error("RecordFormField.handleChange", e.message);
        }
    }

    getEventValue(event) {
        return {[this.field]: event.detail.value};
    }

    get isReadOnly() {
        return this.readOnly || !this.updateable || !this.formAttributes.editMode;
    }

    get showInlineEditTrigger() {
        return this.formAttributes.inlineEdit && !this.formAttributes.editMode && this.updateable && !this.readOnly;
    }

    get fieldValue() {
        return this.getField(this.field);
    }

    get controllerValue() {
        return this.getField(this.controllerName);
    }

    getField(field) {
        return this.record?.[field];
    }

    get inputVariant() {
        return this.variant || (this.formAttributes.density === "comfy" ? "label-stacked" : "label-inline");
    }

    get formElementClasses() {
        const density = this.formAttributes.density;
        return {
            "slds-form-element_stacked"   : density === "comfy",
            "slds-form-element_horizontal": density === "compact"
        };
    }
}
