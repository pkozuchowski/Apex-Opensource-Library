// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import {api, wire} from "lwc";
import Toast from "lightning/toast";
import {gql, graphql} from "lightning/graphql";
import RecordFormComponent from "c/recordFormComponent";
import {createFileVersion, linkFileToRecord} from "./recordFormFileUploadService";

const CONTENT_DOCUMENT_LINKS_QUERY = gql`
    query ContentDocumentLinks($recordId: ID!, $skipQuery: Boolean!) {
        uiapi {
            query {
                ContentDocumentLink(where: { LinkedEntityId: { eq: $recordId } }) @skip(if: $skipQuery) {
                    edges {
                        node {
                            Id
                            ContentDocument {
                                Id
                                Title {
                                    value
                                }
                                FileExtension {
                                    value
                                }
                                ContentSize {
                                    value
                                }
                            }
                        }
                    }
                }
            }
        }
    }
`;

export default class RecordFormFileUpload extends RecordFormComponent {
    @api accept;
    @api label = "Upload Files";
    @api multiple = false;
    @api showExistingAttachments = false;
    pendingFiles = [];
    existingFiles = [];
    completedFiles = [];
    isUploading = false;
    nextFileId = 0;

    @wire(graphql, {query: CONTENT_DOCUMENT_LINKS_QUERY, variables: "$contentDocumentLinkVariables"})
    wiredContentDocumentLinks({data, errors}) {
        if (errors?.length) {
            if (this.showExistingAttachments && this.record?.Id) {
                this.showAttachmentLoadError(errors);
            }
        } else if (data) {
            if (!this.showExistingAttachments || !this.record?.Id) {
                return;
            }
            const edges = data.uiapi?.query?.ContentDocumentLink?.edges ?? [];
            this.existingFiles = edges.map(({node}) => this.mapExistingFile(node));
        }
    }

    get contentDocumentLinkVariables() {
        const recordId = this.record?.Id;
        return {
            recordId : recordId ?? "",
            skipQuery: !this.showExistingAttachments || !recordId
        };
    }

    mapExistingFile(node) {
        const contentDocument = node.ContentDocument;
        const title = contentDocument.Title?.value ?? "";
        const fileExtension = contentDocument.FileExtension?.value;
        const fileName =
            fileExtension && !title.toLowerCase().endsWith(`.${fileExtension.toLowerCase()}`)
                ? `${title}.${fileExtension}`
                : title;

        return {
            id        : `existing-${contentDocument.Id}`,
            documentId: contentDocument.Id,
            name      : fileName,
            size      : contentDocument.ContentSize?.value ?? 0,
            progress  : 100,
            status    : "complete"
        };
    }

    @api
    async postSubmit({data}) {
        if (data?.Id && !this.disabled && this.pendingFiles.some(({status}) => status !== "complete")) {
            await this.startUpload(data.Id);
        }
    }

    @api connectField() {}

    get existingAttachmentRows() {
        return this.showExistingAttachments && this.record?.Id ? this.existingFiles : [];
    }

    get completedUploadRows() {
        const existingDocumentIds = new Set(this.existingAttachmentRows.map(({documentId}) => documentId));
        return this.completedFiles.filter(({documentId}) => !existingDocumentIds.has(documentId));
    }

    get isDisabled() {
        return this.disabled || this.isUploading || (!this.formAttributes?.editMode && !this.record?.Id);
    }

    get isFileRowDisabled() {
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
        if (this.isDisabled) {
            return;
        }
        const completedFiles = this.pendingFiles.filter(({status}) => status === "complete");
        const newFiles = Array.from(event.detail.files ?? [], (file) => ({
            id      : this.nextFileId++,
            file,
            progress: 0,
            status  : "ready"
        }));
        this.pendingFiles = [...completedFiles, ...newFiles];
        if (newFiles.length > 0 && this.record?.Id && !this.formAttributes?.editMode && !this.disabled) {
            this.startUpload(this.record.Id);
        }
    }

    handleRemoveFile(event) {
        if (this.isFileRowDisabled) {
            return;
        }
        const fileId = event.detail.fileId;
        this.pendingFiles = this.pendingFiles.filter((file) => file.id !== fileId);
        if (!this.pendingFiles.some(({status}) => status !== "complete")) {
            this.refs.input.value = null;
        }
    }

    handleDone() {
        const existingDocumentIds = new Set([
            ...this.existingFiles.map(({documentId}) => documentId),
            ...this.completedFiles.map(({documentId}) => documentId)
        ]);
        const uploadedFiles = this.pendingFiles
            .filter(({status}) => status === "complete")
            .filter(({contentDocumentId}) => !existingDocumentIds.has(contentDocumentId))
            .map(({contentDocumentId, file}) => ({
                id        : `existing-${contentDocumentId}`,
                documentId: contentDocumentId,
                name      : file.name,
                size      : file.size,
                progress  : 100,
                status    : "complete"
            }));
        this.completedFiles = [...this.completedFiles, ...uploadedFiles];
        this.pendingFiles = [];
    }

    async startUpload(recordId) {
        if (
            !recordId ||
            this.disabled ||
            this.isUploading ||
            !this.pendingFiles.some(({status}) => status !== "complete")
        ) {
            return;
        }

        this.isUploading = true;
        try {
            await this.uploadSelectedFiles(recordId);
        } catch (uploadError) {
            this.showUploadError(uploadError);
        } finally {
            this.isUploading = false;
        }
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

    showAttachmentLoadError(errors) {
        console.error("Error fetching files attached to record", errors);
        Toast.show(
            {
                label  : "Unable to load attached files",
                message: errors.map(({message}) => message).join("; "),
                variant: "error"
            },
            this
        );
    }
}
