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
    public abstract Decimal getSum(SObjectField field);

    /**@return Average of numeric field values*/
    public abstract Decimal getAverage(SObjectField field);

    /**@return Minimum of numeric field values*/
    public abstract Decimal getMin(SObjectField field);

    /**@return Maximum of numeric field values*/
    public abstract Decimal getMax(SObjectField field);

    /**
     * @return List<V>, V - value type of SObject field. Cast to expected value type.
     */
    public abstract List<Id> getListId(SObjectField field);
    public abstract List<String> getListString(SObjectField field);
    public abstract List<Integer> getListInteger(SObjectField field);

    public abstract List<Object> getList(SObjectField field);
    public abstract List<Object> getList(Mapper valueMapper);

    /**
     * @return Set<V>, V - value type of SObject field. Cast to expected Set type.
     * ex. Set<String> names = (Set<String>) Collection.of(accounts).getSet(Account.Name);
     */
    public abstract Set<Id> getSetId(SObjectField field);
    public abstract Set<String> getSetString(SObjectField field);
    public abstract Set<Integer> getSetInteger(SObjectField field);
    public abstract Object getSet(SObjectField field);
    public abstract Object getSet(Mapper valueMapper);

    /**
     * @return Map<K, V>, K - value type, V - collection item type. LIFO - Last item in collection replace previous in map.
     * Cast to expected map. ex:
     * <pre>
     * Map<String, Account> accountsByExternalId = (Map<String, Account>) Collection.of(accounts).mapBy(Account.ExternalId__c);
     * </pre>
     */
    public abstract Object mapBy(SObjectField field);
    public abstract Object mapBy(SObjectField keyField, SObjectField valueField);
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
    public abstract Object groupBy(Mapper keyMapper);
    public abstract Object groupBy(Mapper keyMapper, Mapper valueMapper);

    /**
     * Maps by concatenation of two fields (without separator)
     */
    public abstract Object groupByConcatenation(SObjectField field1, SObjectField field2);


    /**
     * Sorts collection by given field and order.
     * @param field Field to sort by.
     */
    public abstract Collection orderAsc(SObjectField field);
    public abstract Collection orderDesc(SObjectField field);

    /**
     * Sorts collection using given Comparator implementation.
     */
    public abstract Collection orderBy(Comparator comparator);


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
        Collection isIn(List<SObject> parents);
        Collection isNotIn(Set<Object> values);
        Collection isNotIn(List<Object> values);
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

    public class CollectionException extends Exception {
    }
}