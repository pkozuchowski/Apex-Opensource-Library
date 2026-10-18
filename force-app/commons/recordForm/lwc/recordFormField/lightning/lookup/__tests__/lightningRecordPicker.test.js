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
