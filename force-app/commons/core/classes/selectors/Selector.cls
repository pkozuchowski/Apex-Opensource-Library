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
public inherited sharing abstract class Selector {
    private final static SelectorCache cache = new SelectorCache();
    protected final transient SelectorQuery query;
    private Boolean useCache = true;
    private Map<String, SObjectField> allFields;
    private List<SObjectField> queryFields;
    private Set<SObjectField> cacheFields;


    protected Selector(List<SObjectField> queryFields, SObjectType sObjectType) {
        this.query = new SelectorQuery(this);
        this.query.selectFields(queryFields).fromObject(sObjectType);

        this.allFields = sObjectType.getDescribe().fields.getMap();
        this.queryFields = queryFields;
        this.cacheFields = getCachedFields();
    }


    /*Extenders*/

    /**
     * Query will be executed in "without sharing" context, returning records
     * users does not have access to
     */
    public Selector withoutSharing() {
        this.query.setSharing(Sharing.WITHOUT_SHARING);
        return this;
    }


    /**
    * @return Selector will not reuse cached records to limit SOQLs query limit
    */
    protected Selector useCache(Boolean useCache) {
        this.useCache = false;
        return this;
    }

    public Selector withAllFields() {
        this.query.selectFields(allFields.values());
        return this;
    }


    /*Reductors*/

    /**
     * @return first record returned by query without any conditions or null.
     */
    public virtual SObject one() {
        query.setLimit(1);
        return firstOrNull(query.execute());
    }

    /**
     * @return All records in database
     */
    public virtual SObject[] all() {
        return query.execute();
    }


    /**
    * @return Record by given Salesforce Id
    */
    public virtual SObject byId(Id recordId) {
        return firstOrNull(byId(new List<Id>{recordId}));
    }

    /**
     * @param recordIds List<Id> or (Iterable<Id>) Set<Id> or (Iterable<Id>) List<SObject>
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
    public virtual SObject[] relatedToChildren(List<SObject> childRecords, SObjectField relationShipField) {
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
    public virtual SObject[] relatedToParent(List<SObject> parentRecords, SObjectField relationShipField) {
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
            return query();
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
                && cacheFields.contains(field);
    }

    /**
    * @return All records that are in cache and queries these which are not.
    */
    private List<SObject> getCachedRecords(SObjectField field, String operator, Object value) {
        Map<Id, SObject> result = new Map<Id, SObject>();
        Iterable<Object> iterable = getIterable(value);

        String runtimeValueName = Runtime.getRunningTypeName(iterable).substringBetween('<', '>');
        List<Object> remainingValues = Runtime.newListOfItemType(Type.forName(runtimeValueName));


        Iterator<Object> valueIt = iterable.iterator();
        while (valueIt.hasNext()) {
            Object val = valueIt.next();

            if (cache.containsKey(field, val)) {
                SObject record = cache.retrieve(field, val);
                result.put(record.Id, record);

            } else {
                remainingValues.add(val);
            }
        }


        if (!remainingValues.isEmpty()) {
            this.query.setWhere('' + field + ' ' + operator + ' :value');
            this.query.bindVariable('value', remainingValues);
            result.putAll(query());
        }

        return result.values();
    }

    /**
    * Transforms value into uniform iterable:
    * - primitive V is transformed into new List<T>{V}
    * - List or Sets are casted into Iterable<Object>
    * - List<SObject> is changed into Iterable<Id>
    */
    private Iterable<Object> getIterable(Object value) {
        String typeName = Runtime.getRunningTypeName(value);

        if (value instanceof List<SObject>) {
            return (Iterable<Object>) new Map<Id, SObject>((List<SObject>) value).keySet();

        } else if (typeName.contains('List') || typeName.contains('Set')) {
            return ((Iterable<Object>) value);

        } else {
            Type valueType = Runtime.getRunningType(value);
            List<Object> values = Runtime.newListOfItemType(valueType);
            values.add(value);
            return values;
        }
    }

    /**
    * @return Fields which are viable for caching - by default Ids, External Ids and unique fields
    * For overriding, consider using super() for adding additional fields to this behavior.
    */
    protected virtual Set<SObjectField> getCachedFields() {
        Set<SObjectField> cacheFields = new Set<SObjectField>();

        for (SObjectField sObjectField : this.queryFields) {
            DescribeFieldResult describe = sObjectField.getDescribe();

            if (describe.isIdLookup() || describe.isUnique()) {
                cacheFields.add(sObjectField);
            }
        }

        return cacheFields;
    }

    /**
     * @return First record in list or null if list is empty
     */
    protected SObject firstOrNull(List<SObject> records) {
        return records.isEmpty() ? null : records.get(0);
    }


    /**
    * Executes query and caches results
    */
    protected List<SObject> query() {
        List<SObject> records = this.query.execute();
        cache.store(cacheFields, records);

        return records;
    }

}