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
public virtual inherited sharing class QueryObject extends QueryResults {
    protected final QueryConditions conditionFactory = new QueryConditions();
    protected final QueryBuilder queryBuilder = new QueryBuilder();
    protected final DatabaseService databaseService = new DatabaseService().asSystem();
    protected final List<QueryConditions.Condition> whereConditions = new List<QueryConditions.Condition>();
    protected final List<QueryConditions.Condition> havingConditions = new List<QueryConditions.Condition>();
    protected final QueryBindings bindings = new QueryBindings();

    private AccessType accessType = null;
    private QueryCache cache;
    private Boolean useCache = !Test.isRunningTest();
    private Boolean saveResultsToCache = true;
    private String subqueryRelationshipName;
    private String filterLogic;


    /**
     * Constructs QueryObject for given sObjectType without any fields selected.
     * @param sObjectType to query from
     */
    public QueryObject(SObjectType sObjectType) {
        this.sObjType = sObjectType;
        this.cache = QueryCache.get(sObjectType);
    }

    /**
     * Constructs QueryObject for given sObjectType and given fields selected.
     * @param fields to select
     * @param sObjectType to query from
     */
    public QueryObject(List<String> fields, SObjectType sObjectType) {
        this(sObjectType);
        this.withFields(fields);
    }

    /**
     * Constructs QueryObject for given sObjectType and given fields selected.
     */
    public QueryObject(List<SObjectField> fields, SObjectType sObjectType) {
        this(sObjectType);
        this.withFields(fields);
    }

    /**
     * Selects Standard sObject fields using FIELDS(STANDARD)
     */
    public QueryObject withStandardFields() {
        this.queryBuilder.setFields(new Set<String>{'FIELDS(STANDARD)'});
        return this;
    }

    /**
     * Selects given fields
     * @param fields Comma separated fields ex. selectFields('Id, Name, Username')
     */
    public QueryObject withFields(String fields) {
        List<String> fieldsSplit = fields.trim().split('\\s*,\\s*');
        return withFields(fieldsSplit);
    }

    /**
     * Selects given fields
     */
    public QueryObject withFields(Iterable<String> fields) {
        this.queryBuilder.addFields(fields);
        return this;
    }

    /**
     * Selects given fields
     */
    public QueryObject withFields(List<SObjectField> fields) {
        this.queryBuilder.addFields(fields);
        return this;
    }

    /**
     * Adds all fields from given fieldset.
     */
    public QueryObject withFieldSet(String fieldsetDevName) {
        FieldSet fieldSet = sObjType.getDescribe().fieldSets.getMap().get(fieldsetDevName);
        if (fieldSet == null) {
            throw new QueryException('Invalid FieldSet: ' + fieldsetDevName);

        } else {
            for (FieldSetMember field : fieldSet.getFields()) {
                queryBuilder.addField(field.getFieldPath());
            }
        }
        return this;
    }

    /**
     * Removes given fields from the query.
     * @param fields fields to remove
     */
    public QueryObject withoutFields(List<String> fields) {
        this.queryBuilder.removeFields(fields);
        return this;
    }


    /**
     * Select all fields. Fields are retrieved from sObjectType describe and is different from selecting FIELDS(ALL)
     * as the FIELDS(ALL/STANDARD/CUSTOM) is restricted to 200 records
     */
    public QueryObject withAllFields() {
        List<SObjectField> sObjectField = sObjType.getDescribe().fields.getMap().values();
        Set<String> excluded = new Set<String>{'SystemModstamp'};

        for (Integer i = 0; i < sObjectField.size(); i++) {
            String field = '' + sObjectField[i];

            if (!excluded.contains(field)) {
                queryBuilder.addField(field);
            }
        }

        return this;
    }

    /**
     * Adds lookup fields with given relationship name and parent fields.
     */
    public QueryObject withLookup(String relationshipName, List<SObjectField> parentFields) {
        queryBuilder.addFields(relationshipName, parentFields);
        return this;
    }

    /**
     * Adds lookup fields with given relationship name and parent fields.
     */
    public QueryObject withLookup(String relationshipName, Iterable<String> parentFields) {
        queryBuilder.addFields(relationshipName, parentFields);
        return this;
    }

    /**
     * Adds subquery with given fields and relationship name.
     * Disables caching.
     */
    public QueryObject withChildren(String fieldsCSV, String relationshipName) {
        return withChildren(fieldsCSV.trim().split('\\s*,\\s*'), relationshipName);
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
     * Adds subquery with given fields and relationship name
     * Disables caching.
     */
    public QueryObject withChildren(List<SObjectField> fields, String relationshipName) {
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
    public void mock(String mockId, Object result) {
        Query.mock(this.sObjType, mockId, result);
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
        return groupBy(fields.split('\\s*,\\s*'), groupBy);
    }

    /**
     * Sets group by on query
     */
    public QueryObject groupBy(List<String> fields, String groupBy) {
        this.queryBuilder.setFields(new Set<String>(fields));
        return groupBy(groupBy);
    }

    /**
     * Sets group by on query
     */
    public QueryObject groupBy(String groupBy) {
        this.useCache = false;
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
    public QueryObject havingCondition(QueryConditions.Condition condition) {
        this.useCache = false;
        this.saveResultsToCache = false;
        this.havingConditions.add(condition);
        return this;
    }

    /**
    * Update records with information about when they were last viewed.
    */
    public QueryObject forView() {
        this.queryBuilder.setFor('FOR VIEW');
        return this;
    }

    /**
    * Update records with information about when they were last referenced on related list view.
    */
    public QueryObject forReference() {
        this.queryBuilder.setFor('FOR REFERENCE');
        return this;
    }

    /**
    * Locks records while they’re being updated in order to prevent race conditions and other thread safety problems.
    */
    public QueryObject forUpdate() {
        this.queryBuilder.setFor('FOR UPDATE');
        return this;
    }


    /**
    * Extenders
    * */

    /**
     * Enforces Object and Field level security on records and enforced sharing rules.
     * @throws System.NoAccessException No access to entity when user does not have READ permission to sOObject
     * or any of the fields
     */
    public QueryObject asUser() {
        this.databaseService.asUser();
        return this;
    }

    /**
     * DEVELOPER PREVIEW
     * Enforces Object and Field level security on records and enforced sharing rules.
     * Permission Set permissions are added on top of user permissions.
     */
    public QueryObject asUserWithPermissionSetId(Id permissionSetId) {
        this.databaseService.asUserWithPermissionSetId(permissionSetId);
        return this;
    }

    /**
     * Query will ignore Object and Field Level security and inherit sharing from calling class.
     */
    public QueryObject asSystem() {
        this.databaseService.asSystem();
        return this;
    }

    /**
     * Query will ignore Object and Field Level security, but will enforce record access.
     */
    public QueryObject asSystemWithSharing() {
        this.databaseService.asSystemWithSharing();
        return this;
    }

    /**
     * Query will ignore Object, Field Level security and sharing rules, giving access to all records.
     */
    public QueryObject asSystemWithoutSharing() {
        this.databaseService.asSystemWithoutSharing();
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
     * @throws System.NoAccessException No access to entity when user does not have READ permission to sOObject
     * or any of the fields
     */
    public QueryObject withAccessLevel(AccessLevel accessLevel) {
        this.databaseService.withAccessLevel(accessLevel);
        return this;
    }


    /**
     * Provide filter logic for previously specified conditions
     *
     * @example
     * Query.Accounts
     *  .byName('TestName')
     *  .byRecordTypeDeveloperName('DeveloperName')
     *  .byOwnerId(UserInfo.getUserId())
     *  .withFilterLogic('{0} OR ({1} AND {2})')
     *  .getList();
     */
    public QueryObject withFilterLogic(String filterLogic) {
        this.filterLogic = filterLogic;
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
    public virtual QueryObject byId(Iterable<Id> recordIds) {
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
    public virtual QueryObject byRecordTypeId(Iterable<Id> recordTypeId) {
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
    public virtual QueryObject byRecordTypeDeveloperName(Iterable<String> recordTypeDeveloperName) {
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
    public virtual QueryObject byOwnerId(Iterable<Id> ownerIds) {
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
    public QueryObject wheres(QueryConditions.Condition wheres) {
        this.whereConditions.add(wheres);
        return this;
    }


    /**
     * Adds ORDER By clause to the query
     * ex. .orderBy('CreatedDate DESC');`
     */
    public QueryObject orderBy(SObjectField field, Boolean ascending, Boolean nullFirst) {
        return orderBy(field.toString(), ascending, nullFirst);
    }

    /**
     * Adds ORDER By clause to the query
     * ex. .orderBy('CreatedDate DESC');`
     */
    public QueryObject orderBy(String field, Boolean ascending, Boolean nullFirst) {
        return orderBy(String.format('{0} {1} NULLS {2}', new List<Object>{
            field,
            ascending ? 'ASC' : 'DESC',
            nullFirst ? 'FIRST' : 'LAST'
        }));
    }

    /**
     * Adds ORDER By clause to the query
     * ex. .orderBy('CreatedDate DESC');`
     */
    public QueryObject orderBy(String orderByClause) {
        this.queryBuilder.orderBy(orderByClause);
        return this;
    }


    /**
     *
     * Query reducing methods
     *
     */

    /**
     * @return First and only record returned by query
     * @throws System.ListException if query did not return results
     */
    public override SObject getFirst() {
        this.queryBuilder.setLimit(1);
        return super.getFirst();
    }

    /**
     * @return First record or null if list has no results
     */
    public override SObject getFirstOrNull() {
        this.queryBuilder.setLimit(1);
        return super.getFirstOrNull();
    }


    /**
     * @return Query Locator for current query
     */
    public Database.QueryLocator getQueryLocator() {
        return this.databaseService.getQueryLocator(toSOQL(), bindings.getMap());
    }

    /**
     * @return Database.Cursor for current query.
     */
    public Database.Cursor getCursor() {
        return this.databaseService.getCursor(toSOQL(), bindings.getMap());
    }

    /**
    * @return Count of records
    */
    public Integer getCount() {
        Object mock = getMock();

        if (mock == null) {
            queryBuilder.setFields(new Set<String>{'COUNT(Id) cnt'});
            return (Integer) getList().get(0).get('cnt');

        } else if (mock instanceof List<SObject>) {
            return ((List<SObject>) mock).size();

        } else {
            return (Integer) mock;
        }
    }

    protected override Object getQueryResult() {
        List<SObject> result = Runtime.newListOfItemType(sObjType);
        QueryConditions.Condition compiledExpr = compileConditions(whereConditions);
        Boolean doQuery = true;

        if (canUseCache()) {
            compiledExpr = getCachedRecordsAndReturnRemainderCondition(result);
            doQuery = compiledExpr != null;
        }

        if (doQuery) {
            this.queryBuilder
                .setWhere(compiledExpr.toSOQL(bindings))
                .setHaving(compileConditions(havingConditions).toSOQL(bindings))
                .fromObject(sObjType)
                .toSOQL();

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
            && whereConditions.get(0) instanceof QueryConditions.CacheableCondition
            && ((QueryConditions.CacheableCondition) whereConditions.get(0)).isCacheable()
            && cache.isFieldCacheKey(((QueryConditions.CacheableCondition) whereConditions.get(0)).getCacheKey());
    }

    /**
     * @param result Query result to append cached records to
     * @return True if there's remainder with non-cached values and there has to be query on that.
     */
    private QueryConditions.Condition getCachedRecordsAndReturnRemainderCondition(List<SObject> result) {
        QueryConditions.Condition condition = whereConditions.get(0);
        QueryConditions.CacheableCondition cacheable = (QueryConditions.CacheableCondition) condition;
        QueryCache.Result cacheResult = cache.getCachedRecords(cacheable.getCacheKey(), cacheable.getCacheValue());

        result.addAll(cacheResult.cachedRecords.values());

        if (cacheResult.remainingValues.isEmpty()) {
            return null;

        } else {
            return cacheable.getRemainderCondition(cacheResult.remainingValues);
        }
    }

    private QueryConditions.Condition compileConditions(QueryConditions.Condition[] conditions) {
        if (conditions.isEmpty()) {
            return conditionFactory.blank();

        } else if (conditions.size() == 1) {
            return conditions.get(0);

        } else if (String.isBlank(filterLogic)) {
            return conditionFactory.ANDs(conditions);

        } else {
            return conditionFactory.logic(filterLogic, conditions);
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
            copy.fromObject(sObjType);
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