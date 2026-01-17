import {api, LightningElement} from 'lwc';
import {RecordFormComponent} from "c/recordFormComponent";
import LOCALE from "@salesforce/i18n/locale";

const dateOptions = {year: 'numeric', month: '2-digit', day: '2-digit'};
const timeOptions = {hour: '2-digit', minute: '2-digit'};
const dateTimeOptions = {...dateOptions, ...timeOptions};

function dateString(value, opts) {
    return value ? new Date(value).toLocaleString(LOCALE, opts) : '';
}

const DEFAULT_FORMATTER = {
    Currency: 'currency',
    Percent : 'percent-fixed'
};

export default class RecordFormInput extends RecordFormComponent(LightningElement) {
    /*Lightning Input Properties*/
    @api autocomplete;
    @api dateStyle;
    @api disabled;
    @api fieldLevelHelp;
    @api formatter;
    @api label;
    @api maxLength;
    @api messageToggleActive;
    @api messageToggleInactive;
    @api messageWhenBadInput;
    @api messageWhenPatternMismatch;
    @api messageWhenRangeOverflow;
    @api messageWhenRangeUnderflow;
    @api messageWhenStepMismatch;
    @api messageWhenTooLong;
    @api messageWhenTooShort;
    @api messageWhenTypeMismatch;
    @api messageWhenValueMissing;
    @api min;
    @api minLength;
    @api pattern;
    @api placeholder;
    @api readOnly;
    @api required;
    @api selectionEnd;
    @api selectionStart;
    @api step;
    @api timeAccessKey;
    @api timeAriaControls;
    @api timeAriaDescribedBy;
    @api timeAriaDetails;
    @api timeAriaErrorMessage;
    @api timeAriaLabel;
    @api timeAriaLabelledBy;
    @api timeStepMinutes;
    @api timeStyle;
    @api timezone;
    @api type;
    @api validity;
    @api variant;
    @api additionalProps;


    readOnlyType = 'text';
    dataType = 'String';
    objectApiName;
    readOnlyValueFn = () => this.fieldValue;
    valueFn = () => this.fieldValue;

    @api connectField({fieldInfo, objectInfo, recordTypePicklistValues, formParams}) {
        try {
            super.connectField(arguments[0]);
            this.dataType = fieldInfo?.dataType;
            this.objectApiName = objectInfo.apiName;

            switch (this.dataType) {
                case 'String':
                    this.type = 'text';
                    this.maxLength = this.maxLength ?? fieldInfo.maxLength;
                    break;

                case 'Boolean':
                    this.type = this.type ?? "checkbox";
                    this.readOnlyType = "checkbox";
                    break;

                case 'Double':
                case 'Currency':
                case 'Percent':
                    this.type = this.readOnlyType = 'number';
                    this.formatter = this.formatter || DEFAULT_FORMATTER[fieldInfo.dataType] || 'decimal';
                    this.step = this.step ?? (1 / Math.pow(10, fieldInfo.scale)).toString();
                    break;

                case 'DateTime':
                    this.type = 'datetime';
                    this.dateStyle = this.dateStyle ?? 'short';
                    this.readOnlyValueFn = () => dateString(this.fieldValue, dateTimeOptions);
                    break;

                case 'Date':
                    this.type = 'date';
                    this.dateStyle = this.dateStyle ?? 'short';
                    this.readOnlyValueFn = () => dateString(this.fieldValue, dateOptions);
                    break;

                case 'Email':
                    this.type = this.readOnlyType = 'email';
                    break;

                case 'Phone':
                    this.type = this.readOnlyType = 'phone';
                    break;

                case 'Time':
                    this.type = 'time';
                    // this.timeStyle = this.timeStyle ?? 'short';
                    this.readOnlyValueFn = () => dateString(this.fieldValue, timeOptions);
                    break;

                case 'Url':
                    this.type = this.readOnlyType = 'url';
                    break;
            }


        } catch (e) {
            console.error('RecordFormField.connectField', e.message, e.stack);
        }
    }

    get value() {
        return this.isReadOnly ? this.readOnlyValueFn(this) : this.valueFn(this);
    }

    getEventValue(event) {
        return {[this.field]: event.detail.value || event.detail.checked};
    }

    get classes() {
        return {
            "slds-form-element_readonly": this.isReadOnly,
        }
    }

    get _type() {
        return this.isReadOnly ? this.readOnlyType : this.type;
    }
}