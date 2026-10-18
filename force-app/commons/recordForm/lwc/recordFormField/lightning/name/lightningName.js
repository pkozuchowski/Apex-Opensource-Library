import lightningName from "./lightningName.html";

export class LightningName {
    salutation = {};
    salutationOptions = [];
    firstName = {};
    lastName = {};

    renderExt() {
        return lightningName;
    }

    connectFieldExt({ objectInfo, recordTypePicklistValues }) {
        this.salutation = objectInfo.fields.Salutation;
        this.firstName = objectInfo.fields.FirstName;
        this.lastName = objectInfo.fields.LastName;
        this.salutationOptions = this.options || [
            { label: "--None--", value: "" },
            ...recordTypePicklistValues.Salutation.values
        ];
    }

    get salutationAttributes() {
        return {
            name: this.salutation.apiName,
            label: this.salutation.label,
            value: this.salutationValue,
            variant: this.inputVariant,
            options: this.salutationOptions,
            disabled: this.disabled,
            fieldLevelHelp: this.fieldLevelHelp,
            ...this.typeAttributes.Salutation
        };
    }

    get firstNameAttributes() {
        return {
            name: this.firstName.apiName,
            label: this.firstName.label,
            value: this.firstNameValue,
            variant: this.inputVariant,
            disabled: this.disabled,
            required: this.required,
            fieldLevelHelp: this.fieldLevelHelp,
            ...this.typeAttributes.FirstName
        };
    }

    get lastNameAttributes() {
        return {
            name: this.lastName.apiName,
            label: this.lastName.label,
            value: this.lastNameValue,
            variant: this.inputVariant,
            disabled: this.disabled,
            required: this.required,
            fieldLevelHelp: this.fieldLevelHelp,
            ...this.typeAttributes.LastName
        };
    }

    get nameValue() {
        return `${this.salutationValue} ${this.firstNameValue || ""} ${this.lastNameValue || ""}`.trim();
    }

    get salutationValue() {
        return this.getField(this.salutation.apiName);
    }

    get firstNameValue() {
        return this.getField(this.firstName.apiName);
    }

    get lastNameValue() {
        return this.getField(this.lastName.apiName);
    }

    getEventValue(event) {
        const field = event.target.name;
        return { [field]: event.detail.value };
    }

    /**
     * Person Name renders as three separate inputs (no single compound element to
     * ref), so the base `reportValidity`/`checkValidity`/`setCustomValidity`
     * (which operate on a single `this.refs.input`) must be overridden here to
     * aggregate across all three.
     */
    reportValidity() {
        const salutationValid = this.refs.salutation?.reportValidity?.() ?? true;
        const firstNameValid = this.refs.firstName?.reportValidity?.() ?? true;
        const lastNameValid = this.refs.lastName?.reportValidity?.() ?? true;
        return salutationValid && firstNameValid && lastNameValid;
    }

    checkValidity() {
        const salutationValid = this.refs.salutation?.checkValidity?.() ?? true;
        const firstNameValid = this.refs.firstName?.checkValidity?.() ?? true;
        const lastNameValid = this.refs.lastName?.checkValidity?.() ?? true;
        return salutationValid && firstNameValid && lastNameValid;
    }

    setCustomValidity(message) {
        this.refs.firstName?.setCustomValidity?.(message);
        this.refs.lastName?.setCustomValidity?.(message);
    }
}
