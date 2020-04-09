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
 * Selector layer for Document SObjects
 */
public with sharing class DocumentQuery extends QueryObject {
    public final static List<SObjectField> QUERIED_FIELDS = new List<SObjectField>{
            Document.Id,
            Document.AuthorId,
            Document.Body,
            Document.BodyLength,
            Document.ContentType,
            Document.Description,
            Document.DeveloperName,
            Document.FolderId,
            Document.Name,
            Document.Type,
            Document.Url
    };

    public DocumentQuery() {
        super(QUERIED_FIELDS, Document.SObjectType);
    }


    /**
     * @return Documents by given developer name
     */
    public Document[] byDeveloperName(String developerName) {
        return byField(Document.DeveloperName, '=', developerName);
    }

    /**
     * @return Documents by given developer names (List or Set)
     */
    public Document[] byDeveloperName(Iterable<String> developerNames) {
        return byField(Document.DeveloperName, 'IN', developerNames);
    }
}