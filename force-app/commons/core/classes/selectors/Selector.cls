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
        return firstOrNull(byIds(new List<Id>{recordId}));
    }

    /**
     * @param recordIds List<Id> or (Iterable<Id>) Set<Id>
     * @return Records by given Salesforce Ids
     */
    public virtual SObject[] byIds(Iterable<Id> recordIds) {
        query.setWhere('Id IN :recordIds');
        return Database.query(query.build());
    }

    /**
     * @return SObjects with field equals given value
     */
    public virtual SObject[] byField(SObjectField field, Object value) {
        query.setWhere('' + field + ' = :value');
        return Database.query(query.build());
    }

    /**
     * @return SObjects with field values in given value set.
     */
    public virtual SObject[] byField(SObjectField field, List<Object> values) {
        query.setWhere('' + field + ' IN :values');
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