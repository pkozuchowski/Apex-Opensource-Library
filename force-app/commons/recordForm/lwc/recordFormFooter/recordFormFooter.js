// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import {api, LightningElement} from "lwc";

export default class RecordFormFooter extends LightningElement {
    @api cancelLabel = "Cancel";
    @api saveLabel = "Save";
    @api docked;

    handleCancel(event) {
        event.preventDefault();
        event.stopPropagation();
        this.dispatchEvent(new CustomEvent("cancel", {bubbles: true, composed: true}));
    }

    handleSave(event) {
        event.preventDefault();
        event.stopPropagation();
        this.dispatchEvent(new CustomEvent("save", {bubbles: true, composed: true}));
    }

    get classes() {
        return {
            'slds-docked-form-footer': this.docked,
            'slds-text-align_center' : true
        }
    }
}
