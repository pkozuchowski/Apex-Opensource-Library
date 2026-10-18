import { LightningInputExt } from "../input/lightningInput";
import lightningInput from "../input/lightningInput.html";
import lightningSelect from "./lightningSelect.html";
import lightningDuelingListbox from "./lightningDuelingListbox.html";
import lightningRadioGroup from "./lightningRadioGroup.html";
import lightningCheckboxGroup from "./lightningCheckboxGroup.html";

const OPT_NONE = { label: "--None--", value: "" };

export class LightningPicklist extends LightningInputExt {
    recordTypePicklistValues;
    controlledFields;

    connectFieldExt(data) {
        super.connectFieldExt(data);
        const { objectInfo, recordTypePicklistValues } = data;
        // Identify controlled fields
        this.controlledFields = {};
        this.recordTypePicklistValues = recordTypePicklistValues[this.field];

        /*Clears dependent fields */
        Object.values(objectInfo.fields).forEach((field) => {
            if (field.controllingFields.indexOf(this.field) > -1) {
                this.controlledFields[field.apiName] = "";
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
            value: this.isReadOnly ? this.picklistLabel : this.fieldValue || "",
            options: this.picklistOptions,
            size: this.size
        };
    }

    /**
     * Label for the current value, for read-only display - looked up from the full,
     * unfiltered record type picklist values (not `picklistOptions`, which may be
     * narrowed by `options`/`optionsFilter` and so might not contain the current value).
     * Falls back to the raw value if no matching option is found.
     */
    get picklistLabel() {
        const option = this.recordTypePicklistValues?.values?.find((opt) => opt.value === this.fieldValue);
        return option?.label ?? this.fieldValue ?? "";
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
                options = options.filter((option) => this.optionsFilter.includes(option.value));
            }

            const hasNoneOption = !this.multiple && this.type !== "radio-group";

            if (hasNoneOption) {
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
    connectFieldExt({ fieldInfo, objectInfo, recordTypePicklistValues }) {
        super.connectFieldExt({ fieldInfo, objectInfo, recordTypePicklistValues });
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
            multiple: true,
            options: this.picklistOptions,
            value: this.isReadOnly ? this.picklistLabel : this.fieldValue?.split(";") || [],
            sourceLabel: "Available",
            selectedLabel: "Selected"
        };
    }

    /**
     * Comma-separated labels for the currently selected values, for read-only display.
     * @override
     */
    get picklistLabel() {
        const optionsByValue = new Map((this.recordTypePicklistValues?.values ?? []).map((opt) => [opt.value, opt.label]));
        const values = this.fieldValue ? this.fieldValue.split(";") : [];
        return values.map((value) => optionsByValue.get(value) ?? value).join(", ");
    }

    getEventValue(event) {
        return {
            [this.field]: event.detail.value.join(";")
        };
    }
}
