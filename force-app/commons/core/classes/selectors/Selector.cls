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
    protected SelectorQuery query = new SelectorQuery();

    protected Selector(List<SObjectField> queryFields, SObjectType sObjectType) {
        this.query.selectFields(queryFields).fromObject(sObjectType);
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
        return Database.query(query.toSOQL());
    }

    /**
     * @return All records in database
     */
    public virtual SObject[] all() {
        return Database.query(query.toSOQL());
    }

    /**
     * @return first record returned by query without any conditions.
     */
    public virtual SObject one() {
        query.setLimit(1);
        return Database.query(query.toSOQL());
    }

    /**
     * @return First record in list or null if list is empty
     */
    protected SObject firstOrNull(List<SObject> records) {
        return records.isEmpty() ? null : records.get(0);
    }
}