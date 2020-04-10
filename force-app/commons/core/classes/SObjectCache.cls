/**
* MIT License
*
* Copyright (c) 2018 Piotr Kożuchowski
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
 * Indexed storage for SObjects which groups records by fields and field values.
 * @see SObjectCacheTest
 */
public inherited sharing class SObjectCache {
    private Map<SObjectField, Map<Object, List<SObject>>> storage;

    public SObjectCache() {
        this.storage = new Map<SObjectField, Map<Object, List<SObject>>>();
    }

    /**
     * Initialize Cache with records and fields to cache by.
     */
    public SObjectCache(List<SObject> records, List<SObjectField> fieldsToCacheBy) {
        this();
        for (SObjectField field : fieldsToCacheBy) {
            this.store(field, records);
        }
    }

    /**
     * @return Returns first SObject cached by given field and value or null.
     */
    public Object retrieveFirstValue(SObjectField field, Object value, SObjectField fieldToReturn) {
        SObject record = retrieveFirst(field, value);
        return record == null ? null : record.get(fieldToReturn);
    }

    /**
     * @return Returns first SObject cached by given field and value or null.
     */
    public SObject retrieveFirst(SObjectField field, Object value) {
        List<SObject> result = retrieve(field, value);
        return result.isEmpty() ? null : result[0];
    }

    /**
     * @return All cached SOBjects with given SObject field value.
     */
    public List<SObject> retrieveAll(SObjectField field, Iterable<Object> values) {
        List<SObject> result = new List<SObject>();

        Iterator<Object> it = values.iterator();
        while (it.hasNext()) {
            Object value = it.next();
            result.addAll(retrieve(field, value));
        }

        return result;
    }

    /**
     * @return All cached SOBjects with given SObject field value.
     */
    public List<SObject> retrieve(SObjectField field, Object value) {
        if (containsKey(field, value)) {
            return storage.get(field).get(value);
        } else {
            return new List<SObject>();
        }
    }

    /**
    * @return True, if there are any sObjects cached under given key
    */
    public Boolean containsKey(SObjectField field, Object key) {
        return storage.containsKey(field) && storage.get(field).containsKey(key);
    }

    /**
     * Stores SObjects in internal storage and groups them by value in given SObject field.
     */
    public void store(SObjectField field, List<SObject> records) {
        Map<Object, List<SObject>> valueMap = getFieldMap(field);

        for (SObject sobj : records) {
            Object fieldValue = sobj.get(field);

            if (!valueMap.containsKey(fieldValue)) {
                valueMap.put(fieldValue, new List<SObject>());
            }
            valueMap.get(fieldValue).add(sobj);
        }
    }


    /**
     * @return Map of SObjects by the given field value
     */
    private Map<Object, List<SObject>> getFieldMap(SObjectField field) {
        if (!storage.containsKey(field)) {
            storage.put(field, new Map<Object, List<SObject>>());
        }

        Map<Object, List<SObject>> valueMap = storage.get(field);
        return valueMap;
    }
}