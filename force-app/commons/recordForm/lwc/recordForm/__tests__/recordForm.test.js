// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import { createElement } from "lwc";
import RecordForm from "c/recordForm";
import { getObjectInfo, getPicklistValuesByRecordType } from "lightning/uiObjectInfoApi";
import { getRecord, createRecord, notifyRecordUpdateAvailable } from "lightning/uiRecordApi";

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
        it("Cancel reverts fields to their state when edit mode was entered, not to the latest edits", async () => {
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

            expect(element.editMode).toBe(false);
            expect(changeHandler).toHaveBeenCalledWith(
                expect.objectContaining({ detail: { value: { Id: RECORD_ID, Name: "Before edit" } } })
            );
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
});
