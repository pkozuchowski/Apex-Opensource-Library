/**
* MIT License
*
* Copyright (c) 2018 Piotr Kożuchowski <piotr.b.kozuchowski@gmail.com>
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
 * Class provides static utility methods for the most common actions that take place place
 * in Salesforce business logic:
 * - Mapping records by given field,
 * - Grouping records with the same value in given field,
 * - Gathering values from given field or fields,
 * - Filtering records which have given value or values in given field,
 * - Reducing collection to single variable using Reducer interface
 * - Sorting records by given field or comparator.
 */
public class Collections {

    /**
     * @return true when collection is not null or empty, false otherwise.
     */
    public static Boolean isNotEmpty(List<Object> collection) {
        return !isEmpty(collection);
    }


    /**
     * @return true when collection is null or empty, false otherwise.
     */
    public static Boolean isEmpty(List<Object> collection) {
        return collection == null || collection.isEmpty();
    }


    /**
     * Transforms generic collection to given type.
     * Ex. Map<Object,Object> => Map<String,Account>
     * Casting is done through JSON serialization/deserialization, this process is CPU Time consuming.
     *
     * This method is NPE-safe, when collection is null, then blank instance of target type is returned.
     */
    public static Object cast(Object collection, Type targetType) {
        if (collection == null) {
            return targetType.newInstance();
        }

        return JSON.deserialize(JSON.serialize(collection), targetType);
    }


    /**
     * @return sObject type of List<SObject> or first record.
     */
    public static SObjectType getSObjectType(List<SObject> records) {
        SObjectType sObjectType = records.getSObjectType();
        if (sObjectType == null && !records.isEmpty()) sObjectType = records[0].getSObjectType();

        return sObjectType;
    }


    /**
     * @param records List of SObject records from which values are gathered.
     * @param field SObject field from which value is taken.
     * @return Set of gathered values.
     */
    public static Set<String> getUniqueStringValues(List<SObject> records, SObjectField field) {
        return getUniqueStringValues(records, '' + field);
    }
    public static Set<String> getUniqueStringValues(List<SObject> records, String field) {
        return mapByStringField(records, field).keySet();
    }

    public static Set<Id> getUniqueIdValues(List<SObject> records, SObjectField field) {
        return getUniqueIdValues(records, '' + field);
    }
    public static Set<Id> getUniqueIdValues(List<SObject> records, String field) {
        return mapByIdField(records, field).keySet();
    }

    public static Set<Integer> getUniqueIntegerValues(List<SObject> records, SObjectField field) {
        return getUniqueIntegerValues(records, '' + field);
    }
    public static Set<Integer> getUniqueIntegerValues(List<SObject> records, String field) {
        return mapByIntegerField(records, field).keySet();
    }

    public static Set<Decimal> getUniqueDecimalValues(List<SObject> records, SObjectField field) {
        return getUniqueDecimalValues(records, '' + field);
    }
    public static Set<Decimal> getUniqueDecimalValues(List<SObject> records, String field) {
        return mapByDecimalField(records, field).keySet();
    }

    public static Set<Date> getUniqueDateValues(List<SObject> records, SObjectField field) {
        return getUniqueDateValues(records, '' + field);
    }
    public static Set<Date> getUniqueDateValues(List<SObject> records, String field) {
        return mapByDateField(records, field).keySet();
    }

    public static Set<Datetime> getUniqueDatetimeValues(List<SObject> records, SObjectField field) {
        return getUniqueDatetimeValues(records, '' + field);
    }
    public static Set<Datetime> getUniqueDatetimeValues(List<SObject> records, String field) {
        return mapByDatetimeField(records, field).keySet();
    }

    public static Set<Boolean> getUniqueBooleanValues(List<SObject> records, SObjectField field) {
        return getUniqueBooleanValues(records, '' + field);
    }
    public static Set<Boolean> getUniqueBooleanValues(List<SObject> records, String field) {
        return mapByBooleanField(records, field).keySet();
    }

    public static Set<Object> getUniqueValues(List<SObject> records, SObjectField field) {
        return getUniqueValues(records, '' + field);
    }
    public static Set<Object> getUniqueValues(List<SObject> records, String field) {
        return mapByField(records, field).keySet();
    }
    public static Set<Object> getUniqueValues(List<SObject> records, KeyMapper mapper) {
        return mapBy(records, mapper).keySet();
    }


    /**
     * @param records List of records to return field values from.
     * @param fields List of fields to return values from.
     * @return Set of unique SObject field values of given fields of given records.
     */
    public static Set<Object> getUniqueValues(List<SObject> records, List<SObjectField> fields) {
        return (Set<Object>) reduce(records, new ReducerToSetByFields(fields), new Set<Object>());
    }
    public class ReducerToSetByFields implements Reducer {
        private List<SObjectField> fields;

        public ReducerToSetByFields(List<SObjectField> fields) {
            this.fields = fields;
        }

        public void reduce(Object aggregatedValues, Object item) {
            Set<Object> values = (Set<Object>) aggregatedValues;
            SObject record = (SObject) item;

            for (Integer i = 0, j = fields.size(); i < j; i++) {
                values.add(record.get(fields[i]));
            }
        }
    }


    /** Maps list of SObjects by given String field. */
    public static Map<String, SObject> mapByStringField(List<SObject> records, SObjectField field) {
        return mapByStringField(records, '' + field);
    }
    public static Map<String, SObject> mapByStringField(List<SObject> records, String field) {
        return (Map<String, SObject>) mapByField(records, field, getGenericMap(String.class, records));
    }

    public static Map<Id, SObject> mapByIdField(List<SObject> records, SObjectField field) {
        return mapByIdField(records, '' + field);
    }
    public static Map<Id, SObject> mapByIdField(List<SObject> records, String field) {
        return (Map<Id, SObject>) mapByField(records, field, getGenericMap(Id.class, records));
    }

    public static Map<Integer, SObject> mapByIntegerField(List<SObject> records, SObjectField field) {
        return mapByIntegerField(records, '' + field);
    }
    public static Map<Integer, SObject> mapByIntegerField(List<SObject> records, String field) {
        return (Map<Integer, SObject>) mapByField(records, field, getGenericMap(Integer.class, records));
    }

    public static Map<Decimal, SObject> mapByDecimalField(List<SObject> records, SObjectField field) {
        return mapByDecimalField(records, '' + field);
    }
    public static Map<Decimal, SObject> mapByDecimalField(List<SObject> records, String field) {
        return (Map<Decimal, SObject>) mapByField(records, field, getGenericMap(Decimal.class, records));
    }

    public static Map<Date, SObject> mapByDateField(List<SObject> records, SObjectField field) {
        return mapByDateField(records, '' + field);
    }
    public static Map<Date, SObject> mapByDateField(List<SObject> records, String field) {
        return (Map<Date, SObject>) mapByField(records, field, getGenericMap(Date.class, records));
    }

    public static Map<Datetime, SObject> mapByDatetimeField(List<SObject> records, SObjectField field) {
        return mapByDatetimeField(records, '' + field);
    }
    public static Map<Datetime, SObject> mapByDatetimeField(List<SObject> records, String field) {
        return (Map<Datetime, SObject>) mapByField(records, field, getGenericMap(Datetime.class, records));
    }

    public static Map<Boolean, SObject> mapByBooleanField(List<SObject> records, SObjectField field) {
        return mapByBooleanField(records, '' + field);
    }
    public static Map<Boolean, SObject> mapByBooleanField(List<SObject> records, String field) {
        return (Map<Boolean, SObject>) mapByField(records, field, getGenericMap(Boolean.class, records));
    }

    public static Map<Object, SObject> mapByField(List<SObject> records, SObjectField field) {
        return mapByField(records, '' + field);
    }
    public static Map<Object, SObject> mapByField(List<SObject> records, String field) {
        return (Map<Object, SObject>) mapByField(records, field, getGenericMap(Object.class, records));
    }

    private static Object mapByField(List<SObject> records, String field, IMap abstractMap) {
        KeyMapper mapByField = new SObjectFieldKeyMapper(field);
        Reducer reducer = new ReducerToMapByKeyMapper(mapByField);

        return ((IMap) reduce(records, reducer, abstractMap)).toMap();
    }

    public class ReducerToMapByKeyMapper implements Reducer {
        private KeyMapper mapper;

        public ReducerToMapByKeyMapper(KeyMapper mapper) {
            this.mapper = mapper;
        }

        public void reduce(Object aggregatedValues, Object item) {
            IMap abstractMap = (IMap) aggregatedValues;
            abstractMap.put(mapper.key(item), item);
        }
    }


    /**
     * @param items - List of items to map
     * @param mapper - KeyMapper instance which produce map key for given item.
     * @return Map of items where Item is map's value and key is produced by KeyMapper.
     */
    public static Map<Object, Object> mapBy(List<Object> items, KeyMapper mapper) {
        return (Map<Object, Object>) ((IMap) reduce(items, new ReducerToMapByKeyMapper(mapper), new MapByObject(new Map<Object, Object>()))).toMap();
    }

    /**
     * KeyMapper implementations determine Map's key for given object.
     */
    public interface KeyMapper {
        Object key(Object item);
    }

    /**
     * @param items List of items to map
     * @param mapper Mapper instance which produce Map's Key and Value for each collection item.
     * @return Map of items where both key and value are produced by Mapper implementation.
     */
    public static Map<Object, Object> mapBy(List<Object> items, Mapper mapper) {
        Map<Object, Object> mappedItems = new Map<Object, Object>();

        for (Integer i = 0, size = items.size(); i < size; ++i) {
            Object item = items[i];
            mappedItems.put(mapper.key(item), mapper.value(item));
        }

        return mappedItems;
    }

    /**
     * Mapper implementations determine Map's key and value for given object.
     */
    public interface Mapper {
        Object key(Object item);
        Object value(Object item);
    }


    /**
     * Groups records by given field
     * @return Map where field is the key and List of items is the value
     */
    public static Map<String, List<SObject>> groupByStringField(List<SObject> records, SObjectField field) {
        return groupByStringField(records, '' + field);
    }
    public static Map<String, List<SObject>> groupByStringField(List<SObject> records, String field) {
        return (Map<String, List<SObject>>) groupByField(records, field, new MapByString(new Map<String, List<SObject>>()));
    }

    public static Map<Id, List<SObject>> groupByIdField(List<SObject> records, SObjectField field) {
        return groupByIdField(records, '' + field);
    }
    public static Map<Id, List<SObject>> groupByIdField(List<SObject> records, String field) {
        return (Map<Id, List<SObject>>) groupByField(records, field, new MapById(new Map<Id, List<SObject>>()));
    }

    public static Map<Integer, List<SObject>> groupByIntegerField(List<SObject> records, SObjectField field) {
        return groupByIntegerField(records, '' + field);
    }
    public static Map<Integer, List<SObject>> groupByIntegerField(List<SObject> records, String field) {
        return (Map<Integer, List<SObject>>) groupByField(records, field, new MapByInteger(new Map<Integer, List<SObject>>()));
    }

    public static Map<Decimal, List<SObject>> groupByDecimalField(List<SObject> records, SObjectField field) {
        return groupByDecimalField(records, '' + field);
    }
    public static Map<Decimal, List<SObject>> groupByDecimalField(List<SObject> records, String field) {
        return (Map<Decimal, List<SObject>>) groupByField(records, field, new MapByDecimal(new Map<Decimal, List<SObject>>()));
    }

    public static Map<Date, List<SObject>> groupByDateField(List<SObject> records, SObjectField field) {
        return groupByDateField(records, '' + field);
    }
    public static Map<Date, List<SObject>> groupByDateField(List<SObject> records, String field) {
        return (Map<Date, List<SObject>>) groupByField(records, field, new MapByDate(new Map<Date, List<SObject>>()));
    }

    public static Map<Datetime, List<SObject>> groupByDatetimeField(List<SObject> records, SObjectField field) {
        return groupByDatetimeField(records, '' + field);
    }
    public static Map<Datetime, List<SObject>> groupByDatetimeField(List<SObject> records, String field) {
        return (Map<Datetime, List<SObject>>) groupByField(records, field, new MapByDatetime(new Map<Datetime, List<SObject>>()));
    }

    public static Map<Boolean, List<SObject>> groupByBooleanField(List<SObject> records, SObjectField field) {
        return groupByBooleanField(records, '' + field);
    }
    public static Map<Boolean, List<SObject>> groupByBooleanField(List<SObject> records, String field) {
        return (Map<Boolean, List<SObject>>) groupByField(records, field, new MapByBoolean(new Map<Boolean, List<SObject>>()));
    }

    public static Map<Object, List<SObject>> groupByField(List<SObject> records, SObjectField field) {
        return groupByField(records, '' + field);
    }
    public static Map<Object, List<SObject>> groupByField(List<SObject> records, String field) {
        return (Map<Object, List<SObject>>) groupByField(records, field, new MapByObject(new Map<Object, List<SObject>>()));
    }

    private static Object groupByField(List<SObject> records, String field, IMap abstractMap) {
        KeyMapper mapByField = new SObjectFieldKeyMapper(field);
        Reducer reducer = new ReducerToGroupByKeyMapper(mapByField);

        return ((IMap) reduce(records, reducer, abstractMap)).toMap();
    }


    /**
     * @param records List of items to group
     * @param keyMapper KeyMapper implementation which for each collection item produces Map key.
     *
     * @return Map where Map's Key is produced by KeyMapper and Map's Value is list of collection items which share the same key.
     */
    public static Map<Object, List<Object>> groupBy(List<Object> records, KeyMapper keyMapper) {
        return (Map<Object, List<Object>>) ((IMap) reduce(records, new ReducerToGroupByKeyMapper(keyMapper), new MapByObject(new Map<Object, List<Object>>()))).toMap();
    }

    public class ReducerToGroupByKeyMapper implements Reducer {
        private KeyMapper mapper;

        public ReducerToGroupByKeyMapper(KeyMapper mapper) {
            this.mapper = mapper;
        }

        public void reduce(Object aggregatedValues, Object item) {
            IMap mapInstance = (IMap) aggregatedValues;
            SObject record = (SObject) item;
            Object key = mapper.key(item);

            if (!mapInstance.containsKey(key)) {
                mapInstance.put(key, new List<SObject>());
            }

            List<SObject> groupedRecords = (List<SObject>) mapInstance.get(key);
            groupedRecords.add(record);
        }
    }


    /**
     * @param records List of items to group
     * @param mapper Mapper implementation which for each collection item produces Map key and value.
     *
     * @return Map where Map's key is produced by Mapper's Key() method and Map's value is list of objects
     * created by Mapper's value() method which share the same key.
     */
    public static Map<Object, List<Object>> groupBy(List<SObject> records, Mapper mapper) {
        return (Map<Object, List<Object>>) ((IMap) reduce(records, new ReducerToGroupByMapper(mapper), new MapByObject(new Map<Object, List<Object>>()))).toMap();
    }
    public class ReducerToGroupByMapper implements Reducer {
        private Mapper mapper;

        public ReducerToGroupByMapper(Mapper mapper) {
            this.mapper = mapper;
        }

        public void reduce(Object aggregatedValues, Object item) {
            IMap mapInstance = (IMap) aggregatedValues;
            Object key = mapper.key(item);
            Object value = mapper.value(item);

            if (!mapInstance.containsKey(key)) {
                mapInstance.put(key, new List<Object>());
            }

            List<Object> groupedRecords = (List<Object>) mapInstance.get(key);
            groupedRecords.add(value);
        }
    }


    /**
     * Reduces collection of objects to other collection of given type.
     * @param items input collection to reduce
     * @param reducer Reducer interface implementation. @see Collections.Reducer
     * @param result collection to which input is reduced.
     * <pre>
     * @example
     * reduce(List<Account> accounts, AccountToIdReducer, Set<Id> accountIds);
     *
     * class AccountToIdReducer implements Reducer{
     *  public reduce(Object ids, Object item){
     *      Set<Id> accountIds = (Set<Id>) ids;
     *      accountIds.put( ((Account) item).Id );
     *  }
     * </pre>
     */
    public static Object reduce(List<Object> items, Reducer reducer, Object result) {
        for (Integer i = 0, size = items.size(); i < size; ++i) {
            reducer.reduce(result, items[i]);
        }

        return result;
    }
    /**
     * @param aggregatedValues Collection which holds values reduced so far.
     * @param item currently processed item.
     */
    public interface Reducer {
        void reduce(Object aggregatedValues, Object item);
    }


    /**
     * @return List of SObjects which field is the same as given value.
     */
    public static List<SObject> filterByFieldValue(List<SObject> records, SObjectField field, Object value) {
        return filterByFieldValue(records, '' + field, value);
    }
    public static List<SObject> filterByFieldValue(List<SObject> records, String field, Object value) {
        return filter(records, new FieldValueFilter(field, value));
    }
    public class FieldValueFilter implements Filter {
        private Object value;
        private String field;

        public FieldValueFilter(String field, Object value) {
            this.value = value;
            this.field = field;
        }

        public Boolean accepts(SObject record) {
            return record.get(field) == this.value;
        }
    }


    /**
     * @return List of SObjects where given field contains any of the given values.
     */
    public static List<SObject> filterByFieldValues(List<SObject> records, SObjectField field, Set<Object> values) {
        return filterByFieldValues(records, '' + field, values);
    }
    public static List<SObject> filterByFieldValues(List<SObject> records, String field, Set<Object> values) {
        return filter(records, new FieldValuesFilter(field, values));
    }
    public class FieldValuesFilter implements Filter {
        private Set<Object> values;
        private String field;

        public FieldValuesFilter(String field, Set<Object> values) {
            this.values = values;
            this.field = field;
        }

        public Boolean accepts(SObject record) {
            return values.contains(record.get(field));
        }
    }


    /**
     * @param records List of items to filter.
     * @param filter Filter implementation which for each collection item returns boolean value whether item should
     * be included in the output or not.
     *
     * @return List of items for which filter returned "true".
     */
    public static List<SObject> filter(List<SObject> records, Filter filter) {
        List<SObject> filtered = getNewListOfTheSameSObjectType(records);
        return (List<SObject>) reduce(records, new ReducerByFilter(filter), filtered);
    }

    public interface Filter {
        Boolean accepts(SObject record);
    }

    public class ReducerByFilter implements Reducer {
        private Filter filter;
        public ReducerByFilter(Filter filter) {
            this.filter = filter;
        }

        public void reduce(Object aggregatedValues, Object item) {
            List<SObject> filteredRecords = (List<SObject>) aggregatedValues;
            SObject record = (SObject) item;

            if (filter.accepts(record)) {
                filteredRecords.add(record);
            }
        }
    }


    /**
     * @param records List of Trigger New records
     * @param oldRecords Trigger oldMap
     * @param filter UpdateFilter interface implementation, which for new and old record return boolean value whether
     * new record should be included in output.
     *
     * @return Subset of records parameter for which UpdateFilter returned "true".
     */
    public static List<SObject> filter(List<SObject> records, Map<Id, SObject> oldRecords, UpdateFilter filter) {
        List<SObject> filtered = getNewListOfTheSameSObjectType(records);

        for (Integer i = 0, size = records.size(); i < size; ++i) {
            SObject record = records[i];
            SObject oldRecord = oldRecords.get(record.Id);

            if (filter.accepts(record, oldRecord)) {
                filtered.add(record);
            }
        }

        return filtered;
    }

    public interface UpdateFilter {
        Boolean accepts(SObject record, SObject oldRecord);
    }


    /**
     * @param records List of SObject records to sort.
     * @param field Field to sort by.
     * @param isAscending true -> ascending order, false -> descending order.
     *
     * @return Sorted list of records.
     */
    public static List<SObject> sort(List<SObject> records, SObjectField field, Boolean isAscending) {
        return (List<SObject>) sort(records, new SObjectFieldComparator(field, isAscending));
    }

    public class SObjectFieldComparator implements Comparator {
        private SObjectField field;
        private Integer direction;
        private Comparator fieldTypeComparator;

        public SObjectFieldComparator(SObjectField field, Boolean isAscending) {
            this.field = field;
            this.direction = isAscending ? 1 : -1;
            DisplayType type = field.getDescribe().getType();
            this.fieldTypeComparator = comparatorsByFieldType.get(type);

            if (fieldTypeComparator == null) {
                throw new SortException('FIELD_TYPE_UNSUPPORTED: [' + type + ']');
            }
        }

        public Integer compare(Object thisItem, Object otherItem) {
            Object thisValue = ((SObject) thisItem).get(field);
            Object otherValue = ((SObject) otherItem).get(field);

            return fieldTypeComparator.compare(thisValue, otherValue) * direction;
        }
    }

    private static StringFieldComparator StringFieldComparatorInstance = new StringFieldComparator();
    private static NumericFieldComparator NumericFieldComparatorInstance = new NumericFieldComparator();

    private static Map<Schema.DisplayType, Comparator> comparatorsByFieldType = new Map<DisplayType, Comparator>{
            Schema.DisplayType.ANYTYPE => StringFieldComparatorInstance,
            Schema.DisplayType.BOOLEAN => StringFieldComparatorInstance,
            Schema.DisplayType.COMBOBOX => StringFieldComparatorInstance,
            Schema.DisplayType.CURRENCY => StringFieldComparatorInstance,
            Schema.DisplayType.DATE => StringFieldComparatorInstance,
            Schema.DisplayType.DATETIME => StringFieldComparatorInstance,
            Schema.DisplayType.DOUBLE => NumericFieldComparatorInstance,
            Schema.DisplayType.EMAIL => StringFieldComparatorInstance,
            Schema.DisplayType.ID => StringFieldComparatorInstance,
            Schema.DisplayType.INTEGER => NumericFieldComparatorInstance,
            Schema.DisplayType.PERCENT => NumericFieldComparatorInstance,
            Schema.DisplayType.PHONE => StringFieldComparatorInstance,
            Schema.DisplayType.PICKLIST => StringFieldComparatorInstance,
            Schema.DisplayType.STRING => StringFieldComparatorInstance,
            Schema.DisplayType.TEXTAREA => StringFieldComparatorInstance,
            Schema.DisplayType.TIME => StringFieldComparatorInstance,
            Schema.DisplayType.URL => StringFieldComparatorInstance
    };
    public class StringFieldComparator implements Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            String s1 = thisItem == null ? '' : '' + thisItem;
            String s2 = otherItem == null ? '' : '' + otherItem;
            return s1.compareTo(s2);
        }
    }
    public class NumericFieldComparator implements Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Decimal d1 = thisItem == null ? 0.0 : (Decimal) thisItem;
            Decimal d2 = otherItem == null ? 0.0 : (Decimal) otherItem;

            if (d1 > d2) return 1;
            if (d1 < d2) return -1;
            return 0;
        }
    }
    public class SortException extends Exception {
    }


    /**
     * @param items Collection of items to sort.
     * @param comparator Comparator implementation which compares 2 items to determine order.
     *
     * @return Sorted list of objects with order determined by comparator.
     */
    public static List<Object> sort(List<Object> items, Comparator comparator) {
        List<ObjectComparable> comparables = new List<ObjectComparable>();

        for (Integer i = 0, size = items.size(); i < size; i++) {
            comparables.add(new ObjectComparable(items[i], comparator));
        }

        comparables.sort();
        List<Object> sorted = items.clone();
        sorted.clear();

        for (Integer i = 0, size = comparables.size(); i < size; i++) {
            sorted.add(comparables[i].item);
        }

        return sorted;
    }

    /**
     * Compares 2 objects to determine their order.
     * The implementation of this method should return the following values:
     * 0 if thisItem and otherItem are equal
     * > 0 if thisItem is greater than otherItem
     * < 0 if thisItem is less than otherItem
     */
    public interface Comparator {
        Integer compare(Object thisItem, Object otherItem);
    }

    public virtual class ObjectComparable implements Comparable {
        private Object item;
        private Comparator comparator;

        public ObjectComparable(Object item, Comparator comparator) {
            this.item = item;
            this.comparator = comparator;
        }

        public Integer compareTo(Object other) {
            return comparator.compare(this.item, ((ObjectComparable) other).item);
        }
    }


    /**
     * Key mapper where key is SObject field.
     */
    public virtual class SObjectFieldKeyMapper implements KeyMapper {
        private String field;

        public SObjectFieldKeyMapper(String field) {
            this.field = field;
        }

        public Object key(Object item) {
            return ((SObject) item).get(field);
        }
    }


    /**
     * @return New empty list of the same SObject type as original.
     */
    public static List<SObject> getNewListOfTheSameSObjectType(List<SObject> original) {
        SObjectType sobjType = getSObjectType(original);

        if (sobjType == null) {
            return new List<SObject>();
        } else {
            return (List<SObject>) Type.forName('List<' + sobjType + '>').newInstance();
        }
    }


    /**
     * @return New empty list of the same SObject type as original.
     */
    public static Object getNewMapOfTheSameSObjectType(Type keyType, List<SObject> records) {
        SObjectType sobjType = getSObjectType(records);

        return Type.forName('Map<' + keyType + ',' +
                (sobjType == null ? 'SObject' : String.valueOf(sobjType))
                + '>').newInstance();
    }


    /**
     * IMap factory method which returns proper IMap implementation for given keyType parameter
     * and initializes it with empty Map of the same sObject type as given records.
     */
    private static IMap getGenericMap(Type keyType, List<SObject> records) {
        Object sfMap = getNewMapOfTheSameSObjectType(keyType, records);

        if (keyType == Id.class) return new MapById((Map<Id, Object>) sfMap);
        if (keyType == String.class) return new MapByString((Map<String, Object>) sfMap);
        if (keyType == Integer.class) return new MapByInteger((Map<Integer, Object>) sfMap);
        if (keyType == Decimal.class) return new MapByDecimal((Map<Decimal, Object>) sfMap);
        if (keyType == Date.class) return new MapByDate((Map<Date, Object>) sfMap);
        if (keyType == Datetime.class) return new MapByDatetime((Map<Datetime, Object>) sfMap);
        if (keyType == Boolean.class) return new MapByBoolean((Map<Boolean, Object>) sfMap);

        return new MapByObject((Map<Object, Object>) sfMap);
    }

    /**
     * Set and Map are not covariant types and there's no Map interface in Salesforce which would allow casting differently typed Maps on abstract Map type.
     * Because of that, we cannot cast Map<Id, Account> to Map<Object,Object> or any other map
     * (unless we serialize and deserialize via JSON). It means, that we cannot have one generic method which would take
     * generic Map and operate on it, we would need separate methods for each type of key.
     * This wrapper is a workaround for this, it lets us use AbstractMap regardless of it's key type.
     * Instead of having separate methods for each kind of map, we have IMap implementations for all primitive key types.
     */
    public interface IMap {
        Object toMap();
        void put(Object key, Object value);
        Object get(Object key);
        Boolean containsKey(Object key);
    }

    public class MapByObject implements IMap {
        private Map<Object, Object> mapInstance;

        public MapByObject(Map<Object, Object> mapInstance) {
            this.mapInstance = mapInstance;
        }
        public void put(Object key, Object value) {
            mapInstance.put(key, (Object) value);
        }
        public Boolean containsKey(Object key) {
            return mapInstance.containsKey(key);
        }
        public Object get(Object key) {
            return mapInstance.get(key);
        }
        public Object toMap() {
            return mapInstance;
        }
    }

    public class MapById implements IMap {
        private Map<Id, Object> mapInstance;

        public MapById(Map<Id, Object> mapInstance) {
            this.mapInstance = mapInstance;
        }
        public void put(Object key, Object value) {
            mapInstance.put((Id) key, (Object) value);
        }
        public Boolean containsKey(Object key) {
            return mapInstance.containsKey((Id) key);
        }
        public Object get(Object key) {
            return mapInstance.get((Id) key);
        }
        public Object toMap() {
            return mapInstance;
        }
    }

    public class MapByString implements IMap {
        private Map<String, Object> mapInstance;

        public MapByString(Map<String, Object> mapInstance) {
            this.mapInstance = mapInstance;
        }
        public void put(Object key, Object value) {
            mapInstance.put((String) key, (Object) value);
        }
        public Boolean containsKey(Object key) {
            return mapInstance.containsKey((String) key);
        }
        public Object get(Object key) {
            return mapInstance.get((String) key);
        }
        public Object toMap() {
            return mapInstance;
        }
    }

    public class MapByInteger implements IMap {
        private Map<Integer, Object> mapInstance;

        public MapByInteger(Map<Integer, Object> mapInstance) {
            this.mapInstance = mapInstance;
        }
        public void put(Object key, Object value) {
            mapInstance.put((Integer) key, (Object) value);
        }
        public Boolean containsKey(Object key) {
            return mapInstance.containsKey((Integer) key);
        }
        public Object get(Object key) {
            return mapInstance.get((Integer) key);
        }
        public Object toMap() {
            return mapInstance;
        }
    }

    public class MapByDecimal implements IMap {
        private Map<Decimal, Object> mapInstance;

        public MapByDecimal(Map<Decimal, Object> mapInstance) {
            this.mapInstance = mapInstance;
        }
        public void put(Object key, Object value) {
            mapInstance.put((Decimal) key, (Object) value);
        }
        public Boolean containsKey(Object key) {
            return mapInstance.containsKey((Decimal) key);
        }
        public Object get(Object key) {
            return mapInstance.get((Decimal) key);
        }
        public Object toMap() {
            return mapInstance;
        }
    }

    public class MapByDate implements IMap {
        private Map<Date, Object> mapInstance;

        public MapByDate(Map<Date, Object> mapInstance) {
            this.mapInstance = mapInstance;
        }
        public void put(Object key, Object value) {
            mapInstance.put((Date) key, (Object) value);
        }
        public Boolean containsKey(Object key) {
            return mapInstance.containsKey((Date) key);
        }
        public Object get(Object key) {
            return mapInstance.get((Date) key);
        }
        public Object toMap() {
            return mapInstance;
        }
    }

    public class MapByDatetime implements IMap {
        private Map<Datetime, Object> mapInstance;

        public MapByDatetime(Map<Datetime, Object> mapInstance) {
            this.mapInstance = mapInstance;
        }
        public void put(Object key, Object value) {
            mapInstance.put((Datetime) key, (Object) value);
        }
        public Boolean containsKey(Object key) {
            return mapInstance.containsKey((Datetime) key);
        }
        public Object get(Object key) {
            return mapInstance.get((Datetime) key);
        }
        public Object toMap() {
            return mapInstance;
        }
    }

    public class MapByBoolean implements IMap {
        private Map<Boolean, Object> mapInstance;

        public MapByBoolean(Map<Boolean, Object> mapInstance) {
            this.mapInstance = mapInstance;
        }
        public void put(Object key, Object value) {
            mapInstance.put((Boolean) key, (Object) value);
        }
        public Boolean containsKey(Object key) {
            return mapInstance.containsKey((Boolean) key);
        }
        public Object get(Object key) {
            return mapInstance.get((Boolean) key);
        }
        public Object toMap() {
            return mapInstance;
        }
    }
}