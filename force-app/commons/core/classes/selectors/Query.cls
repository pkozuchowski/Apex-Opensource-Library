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
 * Facade for verbose selector queries:
 * Query.Accounts.byId(...);
 * Query.EmailTemplates.byDeveloperName('FirmQuote');
 */
public inherited sharing class Query {

    /**
     * Mocks query result for given selector type.
     * @param selectorType Type of selector (ex. AccountSelector.class
     * @param mock Implementation of SelectorQueryMock
     */
    public static void setMock(Type selectorType, SelectorQueryMock mock) {
        SelectorQuery.setMock(selectorType, mock);
    }


    public final static AccountSelector Accounts { get {return new AccountSelector();} }
    public final static AttachmentSelector Attachments { get {return new AttachmentSelector();} }
    public final static BusinessHoursSelector BusinessHours { get {return new BusinessHoursSelector();} }
    public final static CaseSelector Cases { get {return new CaseSelector();} }
    public final static ContactSelector Contacts { get {return new ContactSelector();} }
    public final static ContentDocumentSelector ContentDocuments { get {return new ContentDocumentSelector();} }
    public final static EmailMessageSelector EmailMessages { get {return new EmailMessageSelector();} }
    public final static EmailTemplateSelector EmailTemplates { get {return new EmailTemplateSelector();} }
    public final static EventSelector Events { get {return new EventSelector();} }
    public final static LeadSelector Leads { get {return new LeadSelector();} }
    public final static OpportunitySelector Opportunities { get {return new OpportunitySelector();} }
    public final static OrgWideEmailAddressSelector OrgWideEmailAddresses { get {return new OrgWideEmailAddressSelector();} }
    public final static PermissionSetSelector PermissionSets { get {return new PermissionSetSelector();} }
    public final static PricebookEntrySelector PricebookEntries { get {return new PricebookEntrySelector();} }
    public final static PricebookSelector Pricebooks { get {return new PricebookSelector();} }
    public final static ProductSelector Products { get {return new ProductSelector();} }
    public final static ProfileSelector Profiles { get {return new ProfileSelector();} }
    public final static QueueSelector Queues { get {return new QueueSelector();} }
    public final static RecordTypeSelector RecordTypes { get {return new RecordTypeSelector();} }
    public final static StaticResourceSelector StaticResources { get {return new StaticResourceSelector();} }
    public final static TaskSelector Tasks { get {return new TaskSelector();} }
    public final static UserRoleSelector UserRoles { get {return new UserRoleSelector();} }
    public final static UserSelector Users { get {return new UserSelector();} }

    public static ShareSelector SObjectShares(SObjectType shareSObjectType) {
        return new ShareSelector(shareSObjectType);
    }

    public static HistorySelector SObjectHistory(SObjectType shareSObjectType) {
        return new HistorySelector(shareSObjectType);
    }


    /**
     * Queries will be run in "without sharing" context
     */
    public static QueryWithoutSharing withoutSharing() {
        return new QueryWithoutSharing();
    }

    public without sharing class QueryWithoutSharing {
        public final AccountSelector Accounts { get {return (AccountSelector) new AccountSelector().withoutSharing();} }
        public final AttachmentSelector Attachments { get {return (AttachmentSelector) new AttachmentSelector().withoutSharing();} }
        public final CaseSelector Cases { get {return (CaseSelector) new CaseSelector().withoutSharing();} }
        public final ContactSelector Contacts { get {return (ContactSelector) new ContactSelector().withoutSharing();} }
        public final ContentDocumentSelector ContentDocuments { get {return (ContentDocumentSelector) new ContentDocumentSelector().withoutSharing();} }
        public final EmailMessageSelector EmailMessages { get {return (EmailMessageSelector) new EmailMessageSelector().withoutSharing();} }
        public final EmailTemplateSelector EmailTemplates { get {return (EmailTemplateSelector) new EmailTemplateSelector().withoutSharing();} }
        public final EventSelector Events { get {return (EventSelector) new EventSelector().withoutSharing();} }
        public final LeadSelector Leads { get {return (LeadSelector) new LeadSelector().withoutSharing();} }
        public final OpportunitySelector Opportunities { get {return (OpportunitySelector) new OpportunitySelector().withoutSharing();} }
        public final PricebookEntrySelector PricebookEntries { get {return (PricebookEntrySelector) new PricebookEntrySelector().withoutSharing();} }
        public final PricebookSelector Pricebooks { get {return (PricebookSelector) new PricebookSelector().withoutSharing();} }
        public final ProductSelector Products { get {return (ProductSelector) new ProductSelector().withoutSharing();} }
        public final StaticResourceSelector StaticResources { get {return (StaticResourceSelector) new StaticResourceSelector().withoutSharing();} }
        public final TaskSelector Tasks { get {return (TaskSelector) new TaskSelector().withoutSharing();} }
        public final UserSelector Users { get {return (UserSelector) new UserSelector().withoutSharing();} }

        public ShareSelector SObjectShares(SObjectType shareSObjectType) {
            return new ShareSelector(shareSObjectType);
        }

        public HistorySelector SObjectHistory(SObjectType shareSObjectType) {
            return new HistorySelector(shareSObjectType);
        }
    }

    private Query() {
    }
}