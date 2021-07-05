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
 * Class provides methods for the most common actions that take place place
 * in Salesforce business logic:
 * - Mapping records by given field,
 * - Grouping records with the same value in given field,
 * - Gathering values from given field or fields,
 * - Filtering records which have given value or values in given field,
 * - Reducing collection to single variable
 * - Sorting records by given field or comparator.
 *
 * @see CollectionTest
 */
public inherited sharing class CollectionImpl extends Collection {
    private final static CloneOptions defaultCloneOptions = new CloneOptions(false, true, false, false);

    /*Flyweights for reducers*/
    private final static ArithmeticReducer
        MAX = new ReducerToMax(),
        MIN = new ReducerToMin(),
        AVERAGE = new ReducerToAverage(),
        SUM = new ReducerToSum();

    private final static ConditionsFactory conditionsFactory = new ConditionsFactory();

    private List<Object> items;


    public CollectionImpl(List<Object> items) {
        this.items = items;
    }

    public override List<Object> get() { return items; }
    public override Object getFirst() { return isEmpty() ? null : items[0]; }
    public override Object getLast() { return isEmpty() ? null : items[items.size() - 1]; }
    public override Object getRandom() { return isEmpty() ? null : items[(Integer) Math.floor(Math.random() * size())]; }
    public override Object get(Integer i) { return items[i]; }

    public override Collection add(Integer index, Object element) {
        items.add(index, element);
        return this;
    }

    public override Collection add(Object element) {
        items.add(element);
        return this;
    }

    public override Collection addAll(List<Object> elements) {
        items.addAll(elements);
        return this;
    }

    public override Collection addAll(Set<Object> elements) {
        items.addAll(elements);
        return this;
    }

    public override Collection remove(Integer index) {
        items.remove(index);
        return this;
    }

    public override Collection removeLast() {
        if (isNotEmpty()) {
            items.remove(size() - 1);
        }
        return this;
    }

    public override Collection clear() {
        if (isNotEmpty()) {
            items.clear();
        }
        return this;
    }

    public override Collection slice(Integer start, Integer stop) {
        List<Object> other = Runtime.newListOfTheSameType(items);

        for (Integer i = start; i <= stop; i++) {
            other.add(items[i]);
        }

        return Collection.of(other);
    }

    public override Collection slice(List<Integer> indexes) {
        List<Object> other = Runtime.newListOfTheSameType(items);

        for (Integer i : indexes) {
            other.add(this.get(i));
        }

        return Collection.of(other);
    }

    public override Boolean isNotEmpty() { return !isEmpty(); }
    public override Boolean isEmpty() { return items == null || items.isEmpty(); }
    public override Integer size() { return items == null ? 0 : items.size(); }


    public override Collection.FieldFilter filter(SObjectField field) { return filter('' + field); }
    public override Collection.FieldFilter filter(String field) { return new FieldFilterImpl(this, field); }
    public override Collection filterAlike(SObject prototype) { return filter(conditionsFactory.alike(prototype)); }

    public override Collection filter(Condition condition) {
        List<Object> filteredItems = Runtime.newListOfTheSameType(items);

        for (Integer i = 0, size = this.size(); i < size; i++) {
            if (condition.isTrue(items[i])) {
                filteredItems.add(items[i]);
            }
        }

        return Collection.of(filteredItems);
    }


    public override Object reduce(Reducer reducer, Object initialValue) {
        Object previousValue = initialValue;

        for (Integer i = 0, size = this.size(); i < size; ++i) {
            previousValue = reducer.reduce(previousValue, items[i], i);
        }

        return previousValue;
    }

    public override Decimal sum(SObjectField field) { return sum('' + field); }
    public override Decimal sum(String field) { return (Decimal) this.reduce(SUM.ofField(field), 0.0); }

    public override Decimal average(SObjectField field) { return average('' + field); }
    public override Decimal average(String field) { return (Decimal) this.reduce(AVERAGE.ofField(field), null); }

    public override Decimal min(SObjectField field) { return min('' + field); }
    public override Decimal min(String field) { return (Decimal) this.reduce(MIN.ofField(field), null); }

    public override Decimal max(SObjectField field) { return max('' + field); }
    public override Decimal max(String field) { return (Decimal) this.reduce(MAX.ofField(field), 0.0); }


    public override List<Object> listOf(String field) {
        return listOf(getSObjectField(field));
    }
    public override List<Object> listOf(SObjectField field) {
        return listOf('' + field, Runtime.getSObjectFieldType(field));
    }
    public override List<Object> listOf(String field, Type fieldType) {
        assertSObjectCollection();
        return listOf(new FieldMapper(field, fieldType));
    }
    public override List<Object> listOf(Mapper valueMapper) {
        List<Object> values = Runtime.newListOfItemType(valueMapper.valueType());

        for (Integer i = 0, size = size(); i < size; i++) {
            values.add(valueMapper.value(items[i]));
        }

        return values;
    }


    public override Object setOf(String field) {
        return setOf(getSObjectField(field));
    }
    public override Object setOf(SObjectField field) {
        return setOf('' + field, Runtime.getSObjectFieldType(field));
    }
    public override Object setOf(String field, Type fieldType) {
        assertSObjectCollection();
        return setOf(new FieldMapper(field, fieldType));
    }
    public override Object setOf(Mapper valueMapper) {
        return mapToUntypedMap(valueMapper, new ItemMapper(items)).keySet();
    }


    public override Object mapBy(String field) {
        return mapBy(getSObjectField(field));
    }
    public override Object mapBy(String keyField, String valueField) {
        return mapBy(getSObjectField(keyField), getSObjectField(valueField));
    }
    public override Object mapBy(SObjectField field) {
        return mapBy('' + field, Runtime.getSObjectFieldType(field));
    }
    public override Object mapBy(SObjectField keyField, SObjectField valueField) {
        return mapBy('' + keyField, '' + valueField, Runtime.getSObjectFieldType(keyField), Runtime.getSObjectFieldType(valueField));
    }
    public override Object mapBy(String field, Type fieldType) {
        assertSObjectCollection();
        return mapBy(new FieldMapper(field, fieldType));
    }
    public override Object mapBy(String keyField, String valueField, Type keyType, Type valueType) {
        assertSObjectCollection();
        return mapBy(new FieldMapper(keyField, keyType), new FieldMapper(valueField, valueType));
    }
    public override Object mapBy(Mapper keyMapper) {
        return mapBy(keyMapper, new ItemMapper(items));
    }
    public override Object mapBy(Mapper keyMapper, Mapper valueMapper) {
        return mapToUntypedMap(keyMapper, valueMapper).toMap();
    }
    public override Object mapByConcatenation(SObjectField field1, SObjectField field2) {
        return mapBy(new ConcatenatedFieldsMapper(field1, field2));
    }

    private UntypedMap mapToUntypedMap(Mapper keyMapper, Mapper valueMapper) {
        UntypedMap imap = newMap(keyMapper.valueType(), valueMapper.valueType());

        for (Integer i = 0, size = this.size(); i < size; i++) {
            Object item = items[i];
            imap.put(keyMapper.value(item), valueMapper.value(item));
        }

        return imap;
    }


    public override Object groupBy(String field) {
        return groupBy(getSObjectField(field));
    }
    public override Object groupBy(String keyField, String valueField) {
        return groupBy(getSObjectField(keyField), getSObjectField(valueField));
    }
    public override Object groupBy(SObjectField field) {
        return groupBy('' + field, Runtime.getSObjectFieldType(field));
    }
    public override Object groupBy(SObjectField keyField, SObjectField valueField) {
        return groupBy('' + keyField, '' + valueField, Runtime.getSObjectFieldType(keyField), Runtime.getSObjectFieldType(valueField));
    }
    public override Object groupBy(String field, Type fieldType) {
        assertSObjectCollection();
        return groupBy(new FieldMapper(field, fieldType));
    }
    public override Object groupBy(String keyField, String valueField, Type keyType, Type valueType) {
        assertSObjectCollection();
        return groupBy(new FieldMapper(keyField, keyType), new FieldMapper(valueField, valueType));
    }
    public override Object groupBy(Mapper keyMapper) {
        return groupBy(keyMapper, new ItemMapper(items));
    }

    public override Object groupByConcatenation(SObjectField field1, SObjectField field2) {
        return groupBy(new ConcatenatedFieldsMapper(field1, field2));
    }

    public override Object groupBy(Mapper keyMapper, Mapper valueMapper) {
        UntypedMap groupMap = newMap(keyMapper.valueType(), Type.forName('List<' + valueMapper.valueType() + '>'));
        List<Object> emptyList = Runtime.newListOfItemType(valueMapper.valueType());

        for (Integer i = 0, size = size(); i < size; i++) {
            Object item = (Object) items[i];
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


    public override Collection wrap(Type wrapperType) {
        return wrap(new WrapperFactoryAdatper(wrapperType), wrapperType);
    }
    public override Collection wrap(WrapperFactory wrapperFactory, Type wrapperType) {
        List<Object> wrappers = (List<Object>) Runtime.newListOfItemType(wrapperType, new List<Object>());

        for (Integer i = 0, j = size(); i < j; i++) {
            Object wrapper = wrapperFactory.wrap(items[i]);
            wrappers.add(wrapper);
        }

        return Collection.of(wrappers);
    }


    public override Collection orderBy(SObjectField field, Ordering order) {
        assertSObjectCollection();
        return orderBy(new CompareByField(field, order));
    }
    public override Collection orderBy(Comparator comparator) {
        List<ComparableObject> comparables = new List<ComparableObject>();

        for (Integer i = 0, size = size(); i < size; i++) {
            comparables.add(new ComparableObject(items[i], comparator));
        }

        comparables.sort();
        List<Object> sorted = Runtime.newListOfTheSameType(items);

        for (Integer i = 0, size = comparables.size(); i < size; i++) {
            sorted.add(comparables[i].item);
        }

        return Collection.of(sorted);
    }


    public override Collection forEach(Worker worker) {
        for (Integer i = 0, j = size(); i < j; i++) {
            worker.forEach(items[i], i);
        }

        return this;
    }


    public override Collection fill(Integer count, SObject prototype) {
        assertSObjectCollection();
        return fill(count, prototype, defaultCloneOptions);
    }

    public override Collection fill(Integer count, SObject prototype, CloneOptions cloneOptions) {
        assertSObjectCollection();
        for (Integer i = 0; i < count; i++) {
            SObject clone = prototype.clone(
                cloneOptions.preserveId,
                cloneOptions.deepClone,
                cloneOptions.preserveReadonlyTimestamps,
                cloneOptions.preserveAutonumber
            );
            items.add(clone);
        }
        return Collection.of(items);
    }


    public override Collection assert(Condition condition, String message) {
        for (Integer i = 0, size = this.size(); i < size; i++) {
            System.assert(condition.isTrue(items[i]), message);
        }

        return this;
    }

    public override Collection assertEquals(SObjectField field, Object expected, String message) {
        assertSObjectCollection();

        for (Integer i = 0, size = this.size(); i < size; i++) {
            SObject record = (SObject) items[i];
            System.assertEquals(expected, record.get(field), message);
        }

        return this;
    }

    public override Collection assertNotEquals(SObjectField field, Object expected, String message) {
        assertSObjectCollection();

        for (Integer i = 0, size = this.size(); i < size; i++) {
            SObject record = (SObject) items[i];
            System.assertNotEquals(expected, record.get(field), message);
        }

        return this;
    }

    private void assertSObjectCollection() {
        assert(items instanceof List<SObject>, 'Operation only applies to SObject collection.');
    }

    private static void assert(Boolean condition, String errorMsg) {
        if (!condition) throw new CollectionException(errorMsg);
    }

    private SObjectField getSObjectField(String field) {
        SObjectType sObjectType = getSObjectType();
        assert(sObjectType != null, 'Could not determine collection\'s SObject type, please provide field type');

        String apiName = '' + sObjectType + '.' + field;
        return SchemaDescriptions.getSObjectField(apiName);
    }

    private SObjectType getSObjectType() {
        assertSObjectCollection();
        return ((List<SObject>) items).getSObjectType();
    }


    /**
    * Filters
    */

    /**
    * Facade for Field value filters.
    */
    private class FieldFilterImpl implements FieldFilter {
        private Collection collection;
        private ConditionsFactory.FieldValueConditionFactory filterFactory;

        private FieldFilterImpl(Collection filterFacade, String field) {
            this.collection = filterFacade;
            this.filterFactory = new ConditionsFactory.FieldValueConditionFactory(field);
        }

        public Collection equals(Object value) { return collection.filter(filterFactory.equals(value)); }
        public Collection notEquals(Object value) { return collection.filter(filterFactory.notEquals(value)); }
        public Collection greaterThan(Object value) { return collection.filter(filterFactory.greaterThan(value)); }
        public Collection greaterEqualsThan(Object value) { return collection.filter(filterFactory.greaterEqualsThan(value)); }
        public Collection lessThan(Object value) { return collection.filter(filterFactory.lessThan(value)); }
        public Collection lessEqualsThan(Object value) { return collection.filter(filterFactory.lessEqualsThan(value)); }
        public Collection isIn(Set<Object> values) { return collection.filter(filterFactory.isIn(values)); }
        public Collection isIn(List<Object> values) { return collection.filter(filterFactory.isIn(values)); }
        public Collection isNotIn(Set<Object> values) { return collection.filter(filterFactory.isNotIn(values)); }
        public Collection isNotIn(List<Object> values) { return collection.filter(filterFactory.isNotIn(values)); }
        public Collection relatedTo(List<SObject> parents) { return collection.filter(filterFactory.relatedTo(parents)); }
        public Collection contains(String value) { return collection.filter(filterFactory.contains(value)); }
    }


    /**
    * REDUCERS
    * */
    private abstract class ArithmeticReducer implements Reducer {
        private String field;

        public Reducer ofField(String field) {
            this.field = field;
            return this;
        }

        public Object reduce(Object accumulator, Object item, Integer index) {
            Decimal fieldValue = (Decimal) ((SObject) item).get(field);

            if (fieldValue != null) {
                return reduce((Decimal) accumulator, fieldValue, index);
            } else {
                return accumulator;
            }
        }

        protected abstract Decimal reduce(Decimal accumulator, Decimal fieldValue, Integer index);
    }

    private class ReducerToSum extends ArithmeticReducer {
        protected override Decimal reduce(Decimal accumulator, Decimal fieldValue, Integer index) {
            return accumulator + fieldValue;
        }
    }

    private class ReducerToAverage extends ArithmeticReducer {
        private Decimal sum = 0;

        protected override Decimal reduce(Decimal accumulator, Decimal fieldValue, Integer index) {
            this.sum += fieldValue;
            return this.sum / (index + 1);
        }
    }

    private class ReducerToMax extends ArithmeticReducer {
        protected override Decimal reduce(Decimal maxSoFar, Decimal fieldValue, Integer index) {
            if (maxSoFar == null) {
                return fieldValue;

            } else {
                return Math.max(fieldValue, maxSoFar);
            }
        }
    }

    private class ReducerToMin extends ArithmeticReducer {
        protected override Decimal reduce(Decimal minSoFar, Decimal fieldValue, Integer index) {
            if (minSoFar == null) {
                return fieldValue;

            } else {
                return Math.min(fieldValue, minSoFar);
            }
        }
    }


    /*
    *
    * Mappers
    *
    * */


    public class FieldMapper implements Collection.Mapper {
        private String field;
        private Type fieldType;

        public FieldMapper(SObjectField field) {
            this.fieldType = Runtime.getSObjectFieldType(field);
            this.field = '' + field;
        }

        public FieldMapper(String field, Type fieldType) {
            this.fieldType = fieldType;
            this.field = field;
        }

        public Type valueType() { return fieldType; }
        public Object value(Object item) { return ((SObject) item).get(field); }
    }

    public class ItemMapper implements Collection.Mapper {
        private Type itemType;

        public ItemMapper(List<Object> items) { this.itemType = Runtime.getListItemType(items); }
        public Type valueType() { return itemType; }
        public Object value(Object item) { return item; }
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

        public Type valueType() { return String.class; }
    }


    /**
    * WRAPPERS
    * */
    private class WrapperFactoryAdatper implements WrapperFactory {
        private Type wrapperType;

        public WrapperFactoryAdatper(Type wrapperType) {
            this.wrapperType = wrapperType;
        }

        public Object wrap(Object item) {
            Wrapper wrapper = (Wrapper) wrapperType.newInstance();
            wrapper.wrap(item);
            return wrapper;
        }
    }


    /**
     * Compares records by values of the SObject field.
     */
    public class CompareByField implements Comparator {
        private SObjectField field;
        private Integer direction;
        private Comparator comparator;

        public CompareByField(SObjectField field, Ordering ordr) {
            this.field = field;
            this.direction = ordr == Ordering.ASCENDING ? 1 : -1;
            this.comparator = Comparators.getByField(field);
        }

        public Integer compare(Object thisItem, Object otherItem) {
            Object thisValue = ((SObject) thisItem).get(field);
            Object otherValue = ((SObject) otherItem).get(field);

            return comparator.compare(thisValue, otherValue) * direction;
        }
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
    *
    *
    * UntypedMapss
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
     * Instead of having separate methods for each kind of map, we have UntypedMaps implementations for all primitive key types.
     */
    private interface UntypedMap {
        Object toMap();
        Object keySet();
        void put(Object key, Object value);
        Object get(Object key);
        Boolean containsKey(Object key);
    }

    private static UntypedMap newMap(Type keyType, Type objectType) {
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

    private class MapByObject implements UntypedMap {
        private Map<Object, Object> mapInstance;

        public MapByObject(Map<Object, Object> mapInstance) { this.mapInstance = mapInstance; }
        public void put(Object key, Object value) { mapInstance.put(key, (Object) value); }
        public Boolean containsKey(Object key) { return mapInstance.containsKey(key); }
        public Object get(Object key) { return mapInstance.get(key); }
        public Object toMap() { return mapInstance; }
        public Object keySet() { return mapInstance.keySet().clone(); }
    }

    private class MapById implements UntypedMap {
        private Map<Id, Object> mapInstance;

        public MapById(Map<Id, Object> mapInstance) { this.mapInstance = mapInstance; }
        public void put(Object key, Object value) { mapInstance.put((Id) key, (Object) value); }
        public Boolean containsKey(Object key) { return mapInstance.containsKey((Id) key); }
        public Object get(Object key) { return mapInstance.get((Id) key); }
        public Object toMap() { return mapInstance; }
        public Object keySet() { return mapInstance.keySet().clone(); }
    }

    private class MapByString implements UntypedMap {
        private Map<String, Object> mapInstance;

        public MapByString(Map<String, Object> mapInstance) { this.mapInstance = mapInstance; }
        public void put(Object key, Object value) { mapInstance.put((String) key, (Object) value); }
        public Boolean containsKey(Object key) { return mapInstance.containsKey((String) key); }
        public Object get(Object key) { return mapInstance.get((String) key); }
        public Object toMap() { return mapInstance; }
        public Object keySet() { return mapInstance.keySet().clone(); }
    }

    private class MapByInteger implements UntypedMap {
        private Map<Integer, Object> mapInstance;

        public MapByInteger(Map<Integer, Object> mapInstance) { this.mapInstance = mapInstance; }
        public void put(Object key, Object value) { mapInstance.put((Integer) key, (Object) value); }
        public Boolean containsKey(Object key) { return mapInstance.containsKey((Integer) key); }
        public Object get(Object key) { return mapInstance.get((Integer) key); }
        public Object toMap() { return mapInstance; }
        public Object keySet() { return mapInstance.keySet().clone(); }
    }

    private class MapByDecimal implements UntypedMap {
        private Map<Decimal, Object> mapInstance;

        public MapByDecimal(Map<Decimal, Object> mapInstance) { this.mapInstance = mapInstance; }
        public void put(Object key, Object value) { mapInstance.put((Decimal) key, (Object) value); }
        public Boolean containsKey(Object key) { return mapInstance.containsKey((Decimal) key); }
        public Object get(Object key) { return mapInstance.get((Decimal) key); }
        public Object toMap() { return mapInstance; }
        public Object keySet() { return mapInstance.keySet().clone(); }
    }

    private class MapByDate implements UntypedMap {
        private Map<Date, Object> mapInstance;

        public MapByDate(Map<Date, Object> mapInstance) { this.mapInstance = mapInstance; }
        public void put(Object key, Object value) { mapInstance.put((Date) key, (Object) value); }
        public Boolean containsKey(Object key) { return mapInstance.containsKey((Date) key); }
        public Object get(Object key) { return mapInstance.get((Date) key); }
        public Object toMap() { return mapInstance; }
        public Object keySet() { return mapInstance.keySet().clone(); }
    }

    private class MapByDatetime implements UntypedMap {
        private Map<Datetime, Object> mapInstance;

        public MapByDatetime(Map<Datetime, Object> mapInstance) { this.mapInstance = mapInstance; }
        public void put(Object key, Object value) { mapInstance.put((Datetime) key, (Object) value); }
        public Boolean containsKey(Object key) { return mapInstance.containsKey((Datetime) key); }
        public Object get(Object key) { return mapInstance.get((Datetime) key); }
        public Object toMap() { return mapInstance; }
        public Object keySet() { return mapInstance.keySet().clone(); }
    }

    private class MapByBoolean implements UntypedMap {
        private Map<Boolean, Object> mapInstance;

        public MapByBoolean(Map<Boolean, Object> mapInstance) { this.mapInstance = mapInstance; }
        public void put(Object key, Object value) { mapInstance.put((Boolean) key, (Object) value); }
        public Boolean containsKey(Object key) { return mapInstance.containsKey((Boolean) key); }
        public Object get(Object key) { return mapInstance.get((Boolean) key); }
        public Object toMap() { return mapInstance; }
        public Object keySet() { return mapInstance.keySet().clone(); }
    }

    private class MapByTime implements UntypedMap {
        private Map<Time, Object> mapInstance;

        public MapByTime(Map<Time, Object> mapInstance) { this.mapInstance = mapInstance; }
        public void put(Object key, Object value) { mapInstance.put((Time) key, (Object) value); }
        public Boolean containsKey(Object key) { return mapInstance.containsKey((Time) key); }
        public Object get(Object key) { return mapInstance.get((Time) key); }
        public Object toMap() { return mapInstance; }
        public Object keySet() { return mapInstance.keySet().clone(); }
    }
}