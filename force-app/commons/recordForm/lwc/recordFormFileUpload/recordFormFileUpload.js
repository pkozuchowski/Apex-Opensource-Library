// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import {api} from "lwc";
import Toast from "lightning/toast";
import RecordFormComponent from "c/recordFormComponent";
import {createFileVersion, linkFileToRecord} from "./recordFormFileUploadService";

export default class RecordFormFileUpload extends RecordFormComponent {
    @api accept;
    @api label = "Upload Files";
    @api multiple = false;
    pendingFiles = [];
    isUploading = false;
    nextFileId = 0;

    @api
    async postSubmit({data}) {
        if (data?.Id && !this.disabled && this.pendingFiles.some(({status}) => status !== "complete")) {
            this.isUploading = true;
            try {
                await this.uploadSelectedFiles(data.Id);
            } catch (uploadError) {
                this.showUploadError(uploadError);
            } finally {
                this.isUploading = false;
            }
        }
    }

    @api connectField({}) {}

    get isDisabled() {
        return this.disabled || this.isUploading;
    }

    get allFilesUploaded() {
        return this.pendingFiles.length > 0 && this.pendingFiles.every(({status}) => status === "complete");
    }

    get uploadSummary() {
        const uploadedCount = this.pendingFiles.filter(({status}) => status === "complete").length;
        const totalCount = this.pendingFiles.length;
        return `${uploadedCount} of ${totalCount} file${totalCount === 1 ? "" : "s"} uploaded`;
    }

    handleFilesInputChange(event) {
        const completedFiles = this.pendingFiles.filter(({status}) => status === "complete");
        const newFiles = Array.from(event.detail.files ?? [], (file) => ({
            id      : this.nextFileId++,
            file,
            progress: 0,
            status  : "ready"
        }));
        this.pendingFiles = [...completedFiles, ...newFiles];
    }

    handleRemoveFile(event) {
        if (this.isDisabled) {
            return;
        }
        const fileId = event.detail.fileId;
        this.pendingFiles = this.pendingFiles.filter((file) => file.id !== fileId);
        if (!this.pendingFiles.some(({status}) => status !== "complete")) {
            this.refs.input.value = null;
        }
    }

    handleDone() {
        this.pendingFiles = [];
    }

    async uploadSelectedFiles(recordId) {
        const results = await Promise.all(
            this.pendingFiles
                .filter(({status}) => status !== "complete")
                .map(async (pendingFile) => {
                    try {
                        return {
                            status: "fulfilled",
                            file  : await this.uploadFileAndLinkToRecord(recordId, pendingFile)
                        };
                    } catch (reason) {
                        return {status: "rejected", reason};
                    }
                })
        );

        const uploadedFiles = results.filter((result) => result.status === "fulfilled").map((result) => result.file);
        if (uploadedFiles.length > 0) {
            this.dispatchUploadFinished(uploadedFiles);
        }
        if (!this.pendingFiles.some(({status}) => status !== "complete")) {
            this.refs.input.value = null;
        }

        const failedUpload = results.find((result) => result.status === "rejected");
        if (failedUpload) {
            throw failedUpload.reason;
        }
    }

    async uploadFileAndLinkToRecord(recordId, pendingFile) {
        this.updateFile(pendingFile.id, {status: "uploading", progress: 20});
        let contentDocumentId = pendingFile.contentDocumentId;
        try {
            if (!contentDocumentId) {
                contentDocumentId = await createFileVersion(pendingFile.file);
                this.updateFile(pendingFile.id, {contentDocumentId, progress: 70});
            }

            await linkFileToRecord(recordId, contentDocumentId);
            this.updateFile(pendingFile.id, {status: "complete", progress: 100});
            return {name: pendingFile.file.name, documentId: contentDocumentId};
        } catch (error) {
            this.updateFile(pendingFile.id, {status: "failed"});
            throw error;
        }
    }

    updateFile(fileId, updates) {
        this.pendingFiles = this.pendingFiles.map((file) => (file.id === fileId ? {...file, ...updates} : file));
    }

    dispatchUploadFinished(files) {
        this.dispatchEvent(
            new CustomEvent("uploadfinished", {
                detail  : {files},
                bubbles : true,
                composed: true
            })
        );
    }

    showUploadError(error) {
        Toast.show(
            {
                label  : "File upload failed",
                message: error?.body?.message ?? error?.message ?? "Unable to upload the selected file.",
                variant: "error"
            },
            this
        );
    }
}
