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
 * Selector layer for Email Message SObjects
 */
public with sharing class EmailMessageQuery extends QueryObject {
    public final static List<SObjectField> QUERIED_FIELDS = new List<SObjectField>{
            EmailMessage.Id,
            EmailMessage.ActivityId,
            EmailMessage.BccAddress,
            EmailMessage.CcAddress,
            EmailMessage.EmailTemplateId,
            EmailMessage.FromAddress,
            EmailMessage.FromName,
            EmailMessage.HasAttachment,
            EmailMessage.HtmlBody,
            EmailMessage.Incoming,
            EmailMessage.IsBounced,
            EmailMessage.ParentId,
            EmailMessage.Status,
            EmailMessage.Subject,
            EmailMessage.Subject,
            EmailMessage.TextBody,
            EmailMessage.ToAddress
    };

    public EmailMessageQuery() {
        super(QUERIED_FIELDS, EmailMessage.SObjectType);
    }


    /**
     * @return Email Messages associated with given record
     */
    public EmailMessage[] byParentId(Id parentId) {
        return byField(EmailMessage.ParentId, '=', parentId);
    }

    /**
     * @return Email Messages associated with given records (List or Set)
     */
    public EmailMessage[] byParentId(Iterable<Id> parentIds) {
        return byField(EmailMessage.ParentId, 'IN', parentIds);
    }
}