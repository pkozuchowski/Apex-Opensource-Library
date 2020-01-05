/**
* MIT License
*
* Copyright (c) 2019 Piotr Kożuchowski
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

/**
 * Selector layer for Content Document (Files)
 */
public with sharing class ContentDocumentSelector extends Selector {

    public ContentDocumentSelector() {
        super(new List<SObjectField>{
                ContentDocument.Id,
                ContentDocument.Title,
                ContentDocument.FileType

        }, ContentDocument.SObjectType);

        this.query.addParentFields(new List<SObjectField>{
                ContentVersion.Id,
                ContentVersion.ContentSize,
                ContentVersion.ContentUrl,
                ContentVersion.Description,
                ContentVersion.FileType,
                ContentVersion.TagCsv,
                ContentVersion.Title,
                ContentVersion.VersionData

        }, ContentDocument.LatestPublishedVersionId);
    }


    /**
     * @return Content Document with Latest Version linked to given record.
     */
    public ContentDocument[] byLinkedEntityId(Id linkedEntityId) {
        return byLinkedEntityId(new List<Id>{linkedEntityId});
    }

    /**
     * @return Content Document with Latest Version linked to given records (List of Set of ids)
     */
    public ContentDocument[] byLinkedEntityId(Iterable<Id> linkedEntityId) {
        List<ContentDocumentLink> links = Database.query('SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :linkedEntityId');

        Set<Id> documentIds = new Set<Id>();
        for (ContentDocumentLink link : links) {
            documentIds.add(link.ContentDocumentId);
        }

        return byId((Iterable<Id>) documentIds);
    }
}