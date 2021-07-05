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
@JsonAccess(Serializable='never' Deserializable='never')
public inherited sharing virtual class Query extends QueryObject {
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
    public final static PermissionSetAssignmentQuery PermissionSetAssignments { get {return new PermissionSetAssignmentQuery();} }
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


    /**
     * @return Query instance for generic SObjectType
     *
     */
    public static Query fromSObject(SObjectType sObjectType) {
        return new Query(sObjectType);
    }


    /**
     * Constructs Query for given sObjectType without any fields selected.
     * @param sObjectType to query from
     */
    protected Query(SObjectType sObjectType) {
        super(sObjectType);
    }

    /**
     * Constructs QueryObject for given sObjectType and given fields selected.
     * @param fields to select
     * @param sObjectType to query from
     */
    protected Query(List<String> fields, SObjectType sObjectType) {
        super(fields, sObjectType);
    }


    /**
     * Represents SOQL FIELDS() token which can be used to select group of fields
     * without knowing their names in advance.
     */
    public enum Fields {
        ALL,
        CUSTOM,
        STANDARD
    }

    public interface Condition {

        /**
         * @return String representation of WHERE condition.
         * Example: 'AccountId IN :recordIds'
         */
        String toSOQL(QueryBindings bindings);
    }


    /**
     * Represents WHERE clause condition expression that can be used in caching mechanism
     */
    public interface CacheableCondition {
        /**
         * @return True if condition can be used in cache mechanism
         */
        Boolean isCacheable();

        /**
         * @return Key under which Cache saves value-record pairs. Usually it's a field API Name.
         */
        String getCacheKey();

        /**
         * @return Key value udner which SObject instance is cached - usually unique id field value.
         */
        Object getCacheValue();

        /**
         * @param remainder Cache values that did not have cached records.
         * @return Instance of Query.Condition that can retrieve records that were not found in cache.
         */
        Query.Condition getRemainderCondition(List<Object> remainder);
    }


    /**
     * Implement this interface to mock selector query results in unit tests
     */
    public interface Mock {

        /**
         * When mock is set for selector, this method will be called to determine the query result.
         * Mock is supplied with information about query conditions
         *
         * @param condition Query condition - either single or composite
         * @return Mocked query result
         */
        SObject[] mockQuery();
    }
}