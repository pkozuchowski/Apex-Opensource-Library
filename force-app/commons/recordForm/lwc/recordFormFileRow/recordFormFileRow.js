// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import {api, LightningElement} from "lwc";
import {NavigationMixin} from "lightning/navigation";
import {createContentDocumentAndVersion, createRecord} from "lightning/uiRecordApi";

const FILE_EXTENSION_ALIASES = {
    aac : "audio",
    aif : "audio",
    aiff: "audio",
    avi : "video",
    bmp : "image",
    doc : "word",
    docm: "word",
    docx: "word",
    dot : "word",
    dotx: "word",
    flac: "audio",
    gif : "image",
    heic: "image",
    heif: "image",
    jpeg: "image",
    jpg : "image",
    m4a : "audio",
    m4v : "video",
    mkv : "video",
    mov : "video",
    mp3 : "audio",
    mpeg: "video",
    mpg : "video",
    oga : "audio",
    ogg : "audio",
    png : "image",
    pps : "slide",
    ppsx: "slide",
    pptm: "ppt",
    pptx: "ppt",
    tif : "image",
    tiff: "image",
    wav : "audio",
    webm: "video",
    webp: "image",
    wma : "audio",
    wmv : "video",
    xls : "excel",
    xlsm: "excel",
    xlsx: "excel",
    xlt : "excel",
    xltx: "excel"
};

const DOCTYPE_ICONS = new Set([
    "ai",
    "attachment",
    "audio",
    "box_notes",
    "css",
    "csv",
    "eps",
    "excel",
    "exe",
    "flash",
    "gdoc",
    "gdocs",
    "gform",
    "gpres",
    "gsheet",
    "html",
    "image",
    "keynote",
    "library_folder",
    "link",
    "mp4",
    "overlay",
    "pack",
    "pages",
    "pdf",
    "ppt",
    "psd",
    "quip_doc",
    "quip_sheet",
    "quip_slide",
    "rtf",
    "shared_folder",
    "slack_canvas",
    "slack_list_item",
    "slack_lists",
    "slide",
    "stypi",
    "txt",
    "unknown",
    "vcf",
    "video",
    "visio",
    "webex",
    "word",
    "xml",
    "zip"
]);

export default class RecordFormFileRow extends NavigationMixin(LightningElement) {
    @api disabled = false;
    _file;
    progress = 0;
    errorMessage;

    @api
    get file() {
        return this._file;
    }

    set file(value) {
        this._file = {...value};
        this.progress = value?.status === "complete" ? 100 : value?.status === "uploading" ? 20 : 0;
    }

    get sizeLabel() {
        const size = this.file?.size;
        if (size < 1024) {
            return `${size} B`;
        }
        if (size < 1024 * 1024) {
            return `${Math.round(size / 1024)} KB`;
        }
        return `${(size / (1024 * 1024)).toFixed(1)} MB`;
    }

    get progressLabel() {
        return `${this.file.title} upload progress is ${this.progress}%`;
    }

    get fileUrl() {
        const documentId = this.file?.documentId;
        return documentId ? `/lightning/r/ContentDocument/${documentId}/view` : undefined;
    }

    get iconName() {
        return `doctype:${this.iconType}`;
    }

    get iconType() {
        const extension = this.file?.title?.split(".").pop()?.toLowerCase();
        const iconType = FILE_EXTENSION_ALIASES[extension] ?? extension;
        return DOCTYPE_ICONS.has(iconType) ? iconType : "unknown";
    }

    get isNew() {
        return this.file.status === "new" || this.file.status === "error";
    }

    get isComplete() {
        return this.file.status === "complete";
    }

    get isFailed() {
        return this.file.status === "error";
    }

    @api
    async upload(recordId) {
        if (this.file.status === "new" || this.file.status === "error") {
            this.file.status = "uploading";
            this.progress = 20;
            this.errorMessage = undefined;
            this.dispatchStatusChange();
            return this.uploadFileAndLink(recordId);
        }
        return undefined;
    }

    async uploadFileAndLink(recordId) {
        try {
            if (!this.file.documentId) {
                const result = await createContentDocumentAndVersion({
                    title   : this.file.title,
                    fileData: this.file.file
                });
                this.file.documentId = result.contentDocument.id;
                this.progress = 70;
            }

            await createRecord({
                apiName: "ContentDocumentLink",
                fields : {
                    LinkedEntityId   : recordId,
                    ContentDocumentId: this.file.documentId,
                    ShareType        : "V"
                }
            });

            this.file.status = "complete";
            this.progress = 100;
            this.dispatchStatusChange();
        } catch (error) {
            this.file.status = "error";
            this.errorMessage = error?.body?.message ?? error?.message ?? "Unable to upload this file.";
            this.dispatchStatusChange();
            throw error;
        }
    }

    dispatchStatusChange() {
        this.dispatchEvent(
            new CustomEvent("change", {
                detail  : {file: this.file},
                bubbles : true,
                composed: true
            })
        );
    }

    handleOpenFile(event) {
        event.preventDefault();
        if (this.file.documentId) {
            this[NavigationMixin.Navigate]({
                type      : "standard__namedPage",
                attributes: {
                    pageName: "filePreview"
                },
                state     : {
                    recordIds       : this.file.documentId,
                    selectedRecordId: this.file.documentId
                }
            });
        }
    }

    handleRemove() {
        this.dispatchEvent(new CustomEvent("remove", {detail: {fileId: this.file.id}}));
    }
}
