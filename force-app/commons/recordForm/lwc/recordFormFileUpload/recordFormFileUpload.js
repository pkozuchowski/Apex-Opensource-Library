// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import {api, wire} from "lwc";
import Toast from "lightning/toast";
import {gql, graphql} from "lightning/graphql";
import RecordFormComponent from "c/recordFormComponent";

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
    uploadedFiles = [];
    isUploading = false;
    showUploadSummary = false;
    uploadBatchTotal = 0;
    completedUploadCount = 0;
    nextFileId = 0;

    @wire(graphql, {query: CONTENT_DOCUMENT_LINKS_QUERY, variables: "$contentDocumentLinkVariables"})
    wiredContentDocumentLinks({data, errors}) {
        if (errors?.length) {
            this.showAttachmentLoadError(errors);
        } else if (data) {
            const edges = data.uiapi?.query?.ContentDocumentLink?.edges ?? [];
            this.uploadedFiles = edges.map(({node}) => this.mapExistingFile(node));
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
        return {
            id        : `existing-${contentDocument.Id}`,
            documentId: contentDocument.Id,
            title     : contentDocument.Title?.value ?? "",
            size      : contentDocument.ContentSize?.value ?? 0,
            progress  : 100,
            status    : "complete"
        };
    }

    /**
     * Upload selected files after the form successfully saves the record.
     * @param {{data?: Object}} result Submission result containing the saved record.
     * @returns {Promise<void>} Resolves after upload attempts complete.
     */
    @api
    async onAfterSubmit({data}) {
        if (data?.Id && !this.disabled && this.filesNeedUpload) {
            await this.startUpload(data.Id);
        }
    }

    /**
     * This component has no field value to initialize.
     * @returns {void}
     */
    @api connectField() {}

    /**
     * Remove any files that remain pending when the form returns to view mode.
     * @returns {void}
     */
    @api
    onEnterViewMode() {
        this.uploadBatchTotal -= this.pendingFiles.length;
        this.pendingFiles = [];
    }

    get isDisabled() {
        return this.disabled || this.isUploading || (!this.formAttributes?.editMode && !this.record?.Id);
    }

    get isFileRowDisabled() {
        return this.disabled || this.isUploading;
    }

    get filesNeedUpload() {
        return this.pendingFiles.some(({status}) => status !== "complete");
    }

    get uploadSummary() {
        return `${this.completedUploadCount} of ${this.uploadBatchTotal} file${this.uploadBatchTotal === 1 ? "" : "s"} uploaded`;
    }

    handleFilesInputChange(event) {
        const notCompletedFiles = this.pendingFiles.filter(({status}) => status !== "complete");
        const newFiles = Array.from(event.detail.files ?? [], (file) => ({
            id    : this.nextFileId++,
            file,
            title : file.name,
            size  : file.size,
            status: "new"
        }));
        this.pendingFiles = [...notCompletedFiles, ...newFiles];
        if (newFiles.length > 0) {
            if (!this.showUploadSummary) {
                this.uploadBatchTotal = 0;
                this.completedUploadCount = 0;
            }
            this.uploadBatchTotal += newFiles.length;
            this.showUploadSummary = true;
        }

        /*In View Mode, start upload immediately*/
        if (newFiles.length > 0 && this.record?.Id && !this.formAttributes?.editMode && !this.disabled) {
            this.startUpload(this.record.Id);
        }
    }

    async startUpload(recordId) {
        if (!recordId || this.disabled || this.isUploading || !this.filesNeedUpload) {
            return;
        }

        this.isUploading = true;
        try {
            await Promise.resolve();
            const rows = [...this.querySelectorAll("c-record-form-file-row[data-pending]")];
            await Promise.all(rows.map((row) => row.upload(recordId)));
        } catch (uploadError) {
            this.showUploadError(uploadError);
        } finally {
            this.isUploading = false;
        }
    }

    handleFileStatusChange(event) {
        const file = event.detail.file;
        if (file.status === "complete") {
            this.uploadedFiles = [...this.uploadedFiles, file];
            this.pendingFiles = this.pendingFiles.filter((f) => f.id !== file.id);
            this.completedUploadCount += 1;
        } else {
            this.pendingFiles = this.pendingFiles.map(old => old.id === file.id ? file : old);
        }
    }

    handleRemoveFile(event) {
        const fileId = event.detail.fileId;
        if (this.pendingFiles.some((file) => file.id === fileId)) {
            this.uploadBatchTotal -= 1;
        }
        this.pendingFiles = this.pendingFiles.filter((file) => file.id !== fileId);
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
