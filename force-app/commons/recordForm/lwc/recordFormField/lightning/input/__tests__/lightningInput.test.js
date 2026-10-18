// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski

import { LightningNumberExt } from "../lightningInput";

describe("LightningNumberExt", () => {
    it("formats read-only value with decimal places dictated by scale", () => {
        const ext = new LightningNumberExt();
        ext.connectFieldExt({ fieldInfo: { dataType: "Double", scale: 2 } });
        ext.isReadOnly = true;
        ext.fieldValue = 123.456;

        expect(ext.attributes.type).toBe("text");
        expect(ext.attributes.value).toBe("123.46");
    });

    it("formats read-only integer value with scale 0", () => {
        const ext = new LightningNumberExt();
        ext.connectFieldExt({ fieldInfo: { dataType: "Int", scale: 0 } });
        ext.isReadOnly = true;
        ext.fieldValue = 42;

        expect(ext.attributes.type).toBe("text");
        expect(ext.attributes.value).toBe("42");
    });

    it("formats read-only zero value with scale", () => {
        const ext = new LightningNumberExt();
        ext.connectFieldExt({ fieldInfo: { dataType: "Currency", scale: 2 } });
        ext.isReadOnly = true;
        ext.fieldValue = 0;

        expect(ext.attributes.type).toBe("text");
        expect(ext.attributes.value).toBe("0.00");
    });

    it("handles null/undefined/empty read-only value", () => {
        const ext = new LightningNumberExt();
        ext.connectFieldExt({ fieldInfo: { dataType: "Double", scale: 2 } });
        ext.isReadOnly = true;
        ext.fieldValue = null;

        expect(ext.attributes.type).toBe("text");
        expect(ext.attributes.value).toBe("");
    });

    it("returns raw value and number type when not read-only", () => {
        const ext = new LightningNumberExt();
        ext.connectFieldExt({ fieldInfo: { dataType: "Double", scale: 2 } });
        ext.isReadOnly = false;
        ext.fieldValue = 123.456;

        expect(ext.attributes.type).toBe("number");
        expect(ext.attributes.value).toBe(123.456);
    });
});
