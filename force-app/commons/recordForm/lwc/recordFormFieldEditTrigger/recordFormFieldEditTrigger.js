// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import {api, LightningElement} from 'lwc';

export default class RecordFormFieldEditTrigger extends LightningElement {
    @api label;

    get title() {
        return `Edit ${this.label}`;
    }

    handleClick(event) {
        event.preventDefault();
        event.stopPropagation();
        this.dispatchEvent(new CustomEvent('edit', {bubbles: true, composed: true}));
    }
}
