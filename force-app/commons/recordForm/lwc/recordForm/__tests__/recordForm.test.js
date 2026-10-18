// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import { createElement } from "lwc";
import RecordForm from "c/recordForm";
import { getObjectInfo, getPicklistValuesByRecordType } from "lightning/uiObjectInfoApi";
import { getRecord, createRecord, notifyRecordUpdateAvailable } from "lightning/uiRecordApi";
import { graphql } from "lightning/graphql";
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

// `fieldconnected` bubbles from deep inside a slotted field in real usage, but
// dispatching it directly on the `<form>` (where `onfieldconnected` is bound) and
// faking `target` sidesteps jsdom's incomplete shadow/slot composed-event support
// (see the `edit`/keyboard tests below, which use the same technique).
function connectFakeField(form, fieldApiName, overrides = {}) {
    const fakeField = {
        field: fieldApiName,
        connectField: jest.fn(),
        reportValidity: jest.fn(() => true),
        checkValidity: jest.fn(() => true),
        setCustomValidity: jest.fn(),
        ...overrides
    };
    const event = new CustomEvent("fieldconnected", { bubbles: true, composed: true, cancelable: true });
    Object.defineProperty(event, "target", { value: fakeField });
    form.dispatchEvent(event);
    return fakeField;
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

        it("is false after a successful Save, not stale from the pre-edit snapshot", async () => {
            createRecord.mockResolvedValueOnce({ id: RECORD_ID, fields: { Name: { value: "New" } } });
            const element = createRecordForm({ recordId: undefined, editMode: true });
            loadForm();
            await Promise.resolve();

            element.record = { Name: "New" };
            await element.submit();

            expect(element.isDirty()).toBe(false);
        });
    });

    describe("single-field validity methods", () => {
        it("reportValidityForField/checkValidityForField return the field's actual validity", async () => {
            const element = createRecordForm();
            loadForm();
            await Promise.resolve();

            const form = element.shadowRoot.querySelector("form");
            const field = connectFakeField(form, "Name", {
                reportValidity: jest.fn(() => false),
                checkValidity: jest.fn(() => false)
            });

            expect(element.reportValidityForField("Name")).toBe(false);
            expect(field.reportValidity).toHaveBeenCalledTimes(1);
            expect(element.checkValidityForField("Name")).toBe(false);
            expect(field.checkValidity).toHaveBeenCalledTimes(1);
        });

        it("reportValidityForField/checkValidityForField return undefined for an unconnected field", async () => {
            const element = createRecordForm();
            loadForm();
            await Promise.resolve();

            expect(element.reportValidityForField("DoesNotExist")).toBeUndefined();
            expect(element.checkValidityForField("DoesNotExist")).toBeUndefined();
        });

        it("setCustomValidityForField forwards the message to the matching field", async () => {
            const element = createRecordForm();
            loadForm();
            await Promise.resolve();

            const form = element.shadowRoot.querySelector("form");
            const field = connectFakeField(form, "Name");

            element.setCustomValidityForField("Name", "Invalid value");
            expect(field.setCustomValidity).toHaveBeenCalledWith("Invalid value");
        });
    });

    describe("connected field lifecycle", () => {
        it("ignores and removes fields after they disconnect", async () => {
            const element = createRecordForm();
            loadForm();
            await Promise.resolve();

            const form = element.shadowRoot.querySelector("form");
            const staleField = connectFakeField(form, "Name", {
                isConnected: true,
                reportValidity: jest.fn(() => false)
            });

            expect(element.reportValidity().valid).toBe(false);

            staleField.isConnected = false;
            staleField.reportValidity.mockClear();
            expect(element.reportValidity().valid).toBe(true);
            expect(staleField.reportValidity).not.toHaveBeenCalled();
            expect(element.reportValidityForField("Name")).toBeUndefined();
        });
    });

    describe("Record Type Id resolution", () => {
        it("the record's own Record Type Id takes precedence over the name-based GraphQL lookup, regardless of wire order", async () => {
            const element = createRecordForm({ recordTypeName: "Enterprise" });
            loadForm();
            await Promise.resolve();

            // The record's own getRecord wire resolves first, with its true Record Type Id.
            getRecord.emit({
                id: RECORD_ID,
                recordTypeId: "012000000000001AAA",
                fields: { Name: { value: "Acme" } }
            });
            await Promise.resolve();

            // The GraphQL name-based lookup resolves afterward (the two wires are
            // independent/unordered) - it must NOT clobber the already-known value.
            graphql.emit({
                uiapi: {
                    query: {
                        RecordType: {
                            edges: [{ node: { Id: "012000000000002AAA", SobjectType: { value: "Account" } } }]
                        }
                    }
                }
            });
            await Promise.resolve();

            expect(getPicklistValuesByRecordType.getLastConfig().recordTypeId).toBe("012000000000001AAA");
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

        it("ignores rapid repeated Save clicks while the first save is pending", async () => {
            let resolveCreateRecord;
            createRecord.mockReturnValueOnce(
                new Promise((resolve) => {
                    resolveCreateRecord = resolve;
                })
            );
            const element = createRecordForm({ recordId: undefined, editMode: true });
            loadForm();
            await Promise.resolve();

            element.record = { Name: "New" };
            const footer = element.shadowRoot.querySelector("c-record-form-footer");
            footer.dispatchEvent(new CustomEvent("save", { bubbles: true, composed: true }));
            footer.dispatchEvent(new CustomEvent("save", { bubbles: true, composed: true }));

            expect(createRecord).toHaveBeenCalledTimes(1);

            resolveCreateRecord({ id: RECORD_ID, fields: { Name: { value: "New" } } });
            await flushPromises();
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
    });
});
