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
public abstract inherited sharing class Collection {

    /**
     * Constructs collection instance for given items
     */
    public static Collection of(List<Object> items) {
        return new CollectionImpl(items);
    }

    /** @return Salesforce List collection */
    public abstract List<Object> get();

    /** @return First item or null if collection is empty */
    public abstract Object getFirst();

    /** @return Last item or null if collection is empty */
    public abstract Object getLast();

    /** @return Nth item of collection. */
    public abstract Object get(Integer i);
    public abstract Object getRandom();
    public abstract Collection add(Integer index, Object element);
    public abstract Collection add(Object element);
    public abstract Collection addAll(List<Object> elements);
    public abstract Collection addAll(Set<Object> elements);
    public abstract Collection remove(Integer index);
    public abstract Collection removeLast();
    public abstract Collection clear();

    /**
     * @return Slice of the collection from starting index to ending index inclusive.
     */
    public abstract Collection slice(Integer start, Integer stop);

    /**
     * @return Slice of th collection containing given indexes.
     */
    public abstract Collection slice(List<Integer> indexes);

    /**
     * @return true when collection is not null or empty, false otherwise.
     */
    public abstract Boolean isNotEmpty();

    /**
     * @return true when collection is null or empty, false otherwise.
     */
    public abstract Boolean isEmpty();

    /**
     * @return Size of the wrapped collection, 0 if null.
     */
    public abstract Integer size();


    /**
     * Filters collection by SObjects field values
     */
    public abstract FieldFilter filter(SObjectField field);
    public abstract FieldFilter filter(String field);

    /**
     * @return Collection of items filtered by Condition implementation
     */
    public abstract Collection filter(Condition filter);


    /**
     * @return Collection of items which have fields populated similarly to given prototype record
     */
    public abstract Collection filterAlike(SObject prototype);


    /**
     * Reduces collection of objects to single output value returned by Reducer implementation.
     * @param reducer Reducer interface implementation. @see Collection.Reducer
     * @param initialValue collection/object to which input is reduced.
     * @return accumulated value from all items
     */
    public abstract Object reduce(Reducer reducer, Object initialValue);

    /**@return Sum of numeric field values*/
    public abstract Decimal sum(SObjectField field);
    public abstract Decimal sum(String field);

    /**@return Average of numeric field values*/
    public abstract Decimal average(SObjectField field);
    public abstract Decimal average(String field);

    /**@return Minimum of numeric field values*/
    public abstract Decimal min(SObjectField field);
    public abstract Decimal min(String field);

    /**@return Maximum of numeric field values*/
    public abstract Decimal max(SObjectField field);
    public abstract Decimal max(String field);

    /**
     * @return List<V>, V - value type of SObject field.
     */
    public abstract List<Object> listOf(SObjectField field);
    public abstract List<Object> listOf(String field);
    public abstract List<Object> listOf(String field, Type fieldType);
    public abstract List<Object> listOf(Mapper valueMapper);

    /**
     * @return Set<V>, V - value type of SObject field.
     */
    public abstract Object setOf(SObjectField field);
    public abstract Object setOf(String field);
    public abstract Object setOf(String field, Type fieldType);
    public abstract Object setOf(Mapper valueMapper);

    /**
     * @return Map<K, V>, K - value type, V - collection item type. LIFO - Last item in collection replace previous in map.
     */
    public abstract Object mapBy(SObjectField field);
    public abstract Object mapBy(SObjectField keyField, SObjectField valueField);
    public abstract Object mapBy(String field);
    public abstract Object mapBy(String keyField, String valueField);
    public abstract Object mapBy(String field, Type fieldType);
    public abstract Object mapBy(String keyField, String valueField, Type keyType, Type valueType);
    public abstract Object mapBy(Mapper keyMapper);
    public abstract Object mapBy(Mapper keyMapper, Mapper valueMapper);

    /**
     * Maps by concatenation of two fields (without separator)
     */
    public abstract Object mapByConcatenation(SObjectField field1, SObjectField field2);


    /**
     * Group records by field value.
     * @return Map<K, List<V>>, K - value type, V - collection item type
     */
    public abstract Object groupBy(SObjectField field);
    public abstract Object groupBy(SObjectField keyField, SObjectField valueField);
    public abstract Object groupBy(String field);
    public abstract Object groupBy(String keyField, String valueField);
    public abstract Object groupBy(String field, Type fieldType);
    public abstract Object groupBy(String keyField, String valueField, Type keyType, Type valueType);
    public abstract Object groupBy(Mapper keyMapper);
    public abstract Object groupBy(Mapper keyMapper, Mapper valueMapper);

    /**
     * Maps by concatenation of two fields (without separator)
     */
    public abstract Object groupByConcatenation(SObjectField field1, SObjectField field2);


    /**
     * Fills in the list with number of clones of provided prototype record.
     * By default, clone is deep and Id, timestamps and autonumber are not preserved.
     *
     * @param count Number of clones in the list
     * @param prototype Prototype of the record. Clone of this record will be added to the list.
     */
    public abstract Collection fill(Integer count, SObject prototype);

    /**
     * Fills in the list with number of clones of provided prototype record.
     * @param count Number of clones in the list
     * @param prototype Prototype of the record. Clone of this record will be added to the list.
     * @param cloneOptions Collection.CloneOptions instance which determine clone operation characteristics.
     */
    public abstract Collection fill(Integer count, SObject prototype, CloneOptions cloneOptions);


    /**
     * Wraps objects into Wrapper implementation.
     * @param wrapperType Type of concrete class implementing Wrapper interface. Must provide no-args constructor.
     */
    public abstract Collection wrap(Type wrapperType);

    /**
     * Wraps collection items using wrapper factory.
     * @return Collection of wrapped objects;
     */
    public abstract Collection wrap(WrapperFactory wrapperFactory, Type wrapperType);


    /**
     * Sorts collection by given field and order.
     * @param field Field to sort by.
     * @param order Sorting order
     */
    public abstract Collection orderBy(SObjectField field, Ordering order);

    /**
     * Sorts collection using given Comparator implementation.
     */
    public abstract Collection orderBy(Comparator comparator);


    /**
     * For each element in collection, Worker.forEach action is executed.
     */
    public abstract Collection forEach(Worker worker);


    /**
     * Simplifies batch unit testing by performing assertion on entire collection
     */
    public abstract Collection assert(Condition filter, String message);
    public abstract Collection assertEquals(SObjectField field, Object value, String message);
    public abstract Collection assertNotEquals(SObjectField field, Object value, String message);


    /*
    * INTERFACES
    * */


    /**
    * Filter determines whether collection item should be included into result set.
    * */
    public interface FieldFilter {
        Collection equals(Object value);
        Collection notEquals(Object value);
        Collection greaterThan(Object value);
        Collection greaterEqualsThan(Object value);
        Collection lessThan(Object value);
        Collection lessEqualsThan(Object value);
        Collection isIn(Set<Object> values);
        Collection isIn(List<Object> values);
        Collection isNotIn(Set<Object> values);
        Collection isNotIn(List<Object> values);
        Collection relatedTo(List<SObject> parents);
        Collection contains(String value);
    }


    /**
     * Reduces collection to single output variable.
     * @param accumulator Reducers output from previous item or initial value.
     * @param item currently processed item.
     * @param index item's index
     * @return aggregatedValues
     */
    public interface Reducer {
        Object reduce(Object accumulator, Object item, Integer index);
    }

    /**
     * Produces value from given collection item.
     */
    public interface Mapper {
        Type valueType();
        Object value(Object item);
    }


    /**
     * Wrapper interface.
     * Concrete method implementing this interface should have a member variable for wrapped item.
     * wrap method should set that member variable or set other data from the record.
     */
    public interface Wrapper {
        void wrap(Object item);
    }

    /**
     * WrapperFactory interface.
     * Concrete method implementing this interface should produce wrapper for given item.
     */
    public interface WrapperFactory {
        Object wrap(Object item);
    }


    /**
     * Worker performs action on each item in collection.
     */
    public interface Worker {
        void forEach(Object item, Integer index);
    }


    /**
     * Clone options used to populate collection with fill() method
     */
    public class CloneOptions {
        public Boolean preserveId { get; private set; }
        public Boolean deepClone { get; private set; }
        public Boolean preserveReadonlyTimestamps { get; private set; }
        public Boolean preserveAutonumber { get; private set; }

        public CloneOptions(Boolean preserveId, Boolean deepClone, Boolean preserveReadonlyTimestamps, Boolean preserveAutonumber) {
            this.preserveId = preserveId;
            this.deepClone = deepClone;
            this.preserveReadonlyTimestamps = preserveReadonlyTimestamps;
            this.preserveAutonumber = preserveAutonumber;
        }
    }


    public class CollectionException extends Exception {
    }
}