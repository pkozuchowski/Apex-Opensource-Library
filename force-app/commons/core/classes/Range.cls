/**
* Copyright 2019 Piotr Kożuchowski
* based on Apache technology
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

/**
 * A range of objects from a minimum to maximum point inclusive.
 */
public with sharing class Range {
    private Object fromInclusive;
    private Object toInclusive;
    private Comparator comparator;

    /**
     * Obtains a range with the specified minimum and maximum values (both inclusive).
     * @param fromInclusive - the first value that defines the edge of the range, inclusive
     * @param toInclusive - the second value that defines the edge of the range, inclusive
     * @return the range object, not null
     */
    public static Range between(Object fromInclusive, Object toInclusive) {
        return Range.between(fromInclusive, toInclusive, Comparators.getForPrimitive(fromInclusive));
    }

    /**
     * Obtains a range with the specified minimum and maximum values (both inclusive).
     * The range uses the specified Comparator to determine where values lie in the range.
     * @param fromInclusive - the first value that defines the edge of the range, inclusive
     * @param toInclusive - the second value that defines the edge of the range, inclusive
     * @param comparator - the comparator to be used
     * @return the range object, not null
     */
    public static Range between(Object fromInclusive, Object toInclusive, Comparator comparator) {
        return new Range(fromInclusive, toInclusive, comparator);
    }


    private Range(Object fromInclusive, Object toInclusive, Comparator comparator) {
        this.fromInclusive = fromInclusive;
        this.toInclusive = toInclusive;
        this.comparator = comparator;
    }

    /**
     * Adds element to the range.
     * If element is smaller than lower range limit, then it becomes the new lower range limit.
     * If element is bigger than upper range limit, then it becomes the new upper range limit.
     */
    public void add(Object o) {
        if (comparator.compare(fromInclusive, o) > 0) fromInclusive = o;
        if (comparator.compare(toInclusive, o) < 0) toInclusive = o;
    }

    /**
     * @return Upper range limit.
     */
    public Object getMaximum() {
        return toInclusive;
    }

    /**
     * @return Lower range limit.
     */
    public Object getMinimum() {
        return fromInclusive;
    }

    /**
     * Checks whether the specified element occurs within this range.
     * @param element - the element to check for, null returns false
     * @return true if the specified element occurs within this range
     */
    public Boolean contains(Object element) {
        return comparator.compare(fromInclusive, element) <= 0 && comparator.compare(toInclusive, element) >= 0;
    }

    /**
    * Checks whether this range starts with the specified element.
    * @param element - the element to check for, null returns false
    * @return true if the specified element occurs within this range
    *
    * */
    public Boolean isStartedBy(Object element) {
        return comparator.compare(fromInclusive, element) == 0;
    }

    /**
    * Checks whether this range ends with the specified element.
    * @param element - the element to check for, null returns false
    * @return true if the specified element occurs within this range
    * */
    public Boolean isEndedBy(Object element) {
        return comparator.compare(toInclusive, element) == 0;
    }

    /**
     * Checks whether this range is after the specified element.
     * @param element - the element to check for, null returns false
     * @return true if this range is entirely before the specified element
     */
    public Boolean isAfter(Object element) {
        return comparator.compare(fromInclusive, element) > 0;
    }

    /**
     * Checks whether this range is before the specified element.
     * @param element - the element to check for, null returns false
     * @return true if this range is entirely before the specified element
     */
    public Boolean isBefore(Object element) {
        return comparator.compare(toInclusive, element) < 0;
    }

    /**
     * Checks where the specified element occurs relative to this range.
     * @param element - the element to check for
     * @return -1, 0 or +1 depending on the element's location relative to the range
     */
    public Integer elementCompareTo(Object element) {
        if (this.isBefore(element)) return 1;
        if (this.isAfter(element)) return -1;
        return 0;
    }

    /**
     * Checks whether this range contains all the elements of the specified range.
     * @param otherRange - the range to check, null returns false
     * @return true if this range contains the specified range
     */
    public Boolean containsRange(Range otherRange) {
        return comparator.compare(this.fromInclusive, otherRange.fromInclusive) <= 0
                && comparator.compare(this.toInclusive, otherRange.toInclusive) >= 0;
    }

    /**
     * Checks whether this range is completely after the specified range.
     * @param otherRange - the range to check, null returns false
     * @return true if this range contains the specified range
     */
    public Boolean isAfterRange(Range otherRange) {
        return comparator.compare(this.fromInclusive, otherRange.toInclusive) > 0;
    }

    /**
     * Checks whether this range is overlapped by the specified range.
     * Two ranges overlap if there is at least one element in common.
     * @param otherRange - the range to check, null returns false
     * @return true if this range contains the specified range
     */
    public Boolean isOverlappedBy(Range otherRange) {
        return !isBeforeRange(otherRange) && !isAfterRange(otherRange);
    }

    /**
     * Checks whether this range is completely before the specified range.
     * @param otherRange - the range to check, null returns false
     * @return true if this range contains the specified range
     */
    public Boolean isBeforeRange(Range otherRange) {
        return comparator.compare(this.toInclusive, otherRange.fromInclusive) < 0;
    }

    /**
     * Calculate the intersection of this and an overlapping Range.
     * @param otherRange - overlapping Range
     * @return range representing the intersection of this and other (this if equal)
     */
    public Range intersectionWith(Range otherRange) {
        Object newFromInclusive = comparator.compare(this.fromInclusive, otherRange.fromInclusive) >= 0 ? this.fromInclusive : otherRange.fromInclusive;
        Object newToInclusive = comparator.compare(this.toInclusive, otherRange.toInclusive) <= 0 ? this.toInclusive : otherRange.toInclusive;

        return Range.between(newFromInclusive, newToInclusive);
    }

    /**
     * Checks whether this range is equal to other Range.
     * Ranges are equal when their lower and upper limits are equal.
     * @param other other object
     * @return true if other range is equal.
     */
    public Boolean equals(Object other) {
        if (other instanceof Range) {
            Range otherRange = (Range) other;
            return comparator.compare(this.fromInclusive, otherRange.fromInclusive) == 0
                    && comparator.compare(this.toInclusive, otherRange.toInclusive) == 0;

        } else {
            return false;
        }
    }
}