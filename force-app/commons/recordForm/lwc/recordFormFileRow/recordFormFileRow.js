// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import { api, LightningElement } from "lwc";
import { NavigationMixin } from "lightning/navigation";

const FILE_EXTENSION_ALIASES = {
    aac: "audio",
    aif: "audio",
    aiff: "audio",
    avi: "video",
    bmp: "image",
    doc: "word",
    docm: "word",
    docx: "word",
    dot: "word",
    dotx: "word",
    flac: "audio",
    gif: "image",
    heic: "image",
    heif: "image",
    jpeg: "image",
    jpg: "image",
    m4a: "audio",
    m4v: "video",
    mkv: "video",
    mov: "video",
    mp3: "audio",
    mpeg: "video",
    mpg: "video",
    oga: "audio",
    ogg: "audio",
    png: "image",
    pps: "slide",
    ppsx: "slide",
    pptm: "ppt",
    pptx: "ppt",
    tif: "image",
    tiff: "image",
    wav: "audio",
    webm: "video",
    webp: "image",
    wma: "audio",
    wmv: "video",
    xls: "excel",
    xlsm: "excel",
    xlsx: "excel",
    xlt: "excel",
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
    @api file;

    get fileDetails() {
        return this.file?.file ?? this.file ?? {};
    }

    get fileName() {
        return this.fileDetails.name ?? "";
    }

    get sizeLabel() {
        const size = this.fileDetails.size ?? 0;
        if (size < 1024) {
            return `${size} B`;
        }
        if (size < 1024 * 1024) {
            return `${Math.round(size / 1024)} KB`;
        }
        return `${(size / (1024 * 1024)).toFixed(1)} MB`;
    }

    get progressLabel() {
        return `${this.fileName} upload progress is ${this.file?.progress ?? 0}%`;
    }

    get fileUrl() {
        const documentId = this.file?.documentId ?? this.file?.contentDocumentId;
        return documentId ? `/lightning/r/ContentDocument/${documentId}/view` : undefined;
    }

    get iconName() {
        return `doctype:${this.iconType}`;
    }

    get iconType() {
        const extension = this.fileName.split(".").pop()?.toLowerCase();
        const iconType = FILE_EXTENSION_ALIASES[extension] ?? extension;
        return DOCTYPE_ICONS.has(iconType) ? iconType : "unknown";
    }

    get isComplete() {
        return this.file?.status === "complete";
    }

    get showRemoveButton() {
        return !this.disabled && !this.isComplete;
    }

    handleOpenFile(event) {
        event.preventDefault();
        const documentId = this.file?.documentId ?? this.file?.contentDocumentId;
        if (documentId) {
            this[NavigationMixin.Navigate]({
                type: "standard__namedPage",
                attributes: {
                    pageName: "filePreview"
                },
                state: {
                    recordIds: documentId,
                    selectedRecordId: documentId
                }
            });
        }
    }

    handleRemove() {
        this.dispatchEvent(new CustomEvent("remove", { detail: { fileId: this.file.id } }));
    }
}
