// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import {api, LightningElement, track} from 'lwc';
import {extendCtrl} from "./extensions";
import emptyTemplate from './recordFormField.html';
import {RecordFormComponent} from "c/recordFormComponent";

export default class RecordFormField extends RecordFormComponent(LightningElement) {
    // static renderMode = 'light';
    @api field;
    @api typeAttributes;

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

    @api connectField({fieldInfo, objectInfo, recordTypePicklistValues}) {
        try {
            super.connectField(arguments[0]);
            extendCtrl(this, arguments[0]);
            this.connectFieldExt(arguments[0]);
        } catch (e) {
            console.error('RecordFormField.connectField', e.message);
        }
    }

    /**
     * Overrideable in Extension class
     */
    connectFieldExt() {}

    render() {
        return this.renderExt();
    }

    /**
     * Overrideable in Extension class
     */
    renderExt() {
        return emptyTemplate;
    }
}