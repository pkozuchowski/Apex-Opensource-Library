// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import { createElement } from "lwc";
import RecordFormFooter from "c/recordFormFooter";

function createRecordFormFooter(props = {}) {
    const element = createElement("c-record-form-footer", { is: RecordFormFooter });
    Object.assign(element, props);
    document.body.appendChild(element);
    return element;
}

describe("c-record-form-footer", () => {
    afterEach(() => {
        document.body.innerHTML = "";
    });

    it("defaults button labels to Cancel and Save", () => {
        const element = createRecordFormFooter();
        const buttons = element.shadowRoot.querySelectorAll("lightning-button");

        expect(buttons[0].label).toBe("Cancel");
        expect(buttons[1].label).toBe("Save");
    });

    it("uses cancelLabel/saveLabel when provided", () => {
        const element = createRecordFormFooter({ cancelLabel: "Discard", saveLabel: "Update" });
        const buttons = element.shadowRoot.querySelectorAll("lightning-button");

        expect(buttons[0].label).toBe("Discard");
        expect(buttons[1].label).toBe("Update");
    });

    it("dispatches bubbling cancel/save events on click", () => {
        const element = createRecordFormFooter();
        const cancelHandler = jest.fn();
        const saveHandler = jest.fn();
        element.addEventListener("cancel", cancelHandler);
        element.addEventListener("save", saveHandler);

        const buttons = element.shadowRoot.querySelectorAll("lightning-button");
        buttons[0].click();
        buttons[1].click();

        expect(cancelHandler).toHaveBeenCalledTimes(1);
        expect(saveHandler).toHaveBeenCalledTimes(1);
    });
});
