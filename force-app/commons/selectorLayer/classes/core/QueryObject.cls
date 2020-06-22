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
    private final static Set<SObjectType> firstInitialization = new Set<SObjectType>();

    protected final QueryBuilder query;
    protected final DatabaseService databaseService;
    protected final Map<String, SObjectField> allFields;

    private Boolean useCache = true;
    private SObjectType sObjectType;
    private QueryCriteria[] criteria;


    protected QueryObject(List<SObjectField> queryFields, SObjectType sObjectType) {
        this.databaseService = new DatabaseService();
        this.query = new QueryBuilder();
        this.query.addFields(queryFields).fromObject(sObjectType);
        this.criteria = new List<QueryCriteria>();

        this.allFields = sObjectType.getDescribe().fields.getMap();
        this.sObjectType = sObjectType;

        if (!firstInitialization.contains(sObjectType)) {
            firstInitialization.add(sObjectType);

            cache.put(getFieldsToCacheBy(), getRecordsToPrecache());
        }
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
    protected QueryObject withoutSharingImpl() {
        databaseService.setSharing(Sharing.WITHOUT_SHARING);
        return this;
    }


    /**
    * Selector will not use cached records to limit SOQLs query limit.
    *
    * Since there is no proper way to handle method chaining of builder pattern with inheritance in Apex,
    * this method should be reimplemented where it's needed as public XXXSelector withoutCache();
    */
    protected QueryObject withoutCacheImpl() {
        this.useCache = false;
        return this;
    }


    /**
    * Selects all fields on the record
    *
    * Since there is no proper way to handle method chaining of builder pattern with inheritance in Apex,
    * this method should be reimplemented where it's needed as public XXXSelector withAllFields();
    */
    protected QueryObject withAllFieldsImpl() {
        this.query.addFields(allFields.values());
        return this;
    }


    /**
    * Reductors
    * */

    /**
     * @return The most recently created record or null if there isn't any.
     */
    public virtual SObject newest() {
        query.setOrderBy('CreatedDate DESC');
        query.setLimit(1);
        return firstOrNull(executeQuery());
    }

    /**
     * @return All records in database
     */
    public virtual SObject[] all() {
        return getList();
    }


    /**
    * @return Record by given Salesforce Id
    */
    public virtual SObject byId(Id recordId) {
        return firstOrNull(byId(new List<Id>{recordId}));
    }

    /**
     * @param recordIds [List<Id>] or [(Iterable<Id>) Set<Id>] or [(Iterable<Id>) List<SObject>]
     * @return Records by given Salesforce Ids
     */
    public virtual SObject[] byId(Iterable<Id> recordIds) {
        return byField('Id', 'IN', recordIds);
    }


    /**
     * @return First record or null if list has no results
     */
    public SObject getFirst() {
        return firstOrNull(executeQuery());
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
        return new Map<Id, SObject>(getList());
    }

    /**
     * @return Query Locator for current query
     */
    public Database.QueryLocator getQueryLocator() {
        return this.databaseService.getQueryLocator(query.toSOQL(), query.getVariables());
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
    public virtual SObject[] relatedToChildren(SObject[] childRecords, SObjectField relationShipField) {
        Set<Id> parentIds = new Set<Id>();

        for (SObject record : childRecords) {
            parentIds.add((Id) record.get(relationShipField));
        }

        return byId((Iterable<Id>) parentIds);
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
    public virtual SObject[] relatedToParent(SObject[] parentRecords, SObjectField relationShipField) {
        return byField(relationShipField, 'IN', parentRecords);
    }

    /**
     * @return SObject with field equals given value or null
     */
    public virtual SObject oneRecordByField(SObjectField field, String operator, Object value) {
        return firstOrNull(byField(field, operator, value));
    }

    /**
     * @value Expected value or values (may be Set or List) of the field
     * @return SObjects with field values in given value set.
     */
    public virtual SObject[] byField(SObjectField field, String operator, Object value) {
        return byField('' + field, operator, value);
    }

    /**
     * @value Expected value or values (may be Set or List) of the field
     * @return SObjects with field values in given value set.
     */
    public virtual SObject[] byField(String fieldAPIName, String operator, Object value) {
        this.criteria.add(new QueryCriteria(fieldAPIName, operator, value));
        return executeQuery();
    }


    /**
    * @return SObjects which satisfy given query condition
    */
    public SObject[] byCriterion(QueryCriteria criterion) {
        this.criteria.add(criterion);
        return executeQuery();
    }

    /**
    * @return SObjects which satisfy all of given query condition
    */
    public SObject[] byCriteria(QueryCriteria[] criteria) {
        this.criteria.addAll(criteria);
        return executeQuery();
    }


    /**
    * @return Records counted by given SObject field
    */
    public AggregateResult[] countBy(SObjectField field) {
        return countBy('' + field);
    }

    /**
    * @return Records counted by given SObject field
    */
    public AggregateResult[] countBy(String field) {
        this.query.setFields(new List<String>{
                'COUNT(Id) cnt',
                field
        });
        this.query.setGroupBy(field);
        return executeQuery();
    }


    /**
     * @return First record in list or null if list is empty
     */
    protected SObject firstOrNull(SObject[] records) {
        return records.isEmpty() ? null : records.get(0);
    }

    /**
    * Fields returned by this method will be used to cache records.
    * Whenever possible, selector will use cached fields to
    */
    protected virtual Set<SObjectField> getFieldsToCacheBy() {
        return new Set<SObjectField>();
    }

    /**
    * These records will be cached at first initialization of the selector:
    * Example use-cases:
    * - caching all Profiles / UserRoles / Permission Sets to reduce soql limits against these
    * setup objects to 1 during whole transaction
    */
    protected virtual List<SObject> getRecordsToPrecache() {
        return new List<SObject>();
    }

    /**
    * Executes query and caches results
    */
    protected SObject[] executeQuery() {
        List<SObject> result = new List<SObject>();
        Boolean doQuery = true;

        if (canUseCache()) {
            doQuery = getCachedRecords(result);

        } else {
            resolveQueryCriteria();
        }

        if (doQuery) {
            SObject[] records = this.databaseService.query(query.toSOQL(), query.getVariables());
            result.addAll(records);

            if (!(records instanceof AggregateResult[])) {
                cache.put(getFieldsToCacheBy(), records);
            }
        }

        if (mocker.isMocked(sObjectType)) {
            return mocker.mockResponse(this, sObjectType, query.getVariables(), result);

        } else {
            return result;
        }
    }

    /**
    * @return True, if selector can use cached records:
    * - Cache is not explicitly forbidden
    * - There is only 1 query criteria
    * - Operator is either equals or IN
    * - Field is explicitly allowed for caching or Field is unique to use it for upsert (isIdLookup)
    */
    private Boolean canUseCache() {
//        System.debug('useCache: ' + useCache);
//        System.debug('criteria: ' + criteria);
//        System.debug('operator: ' + (criteria[0].operator == '=' || criteria[0].operator == 'IN'));
//        System.debug('getFieldsToCacheBy(): ' + getFieldsToCacheBy());

        return useCache
                && criteria.size() == 1
                && (criteria[0].operator == '=' || criteria[0].operator == 'IN')
                && getFieldsToCacheBy().contains(allFields.get((criteria[0].field)));
    }

    /**
     * @param result Query result to append cached records to
     * @return True if there's remainder with non-cached values and there has to be query on that.
     */
    private Boolean getCachedRecords(List<SObject> result) {
        QueryCriteria criteria = criteria.get(0);
        SObjectField field = allFields.get(criteria.field);
        QueryCache.CacheResult cacheResult = cache.getCachedRecords(field, criteria.value);

        result.addAll(cacheResult.cachedRecords.values());

        if (!cacheResult.remainingValues.isEmpty()) {
            this.query.setWhere(criteria.toString());
            this.query.bindVariable('value', cacheResult.remainingValues);
            return true;

        } else {
            return false;
        }
    }

    /**
     * Adds query criteria to query builder and binds variable
     */
    private void resolveQueryCriteria() {
        List<String> conditionStrings = new List<String>();

        for (Integer i = 0, size = criteria.size(); i < size; i++) {
            conditionStrings.add(criteria[i].toString() + i);
            this.query.bindVariable('value' + i, criteria[i].value);
        }

        if (!conditionStrings.isEmpty()) {
            this.query.setWhere(String.join(conditionStrings, ' AND '));
        }
    }

    /**
    * @return selector cache for protected records.
    */
    protected QueryCache getCache() {
        return cache;
    }
}