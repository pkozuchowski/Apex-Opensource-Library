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
public inherited sharing class Collection {
    public final static Boolean ANY_VALUE = true;
    private final static CloneOptions defaultCloneOptions = new CloneOptions(false, true, false, false);
    private final static ComparisionResult
            EQUALS = new ComparisionEquals(),
            NOT_EQUALS = new ComparisionNotEquals(),
            GREATER_THAN = new ComparisionGreaterThan(),
            GREATER_EQUAL_THAN = new ComparisionGreaterEqualsThan(),
            LESS_THAN = new ComparisionLessThan(),
            LESS_EQUAL_THAN = new ComparisionLessEqualsThan();

    /*Flyweights for reducers*/
    private final static ArithmeticReducer
            MAX = new ReducerToMax(),
            MIN = new ReducerToMin(),
            AVERAGE = new ReducerToAverage(),
            SUM = new ReducerToSum();

    private List<Object> items;


    public static Collection of(List<Object> items) {
        return new Collection(items);
    }

    private Collection(List<Object> items) {
        this.items = items;
    }

    /**
    * @return Salesforce List collection
    * */
    public List<Object> get() {
        return items;
    }

    /**
     * @return First item or null if collection is empty
     */
    public Object getFirst() {
        return isEmpty() ? null : items[0];
    }

    /**
     * @return Last item or null if collection is empty
     */
    public Object getLast() {
        return isEmpty() ? null : items[items.size() - 1];
    }

    /**
     * @return Nth item of collection.
     */
    public Object get(Integer i) {
        return items[i];
    }

    public Collection add(Integer index, Object element) {
        items.add(index, element);
        return this;
    }

    public Collection add(Object element) {
        items.add(element);
        return this;
    }

    public Collection addAll(List<Object> elements) {
        items.addAll(elements);
        return this;
    }

    public Collection addAll(Set<Object> elements) {
        items.addAll(elements);
        return this;
    }

    public Collection remove(Integer index) {
        items.remove(index);
        return this;
    }

    public Collection removeLast() {
        if (isNotEmpty()) {
            items.remove(size() - 1);
        }
        return this;
    }

    /**
     * @return true when collection is not null or empty, false otherwise.
     */
    public Boolean isNotEmpty() {
        return !isEmpty();
    }

    /**
     * @return true when collection is null or empty, false otherwise.
     */
    public Boolean isEmpty() {
        return items == null || items.isEmpty();
    }

    /**
     * @return Size of the wrapped collection, 0 if null.
     */
    public Integer size() {
        return items == null ? 0 : items.size();
    }


    /**
    * Wrap
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
     * Wraps objects into Wrapper implementation.
     * @param wrapperType Type of concrete class implementing Wrapper interface. Must provide no-args constructor.
     */
    public Collection wrap(Type wrapperType) {
        List<Wrapper> wrappers = (List<Wrapper>) Apex.newListOfItemType(wrapperType, new List<Wrapper>());

        for (Integer i = 0, j = size(); i < j; i++) {
            Wrapper wrapper = (Wrapper) wrapperType.newInstance();
            wrapper.wrap(items[i]);
            wrappers.add(wrapper);
        }

        return new Collection(wrappers);
    }

    /**
     * WrapperFactory interface.
     * Concrete method implementing this interface should produce wrapper for given item.
     */
    public interface WrapperFactory {
        Object wrap(Object item);
    }

    /**
     * Wraps collection items using wrapper factory.
     * @return Collection of wrapped objects;
     */
    public Collection wrap(WrapperFactory wrapperFactory, Type wrapperType) {
        List<Object> wrappers = (List<Wrapper>) Apex.newListOfItemType(wrapperType, new List<Object>());

        for (Integer i = 0, j = size(); i < j; i++) {
            Object wrapper = wrapperFactory.wrap(items[i]);
            wrappers.add(wrapper);
        }

        return new Collection(wrappers);
    }


    /**
    * ORDER BY
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
     * Order of sorting
     */
    public enum Order {
        ASCENDING, DESCENDING
    }

    /**
     * Sorts collection by given field and order.
     * @param field Field to sort by.
     * @param isAscending true -> ascending order, false -> descending order.
     * Collection.ASCENDING/DESCENDING can be used instead.
     */
    public Collection orderBy(SObjectField field, Order order) {
        assertSObjectCollection();
        return orderBy(new CompareByField(field, order));
    }

    /**
     * Sorts collection using given Collection.Comparator implementation.
     * @param field Field to sort by.
     * @param isAscending true -> ascending order, false -> descending order.
     * Collection.ASCENDING/DESCENDING can be used instead.
     */
    public Collection orderBy(Comparator comparator) {
        List<ComparableObject> comparables = new List<ComparableObject>();

        for (Integer i = 0, size = size(); i < size; i++) {
            comparables.add(new ComparableObject(items[i], comparator));
        }

        comparables.sort();
        List<Object> sorted = Apex.newListOfTheSameType(items);

        for (Integer i = 0, size = comparables.size(); i < size; i++) {
            sorted.add(comparables[i].item);
        }

        return Collection.of(sorted);
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


    /**
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
     * This method allows for building criteria to filter the collection or to find the first record satisfying the criteria.
     * then() method returns filtered collection for given criteria and can be used in further chaining.
     * getFirst() returns the first record satisfying criteria.
     * For best best performance it's adviced to use Filter implementation since byField() method has quite large overhead
     * scaled linearly with number of linked predicates.
     */
    public FilterFacade filter() {
        return new FilterFacade(this);
    }

    public class FilterFacade {
        private Collection filterCollection;
        private List<Filter> filters;
        private List<Boolean> isAND;

        public FilterFacade(Collection collection) {
            this.filterCollection = collection;
            this.filters = new List<Filter>();
            this.isAND = new List<Boolean>();
        }

        /**
         * Filters Collection using Filter interface implementation.
         */
        public FilterFacade byUsing(Filter filter) {
            addFilter(filter);
            return this;
        }

        /**
         * Filters Collection of updated SObjects using UpdateFilter interface implementation.
         */
        public FilterFacade byUsing(Map<Id, SObject> oldMap, UpdateFilter filter) {
            filterCollection.assertSObjectCollection();
            addFilter(new UpdateFilterToFilterAdapter(oldMap, filter));
            return this;
        }

        /**
         * Filter by field value
         */
        public FieldFilterFacade byField(SObjectField field) {
            filterCollection.assertSObjectCollection();
            return new FieldFilterFacade(this, field);
        }


        /**
         * Collection is filtered to contain only these SObjects which have fields populated like provided example record.
         */
        public FilterFacade alike(SObject prototype) {
            filterCollection.assertSObjectCollection();
            this.filters.add(new FilterByPrototype(prototype));
            return this;
        }

        /**
         * This method exists only for verbosity and can be omitted.
         * Predicates use AND by default.
         */
        public FilterFacade andAlso() {
            return this;
        }

        /**
         * Former and following predicate are joined using OR connective.
         */
        public FilterFacade orElse() {
            this.isAND.set(this.isAND.size() - 1, false);
            return this;
        }

        /**
         * Evaluates filters and returns Collection of filtered items.
         */
        public Collection then() {
            List<Object> filteredItems = Apex.newListOfTheSameType(filterCollection.items);

            for (Integer i = 0, size = filterCollection.size(); i < size; i++) {
                Object item = filterCollection.items[i];

                if (isSatisfyingConditions(item)) {
                    filteredItems.add(item);
                }
            }

            return Collection.of(filteredItems);
        }

        /**
         * @return first item satisfying conditions.
         */
        public Object getFirst() {
            for (Integer i = 0, size = filterCollection.size(); i < size; i++) {
                Object item = filterCollection.items[i];

                if (isSatisfyingConditions(item)) {
                    return item;
                }
            }

            return null;
        }

        private Boolean isSatisfyingConditions(Object item) {
            Boolean accepted = true;
            Integer size = filters.size();

            if (size > 0) accepted = checkFilter(accepted, 0, item);
            if (size > 1) accepted = checkFilter(accepted, 1, item);
            if (size > 2) accepted = checkFilter(accepted, 2, item);
            if (size > 3) accepted = checkFilter(accepted, 3, item);
            if (size > 4) accepted = checkFilter(accepted, 4, item);

            return accepted;
        }

        private Boolean checkFilter(Boolean previousFilter, Integer i, Object item) {
            if (isAND[i]) {
                return previousFilter && this.filters[i].accepts(item);
            } else {
                return previousFilter || this.filters[i].accepts(item);
            }
        }

        void addFilter(Filter filter) {
            assert(filters.size() <= 5, 'Too many filters degrade performance. Implement Filter instead for the best performance.');
            this.filters.add(filter);
            this.isAND.add(true);
        }
    }

    /**
     * Facade for Field value filters.
     */
    public class FieldFilterFacade {
        private FilterFacade filterFacade;
        private SObjectField field;

        private FieldFilterFacade(FilterFacade filterFacade, SObjectField field) {
            this.filterFacade = filterFacade;
            this.field = field;
        }

        public FilterFacade equals(Object value) {
            filterFacade.addFilter(new FilterByFieldValue(field, Collection.EQUALS, value));
            return filterFacade;
        }

        public FilterFacade notEquals(Object value) {
            filterFacade.addFilter(new FilterByFieldValue(field, Collection.NOT_EQUALS, value));
            return filterFacade;
        }

        public FilterFacade greaterThan(Object value) {
            filterFacade.addFilter(new FilterByFieldValue(field, Collection.GREATER_THAN, value));
            return filterFacade;
        }

        public FilterFacade greaterEqualsThan(Object value) {
            filterFacade.addFilter(new FilterByFieldValue(field, Collection.GREATER_EQUAL_THAN, value));
            return filterFacade;
        }

        public FilterFacade lessThan(Object value) {
            filterFacade.addFilter(new FilterByFieldValue(field, Collection.LESS_THAN, value));
            return filterFacade;
        }

        public FilterFacade lessEqualsThan(Object value) {
            filterFacade.addFilter(new FilterByFieldValue(field, Collection.LESS_EQUAL_THAN, value));
            return filterFacade;
        }

        public FilterFacade isIn(Set<Object> values) {
            filterFacade.addFilter(new FilterByFieldValues(field, true, values));
            return filterFacade;
        }

        public FilterFacade isIn(List<Object> values) {
            filterFacade.addFilter(new FilterByFieldValues(field, true, values));
            return filterFacade;
        }

        public FilterFacade isNotIn(Set<Object> values) {
            filterFacade.addFilter(new FilterByFieldValues(field, false, values));
            return filterFacade;
        }

        public FilterFacade isNotIn(List<Object> values) {
            filterFacade.addFilter(new FilterByFieldValues(field, false, values));
            return filterFacade;
        }

        public FilterFacade relatedTo(List<SObject> parents) {
            filterFacade.addFilter(new FilterRelatedTo(parents, field));
            return filterFacade;
        }

        public FilterFacade contains(String value) {
            filterFacade.addFilter(new FilterFieldContaining(field, value));
            return filterFacade;
        }
    }


    /**
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
     * @param worker Concrete class implementing Worker interface. Executes action on each element.
     */
    public Collection forEach(Worker worker) {
        for (Integer i = 0, j = size(); i < j; i++) {
            worker.forEach(items[i], i);
        }

        return this;
    }


    /**
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
    public Collection fill(Integer count, SObject prototype) {
        assertSObjectCollection();
        return fill(count, prototype, defaultCloneOptions);
    }

    /**
     * Fills in the list with number of clones of provided prototype record.
     * @param count Number of clones in the list
     * @param prototype Prototype of the record. Clone of this record will be added to the list.
     * @param opts Collection.CloneOptions instance which determine clone operation characteristics.
     */
    public Collection fill(Integer count, SObject prototype, CloneOptions cloneOptions) {
        assertSObjectCollection();
        for (Integer i = 0; i < count; i++) {
            SObject clone = prototype.clone(
                    cloneOptions.preserveId,
                    cloneOptions.deepClone,
                    cloneOptions.preserveReadonlyTimestamps,
                    cloneOptions.preserveAutonumer
            );
            items.add(clone);
        }
        return Collection.of(items);
    }

    public class CloneOptions {
        public Boolean preserveId { get; private set; }
        public Boolean deepClone { get; private set; }
        public Boolean preserveReadonlyTimestamps { get; private set; }
        public Boolean preserveAutonumer { get; private set; }

        public CloneOptions(Boolean preserveId, Boolean deepClone, Boolean preserveReadonlyTimestamps, Boolean preserveAutonumer) {
            this.preserveId = preserveId;
            this.deepClone = deepClone;
            this.preserveReadonlyTimestamps = preserveReadonlyTimestamps;
            this.preserveAutonumer = preserveAutonumer;
        }
    }


    /**
    * Reduce
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
     * Mapper implementations determine Map's key and value for given object and types of key and value.
     */
    public interface Mapper {
        Type valueType();
        Object value(Object item);
    }

    public ReduceFacade reduce() {
        return new ReduceFacade(this);
    }

    /**
     * Facade for Collection Reducers
     */
    public class ReduceFacade {
        private Collection collection;

        private ReduceFacade(Collection collection) {
            this.collection = collection;
        }

        /**
         * Reduces collection of objects to other collection or object of given type.
         * @param reducer Reducer interface implementation. @see Collections.Reducer
         * @param initialValue collection/object to which input is reduced.
         * @return result after reduction.
         */
        public Object to(Reducer reducer, Object initialValue) {
            Object previousValue = initialValue;

            for (Integer i = 0, size = collection.size(); i < size; ++i) {
                previousValue = reducer.reduce(previousValue, collection.items[i], i);
            }

            return initialValue;
        }

        private Decimal toSum(SObjectField field) {
            return (Decimal) this.to(SUM.ofField(field), 0.0);
        }

        private Decimal toAverage(SObjectField field) {
            return (Decimal) this.to(AVERAGE.ofField(field), null);
        }

        private Decimal toMin(SObjectField field) {
            return (Decimal) this.to(MIN.ofField(field), null);
        }

        private Decimal toMax(SObjectField field) {
            return (Decimal) this.to(MAX.ofField(field), 0.0);
        }


        /**
         * @param field SObject field from which value is taken.
         * @return Set of gathered values.
         */
        public Object toSet(SObjectField field) {
            collection.assertSObjectCollection();
            return toSet(new FieldMapper(field));
        }

        /**
         * @param keyMapper Mapper implementation which returns value for each record
         * @return Set of gathered values.
         */
        public Object toSet(Mapper valueMapper) {
            return mapToUntypedMap(valueMapper, new ItemMapper(collection.items)).keySet();
        }


        /**
         * @param keyField SObject Field to map by
         * @return Map of items where record is map's value and field's value is map's key.
         * Map's key type is derived from field's type.
         */
        public Object toMap(SObjectField field) {
            collection.assertSObjectCollection();
            return toMap(new FieldMapper(field));
        }

        /**
         * @param keyField SObject Field to map's key
         * @param valueField SObject Field to map's value
         * @return Map where record is map's value and field's value is map's key.
         * Map's key and value type is derived from field's type.
         */
        private Object toMap(SObjectField keyField, SObjectField valueField) {
            collection.assertSObjectCollection();
            return toMap(new FieldMapper(keyField), new FieldMapper(valueField));
        }

        /**
         * @param keyMapper Mapper implementation which produce map key for given item.
         * @return Map of items where list item is map's value and key is produced by keyMapper.
         */
        public Object toMap(Mapper keyMapper) {
            return toMap(keyMapper, new ItemMapper(collection.items));
        }

        /**
         * @param keyMapper Mapper instance which produce map key and value for given item.
         * @return Map of items where Item is map's value and key are produced by mappers.
         */
        public Object toMap(Mapper keyMapper, Mapper valueMapper) {
            return mapToUntypedMap(keyMapper, valueMapper).toMap();
        }

        /*
        * Internal method. Maps items to IMap instance.
        * */
        private IMap mapToUntypedMap(Mapper keyMapper, Mapper valueMapper) {
            IMap imap = newMap(keyMapper.valueType(), valueMapper.valueType());

            for (Integer i = 0, j = collection.size(); i < j; i++) {
                Object item = collection.items[i];
                imap.put(keyMapper.value(item), valueMapper.value(item));
            }

            return imap;
        }


        /**
         * Groups collection items by given field to map where key
         * is the field's value and the value is List<SObject> which have the same key.
         * @param field SObject Field
         */
        public Object toGroup(SObjectField field) {
            collection.assertSObjectCollection();
            return toGroup(new FieldMapper(field));
        }

        /**
         * Groups collection items by given field to map where key
         * is the field's value and the value is List<T> with values of @param valueType.
         * @param field SObject Field
         */
        private Object toGroup(SObjectField keyField, SObjectField valueField) {
            collection.assertSObjectCollection();
            return toGroup(new FieldMapper(keyField), new FieldMapper(valueField));
        }

        /**
         * Groups collection items by given Mapper implementation to Map<Key, List<Value>>, where
         * key is produced by the key mapper and the value is List<Object> which have the same key.
         */
        public Object toGroup(Mapper keyMapper) {
            return toGroup(keyMapper, new ItemMapper(collection.items));
        }

        /**
         * Groups collection items by given KeyMapper implementation to Map<Key, List<Value>>, where
         * both key and values are produced by Mapper for each collection item.
         *
         * @param Mapper Collection.Mapper implementation.
         */
        public Object toGroup(Mapper keyMapper, Mapper valueMapper) {
            IMap groupMap = newMap(keyMapper.valueType(), Type.forName('List<' + valueMapper.valueType() + '>'));
            List<Object> emptyList = Apex.newListOfItemType(valueMapper.valueType());

            for (Integer i = 0, j = collection.size(); i < j; i++) {
                Object item = (Object) collection.items[i];
                Object key = keyMapper.value(item);
                Object value = valueMapper.value(item);

                if (!groupMap.containsKey(key)) {
                    groupMap.put(key, emptyList.clone());
                }

                List<Object> groupedRecords = (List<Object>) groupMap.get(key);
                groupedRecords.add(value);
            }

            return groupMap.toMap();
        }


        /**
         * @return List of values from given SObject field
         */
        public List<Object> toList(SObjectField field) {
            collection.assertSObjectCollection();
            return toList(new FieldMapper(field));
        }

        /**
         * @return List of values produced by KeyMapper
         */
        public List<Object> toList(Mapper valueMapper) {
            List<Object> values = Apex.newListOfItemType(valueMapper.valueType());

            for (Integer i = 0, j = collection.size(); i < j; i++) {
                values.add(valueMapper.value(collection.items[i]));
            }

            return values;
        }
    }


    private void assertSObjectCollection() {
        assert(items instanceof List<SObject>, 'Operation only applies to SObject collection.');
    }

    private static void assert(Boolean condition, String errorMsg) {
        if (!condition) throw new CollectionException(errorMsg);
    }

    private class CollectionException extends Exception {
    }


    /*
    *
    *
    *
    * Beyond this point are internal interfaces implementations.
    *
    *
    *
    *
    * */

    /**
    * REDUCERS
    * */
    /**
     * Reduces SObjects to sum of field(s)
     */
    private abstract class ArithmeticReducer implements Reducer {
        private SObjectField field;

        public Reducer ofField(SObjectField field) {
            this.field = field;
            return this;
        }
    }

    /**
     * Reduces SObjects field(s) to their sum.
     */
    private class ReducerToSum extends ArithmeticReducer {
        public Object reduce(Object aggregatedValues, Object item, Integer index) {
            Decimal fieldValue = (Decimal) ((SObject) item).get(field);
            return (Decimal) aggregatedValues
                    + (fieldValue == null ? 0 : fieldValue);
        }
    }

    /**
     * Reduces SObject fields(s)to their average value.
     */
    private class ReducerToAverage extends ArithmeticReducer {
        private Decimal sum = 0;
        private Integer count = 0;

        public Object reduce(Object aggregatedValues, Object item, Integer index) {
            Decimal fieldValue = (Decimal) ((SObject) item).get(field);
            this.count++;
            this.sum += (Decimal) (fieldValue == null ? 0 : fieldValue);
            return this.sum / this.count;
        }
    }

    /**
     * Reduces SObject to their maximal value.
     */
    private class ReducerToMax extends ArithmeticReducer {
        public Object reduce(Object maxSoFar, Object item, Integer index) {
            Decimal fieldValue = (Decimal) ((SObject) item).get(field);

            if (fieldValue == null) {
                return maxSoFar;

            } else if (maxSoFar == null) {
                return fieldValue;

            } else {
                return Math.max(fieldValue, (Decimal) maxSoFar);
            }
        }
    }

    /**
     * Reduces SObject collection to minimal value from given field(s).
     */
    private class ReducerToMin extends ArithmeticReducer {
        public Object reduce(Object minSoFar, Object item, Integer index) {
            Decimal fieldValue = (Decimal) ((SObject) item).get(field);

            if (fieldValue == null) {
                return minSoFar;

            } else if (minSoFar == null) {
                return fieldValue;

            } else {
                return Math.min(fieldValue, (Decimal) minSoFar);
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
    public virtual class FieldMapper implements Collection.Mapper {
        private String field;
        private Type fieldType;

        public FieldMapper(SObjectField field) {
            this.fieldType = getSObjectFieldType(field);
            this.field = '' + field;
        }

        public Type valueType() {
            return fieldType;
        }

        public Object value(Object item) {
            return ((SObject) item).get(field);
        }
    }

    /**
    * Mapper implementation which uses given KeyMapper for producing key,
    * and returns collection item as mapped value.
    * */
    public class ItemMapper implements Collection.Mapper {
        private Type itemType;

        public ItemMapper(List<Object> items) {
            this.itemType = Apex.getListItemType(items);
        }

        public Type valueType() {
            return itemType;
        }
        public Object value(Object item) {
            return item;
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
    public class ConcatenatedFieldsMapper implements Collection.Mapper {
        private SObjectField fieldLeft;
        private SObjectField fieldRight;

        public ConcatenatedFieldsMapper(SObjectField fieldLeft, SObjectField fieldRight) {
            this.fieldLeft = fieldLeft;
            this.fieldRight = fieldRight;
        }

        public Object value(Object item) {
            return '' + ((SObject) item).get(fieldLeft) + ((SObject) item).get(fieldRight);
        }

        public Type valueType() {
            return String.class;
        }
    }


    /*
    *
    * Filters
    *
    * */
    /**
     * Filters List of SObject by field value.
     */
    private class FilterByFieldValue implements Collection.Filter {
        private Object value;
        private String field;
        private Collection.Comparator comparator;
        private final ComparisionResult expectedResult;

        public FilterByFieldValue(SObjectField field, ComparisionResult expectedResult, Object value) {
            this.field = '' + field;
            this.value = value;
            this.expectedResult = expectedResult;
            this.comparator = getFieldComparator(field);
        }

        public Boolean accepts(Object record) {
            Object fieldValue = ((SObject) record).get(field);
            Integer outcome = comparator.compare(fieldValue, value);

            return expectedResult.isTrue(outcome);
        }
    }

    /**
     * Filters SObject collection by SObject prototype.
     * Collection sobject that have the same field values as prototype are accepted.
     */
    private class FilterByPrototype implements Collection.Filter {
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
     */
    private class FilterByFieldValues implements Collection.Filter {
        private Set<Object> values;
        private SObjectField field;
        private Boolean valueIn;

        public FilterByFieldValues(SObjectField field, Boolean valueIn, List<Object> values) {
            this(field, valueIn, new Set<Object>(values));
        }

        public FilterByFieldValues(SObjectField field, Boolean valueIn, Set<Object> values) {
            this.values = values;
            this.field = field;
            this.valueIn = valueIn;
        }

        public Boolean accepts(Object record) {
            return valueIn == (values.contains(((SObject) record).get(field)));
        }
    }

    /**
     * Filters SObject list to those related to given parents by given relationship field.
     */
    private class FilterRelatedTo implements Collection.Filter {
        private Map<Id, SObject> parents;
        private SObjectField relationshipField;

        public FilterRelatedTo(List<SObject> parents, SObjectField relationshipField) {
            this.parents = new Map<Id, SObject>(parents);
            this.relationshipField = relationshipField;
        }

        public Boolean accepts(Object record) {
            return parents.containsKey((Id) ((SObject) record).get(relationshipField));
        }
    }

    /**
     * Filters SObject list to those related to given parents by given relationship field.
     */
    private class FilterFieldContaining implements Collection.Filter {
        private SObjectField field;
        private String value;

        public FilterFieldContaining(SObjectField field, String value) {
            this.field = field;
            this.value = value;
        }

        public Boolean accepts(Object record) {
            String fieldValue = (String) ((SObject) record).get(field);
            return fieldValue.contains(value);
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

    /**
     * Proxy between UpdateFilter and Filter
     */
    private class UpdateFilterToFilterAdapter implements Filter {
        private Map<Id, SObject> oldMap;
        private UpdateFilter updateFilter;

        public UpdateFilterToFilterAdapter(Map<Id, SObject> oldMap, UpdateFilter updateFilter) {
            this.oldMap = oldMap;
            this.updateFilter = updateFilter;
        }

        public Boolean accepts(Object item) {
            return updateFilter.accepts((SObject) item, oldMap.get(((SObject) item).Id));
        }
    }


    /*
    *
    * Comparators
    *
    * */
    private interface ComparisionResult {
        Boolean isTrue(Integer i);
    }
    private class ComparisionEquals implements ComparisionResult {
        public Boolean isTrue(Integer i) {
            return i == 0;
        }
    }
    private class ComparisionNotEquals implements ComparisionResult {
        public Boolean isTrue(Integer i) {
            return i != 0;
        }
    }
    private class ComparisionGreaterThan implements ComparisionResult {
        public Boolean isTrue(Integer i) {
            return i > 1;
        }
    }
    private class ComparisionGreaterEqualsThan implements ComparisionResult {
        public Boolean isTrue(Integer i) {
            return i >= 0;
        }
    }
    private class ComparisionLessThan implements ComparisionResult {
        public Boolean isTrue(Integer i) {
            return i < 0;
        }
    }
    private class ComparisionLessEqualsThan implements ComparisionResult {
        public Boolean isTrue(Integer i) {
            return i <= 0;
        }
    }

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

    private static Collection.Comparator getFieldComparator(SObjectField field) {
        Collection.Comparator comparator = comparatorsByFieldType.get(field.getDescribe().getSoapType());
        return comparator == null ? new AnyComparator() : comparator;
    }

    private class AnyComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            String a = thisItem == null ? '' : '' + thisItem;
            String b = otherItem == null ? '' : '' + otherItem;
            return a.compareTo(b);
        }
    }
    private class BooleanComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Boolean a = (Boolean) thisItem, b = (Boolean) otherItem;
            return a == b ? 0 : 1;
        }
    }
    private class DateComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Date a = (Date) thisItem, b = (Date) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    private class DateTimeComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Datetime a = (Datetime) thisItem, b = (Datetime) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    private class DecimalComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Decimal a = (Decimal) thisItem, b = (Decimal) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    private class DoubleComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Double a = (Double) thisItem, b = (Double) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    private class IntegerComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Integer a = (Integer) thisItem, b = (Integer) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    private class StringComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            String a = (String) thisItem, b = (String) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    private class TimeComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Time a = (Time) thisItem, b = (Time) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }

    /**
     * Compares records by values of the SObject field.
     */
    public class CompareByField implements Collection.Comparator {
        private SObjectField field;
        private Integer direction;
        private Collection.Comparator comparator;

        public CompareByField(SObjectField field, Order ordr) {
            this.field = field;
            this.direction = ordr == Order.ASCENDING ? 1 : -1;
            this.comparator = getFieldComparator(field);
        }

        public Integer compare(Object thisItem, Object otherItem) {
            Object thisValue = ((SObject) thisItem).get(field);
            Object otherValue = ((SObject) otherItem).get(field);

            return comparator.compare(thisValue, otherValue) * direction;
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