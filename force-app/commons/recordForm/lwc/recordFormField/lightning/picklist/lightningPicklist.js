import {LightningInputExt} from "../input/lightningInput";
import lightningInput from '../input/lightningInput.html';
import lightningSelect from './lightningSelect.html';
import lightningDuelingListbox from './lightningDuelingListbox.html';
import lightningRadioGroup from './lightningRadioGroup.html';
import lightningCheckboxGroup from './lightningCheckboxGroup.html';

const OPT_NONE = {label: '--None--', value: ''};

export class LightningPicklist extends LightningInputExt {
    recordTypePicklistValues;
    controlledFields;

    connectFieldExt(data) {
        super.connectFieldExt(data);
        const {objectInfo, recordTypePicklistValues} = data;
        // Identify controlled fields
        this.controlledFields = {};
        this.recordTypePicklistValues = recordTypePicklistValues[this.field];

        /*Clears dependent fields */
        Object.values(objectInfo.fields).forEach(field => {
            if (field.controllingFields.indexOf(this.field) > -1) {
                this.controlledFields[field.apiName] = '';
            }
        });
    }

    renderExt() {
        if (this.isReadOnly) {
            return lightningInput;
        } else if (this.type === "radio-group") {
            return lightningRadioGroup;
        } else {
            return lightningSelect;
        }
    }

    get attributes() {
        return {
            ...super.attributes,
            value  : this.fieldValue || '',
            options: this.picklistOptions,
            size   : this.size
        };
    }

    getEventValue(event) {
        return {
            [this.field]: event.detail.value,
            ...this.controlledFields
        };
    }

    get picklistOptions() {
        try {
            let options;
            const rtValues = this.recordTypePicklistValues?.values;

            if (this.options) {
                options = [...this.options];

            } else if (this.controllerName) {
                const controller = this.recordTypePicklistValues.controllerValues[this.controllerValue];
                options = rtValues.filter((item) => item.validFor.indexOf(controller) > -1);

            } else {
                options = [...rtValues];
            }

            if (this.optionsFilter?.length > 0 && options.length > 1) {
                options = options.filter(option => this.optionsFilter.includes(option.value));
            }

            if (!this.multiple) {
                options.unshift(OPT_NONE);
            }

            return options;
        } catch (e) {
            console.error(e.message);
            return [];
        }
    }
}


export class LightningMultiPicklistExt extends LightningPicklist {

    connectFieldExt({fieldInfo, objectInfo, recordTypePicklistValues}) {
        super.connectFieldExt({fieldInfo, objectInfo, recordTypePicklistValues});
        this.multiple = true;
    }

    renderExt() {
        if (this.isReadOnly) {
            return lightningInput;
        } else if (this.type === "checkbox-group") {
            return lightningCheckboxGroup;
        } else {
            return lightningDuelingListbox;
        }
    }

    get attributes() {
        return {
            ...super.attributes,
            multiple     : true,
            options      : this.picklistOptions,
            value        : this.isReadOnly ? this.fieldValue : (this.fieldValue?.split(';')) || [],
            sourceLabel  : "Available",
            selectedLabel: "Selected"
        };
    }

    getEventValue(event) {
        return {
            [this.field]: event.detail.value.join(';')
        };
    }
}