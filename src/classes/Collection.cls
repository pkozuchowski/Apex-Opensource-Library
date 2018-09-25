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
public class Collection {
    public final static Boolean
            ASCENDING = true,
            DESCENDING = false,
            ANY_VALUE = true;

    public final static String
            EQUALS = '==',
            NOT_EQUALS = '!=',
            GREATER_THAN = '>',
            GREATER_EQUAL_THAN = '>=',
            LESS_THAN = '<',
            LESS_EQUAL_THAN = '<=',
            VALUE_IN = 'IN',
            VALUE_NOT_IN = 'NOT IN';

    private List<Object> items;
    private Map<Id, SObject> old;


    public Collection(List<Object> items) {
        this.items = items;
    }

    /*
    * Constructor used for update trigger.
    * */
    public Collection(List<SObject> items, Map<Id, SObject> old) {
        this.items = items;
        this.old = old;
    }

    /*
    * @return Salesforce List collection
    * */
    public List<Object> toList() {
        return items;
    }

    /**
     * @return true when collection is not null or empty, false otherwise.
     */
    public Boolean isNotEmpty() {
        return Collection.isNotEmpty(items);
    }

    /**
     * @return true when collection is null or empty, false otherwise.
     */
    public Boolean isEmpty() {
        return Collection.isEmpty(items);
    }


    /**
     * @param field SObject field from which value is taken.
     * @return Set of gathered values.
     */
    public Object getUniqueValues(SObjectField field) {
        assertSObjectCollection();
        return Collection.getUniqueValues((SObject[]) items, field);
    }

    /**
     * @param field SObject field from which value is taken.
     * @return Set of gathered values.
     */
    public Object getUniqueValues(Type valueType, String field) {
        assertSObjectCollection();
        return Collection.getUniqueValues(valueType, (SObject[]) items, field);
    }

    /**
     * @param keyMapper KeyMapper implementation which returns value for each record
     * @return Set of gathered values.
     */
    public Object getUniqueValues(KeyMapper keyMapper) {
        return Collection.getUniqueValues(items, keyMapper);
    }

    /**
     * @param fields List of fields to return values from.
     * @return Set of unique SObject field values of given fields of given records.
     */
    public Set<Object> getUniqueValues(List<SObjectField> fields) {
        assertSObjectCollection();
        return Collection.getUniqueValues((SObject[]) items, fields);
    }


    /**
     * @param field SObject Field to map by
     * @return Map of items where record is map's value and field's value is map's key.
     * Map's key type is derived from field's DisplayType.
     */
    public Object mapBy(SObjectField field) {
        assertSObjectCollection();
        return Collection.mapBy((List<SObject>) items, field);
    }

    /**
     * @param keyType Type of returned map's key
     * @param field SObject Field API name to map by
     * @return Map of items where record is map's value and field's value is map's key.
     */
    public Object mapBy(Type keyType, String field) {
        assertSObjectCollection();
        return Collection.mapBy(keyType, (List<SObject>) items, field);
    }

    /**
     * @param mapper KeyMapper instance which produce map key for given item.
     * @return Map of items where list item is map's value and key is produced by KeyMapper.
     */
    public Object mapBy(KeyMapper mapper) {
        return Collection.mapBy(items, mapper);
    }

    /**
     * @param mapper Mapper instance which produce map key and value for given item.
     * @return Map of items where Item is map's value and key is produced by KeyMapper.
     */
    public Object mapBy(Mapper mapper) {
        return Collection.mapBy(items, mapper);
    }


    /**
     * Groups collection items by given field to map where key
     * is the field's value and the value is List<SObject> which have the same key.
     * @param field SObject Field
     */
    public Object groupBy(SObjectField field) {
        assertSObjectCollection();
        return Collection.groupBy((SObject[]) items, field);
    }

    /**
     * Groups collection items by given field to map where key
     * is the field's value and the value is List<SObject> which have the same key.
     * @param keyType Type of the key ex. String.class, Id.class
     * @param field SObject Field
     */
    public Object groupBy(Type keyType, String field) {
        assertSObjectCollection();
        return Collection.groupBy(keyType, (SObject[]) items, field);
    }

    /**
     * Groups collection items by given KeyMapper implementation to Map<Key, List<Value>>, where
     * key is produced by the key mapper and the value is List<Object> which have the same key.
     * @param keyMapper Collection.KeyMapper implementation.
     */
    public Object groupBy(KeyMapper keyMapper) {
        return Collection.groupBy(items, keyMapper);
    }

    /**
     * Groups collection items by given KeyMapper implementation to Map<Key, List<Value>>, where
     * both key and values are produced by Mapper for each collection item.
     *
     * @param Mapper Collection.Mapper implementation.
     */
    public Object groupBy(Mapper mapper) {
        return Collection.groupBy(items, mapper);
    }


    /**
     * Reduces collection to resulting object.
     *
     * @param reducer Collection.Reducer implementation which reduces each item to resulting object.
     * @param result Instance of the result.
     */
    public Object reduce(Reducer reducer, Object result) {
        return Collection.reduce(items, reducer, result);
    }


    /**
     * Wraps objects into Wrapper implementation.
     * @param wrapperType Type of concrete class implementing Wrapper interface. Must provide no-args constructor.
     */
    public Collection wrap(Type wrapperType) {
        return new Collection(Collection.wrap(items, wrapperType));
    }


    /**
     * Sorts collection by given field and order.
     * @param field Field to sort by.
     * @param isAscending true -> ascending order, false -> descending order.
     * Collection.ASCENDING/DESCENDING can be used instead.
     */
    public Collection sort(SObjectField field, Boolean isAscending) {
        assertSObjectCollection();
        return new Collection(Collection.sort((List<SObject>) items, field, isAscending));
    }

    /**
     * Sorts collection using given Collection.Comparator implementation.
     * @param field Field to sort by.
     * @param isAscending true -> ascending order, false -> descending order.
     * Collection.ASCENDING/DESCENDING can be used instead.
     */
    public Collection sort(Comparator comparator) {
        return new Collection(Collection.sort(items, comparator));
    }


    /**
     * Filters collection items using ByFieldValue filter.
     * @see CollectionFilter.ByFieldValue
     */
    public Collection filter(SObjectField field, String operator, Object value) {
        assertSObjectCollection();
        return filter(new CollectionFilter.ByFieldValue(field, operator, value));
    }


    /**
     * Filters collection items using given Filter implementation.
     * @param filter Filter implementation which for each collection item returns boolean value whether item should
     * be included in the output or not.
     */
    public Collection filter(Filter filter) {
        return new Collection(Collection.filter(items, filter));
    }


    /**
     * Filters collection items using given Filter implementation.
     * @param filter UpdateFilter interface implementation, which for new and old record return boolean value whether
     * new record should be included in output.
     */
    public Collection filter(UpdateFilter filter) {
        assertSObjectCollection();
        assert(old != null, 'Operation only applies to Collections initialized ' +
                'with Collection(List<SObject>, Map<Id,SObject>) oldMap constructor.'
        );
        return new Collection(Collection.filter((List<SObject>) items, old, filter));
    }


    /**
     * Fills in the list with number of clones of provided prototype record.
     * By default, clone is deep and Id, timestamps and autonumbers are not preserved.
     *
     * @param listToFill List to fill in.
     * @param count Number of clones in the list
     * @param prototype Prototype of the record. Clone of this record will be added to the list.
     */
    public Collection fill(Integer count, SObject prototype) {
        assertSObjectCollection();
        return new Collection(fill((List<SObject>) items, count, prototype));
    }

    /**
     * Fills in the list with number of clones of provided prototype record.
     * @param listToFill List to fill in.
     * @param count Number of clones in the list
     * @param prototype Prototype of the record. Clone of this record will be added to the list.
     * @param opts Collection.CloneOptions instance which determine clone operation characteristics.
     */
    public Collection fill(Integer count, SObject prototype, CloneOptions cloneOptions) {
        assertSObjectCollection();
        return new Collection(fill((List<SObject>) items, count, prototype, cloneOptions));
    }


    private void assertSObjectCollection() {
        assert(items instanceof List<SObject>, 'Operation only applies to SObject collection.');
    }

    private void assert(Boolean condition, String errorMsg) {
        if (!condition) throw new CollectionException(errorMsg);
    }


    /*
    *
    *
    * STATIC METHODS
    *
    *
    * */
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


    /*
    * @return returns Type of given list single element
    * */
    public static Type getListItemType(List<Object> o) {
        return getType(o, 'Invalid conversion from runtime type List<', '> to Date');
    }

    /*
    * @return returns Type of given object
    * */
    public static Type getType(Object o) {
        return getType(o, 'Invalid conversion from runtime type ', ' to Date');
    }

    private static Type getType(Object o, String open, String close) {
        try {
            Date d = (Date) o;
            return Date.class;
        } catch (Exception ex) {
            String typeName = ex.getMessage().substringBetween(open, close);
            return Type.forName(typeName);
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
     * @param itemType Type of single list element
     * @return New list of given item type.
     */
    public static List<Object> newListOfItemType(Type itemType) {
        return newListOfItemType(itemType, new List<Object>());
    }

    /**
     * @param itemType Type of single list element
     * @param fallbackItemType Fallback type, in case primary type is not constructible (ex. because the type is private).
     * @return New list of given item type.
     */
    public static List<Object> newListOfItemType(Type itemType, List<Object> fallback) {
        try {
            return (List<Object>) Type.forName('List<' + itemType + '>').newInstance();
        } catch (Exception ex) {
            return null;
        }
    }


    /*
    * GET UNIQUE VALUES
    * */
    /**
     * @param records List of SObject records from which values are gathered.
     * @param field SObject field from which value is taken.
     * @return Set of gathered values.
     */
    public static Object getUniqueValues(List<SObject> records, SObjectField field) {
        return getUniqueValues(records, new CollectionMapper.ByField(field));
    }

    /**
     * @param valueType Type of single value in a Set ex. String.class
     * @param records List of SObject records from which values are gathered
     * @param field SObject field from which value is taken.
     * @return Set of gathered values.
     */
    public static Object getUniqueValues(Type valueType, List<SObject> records, String field) {
        return getUniqueValues(records, new CollectionMapper.ByField(valueType, field));
    }

    /**
     * @param records List of items from which values are gathered
     * @param keyMapper KeyMapper implementation which returns value for each record
     * @return Set of gathered values.
     */
    public static Object getUniqueValues(List<Object> records, KeyMapper keyMapper) {
        return mapByFieldToIMap(records, new CollectionMapper.ByKeyMapper(keyMapper, getListItemType(records))).keySet();
    }

    /**
     * @param records List of records to return field values from.
     * @param fields List of fields to return values from.
     * @return Set of unique SObject field values of given fields of given records.
     */
    public static Set<Object> getUniqueValues(List<SObject> records, List<SObjectField> fields) {
        Set<Object> values = new Set<Object>();

        for (Integer fieldIndex = 0, fieldSize = fields.size(); fieldIndex < fieldSize; fieldIndex++) {
            SObjectField field = fields[fieldIndex];

            for (Integer i = 0, j = records.size(); i < j; i++) {
                values.add(records[i].get(field));
            }
        }

        return values;
    }


    /*
    * MAP BY
    * */

    /**
     * KeyMapper implementations determine Map's key for given object and key's type.
     */
    public interface KeyMapper {
        Object key(Object item);
        Type keyType();
    }

    /**
     * Mapper implementations determine Map's key and value for given object and types of key and value.
     */
    public interface Mapper {
        Type keyType();
        Type valueType();
        Object key(Object item);
        Object value(Object item);
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


    /**
     * @param items List of SObject records to map
     * @param field SObject Field to map by
     * @return Map of items where record is map's value and field's value is map's key.
     * Map's key type is derived from field's DisplayType.
     */
    public static Object mapBy(List<SObject> records, SObjectField field) {
        return mapBy(records, new CollectionMapper.ByField(field));
    }

    /**
     * @param keyType Type of returned map's key
     * @param items List of SObject records to map
     * @param field SObject Field API name to map by
     * @return Map of items where record is map's value and field's value is map's key.
     */
    public static Object mapBy(Type keyType, List<SObject> records, String field) {
        return mapBy(records, new CollectionMapper.ByField(keyType, field));
    }

    /**
     * @param items List of items to map
     * @param mapper KeyMapper instance which produce map key for given item.
     * @return Map of items where list item is map's value and key is produced by KeyMapper.
     */
    public static Object mapBy(List<Object> items, KeyMapper mapper) {
        return mapByFieldToIMap(items, new CollectionMapper.ByKeyMapper(mapper, getListItemType(items))).toMap();
    }

    /**
     * @param keyType Type of result Map key ex. String.class
     * @param valueType Type of result Map key ex. Account.class
     * @param items List of items to map
     * @param mapper KeyMapper instance which produce map key for given item.
     * @return Map of items where Item is map's value and key is produced by KeyMapper.
     */
    public static Object mapBy(List<Object> items, Mapper mapper) {
        return mapByFieldToIMap(items, mapper).toMap();
    }

    /*
    * Internal method. Maps items to IMap instance.
    * */
    private static IMap mapByFieldToIMap(List<Object> items, Mapper mapper) {
        IMap imap = CollectionMap.newMap(mapper.keyType(), mapper.valueType());

        for (Integer i = 0, j = items.size(); i < j; i++) {
            Object item = items[i];
            imap.put(mapper.key(item), mapper.value(item));
        }
        return imap;
    }


    /*
    * GROUP BY
    * */

    /**
    * Groups collection items by given field to map where key
    * is the field's value and the value is List<SObject> which have the same key.
    * @param records SObject list to group.
    * @param field SObject Field
    * @return Map<FieldValue : FieldType, List<SObject>>
    */
    public static Object groupBy(List<SObject> records, SObjectField field) {
        return groupBy(records, new CollectionMapper.ByField(field));
    }

    /**
     * Groups collection items by given field to map where key
     * is the field's value and the value is List<SObject> which have the same key.
     * @param keyType Type of the key ex. String.class, Id.class
     * @param records SObject list to group.
     * @param field SObject Field
     * @return Map<FieldValue : keyType, List<SObject>>
     */
    public static Object groupBy(Type keyType, List<SObject> records, String field) {
        return groupBy(records, new CollectionMapper.ByField(keyType, field));
    }

    /**
     * Groups collection items by given KeyMapper implementation to Map<Key, List<Value>>, where
     * both key and values are produced by Mapper for each collection item.
     * @param records List of items to group
     * @param keyMapper KeyMapper implementation which for each collection item produces Map key.
     * @return Map<KeyMapper.key() : KeyMapper.keyType(), List<Object>>
     */
    public static Object groupBy(List<Object> items, KeyMapper keyMapper) {
        return groupBy(items, new CollectionMapper.ByKeyMapper(keyMapper, getListItemType(items)));
    }

    /**
     * Groups collection items by given KeyMapper implementation to Map<Key, List<Value>>, where
     * both key and values are produced by Mapper for each collection item.
     *
     * @param records List of items to group
     * @param mapper Mapper implementation which for each collection item produces Map key and value.
     * @return Map<Mapper.key() : Mapper.keyType(), List<Mapper.value() : Mapper.valueType()>>
     */
    public static Object groupBy(List<Object> items, Mapper mapper) {
        IMap imap = CollectionMap.newMap(mapper.keyType(), Type.forName('List<' + mapper.valueType() + '>'));

        for (Integer i = 0, j = items.size(); i < j; i++) {
            SObject item = (SObject) items[i];
            Object key = mapper.key(item);
            Object value = mapper.value(item);

            if (!imap.containsKey(key)) {
                imap.put(key, newListOfItemType(mapper.valueType()));
            }

            List<Object> groupedRecords = (List<Object>) imap.get(key);
            groupedRecords.add(value);
        }

        return imap.toMap();
    }


    /*
    * REDUCE
    * */

    /**
     * Reduces collection of objects to other collection or object of given type.
     * @param items input collection to reduce
     * @param reducer Reducer interface implementation. @see Collections.Reducer
     * @param result collection/object to which input is reduced.
     * @return result after reduction.
     * <pre>
     * @example
     * Set<Id> accountIds = reduce(List<Account> accounts, AccountToIdReducer, Set<Id> accountIds);
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


    /*
    * WRAP
    * */

    /**
     * Wrapper interface.
     * Concrete method implementing this interface should have a member variable for wrapped item.
     * setItem method should set that member variable.
     */
    public interface Wrapper {
        void setItem(Object item);
    }

    /**
     * Wraps each item into Wrapper class
     *
     * @param items List of objects to wrap.
     * @param wrapperType Type of concrete class implementing Wrapper interface. Must provide no-args constructor and have
     * public accessor.
     * @return List of Wrappers
     */
    public static List<Wrapper> wrap(List<Object> items, Type wrapperType) {
        List<Wrapper> wrappers = (List<Wrapper>) newListOfItemType(wrapperType, new List<Wrapper>());

        for (Integer i = 0, j = items.size(); i < j; i++) {
            Wrapper wrapper = (Wrapper) wrapperType.newInstance();
            wrapper.setItem(items[i]);
            wrappers.add(wrapper);
        }

        return wrappers;
    }


    /*
    * FOR EACH
    * */

    /**
     * Worker performs action on each item in collection.
     */
    public interface Worker {
        void forEach(Object item, Integer index);
    }

    /**
     * For each element in collection, Worker.forEach action is executed.
     *
     * @param items List of items to execute action on
     * @param worker Concrete class implementing Worker interface. Executes action on each element.
     */
    public static void forEach(List<Object> items, Worker worker) {
        for (Integer i = 0, j = items.size(); i < j; i++) {
            worker.forEach(items[i], i);
        }
    }


    /*
    * FILTER
    * */

    /*
    * Filter determines whether collection item should be included into result collection of filter method.
    * */
    public interface Filter {
        Boolean accepts(Object item);
    }

    /*
    * Filter determines whether collection item should be included into result collection of filter method.
    * This kind of filter compares current record value with Trigger.old value.
    * */
    public interface UpdateFilter {
        Boolean accepts(SObject record, SObject oldRecord);
    }


    /**
     * @param items List of items to filter.
     * @param filter Filter implementation which for each collection item returns boolean value whether item should
     * be included in the output or not.
     *
     * @return List of items for which filter returned "true".
     */
    public static List<Object> filter(List<Object> items, Filter filter) {
        List<Object> filtered = newListOfTheSameType(items);

        for (Integer i = 0, j = items.size(); i < j; i++) {
            Object item = items[i];

            if (filter.accepts(item)) {
                filtered.add(item);
            }
        }

        return filtered;
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


    /*
    * SORT
    * */

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


    /**
     * @param records List of SObject records to sort.
     * @param field Field to sort by.
     * @param isAscending true -> ascending order, false -> descending order.
     *
     * @return Sorted list of records.
     */
    public static List<SObject> sort(List<SObject> records, SObjectField field, Boolean isAscending) {
        return (List<SObject>) sort(records, new CollectionComparator.SObjectFieldComparator(field, isAscending));
    }

    /**
     * @param items Collection of items to sort.
     * @param comparator Comparator implementation which compares 2 items to determine order.
     *
     * @return Sorted list of objects with order determined by comparator.
     */
    public static List<Object> sort(List<Object> items, Comparator comparator) {
        List<ComparableObject> comparables = new List<ComparableObject>();

        for (Integer i = 0, size = items.size(); i < size; i++) {
            comparables.add(new ComparableObject(items[i], comparator));
        }

        comparables.sort();
        List<Object> sorted = newListOfTheSameType(items);

        for (Integer i = 0, size = comparables.size(); i < size; i++) {
            sorted.add(comparables[i].item);
        }

        return sorted;
    }


    private virtual class ComparableObject implements Comparable {
        private Object item;
        private Comparator comparator;

        public ComparableObject(Object item, Comparator comparator) {
            this.item = item;
            this.comparator = comparator;
        }

        public Integer compareTo(Object other) {
            return comparator.compare(this.item, ((ComparableObject) other).item);
        }
    }


    /*
    * FILL
    * */

    /**
     * Fills in the list with number of clones of provided prototype record.
     * By default, clone is deep and Id, timestamps and autonumbers are not preserved.
     *
     * @param listToFill List to fill in.
     * @param count Number of clones in the list
     * @param prototype Prototype of the record. Clone of this record will be added to the list.
     */
    public static List<SObject> fill(List<SObject> listToFill, Integer count, SObject prototype) {
        for (Integer i = 0; i < count; i++) {
            SObject clone = prototype.clone(false, true);
            listToFill.add(clone);
        }
        return listToFill;
    }

    /**
     * Fills in the list with number of clones of provided prototype record.
     * @param listToFill List to fill in.
     * @param count Number of clones in the list
     * @param prototype Prototype of the record. Clone of this record will be added to the list.
     * @param opts Collection.CloneOptions instance which determine clone operation characteristics.
     */
    public static List<SObject> fill(List<SObject> listToFill, Integer count, SObject prototype, CloneOptions opts) {
        for (Integer i = 0; i < count; i++) {
            SObject clone = prototype.clone(
                    opts.preserveId,
                    opts.deepClone,
                    opts.preserveReadonlyTimestamps,
                    opts.preserveAutonumer
            );
            listToFill.add(clone);
        }
        return listToFill;
    }

    public class CloneOptions {
        public Boolean preserveId = false,
                deepClone = true,
                preserveReadonlyTimestamps = false,
                preserveAutonumer = false;

        public CloneOptions() {
        }

        public CloneOptions(Boolean preserveId, Boolean deepClone, Boolean preserveReadonlyTimestamps, Boolean preserveAutonumer) {
            this.preserveId = preserveId;
            this.deepClone = deepClone;
            this.preserveReadonlyTimestamps = preserveReadonlyTimestamps;
            this.preserveAutonumer = preserveAutonumer;
        }
    }


    private class CollectionException extends Exception {
    }
}