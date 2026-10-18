// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski

// No default jest stub ships for this module; only its module shape (a default
// export usable as an LWC component) matters here since these tests never render it.
jest.mock("lightning/select", () => ({ default: class extends require("lwc").LightningElement {} }), {
    virtual: true
});

import { LightningName } from "../lightningName";

function fakeInput(valid) {
    return {
        reportValidity: jest.fn(() => valid),
        checkValidity: jest.fn(() => valid),
        setCustomValidity: jest.fn()
    };
}

describe("LightningName validity aggregation", () => {
    // Person Name renders as three separate inputs with no single compound element
    // to `lwc:ref="input"`, so reportValidity()/checkValidity()/setCustomValidity()
    // must be overridden to aggregate across refs.salutation/firstName/lastName,
    // rather than silently no-op'ing via the base class's `this.refs.input`.

    it("reportValidity is true only when all three inputs are valid", () => {
        const cmp = Object.create(LightningName.prototype);
        cmp.refs = { salutation: fakeInput(true), firstName: fakeInput(true), lastName: fakeInput(true) };
        expect(cmp.reportValidity()).toBe(true);

        cmp.refs.firstName = fakeInput(false);
        expect(cmp.reportValidity()).toBe(false);
    });

    it("checkValidity is true only when all three inputs are valid", () => {
        const cmp = Object.create(LightningName.prototype);
        cmp.refs = { salutation: fakeInput(true), firstName: fakeInput(true), lastName: fakeInput(false) };
        expect(cmp.checkValidity()).toBe(false);
    });

    it("defaults to true when a ref isn't connected yet", () => {
        const cmp = Object.create(LightningName.prototype);
        cmp.refs = {};
        expect(cmp.reportValidity()).toBe(true);
        expect(cmp.checkValidity()).toBe(true);
    });

    it("setCustomValidity forwards the message to firstName and lastName, not salutation", () => {
        const cmp = Object.create(LightningName.prototype);
        cmp.refs = { salutation: fakeInput(true), firstName: fakeInput(true), lastName: fakeInput(true) };

        cmp.setCustomValidity("Invalid value");

        expect(cmp.refs.firstName.setCustomValidity).toHaveBeenCalledWith("Invalid value");
        expect(cmp.refs.lastName.setCustomValidity).toHaveBeenCalledWith("Invalid value");
        expect(cmp.refs.salutation.setCustomValidity).not.toHaveBeenCalled();
    });
});
