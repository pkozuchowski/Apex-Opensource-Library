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
    public final static Boolean ANY_VALUE = true;

    public static Collection of(List<Object> items) {
        return new CollectionImpl(items);
    }

    /**
    * @return Salesforce List collection
    * */
    public abstract List<Object> get();

    /**
     * @return First item or null if collection is empty
     */
    public abstract Object getFirst();

    /**
     * @return Last item or null if collection is empty
     */
    public abstract Object getLast();

    /**
     * @return Nth item of collection.
     */
    public abstract Object get(Integer i);
    public abstract Collection add(Integer index, Object element);
    public abstract Collection add(Object element);
    public abstract Collection addAll(List<Object> elements);
    public abstract Collection addAll(Set<Object> elements);
    public abstract Collection remove(Integer index);
    public abstract Collection removeLast();

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
     * This method allows for building criteria to filter the collection or to find the first record satisfying the criteria.
     * then() method returns filtered collection for given criteria and can be used in further chaining.
     * getFirst() returns the first record satisfying criteria.
     * For best best performance it's adviced to use single Filter implementation since byField() method has greater overhead
     * scaled linearly with number of linked predicates.
     */
    public abstract FilterFacade filter();


    /**
     * Reduces collection to the single value, for example
     * List, Set, Map or Group of field values
     */
    public abstract ReduceFacade reduce();


    /**
     * Fills in the list with number of clones of provided prototype record.
     * By default, clone is deep and Id, timestamps and autonumbers are not preserved.
     *
     * @param listToFill List to fill in.
     * @param count Number of clones in the list
     * @param prototype Prototype of the record. Clone of this record will be added to the list.
     */
    public abstract Collection fill(Integer count, SObject prototype);

    /**
     * Fills in the list with number of clones of provided prototype record.
     * @param count Number of clones in the list
     * @param prototype Prototype of the record. Clone of this record will be added to the list.
     * @param opts Collection.CloneOptions instance which determine clone operation characteristics.
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


    /*
    *
    * INTERFACES
    *
    *
    * */


    /**
    * Filter determines whether collection item should be included into result set.
    * */
    public interface Filter {
        Boolean accepts(Object item);
    }


    public interface FilterFacade {
        FilterFacade byUsing(Filter filter);
        /**Checks if record has fields populated as provided example record.*/
        FilterFacade alike(SObject prototype);
        FieldFilterFacade byField(SObjectField field);

        /**
         * This method exists only for verbosity and can be omitted.
         * Predicates use AND by default.
         */
        FilterFacade andAlso();

        /** Former and following predicate are joined using OR connective.*/
        FilterFacade orElse();

        /** Evaluates filters and returns Collection of filtered items. */
        Collection then();

        /** @return first item satisfying conditions. */
        Object getFirst();
    }

    public interface FieldFilterFacade {
        FilterFacade equals(Object value);
        FilterFacade notEquals(Object value);
        FilterFacade greaterThan(Object value);
        FilterFacade greaterEqualsThan(Object value);
        FilterFacade lessThan(Object value);
        FilterFacade lessEqualsThan(Object value);
        FilterFacade isIn(Set<Object> values);
        FilterFacade isIn(List<Object> values);
        FilterFacade isNotIn(Set<Object> values);
        FilterFacade isNotIn(List<Object> values);
        FilterFacade relatedTo(List<SObject> parents);
        FilterFacade containing(String value);
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

    public interface ReduceFacade {
        /**
         * Reduces collection of objects to single output value returned by Reducer implementation.
         * @param reducer Reducer interface implementation. @see Collections.Reducer
         * @param initialValue collection/object to which input is reduced.
         * @return accumulated value from all items
         */
        Object to(Reducer reducer, Object initialValue);
        Decimal toSum(SObjectField field);
        Decimal toAverage(SObjectField field);
        Decimal toMin(SObjectField field);
        Decimal toMax(SObjectField field);

        List<Object> toList(SObjectField field);
        List<Object> toList(Mapper valueMapper);

        Object toSet(SObjectField field);
        Object toSet(Mapper valueMapper);

        Object toMap(SObjectField field);
        Object toMap(SObjectField keyField, SObjectField valueField);
        Object toMap(Mapper keyMapper);
        Object toMap(Mapper keyMapper, Mapper valueMapper);

        Object toGroup(SObjectField field);
        Object toGroup(SObjectField keyField, SObjectField valueField);
        Object toGroup(Mapper keyMapper);
        Object toGroup(Mapper keyMapper, Mapper valueMapper);
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


    public class CollectionException extends Exception {
    }
}