// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import { createElement } from "lwc";
import { createContentDocumentAndVersion, createRecord } from "lightning/uiRecordApi";
import Toast from "lightning/toast";
import { graphql } from "lightning/graphql";
import { mockNavigate } from "lightning/navigation";
import RecordFormFileUpload from "c/recordFormFileUpload";

jest.mock("lightning/uiRecordApi", () => ({
    createContentDocumentAndVersion: jest.fn(),
    createRecord: jest.fn()
}));

jest.mock(
    "lightning/toast",
    () => ({
        __esModule: true,
        default: { show: jest.fn() }
    }),
    { virtual: true }
);

jest.mock("lightning/navigation", () => {
    const navigateSpy = jest.fn();
    const navigateSymbol = Symbol("Navigate");
    const NavigationMixin = (Base) =>
        class extends Base {
            [navigateSymbol](pageReference) {
                navigateSpy(pageReference);
            }
        };
    NavigationMixin.Navigate = navigateSymbol;
    return { NavigationMixin, mockNavigate: navigateSpy };
});

const RECORD_ID = "001xx000003DGb2AAG";
const CONTENT_DOCUMENT_ID = "069xx0000000001AAA";

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

describe("c-record-form-file-upload", () => {
    afterEach(() => {
        document.body.textContent = "";
        jest.clearAllMocks();
    });

    function createUploader(files, properties = {}) {
        const element = createElement("c-record-form-file-upload", { is: RecordFormFileUpload });
        Object.assign(element, { formAttributes: { editMode: true }, ...properties });
        document.body.appendChild(element);
        const input = element.querySelector("lightning-input");
        const selectedFiles = Array.isArray(files) ? files : files ? [files] : [];
        input.dispatchEvent(new CustomEvent("change", { detail: { files: selectedFiles } }));
        return element;
    }

    it("defaults the label and exposes accept, multiple, and disabled attributes", () => {
        const defaultElement = createUploader();
        const defaultInput = defaultElement.querySelector("lightning-input");
        expect(defaultInput.label).toBe("Upload Files");
        expect(defaultInput.multiple).toBe(false);
        expect(defaultInput.accept).toBeUndefined();
        expect(defaultElement.showExistingAttachments).toBe(false);

        document.body.textContent = "";
        const element = createUploader([], {
            accept: ".jpg,.png",
            label: "Profile photos",
            multiple: true,
            disabled: true
        });
        const input = element.querySelector("lightning-input");

        expect(input.label).toBe("Profile photos");
        expect(input.multiple).toBe(true);
        expect(input.accept).toBe(".jpg,.png");
        expect(input.disabled).toBe(true);
    });

    it("forwards validity methods to the file input", () => {
        const element = createUploader();
        const input = element.querySelector("lightning-input");
        input.reportValidity = jest.fn(() => false);
        input.checkValidity = jest.fn(() => false);
        input.setCustomValidity = jest.fn();

        expect(element.reportValidity()).toBe(false);
        expect(element.checkValidity()).toBe(false);
        element.setCustomValidity("Select a valid image.");

        expect(input.reportValidity).toHaveBeenCalledTimes(1);
        expect(input.checkValidity).toHaveBeenCalledTimes(1);
        expect(input.setCustomValidity).toHaveBeenCalledWith("Select a valid image.");
    });

    it("disables file selection in view mode when there is no saved record", () => {
        const element = createUploader([], {
            record: { Id: null },
            formAttributes: { editMode: false }
        });

        expect(element.querySelector("lightning-input").disabled).toBe(true);
        expect(element.querySelector("c-record-form-file-row")).toBeNull();
    });

    it("does not show or query existing attachments by default", async () => {
        const element = createUploader([], { record: { Id: RECORD_ID } });
        await flushPromises();

        expect(element.showExistingAttachments).toBe(false);
        expect(graphql.getLastConfig().variables).toEqual({ recordId: RECORD_ID, skipQuery: true });
        expect(element.querySelector("c-record-form-file-row")).toBeNull();
    });

    it("displays existing attached files as complete rows without remove buttons", async () => {
        const element = createUploader([], { record: { Id: RECORD_ID }, showExistingAttachments: true });
        await flushPromises();

        expect(graphql.getLastConfig().variables).toEqual({ recordId: RECORD_ID, skipQuery: false });

        graphql.emit({
            uiapi: {
                query: {
                    ContentDocumentLink: {
                        edges: [
                            {
                                node: {
                                    Id: "06Axx0000000001AAA",
                                    ContentDocument: {
                                        Id: "069xx0000000001AAA",
                                        Title: { value: "Zrzut ekranu 2026-09-03 145708.png" },
                                        FileExtension: { value: "png" },
                                        ContentSize: { value: 123 }
                                    }
                                }
                            }
                        ]
                    }
                }
            }
        });
        await flushPromises();

        const row = element.querySelector("c-record-form-file-row");
        expect(row.shadowRoot.textContent).toContain("Zrzut ekranu 2026-09-03 145708.png");
        expect(row.shadowRoot.textContent).toContain("123 B");
        expect(row.shadowRoot.querySelector("a").getAttribute("href")).toBe(
            `/lightning/r/ContentDocument/069xx0000000001AAA/view`
        );
        expect(row.shadowRoot.querySelector("lightning-progress-bar").value).toBe(100);
        const successIcon = Array.from(row.shadowRoot.querySelectorAll("lightning-icon")).find(
            (icon) => icon.iconName === "utility:success"
        );
        expect(successIcon).toBeDefined();
        expect(row.shadowRoot.querySelector("lightning-button-icon")).toBeNull();

        const fileLink = row.shadowRoot.querySelector("a");
        const clickEvent = new CustomEvent("click", { bubbles: true, cancelable: true });
        fileLink.dispatchEvent(clickEvent);

        expect(clickEvent.defaultPrevented).toBe(true);
        expect(mockNavigate).toHaveBeenCalledWith({
            type: "standard__namedPage",
            attributes: { pageName: "filePreview" },
            state: {
                recordIds: "069xx0000000001AAA",
                selectedRecordId: "069xx0000000001AAA"
            }
        });
    });

    it("skips the attachment query when the record ID is null", async () => {
        createUploader([], { record: { Id: null }, showExistingAttachments: true });
        await flushPromises();

        expect(graphql.getLastConfig().variables).toEqual({ recordId: "", skipQuery: true });
    });

    it("shows a removable file row before upload and removes it when clicked", async () => {
        const file = new File(["image data"], "photo.png", { type: "image/png" });
        const element = createUploader(file);
        await flushPromises();

        let row = element.querySelector("c-record-form-file-row");
        expect(row.shadowRoot.textContent).toContain("photo.png");
        expect(row.shadowRoot.textContent).toContain("10 B");
        expect(row.shadowRoot.querySelector("a")).toBeNull();
        const removeButton = row.shadowRoot.querySelector("lightning-button-icon");
        expect(removeButton).not.toBeNull();

        removeButton.dispatchEvent(new CustomEvent("click", { bubbles: true, composed: true }));
        await flushPromises();

        row = element.querySelector("c-record-form-file-row");
        expect(row).toBeNull();
    });

    it("starts uploading immediately when an existing record is in view mode", async () => {
        createContentDocumentAndVersion.mockResolvedValueOnce({ contentDocument: { id: CONTENT_DOCUMENT_ID } });
        createRecord.mockResolvedValueOnce({});
        const file = new File(["image data"], "photo.png", { type: "image/png" });
        const element = createUploader(file, {
            record: { Id: RECORD_ID },
            formAttributes: { editMode: false }
        });
        await flushPromises();

        expect(createContentDocumentAndVersion).toHaveBeenCalledTimes(1);
        expect(createRecord).toHaveBeenCalledTimes(1);
        const row = element.querySelector("c-record-form-file-row");
        expect(row.shadowRoot.querySelector("lightning-progress-bar").value).toBe(100);
        expect(row.shadowRoot.querySelector("a").getAttribute("href")).toBe(
            `/lightning/r/ContentDocument/${CONTENT_DOCUMENT_ID}/view`
        );
    });

    it.each([
        ["photo.JPG", "image"],
        ["screenshot.png", "image"],
        ["report.docx", "word"],
        ["spreadsheet.xlsx", "excel"],
        ["presentation.pptx", "ppt"],
        ["clip.mp4", "mp4"],
        ["document.pdf", "pdf"],
        ["unrecognized.filetype", "unknown"]
    ])("selects the %s doctype icon based on its extension", async (fileName, iconType) => {
        const file = new File(["file contents"], fileName);
        const element = createUploader(file);
        await flushPromises();

        const row = element.querySelector("c-record-form-file-row");
        expect(row.shadowRoot.querySelector("lightning-icon").iconName).toBe(`doctype:${iconType}`);
    });

    it("hides the remove button while uploading and displays completion progress", async () => {
        let resolveFileVersion;
        createContentDocumentAndVersion.mockReturnValueOnce(
            new Promise((resolve) => {
                resolveFileVersion = resolve;
            })
        );
        createRecord.mockResolvedValueOnce({});
        const file = new File(["image data"], "photo.png", { type: "image/png" });
        const element = createUploader(file);
        await flushPromises();

        let row = element.querySelector("c-record-form-file-row");
        expect(row.shadowRoot.querySelector("lightning-button-icon")).not.toBeNull();

        const uploadPromise = element.postSubmit({ data: { Id: RECORD_ID } });
        await flushPromises();

        expect(element.querySelector("lightning-input").disabled).toBe(true);
        expect(row.shadowRoot.querySelector("lightning-button-icon")).toBeNull();
        expect(row.shadowRoot.querySelector("lightning-progress-bar").value).toBe(20);

        resolveFileVersion({ contentDocument: { id: CONTENT_DOCUMENT_ID } });
        await uploadPromise;
        await flushPromises();

        const successIcon = Array.from(row.shadowRoot.querySelectorAll("lightning-icon")).find(
            (icon) => icon.iconName === "utility:success"
        );
        expect(successIcon).toBeDefined();
        expect(row.shadowRoot.querySelector("a").getAttribute("href")).toBe(
            `/lightning/r/ContentDocument/${CONTENT_DOCUMENT_ID}/view`
        );

        await flushPromises();

        const uploadedRow = element.querySelector("c-record-form-file-row");
        expect(uploadedRow.shadowRoot.textContent).toContain("photo.png");
        expect(uploadedRow.shadowRoot.querySelector("lightning-button-icon")).toBeNull();
    });

    it("moves completed uploads to uploaded files and Done dismisses the summary", async () => {
        const file = new File(["image data"], "photo.png", { type: "image/png" });
        const element = createUploader(file);
        await flushPromises();

        const row = element.querySelector("c-record-form-file-row");
        row.dispatchEvent(
            new CustomEvent("change", {
                detail: {
                    file: {
                        ...row.file,
                        contentDocumentId: CONTENT_DOCUMENT_ID,
                        status: "complete"
                    }
                },
                bubbles: true,
                composed: true
            })
        );
        await flushPromises();

        expect(element.querySelector("c-record-form-file-row").file.contentDocumentId).toBe(CONTENT_DOCUMENT_ID);
        await flushPromises();
        expect(element.querySelector("c-record-form-file-row").file.status).toBe("complete");
    });

    it("uploads all selected files concurrently", async () => {
        const files = [
            new File(["first image"], "first.png", { type: "image/png" }),
            new File(["second image"], "second.png", { type: "image/png" })
        ];
        createContentDocumentAndVersion
            .mockResolvedValueOnce({ contentDocument: { id: "069xx0000000001AAA" } })
            .mockResolvedValueOnce({ contentDocument: { id: "069xx0000000002AAA" } });
        createRecord.mockResolvedValue({});
        const element = createUploader(files, { multiple: true });
        await element.postSubmit({ data: { Id: RECORD_ID } });

        expect(createContentDocumentAndVersion).toHaveBeenCalledTimes(2);
        expect(createRecord).toHaveBeenCalledTimes(2);
    });

    it("does not upload files when no saved record is passed", async () => {
        const file = new File(["image data"], "photo.png", { type: "image/png" });
        const element = createUploader(file);

        await element.postSubmit({ data: undefined });

        expect(createContentDocumentAndVersion).not.toHaveBeenCalled();
        expect(createRecord).not.toHaveBeenCalled();
    });

    it("reports upload failures without treating the saved record as a failed submission", async () => {
        createContentDocumentAndVersion.mockRejectedValueOnce(new Error("Upload failed."));
        const file = new File(["image data"], "photo.png", { type: "image/png" });
        const element = createUploader(file);

        await expect(element.postSubmit({ data: { Id: RECORD_ID } })).resolves.toBeUndefined();
        await flushPromises();

        expect(Toast.show).toHaveBeenCalledWith(
            expect.objectContaining({
                label: "File upload failed",
                message: "Upload failed.",
                variant: "error"
            }),
            expect.anything()
        );
        const row = element.querySelector("c-record-form-file-row");
        expect(row.shadowRoot.textContent).toContain("photo.png");
        expect(row.shadowRoot.querySelector("lightning-button-icon")).not.toBeNull();
        const errorIcon = Array.from(row.shadowRoot.querySelectorAll("lightning-icon")).find(
            (icon) => icon.iconName === "utility:error"
        );
        expect(errorIcon).toBeDefined();
        expect(errorIcon.variant).toBe("error");
    });
});
