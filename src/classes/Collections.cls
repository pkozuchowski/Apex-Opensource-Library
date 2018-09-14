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
     * @return sObject type of List<SObject> or first record if former is null.
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
    public static Object getUniqueValues(List<SObject> records, SObjectField field) {
        return getUniqueValues(records, new SObjectFieldKeyMapper(field));
    }

    /**
     * @param valueType Type of single value in a Set ex. String.class
     * @param records List of SObject records from which values are gathered
     * @param field SObject field from which value is taken.
     * @return Set of gathered values.
     */
    public static Object getUniqueValues(Type valueType, List<SObject> records, String field) {
        return getUniqueValues(records, new SObjectFieldKeyMapper(valueType, field));
    }

    /**
     * @param records List of SObject records from which values are gathered
     * @param keyMapper KeyMapper implementation which returns value for each record
     * @return Set of gathered values.
     */
    public static Object getUniqueValues(List<SObject> records, KeyMapper keyMapper) {
        return mapByFieldToIMap(records, keyMapper, getIMap(keyMapper.keyType(), records)).keySet();
    }

    /**
     * @param records List of records to return field values from.
     * @param fields List of fields to return values from.
     * @return Set of unique SObject field values of given fields of given records.
     */
    public static Set<Object> getUniqueValues(List<SObject> records, List<SObjectField> fields) {
        Set<Object> values = new Set<Object>();

        for (Integer fieldIndex = 0, fieldSize = fields.size(); fieldIndex < fieldSize; fieldIndex++) {
            for (Integer i = 0, j = records.size(); i < j; i++) {
                values.add(records[i].get(fields[fieldIndex]));
            }
        }

        return values;
    }








    /**
     * @param keyType Type of result Map key
     * @param items List of SObject records to map
     * @param field SObject Field to map by
     * @return Map of items where record is map's value and key is field's value.
     */
    public static Object mapBy(List<SObject> records, SObjectField field) {
        return mapBy(records, new SObjectFieldKeyMapper(field));
    }

    /**
     * @param keyType Type of result Map key
     * @param items List of SObject records to map
     * @param field SObject Field API name to map by
     * @return Map of items where record is map's value and key is field's value.
     */
    public static Object mapBy(Type keyType, List<SObject> records, String field) {
        return mapBy(records, new SObjectFieldKeyMapper(keyType, field));
    }

    /**
     * @param keyType Type of result Map key
     * @param items List of items to map
     * @param mapper KeyMapper instance which produce map key for given item.
     * @return Map of items where Item is map's value and key is produced by KeyMapper.
     */
    public static Object mapBy(List<Object> items, KeyMapper mapper) {
        return mapByFieldToIMap(items, mapper, getIMap(mapper.keyType(), items)).toMap();
    }



    private static IMap mapByFieldToIMap(List<Object> items, KeyMapper mapper, IMap imap) {
        for (Integer i = 0, j = items.size(); i < j; i++) {
            imap.put(mapper.key(items[i]), items[i]);
        }
        return imap;
    }

    /**
     * KeyMapper implementations determine Map's key for given object.
     */
    public interface KeyMapper {
        Object key(Object item);
        Type keyType();
    }


    /**
     * @param keyType Type of result Map key ex. String.class
     * @param valueType Type of result Map key ex. Account.class
     * @param items List of items to map
     * @param mapper KeyMapper instance which produce map key for given item.
     * @return Map of items where Item is map's value and key is produced by KeyMapper.
     */
    public static Object mapBy(List<Object> items, Mapper mapper) {
        IMap iMap = getIMap(mapper.keyType(), mapper.valueType());

        for (Integer i = 0, j = items.size(); i < j; i++) {
            iMap.put(mapper.key(items[i]), mapper.value(items[i]));
        }
        return iMap.toMap();
    }

    /**
     * Mapper implementations determine Map's key and value for given object.
     */
    public interface Mapper {
        Type keyType();
        Type valueType();
        Object key(Object item);
        Object value(Object item);
    }


    public static Object groupByField(Type keyType, List<SObject> records, SObjectField field) {
        return groupByField(keyType, records, '' + field);
    }
    public static Object groupByField(Type keyType, List<SObject> records, String field) {
        return groupByField(records, field, getIMap(keyType, records));
    }

    private static Object groupByField(List<SObject> records, String field, IMap mapInstance) {
        for (Integer i = 0, j = records.size(); i < j; i++) {
            SObject record = (SObject) records[i];
            Object key = record.get(field);

            if (!mapInstance.containsKey(key)) {
                mapInstance.put(key, new List<SObject>());
            }

            List<SObject> groupedRecords = (List<SObject>) mapInstance.get(key);
            groupedRecords.add(record);
        }
        return mapInstance.toMap();
    }


    /**
     * @param records List of items to group
     * @param keyMapper KeyMapper implementation which for each collection item produces Map key.
     *
     * @return Map where Map's Key is produced by KeyMapper and Map's Value is list of collection items which share the same key.
     */
    public static Object groupBy(Type keyType, List<SObject> records, KeyMapper keyMapper) {
        return null;
    }

    public static Object groupBy(Type keyType, Type objectType, List<Object> records, KeyMapper keyMapper) {
        return null;
    }


    /**
     * @param records List of items to group
     * @param mapper Mapper implementation which for each collection item produces Map key and value.
     *
     * @return Map where Map's key is produced by Mapper's Key() method and Map's value is list of objects
     * created by Mapper's value() method which share the same key.
     */
//    public static Object groupBy(List<SObject> records, Mapper mapper) {
//
//        for (Integer i = 0, j = records.size(); i < j; i++) {
//            SObject record = (SObject) records[i];
//            Object key = mapper.key(record);
//            Object value = mapper.value(item);
//
//            if (!mapInstance.containsKey(key)) {
//                mapInstance.put(key, new List<SObject>());
//            }
//
//            List<SObject> groupedRecords = (List<SObject>) mapInstance.get(key);
//            groupedRecords.add(record);
//        }
//
//        return iMap.toMap();
//    }


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
        return (List<SObject>) filter(records, new FieldValueFilter(field, value));
    }
    public class FieldValueFilter implements Filter {
        private Object value;
        private String field;

        public FieldValueFilter(String field, Object value) {
            this.value = value;
            this.field = field;
        }

        public Boolean accepts(Object record) {
            return ((SObject) record).get(field) == this.value;
        }
    }


    /**
     * @return List of SObjects where given field contains any of the given values.
     */
    public static List<SObject> filterByFieldValues(List<SObject> records, SObjectField field, Set<Object> values) {
        return filterByFieldValues(records, '' + field, values);
    }
    public static List<SObject> filterByFieldValues(List<SObject> records, String field, Set<Object> values) {
        return (List<SObject>) filter(records, new FieldValuesFilter(field, values));
    }
    public class FieldValuesFilter implements Filter {
        private Set<Object> values;
        private String field;

        public FieldValuesFilter(String field, Set<Object> values) {
            this.values = values;
            this.field = field;
        }

        public Boolean accepts(Object record) {
            return values.contains(((SObject) record).get(field));
        }
    }


    /**
     * @param records List of items to filter.
     * @param filter Filter implementation which for each collection item returns boolean value whether item should
     * be included in the output or not.
     *
     * @return List of items for which filter returned "true".
     */
    public static List<Object> filter(List<Object> records, Filter filter) {
        List<Object> filtered = newListOfTheSameType(records);

        for (Integer i = 0, j = records.size(); i < j; i++) {
            if (filter.accepts(records[i])) {
                filtered.add(records[i]);
            }
        }

        return filtered;
    }

    public interface Filter {
        Boolean accepts(Object record);
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
        List<SObject> filtered = (List<SObject>) newListOfTheSameType(records);

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
        private Type keyType;

        public SObjectFieldKeyMapper(Type keyType, String field) {
            this.keyType = keyType;
            this.field = field;
        }

        public SObjectFieldKeyMapper(SObjectField field) {
            this.keyType = TYPE_BY_FIELD_TYPE.get(field.getDescribe().getType());
            this.field = '' + field;
        }

        public Object key(Object item) {
            return ((SObject) item).get(field);
        }

        public Type keyType() {
            return keyType;
        }
    }


    /**
     * @return New empty list of the same SObject type as original.
     */
    public static List<Object> newListOfTheSameType(List<Object> original) {
        List<Object> clone = original.clone();
        clone.clear();

        return clone;
    }


    /**
     * IMap factory method which returns proper IMap implementation for given keyType parameter
     * and initializes it with empty Map of the same sObject type as given records.
     */
    private static IMap getIMap(Type keyType, List<Object> records) {
        return getIMap(keyType, getListItemType(records));
    }

    private static IMap getIMap(Type keyType, Type objectType) {
        Object sfMap = Type.forName('Map<' + keyType + ',' + objectType + '>').newInstance();

        if (keyType == Id.class) return new MapById((Map<Id, Object>) sfMap);
        if (keyType == String.class) return new MapByString((Map<String, Object>) sfMap);
        if (keyType == Integer.class) return new MapByInteger((Map<Integer, Object>) sfMap);
        if (keyType == Decimal.class) return new MapByDecimal((Map<Decimal, Object>) sfMap);
        if (keyType == Date.class) return new MapByDate((Map<Date, Object>) sfMap);
        if (keyType == Datetime.class) return new MapByDatetime((Map<Datetime, Object>) sfMap);
        if (keyType == Boolean.class) return new MapByBoolean((Map<Boolean, Object>) sfMap);

        return new MapByObject((Map<Object, Object>) sfMap);
    }

    private static Type getListItemType(Object o) {
        try {
            Date d = (Date) o;
            return Date.class;
        } catch (Exception ex) {
            String typeName = ex.getMessage().substringBetween('Invalid conversion from runtime type List<', '> to Date');
            return Type.forName(typeName);
        }
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
        Object keySet();
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
        public Object keySet() {
            return mapInstance.keySet();
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
        public Object keySet() {
            return mapInstance.keySet();
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
        public Object keySet() {
            return mapInstance.keySet();
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
        public Object keySet() {
            return mapInstance.keySet();
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
        public Object keySet() {
            return mapInstance.keySet();
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
        public Object keySet() {
            return mapInstance.keySet();
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
        public Object keySet() {
            return mapInstance.keySet();
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
        public Object keySet() {
            return mapInstance.keySet();
        }
    }


    private final static Map<Schema.DisplayType, Type> TYPE_BY_FIELD_TYPE = new Map<DisplayType, Type>{
            Schema.DisplayType.ID => Id.class,
            Schema.DisplayType.REFERENCE => Id.class,
            Schema.DisplayType.INTEGER => Integer.class,
            Schema.DisplayType.ADDRESS => String.class,
            Schema.DisplayType.ANYTYPE => Object.class,
            Schema.DisplayType.BASE64 => String.class,
            Schema.DisplayType.BOOLEAN => Boolean.class,
            Schema.DisplayType.COMBOBOX => String.class,
            Schema.DisplayType.CURRENCY => Decimal.class,
            Schema.DisplayType.DATE => Date.class,
            Schema.DisplayType.DATETIME => Datetime.class,
            Schema.DisplayType.DOUBLE => Decimal.class,
            Schema.DisplayType.EMAIL => String.class,
            Schema.DisplayType.ENCRYPTEDSTRING => String.class,
            Schema.DisplayType.JSON => String.class,
            Schema.DisplayType.LOCATION => Decimal.class,
            Schema.DisplayType.MULTIPICKLIST => String.class,
            Schema.DisplayType.PERCENT => Decimal.class,
            Schema.DisplayType.PHONE => String.class,
            Schema.DisplayType.PICKLIST => String.class,
            Schema.DisplayType.STRING => String.class,
            Schema.DisplayType.TEXTAREA => String.class,
            Schema.DisplayType.TIME => Time.class,
            Schema.DisplayType.URL => String.class
    };
}