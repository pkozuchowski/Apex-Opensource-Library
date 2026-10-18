// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski

// No default jest stub ships for this module; only its module shape (a default
// export usable as an LWC component) matters here since these tests never render it.
jest.mock("lightning/select", () => ({ default: class extends require("lwc").LightningElement {} }), {
    virtual: true
});

import { LightningPicklist, LightningMultiPicklistExt } from "../lightningPicklist";

const RECORD_TYPE_PICKLIST_VALUES = {
    values: [
        { label: "Hot Lead", value: "Hot_Lead__c" },
        { label: "Warm", value: "Warm" },
        { label: "Cold", value: "Cold" }
    ]
};

describe("LightningPicklist read-only display", () => {
    it("picklistLabel resolves the label for the current raw API value", () => {
        const cmp = Object.create(LightningPicklist.prototype);
        cmp.recordTypePicklistValues = RECORD_TYPE_PICKLIST_VALUES;
        cmp.fieldValue = "Hot_Lead__c";

        expect(cmp.picklistLabel).toBe("Hot Lead");
    });

    it("picklistLabel falls back to the raw value when no matching option is found", () => {
        const cmp = Object.create(LightningPicklist.prototype);
        cmp.recordTypePicklistValues = RECORD_TYPE_PICKLIST_VALUES;
        cmp.fieldValue = "Unmapped";

        expect(cmp.picklistLabel).toBe("Unmapped");
    });

    it("uses picklistLabel (not the raw value) for the read-only attributes.value", () => {
        const cmp = Object.create(LightningPicklist.prototype);
        cmp.recordTypePicklistValues = RECORD_TYPE_PICKLIST_VALUES;
        cmp.fieldValue = "Hot_Lead__c";
        cmp.isReadOnly = true;
        cmp.label = "Rating"; // short-circuits LightningInputExt.attributes' `this.label || this.fieldInfo.label`

        expect(cmp.attributes.value).toBe("Hot Lead");
    });
});

describe("LightningMultiPicklistExt read-only display", () => {
    it("picklistLabel joins the labels for each selected raw value", () => {
        const cmp = Object.create(LightningMultiPicklistExt.prototype);
        cmp.recordTypePicklistValues = RECORD_TYPE_PICKLIST_VALUES;
        cmp.fieldValue = "Hot_Lead__c;Cold";

        expect(cmp.picklistLabel).toBe("Hot Lead, Cold");
    });

    it("picklistLabel is empty when there's no value", () => {
        const cmp = Object.create(LightningMultiPicklistExt.prototype);
        cmp.recordTypePicklistValues = RECORD_TYPE_PICKLIST_VALUES;
        cmp.fieldValue = undefined;

        expect(cmp.picklistLabel).toBe("");
    });
});
