// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import { createContentDocumentAndVersion, createRecord } from "lightning/uiRecordApi";

export async function createFileVersion(file) {
    const result = await createContentDocumentAndVersion({
        title: file.name,
        fileData: file
    });
    return result.contentDocument.id;
}

export function linkFileToRecord(recordId, contentDocumentId) {
    return createRecord({
        apiName: "ContentDocumentLink",
        fields: {
            LinkedEntityId: recordId,
            ContentDocumentId: contentDocumentId,
            ShareType: "V"
        }
    });
}
