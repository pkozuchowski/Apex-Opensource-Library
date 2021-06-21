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
public abstract inherited sharing class QueryObject {
    private final static QueryMocker mocker = QueryMocker.getInstance();
    private final static QueryCache cache = QueryCache.getInstance();

    protected final QueryConditionFactory conditionFactory = new QueryConditionFactory();
    protected final QueryBuilder queryBuilder = new QueryBuilder();
    protected final DatabaseService databaseService = new DatabaseService();
    protected final List<Query.Condition> conditions = new List<Query.Condition>();
    protected final SObjectType sObjectType;
    protected QueryBindings bindings = new QueryBindings();

    private Boolean useCache = !Test.isRunningTest();
    private AccessType accessType = null;
    private String subqueryRelationshipName;


    /**
     * Constructs QueryObject for given sObjectType without any fields selected.
     * @param sObjectType to query from
     */
    public QueryObject(SObjectType sObjectType) {
        this.sObjectType = sObjectType;
    }

    /**
     * Constructs QueryObject for given sObjectType and given fields selected.
     * @param fields to select
     * @param sObjectType to query from
     */
    public QueryObject(List<String> fields, SObjectType sObjectType) {
        this(sObjectType);
        this.queryBuilder.addFields(fields);
    }


    /**
     * Selects All, Custom or Standard fields.
     * Query is restricted to 200 records in case of ALL and CUSTOM fields.
     */
    public QueryObject selectFields(Query.Fields field) {
        this.queryBuilder.addField(field);
        return this;
    }

    /**
     * Selects given fields
     */
    public QueryObject selectFields(List<String> fields) {
        this.queryBuilder.setFields(fields);
        return this;
    }

    /**
     * Selects given fields
     * @param fields Comma separated fields ex. selectFields('Id, Name, Username')
     */
    public QueryObject selectFields(String fields) {
        List<String> fieldsSplit = fields.deleteWhitespace().split(',');
        this.queryBuilder.setFields(fieldsSplit);
        return this;
    }

    /**
     * Selects given fields
     */
    public QueryObject selectAdditionalFields(List<String> fields) {
        this.queryBuilder.addFields(fields);
        return this;
    }

    /**
     * Select all fields. Fields are retrieved from sObjectType describe and is different from selecting FIELDS(ALL) as the FIELDS(*) is restricted to 200 records
     */
    public QueryObject selectAllFields() {
        Set<String> allFields = sObjectType.getDescribe().fields.getMap().keySet();
        this.queryBuilder.setFields(new List<String>(allFields));
        return this;
    }


    /**
     * Adds subquery with given fields and relationship name.
     * Disables caching.
     */
    public QueryObject selectSubquery(String relationshipName, String fieldsCSV) {
        return selectSubquery(relationshipName, fieldsCSV.deleteWhitespace().split(','));
    }

    /**
     * Adds subquery with given fields and relationship name
     * Disables caching.
     */
    public QueryObject selectSubquery(String relationshipName, List<String> fields) {
        this.useCache = false;
        this.queryBuilder.addSubquery(relationshipName, fields);
        return this;
    }

    /**
     * Adds another query as subquery
     * Disables caching.
     */
    public QueryObject selectSubquery(String relationshipName, QueryObject subquery) {
        this.useCache = false;
        subquery.subqueryRelationshipName = relationshipName;
        subquery.bindings = this.bindings;
        queryBuilder.addSubquery(subquery.toSOQL());
        return this;
    }


    /**
     * Sets limit on query
     */
    public QueryObject limits(Integer l) {
        this.queryBuilder.setLimit(l);
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
    */
    public QueryObject useCache(Boolean useCache) {
        this.useCache = useCache;
        return this;
    }


    /**
     * Enforces Object and Field level security on records.
     * Inaccessible fields are stripped from result and inaccessible objects throws exception.
     *
     * @throws System.NoAccessException No access to entity
     */
    public QueryObject stripInaccessible(AccessType accessType) {
        this.accessType = accessType;
        return this;
    }


    /**
     *
     * Common criteria methods
     *
     */

    /**
    * @return Record by given Salesforce Id
    */
    public virtual QueryObject byId(Id recordId) {
        return byId(new Set<Id>{recordId});
    }

    /**
     * @param records SObjects with Ids
     * @return Records by given Salesforce Ids
     */
    public virtual QueryObject byId(List<SObject> records) {
        return byId(new Map<Id, SObject>(records).keySet());
    }

    /**
     * @param recordIds Set of Salesforce Ids
     * @return Records by given Salesforce Ids
     */
    public virtual QueryObject byId(Set<Id> recordIds) {
        return byField('Id', 'IN', recordIds);
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

        byId(parentIds);
        return this;
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
        this.conditions.add(conditionFactory.field(fieldAPIName, operator, value));
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
        this.conditions.add(wheres);
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
        return getFirstOrEmpty().Id;
    }

    /**
     * @return Field of first record or null if list has no results
     */
    public Object getFirstFieldOrNull(SObjectField field) {
        return getFirstOrEmpty().get(field);
    }

    /**
     * @return Field of first record or null if list has no results
     */
    public Object getFirstFieldOrFallback(SObjectField field, Object fallbackValue) {
        Object val = getFirstOrEmpty().get(field);
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
     * @return First record or empty record instance if list has no results
     */
    public SObject getFirstOrEmpty() {
        this.queryBuilder.setLimit(1);
        List<SObject> result = executeQuery();
        return result.isEmpty() ? sObjectType.newSObject(null, false) : result.get(0);
    }


    /**
     * @return List of SObjects for given conditions
     */
    public SObject[] getList() {
        return executeQuery();
    }


    /**
     * @return Collection of sObjects.
     * Remove this method if you are deploying Query without Collection library
     */
    public Collection getCollection() {
        return Collection.of(getList());
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
     * @return Query Locator for current query
     */
    public Database.QueryLocator getQueryLocator() {
        Query.Condition compiledExp = getCompiledCondition();
        this.queryBuilder.fromObject(sObjectType)
            .setWhere(compiledExp.toSOQL(bindings));

        return this.databaseService.getQueryLocator(queryBuilder.toSOQL(), bindings.getMap());
    }

    /**
    * @return Count of records
    */
    public Integer getCount() {
        return (Integer) getAggregatedResults('COUNT(Id) cnt').get(0).get('cnt');
    }

    /**
    * @return Records counted by given SObject field
    */
    public AggregateResult[] getAggregatedResults(String fields) {
        return getAggregatedResults(fields, null);
    }

    public AggregateResult[] getAggregatedResults(String fields, String groupBy) {
        return getAggregatedResults(fields, groupBy, null);
    }

    public AggregateResult[] getAggregatedResults(String fields, String groupBy, String havingClause) {
        if (String.isNotBlank(fields)) this.queryBuilder.setFields(new List<String>{fields});
        if (String.isNotBlank(groupBy))this.queryBuilder.setGroupBy(groupBy);
        if (String.isNotBlank(havingClause)) this.queryBuilder.setHaving(havingClause);

        this.queryBuilder.fromObject(sObjectType);

        Query.Condition compiledExp = getCompiledCondition();
        this.queryBuilder.setWhere(compiledExp.toSOQL(bindings));
        return this.databaseService.query(queryBuilder.toSOQL(), bindings.getMap());
    }


    /**
    * Fields returned by this method will be used to cache records.
    * Whenever possible, selector will use cached fields to
    */
    protected virtual Set<String> getFieldsToCacheBy() {
        return new Set<String>{'Id'};
    }


    /**
    * Executes query and caches results
    */
    protected SObject[] executeQuery() {
        try {
            Type thisQueryClass = Runtime.getType(this);

            if (mocker.isMocked(thisQueryClass)) {
                return mocker.getMock(thisQueryClass).mockQuery(getCompiledCondition());
            }

            List<SObject> result = getQueryResult();

            if (accessType != null) {
                SObjectAccessDecision decision = Security.stripInaccessible(accessType, result);
                result = decision.getRecords();
            }

            return result;
        } catch (Exception e) {
            QueryException queryException = new QueryException();
            queryException.initCause(e);
            queryException.setMessage(e.getMessage() + '\n' + this.toString());
            throw queryException;
        }
    }

    private List<SObject> getQueryResult() {
        List<SObject> result = Runtime.newListOfItemType(sObjectType);
        Query.Condition compiledExpr = getCompiledCondition();
        Boolean doQuery = true;

        if (canUseCache()) {
            compiledExpr = getCachedRecordsAndReturnRemainderCondition(result);
            doQuery = compiledExpr != null;
        }

        if (doQuery) {
            this.queryBuilder.setWhere(compiledExpr.toSOQL(bindings));
            this.queryBuilder.fromObject(sObjectType);
            SObject[] records = this.databaseService.query(queryBuilder.toSOQL(), bindings.getMap());
            result.addAll(records);

            if (!(records instanceof AggregateResult[])) {
                cache.put(sObjectType, getFieldsToCacheBy(), records);
            }
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
            && conditions.size() == 1
            && conditions.get(0) instanceof Query.CacheableCondition
            && ((Query.CacheableCondition) conditions.get(0)).isCacheable()
            && getFieldsToCacheBy().contains(((Query.CacheableCondition) conditions.get(0)).getCacheKey());
    }

    /**
     * @param result Query result to append cached records to
     * @return True if there's remainder with non-cached values and there has to be query on that.
     */
    private Query.Condition getCachedRecordsAndReturnRemainderCondition(List<SObject> result) {
        Query.Condition condition = conditions.get(0);
        Query.CacheableCondition cacheable = (Query.CacheableCondition) condition;
        QueryCache.Result cacheResult = cache.getCachedRecords(sObjectType, cacheable.getCacheKey(), cacheable.getCacheValue());

        result.addAll(cacheResult.cachedRecords.values());

        if (cacheResult.remainingValues.isEmpty()) {
            return null;

        } else {
            return cacheable.getRemainderCondition(cacheResult.remainingValues);
        }
    }

    private Query.Condition getCompiledCondition() {
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
        Query.Condition compiledExpr = getCompiledCondition();

        QueryBuilder copy = this.queryBuilder.clone();
        copy.setWhere(compiledExpr.toSOQL(bindings));

        if (String.isNotBlank(subqueryRelationshipName)) {
            copy.fromObject(subqueryRelationshipName);
        } else {
            copy.fromObject(sObjectType);
        }

        return copy.toSOQL();
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