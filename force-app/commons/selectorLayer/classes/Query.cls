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
 * Facade for verbose SObject queries:
 * Query.Accounts.byId(...);
 * Query.EmailTemplates.byDeveloperName('FirmQuote');
 */
public inherited sharing class Query {
    public final static AccountQuery Accounts { get {return new AccountQuery();} }
    public final static AttachmentQuery Attachments { get {return new AttachmentQuery();} }
    public final static BusinessHoursQuery BusinessHours { get {return new BusinessHoursQuery();} }
    public final static CaseQuery Cases { get {return new CaseQuery();} }
    public final static ContactQuery Contacts { get {return new ContactQuery();} }
    public final static ContentDocumentQuery ContentDocuments { get {return new ContentDocumentQuery();} }
    public final static EmailMessageQuery EmailMessages { get {return new EmailMessageQuery();} }
    public final static EmailTemplateQuery EmailTemplates { get {return new EmailTemplateQuery();} }
    public final static EventQuery Events { get {return new EventQuery();} }
    public final static LeadQuery Leads { get {return new LeadQuery();} }
    public final static OpportunityQuery Opportunities { get {return new OpportunityQuery();} }
    public final static OrgWideEmailAddressQuery OrgWideEmailAddresses { get {return new OrgWideEmailAddressQuery();} }
    public final static PermissionSetQuery PermissionSets { get {return new PermissionSetQuery();} }
    public final static PricebookEntryQuery PricebookEntries { get {return new PricebookEntryQuery();} }
    public final static PricebookQuery Pricebooks { get {return new PricebookQuery();} }
    public final static ProductQuery Products { get {return new ProductQuery();} }
    public final static ProfileQuery Profiles { get {return new ProfileQuery();} }
    public final static QueueQuery Queues { get {return new QueueQuery();} }
    public final static RecordTypeQuery RecordTypes { get {return new RecordTypeQuery();} }
    public final static StaticResourceQuery StaticResources { get {return new StaticResourceQuery();} }
    public final static TaskQuery Tasks { get {return new TaskQuery();} }
    public final static UserRoleQuery UserRoles { get {return new UserRoleQuery();} }
    public final static UserQuery Users { get {return new UserQuery();} }

    public static ShareQuery SObjectShares(SObjectType shareSObjectType) {
        return new ShareQuery(shareSObjectType);
    }

    public static HistoryQuery SObjectHistory(SObjectType shareSObjectType) {
        return new HistoryQuery(shareSObjectType);
    }

    private Query() {
    }
}