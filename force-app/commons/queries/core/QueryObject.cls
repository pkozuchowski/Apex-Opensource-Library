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
 * Base class for selectors. Contains query builder and common query methods.
 */
@JsonAccess(Serializable='never' Deserializable='never')
public virtual inherited sharing class QueryObject {
    private final static Map<String, Object> queryMocks = new Map<String, Object>();
    private final QueryCache cache;

    protected final QueryConditions conditionFactory = new QueryConditions();
    protected final QueryBuilder queryBuilder = new QueryBuilder();
    protected final DatabaseService databaseService = new DatabaseService();
    protected final List<Query.Condition> whereConditions = new List<Query.Condition>();
    protected final List<Query.Condition> havingConditions = new List<Query.Condition>();
    protected final SObjectType sObjectType;
    protected final QueryBindings bindings = new QueryBindings();

    private AccessType accessType = null;
    private Boolean useCache = !Test.isRunningTest();
    private Boolean saveResultsToCache = true;
    private String subqueryRelationshipName;
    private String mockName = '';
    private String mockKey {
        get {
            return '' + this.sObjectType + '.' + mockName;
        }
    }


    /**
     * Constructs QueryObject for given sObjectType without any fields selected.
     * @param sObjectType to query from
     */
    protected QueryObject(SObjectType sObjectType) {
        this.sObjectType = sObjectType;
        this.cache = getCache();
    }

    /**
     * Constructs QueryObject for given sObjectType and given fields selected.
     * @param fields to select
     * @param sObjectType to query from
     */
    protected QueryObject(List<String> fields, SObjectType sObjectType) {
        this(sObjectType);
        this.withFields(fields);
    }


    /**
     * Selects All, Custom or Standard fields.
     * Query is restricted to 200 records in case of ALL and CUSTOM fields.
     */
    public QueryObject withFields(Query.Fields field) {
        this.queryBuilder.addField(field);
        return this;
    }

    /**
     * Selects given fields
     * @param fields Comma separated fields ex. selectFields('Id, Name, Username')
     */
    public QueryObject withFields(String fields) {
        List<String> fieldsSplit = fields.deleteWhitespace().split(',');
        return withFields(fieldsSplit);
    }

    /**
     * Selects given fields
     */
    public QueryObject withFields(List<String> fields) {
        this.queryBuilder.addFields(fields);
        return this;
    }


    /**
     * Select all fields. Fields are retrieved from sObjectType describe and is different from selecting FIELDS(ALL)
     * as the FIELDS(ALL/STANDARD/CUSTOM) is restricted to 200 records
     */
    public QueryObject withAllFields() {
        List<SObjectField> allFields = sObjectType.getDescribe().fields.getMap().values();
        for (SObjectField sObjectField : allFields) {
            this.queryBuilder.addField('' + sObjectField);
        }
        return this;
    }


    /**
     * Adds subquery with given fields and relationship name.
     * Disables caching.
     */
    public QueryObject withChildren(String fieldsCSV, String relationshipName) {
        return withChildren(fieldsCSV.deleteWhitespace().split(','), relationshipName);
    }

    /**
     * Adds subquery with given fields and relationship name
     * Disables caching.
     */
    public QueryObject withChildren(List<String> fields, String relationshipName) {
        this.useCache = false;
        this.queryBuilder.addSubquery(fields, relationshipName);
        return this;
    }

    /**
     * Adds another query as subquery
     * Disables caching.
     */
    public QueryObject withChildren(QueryObject subquery, String relationshipName) {
        this.useCache = false;
        subquery.subqueryRelationshipName = relationshipName;
        queryBuilder.addSubquery(subquery.toSOQL(this.bindings));
        return this;
    }


    /**
     * Appends mock name. Query methods append to mock name and that name can be used to mock:
     * <pre>
     *     Query.Accounts
     *         .byRecordTypeId(...) // appends 'byRecordTypeId' mock name
     *         .byName(...)         // appends 'byName' mock Name
     * </pre>
     *
     * Then in tests:
     * <pre>
     *     Query.Accounts.mock('.byRecordTypeId.byName', mockedResults);
     * </pre>
     */
    protected QueryObject appendMockName(String mockName) {
        this.mockName += '.' + mockName;
        return this;
    }

    /**
     * Give this query unique name, which can be referenced in Unit Tests to mock results for named query.
     */
    public QueryObject withMockName(String mockName) {
        this.mockName = mockName;
        return this;
    }

    /**
     * @return Mocks output of the query with given result.
     *
     * Usage in Unit Test:
     * <pre>
     *     Query.Accounts.mock('byName', mockAccounts);
     * </pre>
     *
     * In business logic:
     * <pre>
     *     Query.Accounts.byName('Test').getList(); // returns mock accounts
     * </pre>
     */
    public QueryObject mock(String mockName, Object result) {
        queryMocks.put('' + this.sObjectType + '.' + mockName, result);
        return this;
    }

    /**
     * This method prints log with expected mock name.
     * Use this when in doubt what mocked name is expected.
     */
    public QueryObject debugLogMockName() {
        System.debug('Mock Name: \'' + mockName + '\'');
        return this;
    }


    /**
     * Sets limit on query
     */
    public QueryObject withLimit(Integer l) {
        this.queryBuilder.setLimit(l);
        return this;
    }

    /**
     * Sets limit on query
     */
    public QueryObject withOffset(Integer l) {
        this.queryBuilder.setOffset(l);
        return this;
    }


    /**
     * Sets group by on query
     */
    public QueryObject groupBy(String fields, String groupBy) {
        return groupBy(fields.split(','), groupBy);
    }

    /**
     * Sets group by on query
     */
    public QueryObject groupBy(List<String> fields, String groupBy) {
        this.useCache = false;
        this.queryBuilder.setFields(fields);
        this.queryBuilder.setGroupBy(groupBy);
        return this;
    }


    /**
     * Sets HAVING clause on group without any bindings
     * <pre>
     * .havingConditions('COUNT(ID) > 1');
     * </pre>
     */
    public QueryObject havingCondition(String fields) {
        return havingCondition(fields, new Map<String, Object>());
    }

    /**
     * Sets HAVING clause on group with explicit bindings
     * ex `.havingGroupings('COUNT(Id) < :i', new Map<String, Object>{'i' => 5})`
     */
    public QueryObject havingCondition(String fields, Map<String, Object> params) {
        return havingCondition(conditionFactory.wheres(fields, params));
    }

    /**
     * Sets given condition as HAVING clause
     * <pre>
     * QueryConditions c = new QueryConditions();
     * Query.Users
     *     .selectFields('COUNT(ID), Email')
     *     .havingConditions(
     *         c.ANDs(
     *             c.field('COUNT(ID)').greaterThan(5),
     *             c.field('COUNT(ID)').lessThan(10)
     *         )
     *     .toSOQL()
     * <pre>
     */
    public QueryObject havingCondition(Query.Condition condition) {
        this.useCache = false;
        this.saveResultsToCache = false;
        this.havingConditions.add(condition);
        return this;
    }


    /**
    * Extenders
    * */

    /**
     * Query will be executed in "without sharing" context, returning records
     * users does not usually have access to.
     *
     * Since there is no proper way to handle method chaining of builder pattern with inheritance in Apex,
     * this method should be reimplemented where it's needed as public XXXSelector withoutSharing();
     */
    public QueryObject withSharing(Sharing s) {
        databaseService.setSharing(s);
        return this;
    }


    /**
    * Selector will not use cached records to limit SOQLs query limit.
    *
    * Since there is no proper way to handle method chaining of builder pattern with inheritance in Apex,
    * this method should be reimplemented where it's needed as public XXXSelector withoutCache();
    * or used at the end of method chain.
    */
    public QueryObject usingCache(Boolean useCache) {
        this.useCache = useCache;
        return this;
    }


    /**
     * Enforces Object and Field level security on records.
     * Inaccessible fields are stripped from result and inaccessible objects throws exception.
     *
     * @throws System.NoAccessException No access to entity
     */
    public QueryObject withFieldAccess(AccessType accessType) {
        this.accessType = accessType;
        return this;
    }


    /**
     *
     * Common criteria methods
     *
     */

    /**
    * Filters records by Id
    */
    public virtual QueryObject byId(Id recordId) {
        return byId(new Set<Id>{recordId});
    }

    /**
    * Filters records by Id
    */
    public virtual QueryObject byId(List<SObject> records) {
        return byId(new Map<Id, SObject>(records).keySet());
    }

    /**
    * Filters records by Id
    */
    public virtual QueryObject byId(Set<Id> recordIds) {
        appendMockName('byId');
        return byField('Id', 'IN', recordIds);
    }


    /**
     * Filters records by Record Type Id
     */
    public virtual QueryObject byRecordTypeId(Id recordTypeId) {
        return byRecordTypeId(new Set<Id>{recordTypeId});
    }

    /**
     * Filters records by RecordTypeId
     */
    public virtual QueryObject byRecordTypeId(Set<Id> recordTypeId) {
        appendMockName('byRecordTypeId');
        return byField('RecordTypeId', 'IN', recordTypeId);
    }

    /**
     * Filters records by RecordTypeId
     */
    public virtual QueryObject byRecordTypeDeveloperName(String recordTypeDeveloperName) {
        return byRecordTypeDeveloperName(new Set<String>{recordTypeDeveloperName});
    }

    /**
     * Filters records by RecordTypeId
     */
    public virtual QueryObject byRecordTypeDeveloperName(Set<String> recordTypeDeveloperName) {
        appendMockName('byRecordTypeDeveloperName');
        return byField('RecordType.DeveloperName', 'IN', recordTypeDeveloperName);
    }


    /**
     * Filters records by OwnerId
     */
    public virtual QueryObject byOwnerId(Id ownerId) {
        return byOwnerId(new Set<Id>{ownerId});
    }

    /**
     * Filters records by OwnerId
     */
    public virtual QueryObject byOwnerId(Set<Id> ownerIds) {
        appendMockName('byOwnerId');
        return byField('OwnerId', 'IN', ownerIds);
    }


    /**
     * @example
     * <pre>
     * List<Account> accounts = Query.Accounts.relatedToChildren(contacts, Contact.AccountId);
     * </pre>
     *
     * @param childRecords List of children records for which oarent records are queried
     * @param relationShipField Parent field on records (ex. Contact.AccountId for Contacts children of Accounts)
     * @return List of parent records related to given child records by given field ex. Accounts related to given contacts
     */
    public virtual QueryObject relatedToChildren(SObject[] childRecords, SObjectField relationShipField) {
        return relatedToChildren(childRecords, '' + relationShipField);
    }

    public virtual QueryObject relatedToChildren(SObject[] childRecords, String relationShipField) {
        Set<Id> parentIds = new Set<Id>();

        for (SObject record : childRecords) {
            parentIds.add((Id) record.get(relationShipField));
        }

        return byField('Id', 'IN', parentIds);
    }


    /**
     * @example
     * <pre>
     * List<Contact> contacts = Query.Contacts.relatedToParent(accounts, Contact.AccountId);
     * </pre>
     *
     * @param parentRecords List of child records in relationship
     * @param relationShipField Parent field on records (ex. Contact.AccountId for list of Contacts)
     * @return List of child records related to given parent records by given field
     */
    public virtual QueryObject relatedToParent(SObject[] parentRecords, SObjectField relationShipField) {
        return byField(relationShipField, 'IN', new Map<Id, SObject>(parentRecords).keySet());
    }


    /**
     * @value Expected value or values (may be Set or List) of the field
     * @return SObjects with field values in given value set.
     */
    public virtual QueryObject byField(SObjectField field, String operator, Object value) {
        return byField('' + field, operator, value);
    }

    /**
     * @value Expected value or values (may be Set or List) of the field
     * @return SObjects with field values in given value set.
     */
    public virtual QueryObject byField(String fieldAPIName, String operator, Object value) {
        this.whereConditions.add(conditionFactory.field(fieldAPIName, operator, value));
        return this;
    }


    /**
     * Adds explicitly typed WHERE condition.
     * Example:
     * <pre>
     * this.wheres('ParentId IN :parentIds', new Map<String,Object>{'parentIds' => parentIds});
     * </pre>
     *
     * @param whereString Condition without WHERE keyword
     * @param params Bind variables present in WHERE clause
     */
    public QueryObject wheres(String whereString, Map<String, Object> params) {
        return wheres(conditionFactory.wheres(whereString, params));
    }

    /**
     * Adds WHERE clause to query conditions
     */
    public QueryObject wheres(Query.Condition wheres) {
        this.whereConditions.add(wheres);
        return this;
    }


    /**
     *
     * Query reducing methods
     *
     */


    /**
     * @return Id of first record or null if list has no results
     */
    public Id getFirstIdOrNull() {
        return getFirstOrNull()?.Id;
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
        Object val = getFirstOrNull()?.get(field);
        return val == null ? fallbackValue : val;
    }


    /**
     * @return First and only record returned by query
     * @throws System.ListException if query did not return results
     */
    public SObject getFirst() {
        this.queryBuilder.setLimit(1);
        List<SObject> result = executeQuery();
        return result.get(0);
    }

    /**
     * @return First record or null if list has no results
     */
    public SObject getFirstOrNull() {
        this.queryBuilder.setLimit(1);
        List<SObject> result = executeQuery();
        return result.isEmpty() ? null : result.get(0);
    }


    /**
     * @return List of SObjects for given conditions
     */
    public SObject[] getList() {
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
        Map<Id, SObject> resultMap = (Map<Id, SObject>) Type.forName('Map<Id,' + sObjectType + '>').newInstance();
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
        Map<String, SObject> resultMap = (Map<String, SObject>) Type.forName('Map<String,' + sObjectType + '>')
            .newInstance();

        for (SObject record : getList()) {
            String key = '' + record.get(field);
            resultMap.put(key, record);
        }

        return resultMap;
    }


    /**
     * @return Query Locator for current query
     */
    public Database.QueryLocator getQueryLocator() {
        this.queryBuilder
            .fromObject(sObjectType)
            .setWhere(compileConditions(whereConditions).toSOQL(bindings));

        return this.databaseService.getQueryLocator(queryBuilder.toSOQL(), bindings.getMap());
    }

    /**
    * @return Count of records
    */
    public Integer getCount() {
        if (queryMocks.containsKey(mockKey)) {
            return (Integer) queryMocks.get(mockKey);
        } else {
            queryBuilder.setFields(new List<String>{'COUNT(Id) cnt'});
            return (Integer) getList().get(0).get('cnt');
        }
    }


    /**
    * Fields returned by this method will be used to cache records.
    * Whenever possible, selector will use cached fields to
    */
    protected virtual QueryCache getCache() {
        return null;
    }


    /**
    * Executes query and caches results
    */
    protected SObject[] executeQuery() {
        try {
            List<SObject> result = getQueryResult();

            if (accessType != null) {
                SObjectAccessDecision decision = Security.stripInaccessible(accessType, result);
                result = decision.getRecords();
            }

            return result;
        } catch (Exception e) {
            System.debug(e.getStackTraceString());
            QueryException queryException = new QueryException();
            queryException.initCause(e);
            queryException.setMessage(e.getMessage() + '\n' + this.toString());
            throw queryException;
        }
    }

    private List<SObject> getQueryResult() {
        if (queryMocks.containsKey(mockKey)) {
            return (SObject[]) queryMocks.get(mockKey);
        }

        List<SObject> result = Runtime.newListOfItemType(sObjectType);
        Query.Condition compiledExpr = compileConditions(whereConditions);
        Boolean doQuery = true;

        if (canUseCache()) {
            compiledExpr = getCachedRecordsAndReturnRemainderCondition(result);
            doQuery = compiledExpr != null;
        }

        if (doQuery) {
            this.queryBuilder.setWhere(compiledExpr.toSOQL(bindings));
            this.queryBuilder.setHaving(compileConditions(havingConditions).toSOQL(bindings));
            this.queryBuilder.fromObject(sObjectType);
            SObject[] records = this.databaseService.query(queryBuilder.toSOQL(), bindings.getMap());

            if (cache != null && !(records instanceof AggregateResult[])) {
                cache.put(records);
            }

            records.addAll(result);
            return records;
        }

        return result;
    }


    /**
    * @return True, if selector can use cached records:
    * - Cache is not explicitly forbidden
    * - There is only 1 query criteria
    * - Criteria value is not blank
    * - Operator is either equals or IN
    * - Field is explicitly allowed for caching or Field is unique to use it for upsert (isIdLookup)
    */
    private Boolean canUseCache() {
        return this.useCache
            && this.cache != null
            && whereConditions.size() == 1
            && whereConditions.get(0) instanceof Query.CacheableCondition
            && ((Query.CacheableCondition) whereConditions.get(0)).isCacheable()
            && cache.isFieldCacheKey(((Query.CacheableCondition) whereConditions.get(0)).getCacheKey());
    }

    /**
     * @param result Query result to append cached records to
     * @return True if there's remainder with non-cached values and there has to be query on that.
     */
    private Query.Condition getCachedRecordsAndReturnRemainderCondition(List<SObject> result) {
        Query.Condition condition = whereConditions.get(0);
        Query.CacheableCondition cacheable = (Query.CacheableCondition) condition;
        QueryCache.Result cacheResult = cache.getCachedRecords(cacheable.getCacheKey(), cacheable.getCacheValue());

        result.addAll(cacheResult.cachedRecords.values());

        if (cacheResult.remainingValues.isEmpty()) {
            return null;

        } else {
            return cacheable.getRemainderCondition(cacheResult.remainingValues);
        }
    }

    private Query.Condition compileConditions(Query.Condition[] conditions) {
        if (conditions.isEmpty()) {
            return conditionFactory.blank();

        } else if (conditions.size() == 1) {
            return conditions.get(0);

        } else {
            return conditionFactory.ANDs(conditions);
        }
    }

    /**
     * @return SOQL representation of the Query
     */
    public String toSOQL() {
        return toSOQL(bindings);
    }

    private String toSOQL(QueryBindings bindings) {
        QueryBuilder copy = this.queryBuilder.clone();

        copy.setWhere(compileConditions(whereConditions).toSOQL(bindings));
        copy.setHaving(compileConditions(havingConditions).toSOQL(bindings));

        if (String.isNotBlank(subqueryRelationshipName)) {
            copy.fromObject(subqueryRelationshipName);
        } else {
            copy.fromObject(sObjectType);
        }

        return copy.toSOQL();
    }

    /**
     * @return Query Binding's value
     */
    @TestVisible
    private Object getBinding(String name) {
        return bindings.getMap().get(name);
    }

    /**
     * @return String representation of the Query (SQOL + Bindings)
     */
    public override String toString() {
        return new List<Object>{
            this.toSOQL(),
            bindings.getMap()
        }.toString();
    }
}