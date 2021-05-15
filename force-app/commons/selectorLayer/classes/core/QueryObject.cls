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
public inherited sharing abstract class QueryObject {
    private final static QueryMocker mocker = QueryMocker.getInstance();
    private final static QueryCache cache = QueryCache.getInstance();

    protected final QueryBuilder query = new QueryBuilder();
    protected final DatabaseService databaseService = new DatabaseService();
    protected final List<QueryWhere> conditions = new List<QueryWhere>();

    private Boolean useCache = true;
    private Boolean enforceSecurity = false;
    private SObjectType sObjectType;

    public abstract List<String> getFields();
    public abstract SObjectType getSObjectType();

    /**
     * Standard constructor for used in the most of QueryObject implementations
     * Initializes QueryBuilder with default fields and sObjectType
     */
    public QueryObject() {
        this(true);
    }

    /**
     * @param doInit if true, initializes QueryBuilder
     * This is special constructor which is used only when initialization has to be delayed after concrete's class constructor code.
     */
    protected QueryObject(Boolean doInit) {
        if (doInit) init();
    }

    /**
     * Initializes QueryBuilder with default fields and sObjectType
     */
    protected void init() {
        this.sObjectType = getSObjectType();
        this.query.setFields(getFields())
            .fromObject(sObjectType);
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
    public QueryObject withoutSharing() {
        databaseService.setSharing(Sharing.WITHOUT_SHARING);
        return this;
    }


    /**
    * Selector will not use cached records to limit SOQLs query limit.
    *
    * Since there is no proper way to handle method chaining of builder pattern with inheritance in Apex,
    * this method should be reimplemented where it's needed as public XXXSelector withoutCache();
    */
    public QueryObject withoutCache() {
        this.useCache = false;
        return this;
    }


    /**
    * Selects all fields on the record
    *
    * Since there is no proper way to handle method chaining of builder pattern with inheritance in Apex,
    * this method should be reimplemented where it's needed as public XXXSelector withAllFields();
    */
    public QueryObject withAllFields() {
        this.query.setFields(getAllFieldsList());
        return this;
    }


    /**
     * Enforces Object and Field level security on records.
     * Inaccessible fields are stripped from result and inaccessible objects throws exception.
     *
     * @throws System.NoAccessException No access to entity
     */
    public QueryObject withEnforcedSecurity() {
        this.enforceSecurity = true;
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
        this.conditions.add(new QueryWheres.FieldWhere(fieldAPIName, operator, value));
        return this;
    }


    /**
     * Adds WHERE clause to query conditions
     */
    protected QueryObject wheres(QueryWhere wheres) {
        this.conditions.add(wheres);
        return this;
    }

    /**
    * Composite query condition that joins inner where clauses with AND operator
    */
    protected QueryWhere ANDs(QueryWhere w1, QueryWhere w2) {
        return new QueryWheres.ANDWhere(new List<QueryWhere>{w1, w2});
    }
    protected QueryWhere ANDs(QueryWhere w1, QueryWhere w2, QueryWhere w3) {
        return new QueryWheres.ANDWhere(new List<QueryWhere>{w1, w2, w3});
    }
    protected QueryWhere ANDs(QueryWhere w1, QueryWhere w2, QueryWhere w3, QueryWhere w4) {
        return new QueryWheres.ANDWhere(new List<QueryWhere>{w1, w2, w3, w4});
    }
    protected QueryWhere ANDs(QueryWhere w1, QueryWhere w2, QueryWhere w3, QueryWhere w4, QueryWhere w5) {
        return new QueryWheres.ANDWhere(new List<QueryWhere>{w1, w2, w3, w4, w5});
    }
    protected QueryWhere ANDs(QueryWhere[] conditions) {
        return new QueryWheres.ANDWhere(conditions);
    }

    /**
    * Composite query condition that joins inner where clauses with OR operator
    */
    protected QueryWhere ORs(QueryWhere w1, QueryWhere w2) {
        return new QueryWheres.ORWhere(new List<QueryWhere>{w1, w2});
    }
    protected QueryWhere ORs(QueryWhere w1, QueryWhere w2, QueryWhere w3) {
        return new QueryWheres.ORWhere(new List<QueryWhere>{w1, w2, w3});
    }
    protected QueryWhere ORs(QueryWhere w1, QueryWhere w2, QueryWhere w3, QueryWhere w4) {
        return new QueryWheres.ORWhere(new List<QueryWhere>{w1, w2, w3, w4});
    }
    protected QueryWhere ORs(QueryWhere w1, QueryWhere w2, QueryWhere w3, QueryWhere w4, QueryWhere w5) {
        return new QueryWheres.ORWhere(new List<QueryWhere>{w1, w2, w3, w4, w5});
    }
    protected QueryWhere ORs(QueryWhere[] conditions) {
        return new QueryWheres.ORWhere(conditions);
    }


    /**
     * Creates field WHERE condition
     */
    protected QueryWheres.FieldWhereFactory field(SObjectField field) {
        return field('' + field);
    }
    protected QueryWheres.FieldWhereFactory field(String field) {
        return new QueryWheres.FieldWhereFactory(field);
    }


    /**
     * Negates passed WHERE clause with NOT keyword
     */
    protected QueryWhere NOTs(QueryWhere condition) {
        return new QueryWheres.NotWhere(condition);
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
        this.query.setLimit(1);
        List<SObject> result = executeQuery();
        return result.get(0);
    }

    /**
     * @return First record or null if list has no results
     */
    public SObject getFirstOrNull() {
        this.query.setLimit(1);
        List<SObject> result = executeQuery();
        return result.isEmpty() ? null : result.get(0);
    }

    /**
     * @return First record or empty record instance if list has no results
     */
    public SObject getFirstOrEmpty() {
        this.query.setLimit(1);
        List<SObject> result = executeQuery();
        return result.isEmpty() ? getSObjectType().newSObject(null, false) : result.get(0);
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
        Map<Id, SObject> resultMap = (Map<Id, SObject>) Type.forName('Map<Id,' + getSObjectType() + '>').newInstance();
        resultMap.putAll(getList());

        return resultMap;
    }


    /**
     * @return Query Locator for current query
     */
    public Database.QueryLocator getQueryLocator() {
        this.query.addFields(getFields())
            .fromObject(getSObjectType())
            .setQueryCriteria(conditions);

        return this.databaseService.getQueryLocator(query.toSOQL(), query.getVariables());
    }

    /**
    * @return Count of records
    */
    public Integer getCount() {
        return (Integer) getCountBy(new List<String>()).get(0).get('cnt');
    }

    /**
    * @return Records counted by given SObject field
    */
    public AggregateResult[] getCountBy(List<String> fields) {
        String fieldsCSV = fields == null ? '' : String.join(fields, ',');

        this.query.setFields(new List<String>{'COUNT(Id) cnt'});

        if (String.isNotBlank(fieldsCSV)) {
            this.query.addFields(fields);
            this.query.setGroupBy(fieldsCSV);
        }

        this.query.fromObject(getSObjectType());
        return this.databaseService.query(query.toSOQL(), query.getVariables());
    }


    /**
    * Fields returned by this method will be used to cache records.
    * Whenever possible, selector will use cached fields to
    */
    protected virtual Set<String> getFieldsToCacheBy() {
        return new Set<String>{'Id'};
    }


    /**
     * @return List of all fields API names
     */
    protected List<String> getAllFieldsList() {
        return new List<String>(getAllFieldsMap().keySet());
    }

    /**
     * @return All fields for query's sObject type
     */
    protected Map<String, SObjectField> getAllFieldsMap() {
        return SchemaDescriptions.getFieldsMap(this.getSObjectType());
    }


    /**
    * Executes query and caches results
    */
    protected SObject[] executeQuery() {
        List<SObject> result = Runtime.newListOfItemType(getSObjectType());
        Boolean doQuery = true;

        if (canUseCache()) {
            doQuery = getCachedRecords(result);

        } else {
            this.query.setQueryCriteria(conditions);
        }

        if (doQuery) {
            SObject[] records = this.databaseService.query(query.toSOQL(), query.getVariables());
            result.addAll(records);

            if (!(records instanceof AggregateResult[])) {
                cache.put(sObjectType, getFieldsToCacheBy(), records);
            }
        }

        Type thisQueryClass = Runtime.getType(this);
        if (mocker.isMocked(thisQueryClass)) {
            QueryMock mock = mocker.getMock(thisQueryClass);
            result = mock.handleQuery(thisQueryClass, conditions, result);
        }

        if (enforceSecurity) {
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.READABLE, result);
            result = decision.getRecords();
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
        return useCache;
//        return useCache
//            && conditions.size() == 1
//            && (conditions[0].operator == '=' || conditions[0].operator == 'IN')
//            && conditions[0].value != null
//            && conditions[0].value != ''
//            && getFieldsToCacheBy().contains(conditions[0].field);
    }

    /**
     * @param result Query result to append cached records to
     * @return True if there's remainder with non-cached values and there has to be query on that.
     */
    private Boolean getCachedRecords(List<SObject> result) {
        return false;
//        QueryCriteria criteria = conditions.get(0);
//        QueryCache.CacheResult cacheResult = cache.getCachedRecords(sObjectType, criteria.field, criteria.value);
//
//        result.addAll(cacheResult.cachedRecords.values());
//
//        if (!cacheResult.remainingValues.isEmpty()) {
//            this.query.setWhere(conditions.toString());
//            this.query.bindVariable('value', cacheResult.remainingValues);
//            return true;
//
//        } else {
//            return false;
//        }
    }
}