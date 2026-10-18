// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import { api } from "lwc";
import { extendCtrl } from "./extensions";
import emptyTemplate from "./recordFormField.html";
import RecordFormComponent from "c/recordFormComponent";

export default class RecordFormField extends RecordFormComponent {
    static renderMode = "light";
    @api field;
    @api typeAttributes = {};

    @api options;
    /*Array of picklist values to present (['A', 'B', 'C'])*/
    @api optionsFilter;

    /**
     * For a polymorphic lookup (e.g. OwnerId -> User or Group), forces the record
     * picker to search/display this object API name instead of guessing from the
     * field's (unordered) list of reference-to objects.
     */
    @api lookupObject;

    /**
     * For a lookup field, restricts the record picker's search results. Passed
     * straight through to `lightning-record-picker`'s `filter` attribute, e.g.
     * `{criteria: [{fieldPath: 'IsActive', operator: 'eq', value: true}]}`.
     */
    @api lookupFilter;

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

    @api connectField(data) {
        try {
            super.connectField(data);
            extendCtrl(this, data);
            this.connectFieldExt(data);
        } catch (e) {
            console.error("RecordFormField.connectField", e.message);
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
