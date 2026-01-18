import lightningInput from './lightningInput.html';
import LOCALE from "@salesforce/i18n/locale";

export class LightningInputExt {

    renderExt() {
        return lightningInput;
    }

    connectFieldExt({fieldInfo}) {
        this.label = this.label ?? fieldInfo.label;
    }

    get attributes() {
        return {
            label         : this.label || this.fieldInfo.label,
            readOnly      : this.isReadOnly,
            required      : this.required,
            variant       : this.variant ?? this.formVariant,
            value         : this.fieldValue,
            disabled      : this.disabled,
            fieldLevelHelp: this.fieldLevelHelp,
            placeholder   : this.placeholder,
            validity      : this.validity,

            messageWhenBadInput    : this.messageWhenBadInput,
            messageWhenValueMissing: this.messageWhenValueMissing,
            ...this.typeAttributes
        };
    }

    get classes() {
        return {
            "slds-form-element_readonly": this.isReadOnly
        };
    }
}

export class LightningTextExt extends LightningInputExt {

    connectFieldExt({fieldInfo}) {
        super.connectFieldExt(arguments[0]);
        this.maxLength = this.maxLength ?? fieldInfo.length ?? 255;
    }

    get attributes() {
        return {
            ...super.attributes,
            autocomplete              : this.autocomplete ?? 'off',
            maxLength                 : this.maxLength,
            minLength                 : this.minLength,
            type                      : 'text',
            pattern                   : this.pattern,
            messageWhenPatternMismatch: this.messageWhenPatternMismatch,
            messageWhenTypeMismatch   : this.messageWhenTypeMismatch,
        }
    }
}

export class LightningCheckboxExt extends LightningInputExt {
    get attributes() {
        return {
            ...super.attributes,
            type                 : this.isReadOnly ? 'checkbox' : (this.type ?? 'checkbox'),
            checked              : this.fieldValue,
            messageToggleActive  : this.messageToggleActive,
            messageToggleInactive: this.messageToggleInactive,
            messageWhenTooLong   : this.messageWhenTooLong,
            messageWhenTooShort  : this.messageWhenTooShort,
        }
    }

    getEventValue(event) {
        return {[this.field]: event.detail.checked}
    }
}

export class LightningNumberExt extends LightningInputExt {

    connectFieldExt({fieldInfo}) {
        const DEFAULT_FORMATTER = {
            Currency: 'currency',
            Percent : 'percent-fixed'
        };
        this.formatter = this.formatter || DEFAULT_FORMATTER[fieldInfo.dataType] || 'decimal';
        this.step = this.step || (1 / Math.pow(10, fieldInfo.scale)).toString();
    }

    get attributes() {
        return {
            ...super.attributes,
            type                     : this.isReadOnly ? 'number' : this.type ?? 'number',
            formatter                : this.formatter,
            messageWhenRangeOverflow : this.messageWhenRangeOverflow,
            messageWhenRangeUnderflow: this.messageWhenRangeUnderflow,
            messageWhenStepMismatch  : this.messageWhenStepMismatch,
            step                     : this.step
        };
    }
}

const dateOptions = {year: 'numeric', month: '2-digit', day: '2-digit'};
const timeOptions = {hour: '2-digit', minute: '2-digit'};
const dateTimeOptions = {...dateOptions, ...timeOptions};

function dateString(value, opts) {
    return value ? new Date(value).toLocaleString(LOCALE, opts) : '';
}

export class LightningDateExt extends LightningInputExt {
    get attributes() {
        return {
            ...super.attributes,
            type     : this.isReadOnly ? 'text' : 'date',
            dateStyle: this.dateStyle ?? 'short',
            value    : this.isReadOnly ?
                dateString(this.fieldValue, dateOptions)
                : this.fieldValue
        };
    }
}

export class LightningDateTimeExt extends LightningInputExt {
    get attributes() {
        return {
            ...super.attributes,
            type     : this.isReadOnly ? 'text' : 'datetime',
            dateStyle: this.dateStyle ?? 'short',
            timezone : this.timezone,
            value    : this.isReadOnly ?
                dateString(this.fieldValue, dateTimeOptions)
                : this.fieldValue
        };
    }
}

export class LightningTimeExt extends LightningInputExt {
    get attributes() {
        return {
            ...super.attributes,
            type                : this.isReadOnly ? 'text' : 'time',
            timeAccessKey       : this.timeAccessKey,
            timeAriaControls    : this.timeAriaControls,
            timeAriaDescribedBy : this.timeAriaDescribedBy,
            timeAriaDetails     : this.timeAriaDetails,
            timeAriaErrorMessage: this.timeAriaErrorMessage,
            timeAriaLabel       : this.timeAriaLabel,
            timeAriaLabelledBy  : this.timeAriaLabelledBy,
            timeStepMinutes     : this.timeStepMinutes,
            timeStyle           : this.timeStyle,
            value               : this.isReadOnly ?
                (this.fieldValue ? dateString('2026-01-01T' + this.fieldValue, timeOptions) : '')
                : this.fieldValue
        };
    }
}

export class LightningEmailExt extends LightningTextExt {
    get attributes() {
        return {
            ...super.attributes,
            type: 'email'
        };
    }
}

export class LightningPhoneExt extends LightningTextExt {
    get attributes() {
        return {
            ...super.attributes,
            type: 'phone'
        };
    }
}

export class LightningUrlExt extends LightningTextExt {
    get attributes() {
        return {
            ...super.attributes,
            type: 'url'
        };
    }
}