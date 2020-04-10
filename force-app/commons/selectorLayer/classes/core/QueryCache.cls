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
public inherited sharing class QueryCache {
    private Map<SObjectField, Map<Object, SObject>> storage = new Map<SObjectField, Map<Object, SObject>>();


    /**
     * @return Cached SObject with given SObject field value.
     */
    public SObject get(SObjectField field, Object value) {
        return storage.get(field).get(value);
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
    public void put(Set<SObjectField> fields, List<SObject> records) {
        for (SObjectField sObjectField : fields) {
            Map<Object, SObject> valueMap = getFieldMap(sObjectField);

            for (SObject sobj : records) {
                Object fieldValue = sobj.get(sObjectField);
                valueMap.put(fieldValue, sobj);
            }
        }
    }

    /**
     * @return Map of SObjects by the given field value
     */
    private Map<Object, SObject> getFieldMap(SObjectField field) {
        if (!storage.containsKey(field)) {
            storage.put(field, new Map<Object, SObject>());
        }

        return storage.get(field);
    }


    /**
      * @return Pair:
      * Map<Id, SObject> Cached objects
      * List<Object> remaining values
      */
    public CacheResult getCachedRecords(SObjectField field, Object value) {
        Map<Id, SObject> cachedRecords = new Map<Id, SObject>();
        Iterable<Object> iterable = getIterable(field, value);

        Type itemType = Runtime.getIterableItemType(iterable);
        List<Object> remainingValues = Runtime.newListOfItemType(itemType);


        Iterator<Object> valueIt = iterable.iterator();
        while (valueIt.hasNext()) {
            Object val = valueIt.next();

            if (containsKey(field, val)) {
                SObject record = get(field, val);
                cachedRecords.put(record.Id, record);

            } else {
                remainingValues.add(val);
            }
        }


        return new CacheResult(cachedRecords, remainingValues);
    }

    /**
    * Transforms value into uniform iterable:
    * - primitive V is transformed into new List<T>{V}
    * - List or Sets are casted into Iterable<Object>
    * - SObject[] is changed into Iterable<Id>
    */
    private Iterable<Object> getIterable(SObjectField field, Object value) {
        if (value == null) {
            List<Object> values = Runtime.newListOfFieldType(field);
            values.add(value);
            return values;

        } else {
            String typeName = Runtime.getTypeName(value);

            if (value instanceof SObject[]) {
                return (Iterable<Object>) new Map<Id, SObject>((SObject[]) value).keySet();

            } else if (typeName.contains('List') || typeName.contains('Set')) {
                return ((Iterable<Object>) value);

            } else {
                List<Object> values = Runtime.newListOfFieldType(field);
                values.add(value);
                return values;
            }
        }
    }


    public class CacheResult {
        public Map<Id, SObject> cachedRecords;
        public List<Object> remainingValues;

        private CacheResult(Map<Id, SObject> cachedRecords, List<Object> remainingValues) {
            this.cachedRecords = cachedRecords;
            this.remainingValues = remainingValues;
        }
    }
}