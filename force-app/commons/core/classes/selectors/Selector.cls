public abstract class Selector {
    protected SelectorQuery query = new SelectorQuery();

    protected Selector(List<SObjectField> queryFields, SObjectType sObjectType) {
        this.query.selectFields(queryFields)
                .fromObject(sObjectType);
    }


    /**
     * @return Record by given Salesforce Id or null
     */
    public virtual SObject byId(Id recordId) {
        return firstOrNull(byId(new List<Id>{recordId}));
    }

    /**
     * @param recordIds List<Id> or (Iterable<Id>) Set<Id>
     * @return Records by given Salesforce Ids
     */
    public virtual SObject[] byId(Iterable<Id> recordIds) {
        return byField('Id', 'IN', recordIds);
    }

    /**
     * @return SObject with field equals given value or null
     */
    public virtual SObject oneRecordByField(SObjectField field, String operator, Object value) {
        return firstOrNull(byField(field, operator, value));
    }

    /**
     * @values List or Set of any type, cast to (Iterable<Object>)
     * @return SObjects with field values in given value set.
     */
    public virtual SObject[] byField(SObjectField field, String operator, Object values) {
        return byField('' + field, operator, values);
    }

    /**
     * @values List or Set of any type, cast to (Iterable<Object>)
     * @return SObjects with field values in given value set.
     */
    public virtual SObject[] byField(String field, String operator, Object values) {
        query.setWhere(field + ' ' + operator + ' :values');
        return Database.query(query.build());
    }

    /**
     * @return All records in database
     */
    public virtual SObject[] all() {
        return Database.query(query.build());
    }

    /**
     * @return first record returned by query without any conditions.
     */
    public virtual SObject one() {
        query.setLimit(1);
        return Database.query(query.build());
    }

    /**
     * @return First record in list or null if list is empty
     */
    protected SObject firstOrNull(List<SObject> records) {
        return records.isEmpty() ? null : records.get(0);
    }
}