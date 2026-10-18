// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import { createElement } from "lwc";
import RecordForm from "c/recordForm";
import { getObjectInfo, getPicklistValuesByRecordType } from "lightning/uiObjectInfoApi";
import { getRecord, createRecord, notifyRecordUpdateAvailable } from "lightning/uiRecordApi";
import LightningConfirm from "lightning/confirm";

jest.mock("lightning/confirm", () => ({
    __esModule: true,
    default: { open: jest.fn() }
}));

const RECORD_ID = "001xx000003DGb2AAG";

const OBJECT_INFO = {
    apiName: "Account",
    defaultRecordTypeId: "012000000000000AAA",
    recordTypeInfos: {},
    fields: {
        Name: { apiName: "Name", label: "Account Name", compound: false, updateable: true, createable: true }
    }
};

const PICKLIST_VALUES = { picklistFieldValues: {} };

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

function createRecordForm(props = {}) {
    const element = createElement("c-record-form", { is: RecordForm });
    Object.assign(element, { objectApiName: "Account", recordId: RECORD_ID, ...props });
    document.body.appendChild(element);
    return element;
}

function loadForm() {
    getObjectInfo.emit(OBJECT_INFO);
    getPicklistValuesByRecordType.emit(PICKLIST_VALUES);
}

describe("c-record-form", () => {
    afterEach(() => {
        document.body.innerHTML = "";
        jest.clearAllMocks();
    });

    describe("attribute passthrough", () => {
        it("reflects density, isPersonAccount, inlineEdit and hideFooter", () => {
            const element = createRecordForm({
                density: "compact",
                isPersonAccount: true,
                inlineEdit: true,
                hideFooter: true
            });

            expect(element.density).toBe("compact");
            expect(element.isPersonAccount).toBe(true);
            expect(element.inlineEdit).toBe(true);
            expect(element.hideFooter).toBe(true);
        });

        it("accepts optionalFields as an array or a comma-separated string", () => {
            const element = createRecordForm();

            element.optionalFields = "Industry,AnnualRevenue";
            expect(element.optionalFields).toEqual(["Industry", "AnnualRevenue"]);

            element.optionalFields = ["Rating"];
            expect(element.optionalFields).toEqual(["Rating"]);
        });

        it("qualifies short optionalFields names with objectApiName for the record wire", async () => {
            const element = createRecordForm({ optionalFields: ["Industry", "Account.AnnualRevenue"] });
            loadForm();
            await Promise.resolve();

            const config = getRecord.getLastConfig();
            expect(config.optionalFields).toEqual(
                expect.arrayContaining(["Account.Industry", "Account.AnnualRevenue"])
            );
        });
    });

    describe("edit mode", () => {
        it("defaults to inlineEdit=true, editMode=false (view mode with pencil icons)", () => {
            const element = createRecordForm();
            expect(element.inlineEdit).toBe(true);
            expect(element.editMode).toBe(false);
        });

        it("can be set to true upfront (e.g. to skip inlineEdit/pencil icons) to start the form editable", () => {
            const element = createRecordForm({ editMode: true });

            expect(element.editMode).toBe(true);
            element.editMode = false;
            expect(element.editMode).toBe(false);
        });

        it("switches on when a field dispatches a bubbling edit event (pencil click)", async () => {
            const element = createRecordForm();
            loadForm();
            await Promise.resolve();

            // A real pencil click dispatches `edit` from deep inside a slotted field
            // component; the `<form>` is where recordForm actually listens for it
            // (`onedit={onFieldEdit}`), so that's the boundary this test verifies -
            // the browser's own composed-event bubbling through <slot> is platform
            // behavior, not something recordForm.js needs this test to re-prove.
            const form = element.shadowRoot.querySelector("form");
            form.dispatchEvent(new CustomEvent("edit", { bubbles: true, composed: true }));

            expect(element.editMode).toBe(true);
        });
    });

    describe("isDirty()", () => {
        it("is false when edit mode was never entered", () => {
            const element = createRecordForm();
            expect(element.isDirty()).toBe(false);
        });

        it("is false right after entering edit mode, true once a field changes", () => {
            const element = createRecordForm();
            element.record = { Id: RECORD_ID, Name: "Original" };
            element.editMode = true;

            expect(element.isDirty()).toBe(false);

            element.record = { Id: RECORD_ID, Name: "Changed" };
            expect(element.isDirty()).toBe(true);
        });
    });

    describe("Cancel/Save footer visibility", () => {
        it("is hidden when hideFooter is true", async () => {
            const element = createRecordForm({ hideFooter: true });
            loadForm();
            await Promise.resolve();

            expect(element.shadowRoot.querySelector("c-record-form-footer")).toBeNull();
        });

        it("is hidden by default (view mode) and appears once editMode is switched on", async () => {
            const element = createRecordForm();
            loadForm();
            await Promise.resolve();

            expect(element.shadowRoot.querySelector("c-record-form-footer")).toBeNull();

            element.editMode = true;
            await Promise.resolve();

            expect(element.shadowRoot.querySelector("c-record-form-footer")).not.toBeNull();
        });

        it("is shown immediately when editMode is set true upfront", async () => {
            const element = createRecordForm({ editMode: true });
            loadForm();
            await Promise.resolve();

            expect(element.shadowRoot.querySelector("c-record-form-footer")).not.toBeNull();
        });
    });

    describe("Cancel/Save footer actions", () => {
        it("Cancel reverts fields to their edit-mode-entry state when confirmed, not to the latest edits", async () => {
            LightningConfirm.open.mockResolvedValue(true);
            const element = createRecordForm({ editMode: false });
            loadForm();
            await Promise.resolve();

            element.record = { Id: RECORD_ID, Name: "Before edit" };
            element.editMode = true; // snapshot taken here: {Id, Name: 'Before edit'}
            await Promise.resolve();

            // Simulate the user typing into a field after entering edit mode - the
            // consumer's onchange handler would merge this into the bound record.
            element.record = { Id: RECORD_ID, Name: "Typed but unsaved" };

            const changeHandler = jest.fn();
            element.addEventListener("change", changeHandler);

            const footer = element.shadowRoot.querySelector("c-record-form-footer");
            footer.dispatchEvent(new CustomEvent("cancel", { bubbles: true, composed: true }));
            await flushPromises();

            expect(LightningConfirm.open).toHaveBeenCalled();
            expect(element.editMode).toBe(false);
            expect(changeHandler).toHaveBeenCalledWith(
                expect.objectContaining({ detail: { value: { Id: RECORD_ID, Name: "Before edit" } } })
            );
        });

        it("Cancel keeps editing when the discard confirmation is declined", async () => {
            LightningConfirm.open.mockResolvedValue(false);
            const element = createRecordForm({ editMode: false });
            loadForm();
            await Promise.resolve();

            element.record = { Id: RECORD_ID, Name: "Before edit" };
            element.editMode = true;
            await Promise.resolve();
            element.record = { Id: RECORD_ID, Name: "Typed but unsaved" };

            const footer = element.shadowRoot.querySelector("c-record-form-footer");
            footer.dispatchEvent(new CustomEvent("cancel", { bubbles: true, composed: true }));
            await flushPromises();

            expect(element.editMode).toBe(true);
            expect(element.record).toEqual({ Id: RECORD_ID, Name: "Typed but unsaved" });
        });

        it("Cancel skips the confirmation entirely when disableConfirmDiscard is set", async () => {
            const element = createRecordForm({ editMode: false, disableConfirmDiscard: true });
            loadForm();
            await Promise.resolve();

            element.record = { Id: RECORD_ID, Name: "Before edit" };
            element.editMode = true;
            await Promise.resolve();
            element.record = { Id: RECORD_ID, Name: "Typed but unsaved" };

            const footer = element.shadowRoot.querySelector("c-record-form-footer");
            footer.dispatchEvent(new CustomEvent("cancel", { bubbles: true, composed: true }));
            await flushPromises();

            expect(LightningConfirm.open).not.toHaveBeenCalled();
            expect(element.editMode).toBe(false);
        });

        it("Cancel skips the confirmation when nothing changed (not dirty)", async () => {
            const element = createRecordForm({ editMode: false });
            loadForm();
            await Promise.resolve();

            element.record = { Id: RECORD_ID, Name: "Unchanged" };
            element.editMode = true;
            await Promise.resolve();

            const footer = element.shadowRoot.querySelector("c-record-form-footer");
            footer.dispatchEvent(new CustomEvent("cancel", { bubbles: true, composed: true }));
            await flushPromises();

            expect(LightningConfirm.open).not.toHaveBeenCalled();
            expect(element.editMode).toBe(false);
        });

        it("Save calls submit() and exits edit mode once the record is created", async () => {
            createRecord.mockResolvedValueOnce({ id: RECORD_ID, fields: { Name: { value: "New" } } });
            const element = createRecordForm({ recordId: undefined, editMode: true });
            loadForm();
            await Promise.resolve();

            element.record = { Name: "New" };
            await Promise.resolve();

            const footer = element.shadowRoot.querySelector("c-record-form-footer");
            footer.dispatchEvent(new CustomEvent("save", { bubbles: true, composed: true }));
            await flushPromises();

            expect(createRecord).toHaveBeenCalled();
            expect(notifyRecordUpdateAvailable).toHaveBeenCalled();
            expect(element.editMode).toBe(false);
        });
    });

    describe("Keyboard shortcuts", () => {
        function dispatchKey(form, key, targetTagName) {
            const event = new KeyboardEvent("keydown", { key, bubbles: true, composed: true, cancelable: true });
            if (targetTagName) {
                Object.defineProperty(event, "target", { value: { tagName: targetTagName } });
            }
            form.dispatchEvent(event);
        }

        it("Escape cancels edit mode (with confirmation, since dirty)", async () => {
            LightningConfirm.open.mockResolvedValue(true);
            const element = createRecordForm({ editMode: false });
            loadForm();
            await Promise.resolve();

            element.record = { Id: RECORD_ID, Name: "Before edit" };
            element.editMode = true;
            await Promise.resolve();
            element.record = { Id: RECORD_ID, Name: "Typed but unsaved" };

            const form = element.shadowRoot.querySelector("form");
            dispatchKey(form, "Escape");
            await flushPromises();

            expect(LightningConfirm.open).toHaveBeenCalled();
            expect(element.editMode).toBe(false);
        });

        it("does nothing when not in edit mode", async () => {
            const element = createRecordForm({ editMode: false });
            loadForm();
            await Promise.resolve();

            const form = element.shadowRoot.querySelector("form");
            dispatchKey(form, "Escape");
            await flushPromises();

            expect(LightningConfirm.open).not.toHaveBeenCalled();
        });

        it("Enter submits the form", async () => {
            createRecord.mockResolvedValueOnce({ id: RECORD_ID, fields: { Name: { value: "New" } } });
            const element = createRecordForm({ recordId: undefined, editMode: true });
            loadForm();
            await Promise.resolve();
            element.record = { Name: "New" };

            const form = element.shadowRoot.querySelector("form");
            dispatchKey(form, "Enter", "LIGHTNING-INPUT");
            await flushPromises();

            expect(createRecord).toHaveBeenCalled();
        });

        it("Enter is ignored inside a textarea/rich-text/record-picker/combobox/dual-listbox", async () => {
            const element = createRecordForm({ recordId: undefined, editMode: true });
            loadForm();
            await Promise.resolve();
            element.record = { Name: "New" };

            const form = element.shadowRoot.querySelector("form");
            dispatchKey(form, "Enter", "LIGHTNING-TEXTAREA");
            await flushPromises();

            expect(createRecord).not.toHaveBeenCalled();
        });
    });
});
