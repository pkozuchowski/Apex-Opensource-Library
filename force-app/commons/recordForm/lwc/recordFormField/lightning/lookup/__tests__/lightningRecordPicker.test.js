// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import { LightningReferenceExt } from "../lightningRecordPicker";

describe("LightningReferenceExt.connectFieldExt", () => {
    it("resolves the same objectApiName regardless of referenceToInfos order, when lookupObject is not set", () => {
        const fieldInfo = { referenceToInfos: [{ apiName: "User" }, { apiName: "Group" }] };
        const reversedFieldInfo = { referenceToInfos: [{ apiName: "Group" }, { apiName: "User" }] };

        const cmp = Object.create(LightningReferenceExt.prototype);
        cmp.connectFieldExt({ fieldInfo });
        const reversedCmp = Object.create(LightningReferenceExt.prototype);
        reversedCmp.connectFieldExt({ fieldInfo: reversedFieldInfo });

        expect(cmp.objectApiName).toBe(reversedCmp.objectApiName);
        expect(cmp.objectApiName).toBe("Group"); // alphabetically first
    });

    it("uses lookupObject to force the choice when set, regardless of referenceToInfos", () => {
        const fieldInfo = { referenceToInfos: [{ apiName: "Group" }, { apiName: "User" }] };

        const cmp = Object.create(LightningReferenceExt.prototype);
        cmp.lookupObject = "User";
        cmp.connectFieldExt({ fieldInfo });

        expect(cmp.objectApiName).toBe("User");
    });
});

describe("LightningReferenceExt.attributes", () => {
    it("passes lookupFilter through as the record picker's filter attribute", () => {
        const cmp = Object.create(LightningReferenceExt.prototype);
        cmp.label = "Owner"; // short-circuits LightningInputExt.attributes' `this.label || this.fieldInfo.label`
        cmp.lookupFilter = { criteria: [{ fieldPath: "IsActive", operator: "eq", value: true }] };

        expect(cmp.attributes.filter).toBe(cmp.lookupFilter);
    });

    it("leaves filter undefined when lookupFilter is not set", () => {
        const cmp = Object.create(LightningReferenceExt.prototype);
        cmp.label = "Owner";

        expect(cmp.attributes.filter).toBeUndefined();
    });
});
