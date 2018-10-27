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

    private final static CloneOptions defaultCloneOptions = new CloneOptions(false, true, false, false);

    private List<Object> items;


    public Collection(List<Object> items) {
        this.items = items;
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
     * Filters List of SObject by field value.
     * Operators:
     * <ul>
     *  <li>'==' or Collection.EQUALS</li>
     *  <li>'!=' or Collection.NOT_EQUALS</li>
     *  <li>'>' or Collection.GREATER_THAN</li>
     *  <li>'>=' or Collection.GREATER_EQUAL_THAN</li>
     *  <li>'<' or Collection.LESS_THAN</li>
     *  <li>'<=' or Collection.LESS_EQUAL_THAN</li>
     * </ul>
     *
     * @example
     * <pre>
     *     new Collection(accounts).filter(Account.CreatedDate,'>=', Date.today().addDays(-1));
     * </pre>
     */
    public Collection filter(SObjectField field, String operator, Object value) {
        assertSObjectCollection();
        return new Collection(filter((List<SObject>) items, field, operator, value));
    }


    /**
     * Filters List of SObject by given Prototype record.
     * @return SObject that have the same values in fields as given prototype
     */
    public Collection filter(SObject prototype) {
        return new Collection(filter((List<SObject>) items, prototype));
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
    public Collection filter(Map<Id, SObject> oldMap, UpdateFilter filter) {
        assertSObjectCollection();
        return new Collection(Collection.filter((List<SObject>) items, oldMap, filter));
    }


    /**
     * @return First collection item accepted by Collection.FilterByFieldValue, or null.
     * @see Collection.FilterByFieldValue
     * @see Collection.filter(SObjectField field, String operator, Object value)
     */
    public SObject find(SObjectField field, String operator, Object value) {
        assertSObjectCollection();
        return find((List<SObject>) items, field, operator, value);
    }

    /**
     * @return First collection item which matches all fields specified on prototype.
     */
    public SObject find(SObject prototype) {
        assertSObjectCollection();
        return (SObject) find((List<SObject>) items, new FilterByPrototype(prototype));
    }

    /**
     * @param filter Filter implementation used in the search.
     * @return First collection item accepted by filter or null.
     */
    public Object find(Filter filter) {
        return find(items, filter);
    }


    /**
     * For each element in collection, Worker.forEach action is executed.
     * @param worker Concrete class implementing Worker interface. Executes action on each element.
     */
    public Collection forEach(Worker worker) {
        Collection.forEach(items, worker);
        return this;
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
        return getUniqueValues(records, new MapByField(field));
    }

    /**
     * @param valueType Type of single value in a Set ex. String.class
     * @param records List of SObject records from which values are gathered
     * @param field SObject field from which value is taken.
     * @return Set of gathered values.
     */
    public static Object getUniqueValues(Type valueType, List<SObject> records, String field) {
        return getUniqueValues(records, new MapByField(valueType, field));
    }

    /**
     * @param records List of items from which values are gathered
     * @param keyMapper KeyMapper implementation which returns value for each record
     * @return Set of gathered values.
     */
    public static Object getUniqueValues(List<Object> records, KeyMapper keyMapper) {
        return mapByFieldToIMap(records, new MapByKeyMapper(keyMapper, getListItemType(records))).keySet();
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
     * Set and Map are not covariant types and there's no Map interface in Salesforce which would allow casting
     * differently typed Maps on abstract Map type.
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
        return mapBy(records, new MapByField(field));
    }

    /**
     * @param keyType Type of returned map's key
     * @param items List of SObject records to map
     * @param field SObject Field API name to map by
     * @return Map of items where record is map's value and field's value is map's key.
     */
    public static Object mapBy(Type keyType, List<SObject> records, String field) {
        return mapBy(records, new MapByField(keyType, field));
    }

    /**
     * @param items List of items to map
     * @param mapper KeyMapper instance which produce map key for given item.
     * @return Map of items where list item is map's value and key is produced by KeyMapper.
     */
    public static Object mapBy(List<Object> items, KeyMapper mapper) {
        return mapByFieldToIMap(items, new MapByKeyMapper(mapper, getListItemType(items))).toMap();
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
        IMap imap = newMap(mapper.keyType(), mapper.valueType());

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
        return groupBy(records, new MapByField(field));
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
        return groupBy(records, new MapByField(keyType, field));
    }

    /**
     * Groups collection items by given KeyMapper implementation to Map<Key, List<Value>>, where
     * both key and values are produced by Mapper for each collection item.
     * @param records List of items to group
     * @param keyMapper KeyMapper implementation which for each collection item produces Map key.
     * @return Map<KeyMapper.key() : KeyMapper.keyType(), List<Object>>
     */
    public static Object groupBy(List<Object> items, KeyMapper keyMapper) {
        return groupBy(items, new MapByKeyMapper(keyMapper, getListItemType(items)));
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
        IMap imap = newMap(mapper.keyType(), Type.forName('List<' + mapper.valueType() + '>'));

        for (Integer i = 0, j = items.size(); i < j; i++) {
            Object item = (Object) items[i];
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
     * @param aggregatedValues Collection which holds values reduced so far.
     * @param item currently processed item.
     * @return aggregatedValues
     */
    public interface Reducer {
        Object reduce(Object aggregatedValues, Object item, Integer index);
    }

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
            result = reducer.reduce(result, items[i], i);
        }

        return result;
    }


    /*
    * WRAP
    * */

    /**
     * Wrapper interface.
     * Concrete method implementing this interface should have a member variable for wrapped item.
     * wrap method should set that member variable or set other data from the record.
     */
    public interface Wrapper {
        void wrap(Object item);
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
            wrapper.wrap(items[i]);
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
     * Filters List of SObject by field value.
     * Operators:
     * <ul>
     *  <li>'==' or Collection.EQUALS</li>
     *  <li>'!=' or Collection.NOT_EQUALS</li>
     *  <li>'>' or Collection.GREATER_THAN</li>
     *  <li>'>=' or Collection.GREATER_EQUAL_THAN</li>
     *  <li>'<' or Collection.LESS_THAN</li>
     *  <li>'<=' or Collection.LESS_EQUAL_THAN</li>
     * </ul>
     *
     * @example
     * <pre>
     *     Collection.filter(accounts, Account.CreatedDate,'>=', Date.today().addDays(-1) );
     * </pre>
     */
    public static List<SObject> filter(List<SObject> records, SObjectField field, String operator, Object value) {
        return (List<SObject>) filter(records, new FilterByFieldValue(field, operator, value));
    }


    /**
     * Filters List of SObject by given Prototype record.
     * @return SObject that have the same values in fields as given prototype
     */
    public static List<SObject> filter(List<SObject> records, SObject prototype) {
        return (List<SObject>) filter(records, new FilterByPrototype(prototype));
    }


    /**
     * @param items List of items to Filter
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


    /******
    * FIND
    * */

    /**
     * @return First collection item accepted by Collection.FilterByFieldValue, or null.
     * @see Collection.FilterByFieldValue
     */
    public static SObject find(List<SObject> records, SObjectField field, String operator, Object value) {
        return (SObject) find(records, new FilterByFieldValue(field, operator, value));
    }

    /**
     * @return First collection item which matches all fields specified on prototype.
     */
    public static SObject find(List<SObject> records, SObject prototype) {
        return (SObject) find(records, new FilterByPrototype(prototype));
    }

    /**
     * @param filter Filter implementation used in the search.
     * @return First collection item accepted by filter or null.
     */
    public static Object find(List<Object> items, Filter filter) {
        for (Integer i = 0, j = items.size(); i < j; i++) {
            Object item = items[i];

            if (filter.accepts(item)) {
                return item;
            }
        }

        return null;
    }


    /******
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
        return (List<SObject>) sort(records, new CompareByField(field, isAscending));
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
        return fill(listToFill, count, prototype, defaultCloneOptions);
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
        public Boolean
                preserveId,
                deepClone,
                preserveReadonlyTimestamps,
                preserveAutonumer;

        public CloneOptions(Boolean preserveId, Boolean deepClone, Boolean preserveReadonlyTimestamps, Boolean preserveAutonumer) {
            this.preserveId = preserveId;
            this.deepClone = deepClone;
            this.preserveReadonlyTimestamps = preserveReadonlyTimestamps;
            this.preserveAutonumer = preserveAutonumer;
        }
    }


    private class CollectionException extends Exception {
    }


    /*
    * 
    * 
    * 
    * Beyond this point are interfaces implementations.
    *
    *  
    * 
    * 
    * */


    /*
    * 
    * Filters
    * 
    * */
    private final static Map<String, Set<Integer>> COMPARATOR_OUTCOMES = new Map<String, Set<Integer>>{
            Collection.GREATER_THAN => new Set<Integer>{
                    1
            },
            Collection.GREATER_EQUAL_THAN => new Set<Integer>{
                    0, 1
            },
            Collection.LESS_THAN => new Set<Integer>{
                    -1
            },
            Collection.LESS_EQUAL_THAN => new Set<Integer>{
                    0, -1
            },
            Collection.EQUALS => new Set<Integer>{
                    0
            },
            Collection.NOT_EQUALS => new Set<Integer>{
                    1, -1
            }
    };

    /**
     * Filters List of SObject by field value.
     * Operators:
     * <ul>
     *  <li>'==' or Collection.EQUALS</li>
     *  <li>'!=' or Collection.NOT_EQUALS</li>
     *  <li>'>' or Collection.GREATER_THAN</li>
     *  <li>'>=' or Collection.GREATER_EQUAL_THAN</li>
     *  <li>'<' or Collection.LESS_THAN</li>
     *  <li>'<=' or Collection.LESS_EQUAL_THAN</li>
     * </ul>
     *
     * @example
     * <pre>
     *     new Collection(accounts).filter(new Collection.FilterByFieldValue(Account.CreatedDate,'>=', Date.today().addDays(-1)));
     *     Collection.filter(accounts, new Collection.FilterByFieldValue(Account.CreatedDate,'>=', Date.today().addDays(-1) ));
     * </pre>
     */
    public class FilterByFieldValue implements Collection.Filter {
        private Object value;
        private String field;
        private String operator;
        private Collection.Comparator comparator;
        private final Set<Integer> acceptedCompareValues;

        public FilterByFieldValue(SObjectField field, String operator, Object value) {
            this.field = '' + field;
            this.operator = operator;
            this.value = value;
            this.acceptedCompareValues = COMPARATOR_OUTCOMES.get(operator);
            this.comparator = getComparatorByField(field);
        }

        public Boolean accepts(Object record) {
            Object fieldValue = ((SObject) record).get(field);
            Integer outcome = comparator.compare(fieldValue, value);

            return acceptedCompareValues.contains(outcome);
        }
    }


    /**
     *Filters SObject collection by SObject prototype.
     * Collection sobject that have the same field values as prototype are accepted.
     *
     * @example
     * <pre>
     *     new ByPrototype(new Opportunity(Name = 'Test Opportunity', StageNem='Analysis'))
     *     would return Opportunities with Name = 'Test Opportunity' and Stage Analysis.
     * </pre>
     */
    public class FilterByPrototype implements Collection.Filter {
        private Map<String, Object> fieldsValues;

        public FilterByPrototype(SObject prototype) {
            this.fieldsValues = prototype.getPopulatedFieldsAsMap();
        }

        public Boolean accepts(Object item) {
            SObject record = (SObject) item;

            for (String field : fieldsValues.keySet()) {
                if (record.get(field) != fieldsValues.get(field)) {
                    return false;
                }
            }

            return true;
        }
    }


    /**
     * Filters List of SObject by one of many possible field values.
     * Operators:
     * <ul>
     *  <li>'IN' or Collection.VALUE_IN</li>
     *  <li>'NOT IN' or Collection.VALUE_NOT_IN</li>
     * </ul>
     *
     * @example
     * <pre>
     *     new Collection(accounts).filter(new Collection.FilterByFieldValues(Account.Name,'IN',new Set<Object>{'Test Account', 'Other Account'}));
     * </pre>
     */
    public class FilterByFieldValues implements Collection.Filter {
        private Set<Object> values;
        private String field;
        private Boolean valueIn;

        public FilterByFieldValues(SObjectField field, String operator, Set<Object> values) {
            this('' + field, operator, values);
        }

        public FilterByFieldValues(String field, String operator, Set<Object> values) {
            this.values = values;
            this.field = field;
            this.valueIn = operator == Collection.VALUE_IN;
        }


        public Boolean accepts(Object record) {
            return valueIn == (values.contains(((SObject) record).get(field)));
        }
    }


    /**
     * Filters SObject list to those related to given parents by given relationship field.
     *
     * @example
     * <pre>
     *     Collection.filter(contacts, new Collection.FilterRelatedTo(accounts, Contact.AccountId));
     * </pre>
     */
    public class FilterRelatedTo implements Collection.Filter {
        private Map<Id, SObject> parents;
        private SObjectField relationshipField;

        public FilterRelatedTo(List<SObject> parents, SObjectField relationshipField) {
            this(new Map<Id, SObject>(parents), relationshipField);
        }

        public FilterRelatedTo(Map<Id, SObject> parents, SObjectField relationshipField) {
            this.parents = new Map<Id, SObject>(parents);
            this.relationshipField = relationshipField;
        }

        public Boolean accepts(Object record) {
            return parents.containsKey((Id) ((SObject) record).get(relationshipField));
        }
    }


    /**
     * Filters SObjects by distance to given Geolocation.
     */
    public class FilterByDistance implements Collection.Filter {
        private Location targetLocation;
        private String field;
        private String unit;
        private Double maxDistance;

        /**
         * @param locationField Geolocation field to filter by.
         * @param targetLocation Target geolocation to filter by distance to.
         * @param maxDistance Max. distance from the target location
         * @param unit Distance unit 'km'/'mi'
         */
        public FilterByDistance(SObjectField locationField, Location targetLocation, Double maxDistance, String unit) {
            this.field = '' + locationField;
            this.targetLocation = targetLocation;
            this.unit = unit;
            this.maxDistance = maxDistance;
        }

        public Boolean accepts(Object record) {
            Location fieldValue = (Location) ((SObject) record).get(field);
            return Location.getDistance(fieldValue, targetLocation, unit) <= maxDistance;
        }
    }


    /**
     * Filter records that changed field value to other value.
     * Developer can specify any value by using Collection.ANY_VALUE, keep in mind though
     * that using "true" or "false" will not work.
     *
     * @example
     * <pre>
     *     new Collection(accounts).filter(new Collection.FilterFieldChanged(Opportunity.StageName, Collection.ANY_VALUE, 'Closed'));
     * </pre>
     */
    public class FilterByFieldChanged implements Collection.UpdateFilter {
        private Object fromValue;
        private Object toValue;
        private SObjectField field;

        public FilterByFieldChanged(SObjectField field) {
            this.field = field;
            this.fromValue = this.toValue = Collection.ANY_VALUE;
        }

        public FilterByFieldChanged(SObjectField field, Object fromValue, Object toValue) {
            this.field = field;
            this.fromValue = fromValue;
            this.toValue = toValue;
        }

        public Boolean accepts(SObject record, SObject old) {
            Object currentValue = record.get(field),
                    oldValue = old.get(field);

            if (fromValue === Collection.ANY_VALUE && toValue === Collection.ANY_VALUE) {
                return currentValue != oldValue;

            } else if (fromValue !== Collection.ANY_VALUE && toValue === Collection.ANY_VALUE) {
                return oldValue == fromValue;

            } else if (fromValue === Collection.ANY_VALUE && toValue !== Collection.ANY_VALUE) {
                return currentValue == toValue;

            } else {
                return oldValue == fromValue && currentValue == toValue;
            }
        }
    }


    /*
    *
    * Mappers
    *
    * */
    private final static Map<Schema.SoapType, Type> FIELD_TYPE_MAP = new Map<SoapType, Type>{
            Schema.SoapType.ID => Id.class,
            Schema.SoapType.INTEGER => Integer.class,
            Schema.SoapType.BOOLEAN => Boolean.class,
            Schema.SoapType.DATE => Date.class,
            Schema.SoapType.DATETIME => Datetime.class,
            Schema.SoapType.DOUBLE => Decimal.class,
            Schema.SoapType.STRING => String.class,
            Schema.SoapType.TIME => Time.class
    };
    private static Type getSObjectFieldType(SObjectField field) {
        return FIELD_TYPE_MAP.get(field.getDescribe().getSoapType());
    }


    /**
    * Maps SObject collection by SObject field.
    * */
    public virtual class MapByField implements Collection.KeyMapper {
        private String field;
        private Type keyType;

        public MapByField(Type keyType, String field) {
            this.keyType = keyType;
            this.field = field;
        }

        public MapByField(SObjectField field) {
            this.keyType = getSObjectFieldType(field);
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
    * Maps collection by pair of fields and separator. ex.
    * Junction object by both parent fields.
    * This mapper will always map by String key.
    *
    * @example
    * <pre>
    *       Map<String, JunctionObject> junctionRecordsByParents =
    *           Collection.mapBy(junctionRecords,
    *               new Collection.MapByFieldPair(JunctionObject.ParentId1, '_', JunctionObject.ParentId2)
    *           );
    * </pre>
    * */
    public virtual class MapByFieldPair implements Collection.KeyMapper {
        private String fieldLeft;
        private String fieldRight;
        private String separator = '';

        public MapByFieldPair(SObjectField fieldLeft, String separator, SObjectField fieldRight) {
            this('' + fieldLeft, separator, '' + fieldRight);
        }

        public MapByFieldPair(String fieldLeft, String separator, String fieldRight) {
            this.separator = separator;
            this.fieldLeft = fieldLeft;
            this.fieldRight = fieldRight;
        }

        public Object key(Object item) {
            return ((SObject) item).get(fieldLeft) + separator + ((SObject) item).get(fieldRight);
        }

        public Type keyType() {
            return String.class;
        }
    }


    /**
    * Mapper implementation which uses given KeyMapper for producing key,
    * and returns collection item as mapped value.
    * */
    public class MapByKeyMapper implements Collection.Mapper {
        private Collection.KeyMapper keyMapper;
        private Type valueType;

        public MapByKeyMapper(Collection.KeyMapper keyMapper, Type valueType) {
            this.keyMapper = keyMapper;
            this.valueType = valueType;
        }

        public Type keyType() {
            return keyMapper.keyType();
        }

        public Type valueType() {
            return valueType;
        }

        public Object key(Object item) {
            return keyMapper.key(item);
        }

        public Object value(Object item) {
            return item;
        }
    }


    /*
    *
    * Comparators
    *
    * */
    private final static Map<Schema.SoapType, Collection.Comparator> comparatorsByFieldType = new Map<SoapType, Collection.Comparator>{
            SoapType.ID => new StringComparator(),
            SoapType.STRING => new StringComparator(),
            SoapType.DATE => new DateComparator(),
            SoapType.DATETIME => new DateTimeComparator(),
            SoapType.INTEGER => new IntegerComparator(),
            SoapType.DECIMAL => new DecimalComparator(),
            SoapType.DOUBLE => new DoubleComparator(),
            SoapType.BOOLEAN => new BooleanComparator(),
            SoapType.TIME => new BooleanComparator()
    };

    private static Collection.Comparator getComparatorByField(SObjectField field) {
        Collection.Comparator comparator = comparatorsByFieldType.get(field.getDescribe().getSoapType());

        if (comparator == null) {
            comparator = new AnyComparator();
        }

        return comparator;
    }


    public class AnyComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            String a = thisItem == null ? '' : '' + thisItem;
            String b = otherItem == null ? '' : '' + otherItem;

            return a.compareTo(b);
        }
    }
    public class BooleanComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Boolean a = (Boolean) thisItem, b = (Boolean) otherItem;
            return a == b ? 0 : 1;
        }
    }
    public class DateComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Date a = (Date) thisItem, b = (Date) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    public class DateTimeComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Datetime a = (Datetime) thisItem, b = (Datetime) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    public class DecimalComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Decimal a = (Decimal) thisItem, b = (Decimal) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    public class DoubleComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Double a = (Double) thisItem, b = (Double) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    public class IntegerComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Integer a = (Integer) thisItem, b = (Integer) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    public class StringComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            String a = (String) thisItem, b = (String) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    public class TimeComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Time a = (Time) thisItem, b = (Time) otherItem;
            return a == b ? 0 : 1;
        }
    }


    /**
     * Compares records by values of the SObject field.
     */
    public class CompareByField implements Collection.Comparator {
        private SObjectField field;
        private Integer direction;
        private Collection.Comparator comparator;

        public CompareByField(SObjectField field, Boolean isAscending) {
            this.field = field;
            this.direction = isAscending ? 1 : -1;
            this.comparator = getComparatorByField(field);
        }

        public Integer compare(Object thisItem, Object otherItem) {
            Object thisValue = ((SObject) thisItem).get(field);
            Object otherValue = ((SObject) otherItem).get(field);

            return comparator.compare(thisValue, otherValue) * direction;
        }
    }


    /**
     * Compares SObjects by distance to given geolocation.
     */
    public class CompareByDistance implements Collection.Comparator {
        private SObjectField field;
        private Integer direction;
        private Integer nullsPosition = 1;
        private Location target;
        private Map<Id, Double> distanceCache;

        /**
         * By default, nulls and closest are first.
         * @param field Location field
         * @param geoLocation Target geolocation. Records are sorted by distance to this location.
         */
        public CompareByDistance(SObjectField field, Location geoLocation) {
            this.distanceCache = new Map<Id, Double>();
            this.field = field;
            this.direction = -1;
            this.nullsPosition = -1;
            this.target = geoLocation;
        }

        public CompareByDistance closestFirst(Boolean closestFirst) {
            this.nullsPosition = closestFirst ? -1 : 1;
            return this;
        }

        public CompareByDistance nullFirst(Boolean nullFirst) {
            this.direction = nullFirst ? -1 : 1;
            return this;
        }

        public Integer compare(Object thisItem, Object otherItem) {
            Double thisDistance = getDistance((SObject) thisItem);
            if (thisDistance == null) return nullsPosition;

            Double otherDistance = getDistance((SObject) otherItem);
            if (otherDistance == null) return -nullsPosition;

            return direction * (thisDistance > otherDistance ? 1 :
                    thisDistance < otherDistance ? -1
                            : 0);
        }

        private Double getDistance(SObject record) {
            if (distanceCache.containsKey(record.Id)) {
                return distanceCache.get(record.Id);
            }

            Location loc = (Location) record.get(field);
            if (loc == null) {
                return null;
            }

            Double distance = this.target.getDistance((Location) record.get(field), 'km');
            distanceCache.put(record.Id, distance);

            return distance;
        }
    }


    /*
    *
    *
    * IMaps
    *
    *
    * */

    /**
     * IMap factory method which returns proper IMap implementation for given keyType parameter
     * and initializes it with empty Map of the same sObject type as given records.
     */
    private static Collection.IMap newMap(Type keyType, Type objectType) {
        Object sfMap = Type.forName('Map<' + keyType + ',' + objectType + '>').newInstance();

        if (keyType == Id.class) return new MapById((Map<Id, Object>) sfMap);
        if (keyType == String.class) return new MapByString((Map<String, Object>) sfMap);
        if (keyType == Integer.class) return new MapByInteger((Map<Integer, Object>) sfMap);
        if (keyType == Decimal.class) return new MapByDecimal((Map<Decimal, Object>) sfMap);
        if (keyType == Date.class) return new MapByDate((Map<Date, Object>) sfMap);
        if (keyType == Datetime.class) return new MapByDatetime((Map<Datetime, Object>) sfMap);
        if (keyType == Boolean.class) return new MapByBoolean((Map<Boolean, Object>) sfMap);
        if (keyType == Time.class) return new MapByTime((Map<Time, Object>) sfMap);

        return new MapByObject((Map<Object, Object>) sfMap);
    }


    private class MapByObject implements Collection.IMap {
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

    private class MapById implements Collection.IMap {
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

    private class MapByString implements Collection.IMap {
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

    private class MapByInteger implements Collection.IMap {
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

    private class MapByDecimal implements Collection.IMap {
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

    private class MapByDate implements Collection.IMap {
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

    private class MapByDatetime implements Collection.IMap {
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

    private class MapByBoolean implements Collection.IMap {
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

    private class MapByTime implements Collection.IMap {
        private Map<Time, Object> mapInstance;

        public MapByTime(Map<Time, Object> mapInstance) {
            this.mapInstance = mapInstance;
        }
        public void put(Object key, Object value) {
            mapInstance.put((Time) key, (Object) value);
        }
        public Boolean containsKey(Object key) {
            return mapInstance.containsKey((Time) key);
        }
        public Object get(Object key) {
            return mapInstance.get((Time) key);
        }
        public Object toMap() {
            return mapInstance;
        }
        public Object keySet() {
            return mapInstance.keySet();
        }
    }
}