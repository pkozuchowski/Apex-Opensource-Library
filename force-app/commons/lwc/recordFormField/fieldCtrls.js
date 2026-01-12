import LOCALE from '@salesforce/i18n/locale';
import lightningInput from './lightningInput.html';
import lightningTextarea from './lightningTextarea.html';
import lightningRecordPicker from './lightningRecordPicker.html';
import lightningSelect from './lightningSelect.html';
import lightningRichText from './lightningRichText.html';
import lightningDuelingListbox from './lightningDuelingListbox.html';
import lightningRadioGroup from './lightningRadioGroup.html';
import lightningCheckboxGroup from './lightningCheckboxGroup.html';

const eventValue = (event) => event.detail.value;
const noop = () => {};

function FieldCtrl({props = noop, render, outputValue}) {
    return {
        render     : render || (() => lightningInput),
        props      : (cmp) => {
            return ({
                label   : cmp.label || cmp.fieldInfo.label,
                readOnly: cmp.isReadOnly,
                required: cmp.required,
                variant : cmp.variant || cmp.formParams?.variant,
                value   : cmp.fieldValue,
                disabled: cmp.disabled,
                ...props(cmp),
                ...cmp.additionalProps
            })
        },
        outputValue: outputValue || eventValue,
        classes    : (cmp) => ({
            "slds-form-element_readonly": cmp.isReadOnly
        })
    }
}

const StringCtrl = FieldCtrl({
    props: () => ({type: 'text'})
});

const BooleanInputCtr = FieldCtrl({
    props      : (cmp) => ({
        type   : 'checkbox',
        checked: cmp.fieldValue
    }),
    outputValue: (event) => event.detail.checked
});

const NumberInputCtr = function (cmp) {
    const step = cmp.step || (1 / Math.pow(10, cmp.fieldInfo.scale)).toString();
    const formatter = cmp.formatter || {
        Currency: 'currency',
        Percent : 'percent-fixed'
    }[cmp.fieldInfo.dataType] || 'decimal';

    return FieldCtrl({
        props: () => ({
            type: 'number', formatter, step
        }),
    });
}

const dateOptions = {year: 'numeric', month: '2-digit', day: '2-digit'};
const timeOptions = {hour: '2-digit', minute: '2-digit'};
const dateTimeOptions = {...dateOptions, ...timeOptions};

function dateString(value, opts) {
    return value ? new Date(value).toLocaleString(LOCALE, opts) : '';
}

const DateCtrl = FieldCtrl({
    props: (cmp) => ({
        type     : cmp.isReadOnly ? 'text' : 'date',
        dateStyle: 'short',
        value    : cmp.isReadOnly ?
            dateString(cmp.fieldValue, dateOptions)
            : cmp.fieldValue
    })
});

const DateTimeCtrl = FieldCtrl({
    props: (cmp) => ({
        type     : cmp.isReadOnly ? 'text' : 'datetime',
        dateStyle: 'short',
        value    : cmp.isReadOnly ?
            dateString(cmp.fieldValue, dateTimeOptions)
            : cmp.fieldValue
    })
});

const TimeCtrl = FieldCtrl({
    props: (cmp) => ({
        type : cmp.isReadOnly ? 'text' : 'time',
        value: cmp.isReadOnly ?
            (cmp.fieldValue ? dateString('2026-01-01T' + cmp.fieldValue, timeOptions) : '')
            : cmp.fieldValue
    })
});

const EmailCtrl = FieldCtrl({
    props: () => ({type: 'email'})
});

const PhoneCtrl = FieldCtrl({
    props: () => ({type: 'phone'})
});

const UrlCtrl = FieldCtrl({
    props: () => ({type: 'url'})
});

const TextAreaInputCtrl = FieldCtrl({
    render: () => lightningTextarea,
});

const RichTextCtrl = FieldCtrl({
    render: () => lightningRichText,
    props : () => ({
        formats: [
            'font', 'size', 'bold', 'italic', 'underline', 'strike', 'list',
            'indent', 'align', 'link', 'image', 'clean', 'header', 'color'
        ]
    })
});

const ReferenceCtrl = FieldCtrl({
    render     : () => lightningRecordPicker,
    props      : (cmp) => ({
        objectApiName: cmp.fieldInfo.referenceToInfos[0].apiName,
        disabled     : cmp.disabled || cmp.isReadOnly
    }),
    outputValue: (event) => event.detail.recordId
});

const PicklistCtrl = FieldCtrl({
    render: (cmp) => {
        if (cmp.isReadOnly) {
            return lightningInput;
        } else if (cmp.type === "radioGroup") {
            return lightningRadioGroup;
        } else {
            return lightningSelect;
        }
    },
    /*TODO: Display Picklist Label on Read Only*/
    props: (cmp) => ({
        value  : cmp.fieldValue || '',
        options: cmp.picklistOptions
    })
});

const MultiPicklistCtrl = FieldCtrl({
    render     : (cmp) => {
        if (cmp.isReadOnly) {
            return lightningInput;
        } else if (cmp.type === "checkboxGroup") {
            return lightningCheckboxGroup;
        } else {
            return lightningDuelingListbox;
        }
    },
    props      : (cmp) => ({
        multiple     : true,
        options      : cmp.picklistOptions,
        value        : cmp.isReadOnly ? cmp.fieldValue : (cmp.fieldValue?.split(';')) || [],
        sourceLabel  : "Available",
        selectedLabel: "Selected"
    }),
    outputValue: (event) => event.detail.value.join(';')
});

export function getFieldHandler(cmp) {
    try {
        switch (cmp.fieldInfo.dataType) {
            case 'String':
                return StringCtrl;
            case 'Boolean':
                return BooleanInputCtr;
            case 'Double':
                return NumberInputCtr(cmp);
            case 'Currency':
                return NumberInputCtr(cmp);
            case 'Percent':
                return NumberInputCtr(cmp);
            case 'DateTime':
                return DateTimeCtrl;
            case 'Date':
                return DateCtrl;
            case 'Email':
                return EmailCtrl;
            case 'Phone':
                return PhoneCtrl;
            case 'Time':
                return TimeCtrl;
            case 'Url':
                return UrlCtrl;
            case 'TextArea':
                return cmp.fieldInfo.extraTypeInfo === "PlainTextArea" ?
                    TextAreaInputCtrl : RichTextCtrl;
            case 'Reference':
                return ReferenceCtrl;
            case 'Picklist':
                return PicklistCtrl;
            case 'MultiPicklist':
                return MultiPicklistCtrl;
        }
    } catch (e) {
        console.log(e.message);
    }
}