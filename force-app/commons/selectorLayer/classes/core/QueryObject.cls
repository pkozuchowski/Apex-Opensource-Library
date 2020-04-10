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
    private final static QueryMocker queryMocker = new QueryMocker();
    private final static Set<SObjectType> firstInitialization = new Set<SObjectType>();
    private final static QueryCache cache = new QueryCache();

    protected final QueryBuilder query;
    protected final DatabaseService databaseService;
    protected final Map<String, SObjectField> allFields;

    private Boolean useCache = true;
    private SObjectType sObjectType;


    protected QueryObject(List<SObjectField> queryFields, SObjectType sObjectType) {
        this.databaseService = new DatabaseService();
        this.query = new QueryBuilder();
        this.query.selectFields(queryFields).fromObject(sObjectType);

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
        this.query.selectFields(allFields.values());
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
        return executeQuery();
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
        SObjectField field = allFields.get(fieldAPIName);

        if (canUseCache(operator, field)) {
            return getCachedRecords(field, operator, value);

        } else {
            this.query.setWhere(fieldAPIName + ' ' + operator + ' :value');
            this.query.bindVariable('value', value);
            return executeQuery();
        }
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
        SObject[] records = this.databaseService.query(query.toSOQL(), query.getVariables());

        if (queryMocker.isMocked(sObjectType)) {
            return queryMocker.mockResponse(this, sObjectType, query.getVariables(), records);

        } else {
            cache.put(getFieldsToCacheBy(), records);
            return records;
        }
    }


    /**
    * @return True, if selector can use cached records:
    * - Cache is not explicitly forbidden
    * - Operator is either equals or IN
    * - Field is explicitly allowed for caching or Field is unique to use it for upsert (isIdLookup)
    */
    private Boolean canUseCache(String operator, SObjectField field) {
        return useCache
                && (operator == '=' || operator == 'IN')
                && getFieldsToCacheBy().contains(field);
    }

    /**
    * @return All records that are in cache and queries these which are not.
    */
    private SObject[] getCachedRecords(SObjectField field, String operator, Object value) {
        QueryCache.CacheResult result = cache.getCachedRecords(field, value);

        if (!result.remainingValues.isEmpty()) {
            this.query.setWhere('' + field + ' ' + operator + ' :value');
            this.query.bindVariable('value', result.remainingValues);
            result.cachedRecords.putAll(executeQuery());
        }

        return result.cachedRecords.values();
    }


    /**
    * @return selector cache for protected records.
    */
    protected QueryCache getCache() {
        return cache;
    }
}