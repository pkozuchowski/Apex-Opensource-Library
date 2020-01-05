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
    public final static AccountSelector Accounts { get {return new AccountSelector();} }
    public final static BusinessHoursSelector BusinessHours { get {return new BusinessHoursSelector();} }
    public final static CaseSelector Cases { get {return new CaseSelector();} }
    public final static ContactSelector Contacts { get {return new ContactSelector();} }
    public final static EmailTemplateSelector EmailTemplates { get {return new EmailTemplateSelector();} }
    public final static LeadSelector Leads { get {return new LeadSelector();} }
    public final static OpportunitySelector Opportunities { get {return new OpportunitySelector();} }
    public final static PermissionSetSelector PermissionSets { get {return new PermissionSetSelector();} }
    public final static PricebookSelector Pricebooks { get {return new PricebookSelector();} }
    public final static ProfileSelector Profiles { get {return new ProfileSelector();} }
    public final static QueueSelector Queues { get {return new QueueSelector();} }
    public final static RecordTypeSelector RecordTypes { get {return new RecordTypeSelector();} }
    public final static StaticResourceSelector StaticResources { get {return new StaticResourceSelector();} }
    public final static UserRoleSelector UserRoles { get {return new UserRoleSelector();} }
    public final static UserSelector Users { get {return new UserSelector();} }

    public static ShareSelector SObjectShares(SObjectType shareSObjectType) {
        return new ShareSelector(shareSObjectType);
    }

    public static HistorySelector SObjectHistory(SObjectType shareSObjectType) {
        return new HistorySelector(shareSObjectType);
    }
}