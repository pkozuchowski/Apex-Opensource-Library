import LOCALE from '@salesforce/i18n/locale';
import lightningInput from './lightningInput.html';
import lightningTextarea from './lightningInput.html';
import lightningRecordPicker from './lightningInput.html';
import lightningSelect from './lightningInput.html';
import lightningRichText from './lightningRichText.html';
import lightningDuelingListbox from './lightningInput.html';
import lightningRadioGroup from './lightningInput.html';
import lightningCheckboxGroup from './lightningInput.html';
import lightningAddress from './lightningInput.html';

const eventValue = (cmp, event) => ({[cmp.field]: event.detail.value})
const noop = () => {};

export function getFieldHandler(cmp, objectInfo, recordTypePicklistValues) {
    try {
        let designSystem = cmp.formParams.designSystem;
        if (!designSystem || designSystem === "lightning") {
            switch (cmp.fieldInfo.dataType) {
                case 'TextArea':
                    return cmp.fieldInfo.extraTypeInfo === "PlainTextArea" ?
                        LightningTextAreaInputCtrl : LightningRichTextCtrl;
                case 'Reference':
                    return LightningReferenceCtrl;
            }
        }
    } catch (e) {
        console.log(e.message);
    }
}


const LightningTimeCtrl = LightningInputCtrl({
    props: (cmp) => ({
        type : cmp.isReadOnly ? 'text' : 'time',
        value: cmp.isReadOnly ?
            (cmp.fieldValue ? dateString('2026-01-01T' + cmp.fieldValue, timeOptions) : '')
            : cmp.fieldValue
    })
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