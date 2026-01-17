import {api, LightningElement} from 'lwc';
import {RecordFormComponent} from "c/recordFormComponent";
import lightningCheckboxGroup from './lightningCheckboxGroup.html';
import lightningDualListbox from './lightningDualListbox.html';
import lightningPicklistOutput from './lightningPicklistOutput.html';
import lightningRadioGroup from './lightningRadioGroup.html';
import lightningSelect from './lightningSelect.html';

const TEMPLATES = {
    'select'        : lightningSelect,
    'button'        : lightningRadioGroup,
    'radio-group'   : lightningRadioGroup,
    'listbox'       : lightningDualListbox,
    'checkbox-group': lightningCheckboxGroup,
};
const OPT_NONE = {label: '--None--', value: ''};

export default class RecordFormPicklist extends RecordFormComponent(LightningElement) {
    @api messageWhenValueMissing;
    @api options;
    /**
     * Array of option values to display from the options set: ex. ['A','B']
     * Useful when options are sourced from the field setup
     * */
    @api optionsFilter;
    @api required;
    @api size = 3;
    @api validity;
    @api variant = 'standard';
    /**
     * Single: select, radio-group, button
     * Multiple: listbox, checkbox-group
     */
    @api type;
    @api sourceLabel = "Available";
    @api selectedLabel = "Chosen";
    multiple;
    recordTypePicklistValues;

    connectField({fieldInfo, recordTypePicklistValues}) {
        try {
            super.connectField(arguments[0]);
            this.recordTypePicklistValues = recordTypePicklistValues[this.field];
            this.multiple = fieldInfo.dataType === 'MultiPicklist';
            this.type = this.type ?? (fieldInfo.dataType === 'MultiPicklist' ? 'listbox' : 'select');
        } catch (e) {
            console.log(e.message);
        }
    }

    get value() {
        if (this.isReadOnly || !this.multiple) {
            return this.fieldValue;
        }
        return this.fieldValue?.split(';') ?? [];
    }

    getEventValue(event) {
        if (this.multiple) {
            return {[this.field]: event.detail.value.join(';')};
        }
        return {[this.field]: event.detail.value};
    }

    get picklistOptions() {
        let options;
        let rtValues = this.recordTypePicklistValues.values;

        if (this.options) {
            options = [...this.options];

        } else if (this.controllerName && rtValues) {
            let controller = this.recordTypePicklistValues.controllerValues[this.controllerValue];
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
    }

    render() {
        return (this.isReadOnly ? lightningPicklistOutput : TEMPLATES[this.type]) || lightningSelect;
    }
}