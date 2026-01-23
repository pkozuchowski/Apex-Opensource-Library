import lightningName from "./lightningName.html";

export class LightningName {
    salutation = {};
    salutationOptions = [];
    firstName = {};
    lastName = {};

    renderExt() {
        return lightningName;
    }

    connectFieldExt({objectInfo, recordTypePicklistValues}) {
        this.salutation = objectInfo.fields.Salutation;
        this.firstName = objectInfo.fields.FirstName;
        this.lastName = objectInfo.fields.LastName;
        this.salutationOptions = this.options || [
            {label: "--None--", value: ""},
            ...recordTypePicklistValues.Salutation.values
        ];
    }

    get salutationAttributes() {
        return {
            name   : this.salutation.apiName,
            label  : this.salutation.label,
            value  : this.salutationValue,
            variant: this.inputVariant,
            options: this.salutationOptions,
            ...this.typeAttributes.Salutation,
        };
    }

    get firstNameAttributes() {
        return {
            name   : this.firstName.apiName,
            label  : this.firstName.label,
            value  : this.firstNameValue,
            variant: this.inputVariant,
            ...this.typeAttributes.FirstName,
        };
    }

    get lastNameAttributes() {
        return {
            name   : this.lastName.apiName,
            label  : this.lastName.label,
            value  : this.lastNameValue,
            variant: this.inputVariant,
            ...this.typeAttributes.LastName,
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
        return {[field]: event.detail.value};
    }
}