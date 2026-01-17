// SPDX-License-Identifier: MIT
// Copyright 2026 Piotr Kożuchowski
import {api, LightningElement, track} from 'lwc';
import picklist from './picklist.html';
import lightningInput from './lightningInput.html';
import lightningTextarea from './lightningTextarea.html';
import lightningRecordPicker from './lightningRecordPicker.html';
import lightningRichText from './lightningRichText.html';
import lightningAddress from './lightningAddress.html';
import {RecordFormComponent} from "c/recordFormComponent";

const TEMPLATES = {
    'String'       : lightningInput,
    'Boolean'      : lightningInput,
    'Double'       : lightningInput,
    'Currency'     : lightningInput,
    'Percent'      : lightningInput,
    'DateTime'     : lightningInput,
    'Date'         : lightningInput,
    'Email'        : lightningInput,
    'Phone'        : lightningInput,
    'Time'         : lightningInput,
    'Url'          : lightningInput,
    'PlainTextArea': lightningTextarea,
    'RichTextArea' : lightningRichText,
    'Reference'    : lightningRecordPicker,
    'Address'      : lightningAddress,
    'Picklist'     : picklist,
    'MultiPicklist': picklist,
}


export default class RecordFormField extends RecordFormComponent(LightningElement) {
    static renderMode = 'light';
    @api field;

    @api options;
    /*Array of picklist values to present (['A', 'B', 'C'])*/
    @api optionsFilter;

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

    dataType = 'String';
    objectApiName;

    connectedCallback() {
        this.dispatchEvent(new CustomEvent('fieldconnected', {
            detail : {
                wrapper: true
            },
            bubbles: true, composed: true
        }));
    }

    @api connectField({fieldInfo, objectInfo, recordTypePicklistValues, formParams}) {
        try {
            super.connectField(arguments[0]);
            this.dataType = fieldInfo?.dataType;
            this.objectApiName = objectInfo.apiName;

            switch (this.dataType) {
                case 'TextArea':
                    this.dataType = fieldInfo.extraTypeInfo;
                    this.maxLength = this.maxLength ?? fieldInfo.maxLength;
                // case 'Reference':
                //     return LightningReferenceCtrl;
            }


        } catch (e) {
            console.error('RecordFormField.connectField', e.message, e.stack);
        }
    }

    render() {
        return TEMPLATES[this.dataType] || lightningInput;
    }
}