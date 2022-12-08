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
    private final static QueryCache instance = new QueryCache();
    private Map<String, Map<Object, SObject>> storage = new Map<String, Map<Object, SObject>>();


    public static QueryCache getInstance() {
        return instance;
    }

    private QueryCache() {
    }


    /**
     * Stores SObjects in internal storage and groups them by value in given SObject field.
     * Blank values are not cached.
     */
    public void put(SObjectType sObjectType, Set<String> fields, List<SObject> records) {
        for (String sObjectField : fields) {
            Map<Object, SObject> valueMap = getFieldMap(sObjectType, sObjectField);

            for (Integer i = 0, size = records.size(); i < size; i++) {
                SObject record = records[i];
                Object fieldValue = record.get(sObjectField);

                if (fieldValue != null || fieldValue != '') {
                    valueMap.put(fieldValue, record);
                }
            }
        }
    }

    /**
      * @return Pair:
      * Map<Id, SObject> Cached objects
      * List<Object> remaining values
      */
    public Result getCachedRecords(SObjectType sObjectType, String field, Object value) {
        Map<Id, SObject> cachedRecords = new Map<Id, SObject>();
        Iterable<Object> iterable = getIterable(value);

        Type itemType = Runtime.getIterableItemType(iterable);
        List<Object> remainingValues = Runtime.newListOfItemType(itemType);


        Iterator<Object> valueIt = iterable.iterator();
        while (valueIt.hasNext()) {
            Object val = valueIt.next();

            if (val != null && val != '' && containsKey(sObjectType, field, val)) {
                SObject record = get(sObjectType, field, val);
                cachedRecords.put(record.Id, record);

            } else {
                remainingValues.add(val);
            }
        }


        return new Result(cachedRecords, remainingValues);
    }


    /**
    * Transforms value into uniform iterable:
    * - primitive V is transformed into new List<T>{V}
    * - List or Sets are casted into Iterable<Object>
    * - SObject[] is changed into Iterable<Id>
    */
    private Iterable<Object> getIterable(Object value) {
        String typeName = Runtime.getTypeName(value);

        if (value instanceof SObject[]) {
            return (Iterable<Object>) new Map<Id, SObject>((SObject[]) value).keySet();

        } else if (typeName.contains('List') || typeName.contains('Set')) {
            return ((Iterable<Object>) value);

        } else {
            Type valueType = Runtime.getType(value);
            List<Object> values = Runtime.newListOfItemType(valueType);
            values.add(value);
            return values;
        }
    }

    /**
     * @return Cached SObject with given SObject field value.
     */
    private SObject get(SObjectType sObjectType, String field, Object value) {
        return storage.get('' + sObjectType + '.' + field).get(value);
    }

    /**
    * @return True, if there are any sObjects cached under given key
    */
    private Boolean containsKey(SObjectType sObjectType, String field, Object key) {
        String fieldKey = '' + sObjectType + '.' + field;
        return storage.containsKey(fieldKey) && storage.get(fieldKey).containsKey(key);
    }


    /**
     * @return Map of SObjects by the given field value
     */
    private Map<Object, SObject> getFieldMap(SObjectType sObjectType, String field) {
        String key = '' + sObjectType + '.' + field;

        if (!storage.containsKey(key)) {
            storage.put(key, new Map<Object, SObject>());
        }

        return storage.get(key);
    }


    /**
     * Result of Cache retrieve operation - a pair of cached records and remaining values that were not found in cache.
     */
    public class Result {
        public Map<Id, SObject> cachedRecords;
        public List<Object> remainingValues;

        private Result(Map<Id, SObject> cachedRecords, List<Object> remainingValues) {
            this.cachedRecords = cachedRecords;
            this.remainingValues = remainingValues;
        }
    }
}