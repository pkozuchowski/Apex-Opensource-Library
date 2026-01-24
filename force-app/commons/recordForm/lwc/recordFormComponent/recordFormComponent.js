// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import {api, LightningElement} from "lwc";

export default class RecordFormComponent extends LightningElement {
    static renderMode = 'light';

    @api field;
    @api record;
    @api fieldLevelHelp;
    @api readOnly;
    @api disabled;
    @api required;
    @api validity;
    @api variant;
    @api designSystem;
    @api formAttributes = {};
    controllerName;
    updateable;

    connectedCallback() {
        this.dispatchEvent(new CustomEvent('fieldconnected', {
            detail : {},
            bubbles: true, composed: true
        }));
    }

    @api
    connectField({fieldInfo, objectInfo}) {
        try {
            this.label = this.label ?? fieldInfo.label;
            this.fieldLevelHelp = fieldInfo.inlineHelpText;
            this.controllerName = fieldInfo.controllerName;
            this.required = this.required ?? fieldInfo.required;
            this.updateable = (fieldInfo.updateable || (fieldInfo.compound
                && Object
                    .values(objectInfo.fields)
                    .some(field => field.compoundFieldName === fieldInfo.apiName && field.updateable)));
        } catch (e) {
            console.error('connectField Cmp', fieldInfo, e.message, e.stack);
        }
    }

    @api
    reportValidity() {
        return this.refs.input?.reportValidity?.() ?? true;
    }

    @api
    setCustomValidity(message) {
        return this.refs.input?.setCustomValidity?.(message);
    }

    @api
    checkValidity() {
        return this.refs.input?.checkValidity?.() ?? true;
    }

    handleFieldChange(event) {
        try {
            event.preventDefault();
            event.stopPropagation();
            this.dispatchEvent(new CustomEvent('change', {
                detail : {
                    value: this.getEventValue(event)
                },
                bubbles: true,
            }));
        } catch (e) {
            console.error('RecordFormField.handleChange', e.message);
        }
    }

    getEventValue(event) {
        return ({[this.field]: event.detail.value});
    }

    get isReadOnly() {
        return this.formAttributes.readOnly || this.readOnly || !this.updateable;
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
        return this.variant || (this.formAttributes.density === "comfy" ?
            "label-stacked" : "label-inline");
    }

    get formElementClasses() {
        const density = this.formAttributes.density;
        return {
            "slds-form-element_stacked"   : density === "comfy",
            "slds-form-element_horizontal": density === "compact",
        };
    }
}
