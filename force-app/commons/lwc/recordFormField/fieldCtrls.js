import LOCALE from '@salesforce/i18n/locale';
import lightningInput from './lightningInput.html';
import lightningTextarea from './lightningTextarea.html';
import lightningRecordPicker from './lightningRecordPicker.html';
import lightningSelect from './lightningSelect.html';
import lightningRichText from './lightningRichText.html';
import lightningDuelingListbox from './lightningDuelingListbox.html';
import lightningRadioGroup from './lightningRadioGroup.html';
import lightningCheckboxGroup from './lightningCheckboxGroup.html';
import lightningAddress from './lightningAddress.html';

const eventValue = (cmp, event) => ({[cmp.field]: event.detail.value})
const noop = () => {};

export function getFieldHandler(cmp, objectInfo) {
    try {
        let designSystem = cmp.formParams.designSystem;
        if (!designSystem || designSystem === "lightning") {
            switch (cmp.fieldInfo.dataType) {
                case 'String':
                    return LightningTextCtrl;
                case 'Boolean':
                    return LightningCheckboxCtrl;
                case 'Double':
                    return LightningNumberCtrl(cmp);
                case 'Currency':
                    return LightningNumberCtrl(cmp);
                case 'Percent':
                    return LightningNumberCtrl(cmp);
                case 'DateTime':
                    return LightningDateTimeCtrl;
                case 'Date':
                    return LightningDateCtrl;
                case 'Email':
                    return LightningEmailCtrl;
                case 'Phone':
                    return LightningPhoneCtrl;
                case 'Time':
                    return LightningTimeCtrl;
                case 'Url':
                    return LightningUrlCtrl;
                case 'TextArea':
                    return cmp.fieldInfo.extraTypeInfo === "PlainTextArea" ?
                        LightningTextAreaInputCtrl : LightningRichTextCtrl;
                case 'Reference':
                    return LightningReferenceCtrl;
                case 'Picklist':
                    return LightningPicklistCtrl(cmp, objectInfo);
                case 'MultiPicklist':
                    return LightningMultiPicklistCtrl;
                case 'Address':
                    return LightningAddressCtrl(cmp, objectInfo);
            }
        }
    } catch (e) {
        console.log(e.message);
    }
}

function LightningInputCtrl({props = noop, render, outputValue}) {
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

const LightningTextCtrl = LightningInputCtrl({
    props: () => ({type: 'text'})
});

const LightningCheckboxCtrl = LightningInputCtrl({
    props      : (cmp) => ({
        type   : 'checkbox',
        checked: cmp.fieldValue
    }),
    outputValue: (cmp, event) => ({
        [cmp.field]: event.detail.checked
    })
});

const LightningNumberCtrl = function (cmp) {
    const step = cmp.step || (1 / Math.pow(10, cmp.fieldInfo.scale)).toString();
    const formatter = cmp.formatter || {
        Currency: 'currency',
        Percent : 'percent-fixed'
    }[cmp.fieldInfo.dataType] || 'decimal';

    return LightningInputCtrl({
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

const LightningDateCtrl = LightningInputCtrl({
    props: (cmp) => ({
        type     : cmp.isReadOnly ? 'text' : 'date',
        dateStyle: 'short',
        value    : cmp.isReadOnly ?
            dateString(cmp.fieldValue, dateOptions)
            : cmp.fieldValue
    })
});

const LightningDateTimeCtrl = LightningInputCtrl({
    props: (cmp) => ({
        type     : cmp.isReadOnly ? 'text' : 'datetime',
        dateStyle: 'short',
        value    : cmp.isReadOnly ?
            dateString(cmp.fieldValue, dateTimeOptions)
            : cmp.fieldValue
    })
});

const LightningTimeCtrl = LightningInputCtrl({
    props: (cmp) => ({
        type : cmp.isReadOnly ? 'text' : 'time',
        value: cmp.isReadOnly ?
            (cmp.fieldValue ? dateString('2026-01-01T' + cmp.fieldValue, timeOptions) : '')
            : cmp.fieldValue
    })
});

const LightningEmailCtrl = LightningInputCtrl({
    props: () => ({type: 'email'})
});

const LightningPhoneCtrl = LightningInputCtrl({
    props: () => ({type: 'phone'})
});

const LightningUrlCtrl = LightningInputCtrl({
    props: () => ({type: 'url'})
});

const LightningTextAreaInputCtrl = LightningInputCtrl({
    render: () => lightningTextarea,
});

const LightningRichTextCtrl = LightningInputCtrl({
    render: () => lightningRichText,
    props : () => ({
        formats: [
            'font', 'size', 'bold', 'italic', 'underline', 'strike', 'list',
            'indent', 'align', 'link', 'image', 'clean', 'header', 'color'
        ]
    })
});

const LightningReferenceCtrl = LightningInputCtrl({
    render     : () => lightningRecordPicker,
    props      : (cmp) => ({
        objectApiName: cmp.fieldInfo.referenceToInfos[0].apiName,
        disabled     : cmp.disabled || cmp.isReadOnly
    }),
    outputValue: (cmp, event) => ({
        [cmp.field]: event.detail.recordId
    })
});

const LightningPicklistCtrl = function (cmp, objectInfo) {
    const controlledFields = {};
    Object.values(objectInfo.fields).forEach(field => {
        if (field.controllingFields.indexOf(cmp.field) > -1) {
            controlledFields[field.apiName] = '';
        }
    });

    return LightningInputCtrl({
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
        props      : (cmp) => ({
            value  : cmp.fieldValue || '',
            options: cmp.picklistOptions
        }),
        outputValue: (cmp, event) => ({
            [cmp.field]: event.detail.value,
            ...controlledFields
        })
    });
};


const LightningMultiPicklistCtrl = LightningInputCtrl({
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
    outputValue: (cmp, event) => ({
        [cmp.field]: event.detail.value.join(';')
    })
});

const LightningAddressCtrl = function (cmp, objectInfo) {
    const addressField = cmp.field;
    const addressComponents = {};

    Object.values(objectInfo.fields).forEach(field => {
        if (field.compoundFieldName === addressField) {
            addressComponents[field.compoundComponentName] = field;
        }
    });

    let street = addressComponents.Street;
    let city = addressComponents.City;
    let country = addressComponents.Country;
    let postalCode = addressComponents.PostalCode;
    let province = addressComponents.State;

    return LightningInputCtrl({
        render     : () => lightningAddress,
        props      : (cmp) => ({
            addressLabel   : cmp.label || cmp.fieldInfo.label,
            street         : cmp.getField(street?.apiName),
            streetLabel    : street?.label,
            city           : cmp.getField(city?.apiName),
            cityLabel      : city?.label,
            country        : cmp.getField(country?.apiName),
            countryLabel   : country?.label,
            postalCode     : cmp.getField(postalCode?.apiName),
            postalCodeLabel: postalCode?.label,
            province       : cmp.getField(province?.apiName),
            provinceLabel  : province?.label,
        }),
        outputValue: (cmp, event) => ({
            [street.apiName]    : event.target.street,
            [city.apiName]      : event.target.city,
            [province.apiName]  : event.target.province,
            [country.apiName]   : event.target.country,
            [postalCode.apiName]: event.target.postalCode,
        })
    });
}