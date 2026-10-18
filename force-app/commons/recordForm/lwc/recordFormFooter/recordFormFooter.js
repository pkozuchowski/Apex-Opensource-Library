// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import {LightningElement} from 'lwc';

export default class RecordFormFooter extends LightningElement {

    handleCancel(event) {
        event.preventDefault();
        event.stopPropagation();
        this.dispatchEvent(new CustomEvent('cancel', {bubbles: true, composed: true}));
    }

    handleSave(event) {
        event.preventDefault();
        event.stopPropagation();
        this.dispatchEvent(new CustomEvent('save', {bubbles: true, composed: true}));
    }
}
