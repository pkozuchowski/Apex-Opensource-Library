// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski

import {api, LightningElement} from 'lwc';

export default class RecordFormFieldOutput extends LightningElement {
    @api label;
    @api density;

    get classes() {
        return {
            "slds-form-element slds-form-element_readonly": true,
            "slds-form-element_stacked"                   : this.density === "comfy",
            "slds-form-element_horizontal"                : this.density === "compact",
        };
    }
}