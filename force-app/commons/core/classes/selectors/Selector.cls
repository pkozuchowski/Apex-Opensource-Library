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
    protected transient SelectorQuery query;

    protected Selector(List<SObjectField> queryFields, SObjectType sObjectType) {
        this.query = new SelectorQuery(this);
        this.query.selectFields(queryFields).fromObject(sObjectType);
    }

    /**
     * Query will be executed in "without sharing" context, returning records
     * users does not have access to
     */
    public Selector withoutSharing() {
        this.query.setSharing(Sharing.WITHOUT_SHARING);
        return this;
    }


    /**
     * @return Record by given Salesforce Id or null
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
     * @param relationShipField Parent field on records (ex. Contact.AccountId for list of Contacts)
     * @param childRecords List of child records in relationship
     * @return List of parent records related to given child records by given field
     */
    public virtual SObject[] byChild(SObjectField relationShipField, List<SObject> childRecords) {
        Set<Id> parentIds = new Set<Id>();
        for (SObject record : childRecords) {
            parentIds.add((Id) record.get(relationShipField));
        }

        return byId((Iterable<Id>) parentIds);
    }

    /**
     * @param relationShipField Parent field on records (ex. Contact.AccountId for list of Contacts)
     * @param parentRecords List of child records in relationship
     * @return List of child records related to given parent records by given field
     */
    public virtual SObject[] byParent(SObjectField relationShipField, List<SObject> parentRecords) {
        return byField(relationShipField, 'IN', parentRecords);
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
        query.bindVariable('values', values);
        query.setWhere(field + ' ' + operator + ' :values');
        return query.execute();
    }

    /**
     * @return All records in database
     */
    public virtual SObject[] all() {
        return query.execute();
    }

    /**
     * @return first record returned by query without any conditions or null.
     */
    public virtual SObject one() {
        query.setLimit(1);
        return firstOrNull(query.execute());
    }

    /**
     * @return First record in list or null if list is empty
     */
    protected SObject firstOrNull(List<SObject> records) {
        return records.isEmpty() ? null : records.get(0);
    }
}