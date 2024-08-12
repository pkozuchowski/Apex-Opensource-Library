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
public inherited sharing virtual class Query {
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
    public static QueryObject fromSObject(SObjectType sObjectType) {
        return new QueryObject(sObjectType);
    }

    /**
     * This method takes the query directly, but returns mock if needed.
     * It's more realistic than full mocking, since access can be validated and limits are more realistic.
     */
    public static Query.Results of(List<SObject> results) {
        return new Query.Results(results);
    }

    /**
     * Mocks query result using either mockId or client's class name and method.
     * <pre>
     *     class AccountQuotingService{
     *         public void generateQuotes(Set<Id> accountIds){
     *              List<Account> accs = Query.Accounts.byId(accountIds).getList();
     *         }
     *     }
     *
     * </pre>
     *
     * In unit tests:
     * <pre>
     *     Query.mock('AccountQuotingService.generateQuotes', new List<Account>{});
     *     // or
     *     Query.Accounts.mock('AccountQuotingService.generateQuotes', mockedResults);
     * </pre>
    */
    public static void mock(String mockIdOrClientName, List<SObject> result) {
        mock(result.getSObjectType(), mockIdOrClientName, result);
    }

    /**
     * Mocks query result using either mockId or client's class name and method.
     * <pre>
     *     class AccountQuotingService{
     *         public void generateQuotes(Set<Id> accountIds){
     *              List<Account> accs = Query.Accounts.byId(accountIds).getList();
     *         }
     *     }
     *
     * </pre>
     *
     * In unit tests:
     * <pre>
     *     Query.mock(Account.SObjectType, 'AccountQuotingService.generateQuotes', mockedResults);
     *     // or
     *     Query.Accounts.mock('AccountQuotingService.generateQuotes', mockedResults);
     * </pre>
    */
    public static void mock(SObjectType sobjType, String mockIdOrClientName, Object result) {
        mockedSObjects.add(sobjType);
        mockedQueries.put('' + sobjType + '.' + mockIdOrClientName, result);
    }

    private final static Map<String, Object> mockedQueries = new Map<String, Object>();
    private final static Set<SObjectType> mockedSObjects = new Set<SObjectType>();


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
         * @return Key value under which SObject instance is cached - usually unique id field value.
         */
        Object getCacheValue();

        /**
         * @param remainder Cache values that did not have cached records.
         * @return Instance of Query.Condition that can retrieve records that were not found in cache.
         */
        Query.Condition getRemainderCondition(List<Object> remainder);
    }


    /**
     * Mockable wrapper for query results
     */
    public virtual class Results {
        protected List<SObject> result;
        protected SObjectType sObjType;
        protected String mockName = '';
        protected AccessType accessType = null;

        protected Results() {}

        protected Results(List<SObject> result) {
            this.result = result;
            this.sObjType = result.getSObjectType();
        }

        /**
         * Enforces Object and Field level security on records.
         * Inaccessible fields are stripped from result and inaccessible objects throws exception.
         *
         * @throws System.NoAccessException No access to entity when user does not have READ permission to sOObject
         */
        public Query.Results stripInaccessible(AccessType accessType) {
            this.accessType = accessType;
            return this;
        }

        /**
         * @return Id of first record or null if list has no results
         */
        public Id getFirstIdOrNull() {
            return getFirstOrNull()?.Id;
        }

        /**
         * Give this query unique name, which can be referenced in Unit Tests to mock results for named query.
         */
        public Query.Results withMockName(String mockName) {
            this.mockName = mockName;
            return this;
        }

        /**
         * @return Field of first record or null if list has no results
         */
        public Object getFirstFieldOrNull(SObjectField field) {
            return getFirstOrNull()?.get(field);
        }

        /**
         * @return Field of first record or fallback value if list has no results
         */
        public Object getFirstFieldOrFallback(SObjectField field, Object fallbackValue) {
            return getFirstOrNull()?.get(field) ?? fallbackValue;
        }


        /**
         * @return First and only record returned by query
         * @throws System.ListException if query did not return results
         */
        public virtual SObject getFirst() {
            return getList().get(0);
        }

        /**
         * @return First record or null if list has no results
         */
        public virtual SObject getFirstOrNull() {
            List<SObject> result = executeQuery();
            return result.isEmpty() ? null : result.get(0);
        }


        /**
         * @return List of SObjects for given conditions
         */
        public virtual SObject[] getList() {
            return executeQuery();
        }


        /**
         * @return Ids for SObjects
         */
        public Set<Id> getIds() {
            return getMapById().keySet();
        }

        /**
         * @return SObject map by Ids
         */
        public Map<Id, SObject> getMapById() {
            Map<Id, SObject> resultMap = (Map<Id, SObject>) Type.forName('Map<Id,' + sObjType + '>').newInstance();
            resultMap.putAll(getList());

            return resultMap;
        }

        /**
         * @return SObject map by unique string
         */
        public Map<String, SObject> getMapByString(SObjectField field) {
            return getMapByString('' + field);
        }

        /**
         * @return SObject map by unique string
         */
        public Map<String, SObject> getMapByString(String field) {
            Map<String, SObject> resultMap = (Map<String, SObject>) Type.forName('Map<String,' + sObjType + '>')
                .newInstance();

            for (SObject record : getList()) {
                String key = '' + record.get(field);
                resultMap.put(key, record);
            }

            return resultMap;
        }

        protected virtual SObject[] executeQuery() {
            this.result = (SObject[]) getMock() ?? result;

            if (accessType != null) {
                SObjectAccessDecision decision = Security.stripInaccessible(accessType, result);
                this.result = decision.getRecords();
            }

            return result;
        }

        /**
        * @return Mocked query results, if sObject was mocked and class that invoked query is mocked.
        */
        protected Object getMock() {
            String mockKey = '' + this.sObjType + '.' + mockName;

            if (Test.isRunningTest()
                && mockedSObjects.contains(this.sObjType)) {

                if (mockedQueries.containsKey(mockKey)) {
                    return mockedQueries.get(mockKey);

                } else {
                    for (Runtime.StackTraceLine line : Runtime.getStackTrace()) {
                        String mockName = '' + this.sObjType + '.' + line.apexClassMethod;

                        if (mockedQueries.containsKey(mockName)) {
                            return mockedQueries.get(mockName);
                        }
                    }
                }
            }

            return null;
        }
    }
}