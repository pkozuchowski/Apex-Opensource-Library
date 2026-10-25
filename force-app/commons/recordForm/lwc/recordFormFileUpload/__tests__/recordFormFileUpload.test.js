// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import { createElement } from "lwc";
import { createContentDocumentAndVersion, createRecord } from "lightning/uiRecordApi";
import Toast from "lightning/toast";
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
        Object.assign(element, properties);
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

    it("shows a removable file row before upload and removes it when clicked", async () => {
        const file = new File(["image data"], "photo.png", { type: "image/png" });
        const element = createUploader(file);
        await flushPromises();

        let row = element.querySelector("c-record-form-file-row");
        expect(row.shadowRoot.textContent).toContain("photo.png");
        expect(row.shadowRoot.textContent).toContain("10 B");
        const removeButton = row.shadowRoot.querySelector("lightning-button-icon");
        expect(removeButton).not.toBeNull();

        removeButton.dispatchEvent(new CustomEvent("click", { bubbles: true, composed: true }));
        await flushPromises();

        row = element.querySelector("c-record-form-file-row");
        expect(row).toBeNull();
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
        expect(element.textContent).toContain("1 of 1 file uploaded");
        expect(element.querySelector("lightning-button").label).toBe("Done");
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
        const uploadFinished = jest.fn();
        element.addEventListener("uploadfinished", uploadFinished);

        await element.postSubmit({ data: { Id: RECORD_ID } });

        expect(createContentDocumentAndVersion).toHaveBeenCalledTimes(2);
        expect(createRecord).toHaveBeenCalledTimes(2);
        expect(uploadFinished).toHaveBeenCalledWith(
            expect.objectContaining({
                detail: {
                    files: [
                        { name: "first.png", documentId: "069xx0000000001AAA" },
                        { name: "second.png", documentId: "069xx0000000002AAA" }
                    ]
                }
            })
        );
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
    });
});
