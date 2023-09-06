/**
* MIT License
*
* Copyright (c) 2019 Piotr Kożuchowski
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
@IsTest(IsParallel=true)
private class RangeTest {
    static Range integerRange = Range.between(-100, 100);
    static Range dateRange = Range.between(
            Date.today().addDays(-10),
            Date.today().addDays(10)
    );
    static Range datetimeRange = Range.between(
            Datetime.now().addDays(-10),
            Datetime.now().addDays(10)
    );


    /**
     *@description
     * Range.getMaximum() returns upper limit of the range.
     */
    @IsTest
    static void testGetMaximum() {
        System.assertEquals(100, integerRange.getMaximum());
        System.assertEquals(Date.today().addDays(10), dateRange.getMaximum());
        System.assertEquals(Datetime.now().addDays(10), datetimeRange.getMaximum());
    }

    /**
     *@description
     * Range.getMinimum() returns lower limit of the range.
     */
    @IsTest
    static void testGetMinimum() {
        System.assertEquals(-100, integerRange.getMinimum());
        System.assertEquals(Date.today().addDays(-10), dateRange.getMinimum());
        System.assertEquals(Datetime.now().addDays(-10), datetimeRange.getMinimum());
    }

    /**
     *@description
     * Range.add(element) adds element to the range which may become new lower or upper limit
     */
    @IsTest
    static void testAdd() {
        integerRange.add(150);
        integerRange.add(-110);

        System.assertEquals(-110, integerRange.getMinimum());
        System.assertEquals(150, integerRange.getMaximum());

        dateRange.add(Date.today().addDays(100));
        System.assertEquals(Date.today().addDays(100), dateRange.getMaximum());
    }

    /**
     *@description
     * Range.contains() checks whether element is within the range.
     */
    @IsTest
    static void testContains() {
        System.assert(integerRange.contains(-10));
        System.assert(integerRange.contains(9));
        System.assert(integerRange.contains(0));
        System.assert(datetimeRange.contains(Datetime.now()));
        System.assert(datetimeRange.contains(Datetime.now().addDays(2)));
    }

    /**
     *@description
     * Range.isStartedBy() checks whether given element is the lower limit of the range
     */
    @IsTest
    static void testIsStartedBy() {
        System.assertEquals(true, integerRange.isStartedBy(-100));
        System.assertEquals(false, integerRange.isStartedBy(100));
        System.assertEquals(true, dateRange.isStartedBy(Date.today().addDays(-10)));
        System.assertEquals(false, dateRange.isStartedBy(Date.today()));
    }

    /**
     *@description
     * Range.isEndedBy()() checks whether given element is the lower limit of the range
     */
    @IsTest
    static void testIsEndedBy() {
        System.assertEquals(true, integerRange.isEndedBy(100));
        System.assertEquals(false, integerRange.isEndedBy(50));
        System.assertEquals(true, dateRange.isEndedBy(Date.today().addDays(10)));
        System.assertEquals(false, dateRange.isEndedBy(Date.today()));
    }

    /**
     *@description
     * Range.isAfter() returns true if Range is completely after given element
     */
    @IsTest
    static void testIsAfter() {
        System.assertEquals(true, integerRange.isAfter(-150));
        System.assertEquals(false, integerRange.isAfter(-100));
        System.assertEquals(false, integerRange.isAfter(-90));
        System.assertEquals(false, integerRange.isAfter(null));
        System.assertEquals(true, dateRange.isAfter(Date.today().addDays(-11)));
        System.assertEquals(false, dateRange.isAfter(Date.today().addDays(-10)));
        System.assertEquals(false, dateRange.isAfter(null));
    }

    /**
     *@description
     * Range.isBefore()() returns true if Range is completely after given element
     */
    @IsTest
    static void testIsBefore() {
        System.assertEquals(true, integerRange.isBefore(150));
        System.assertEquals(false, integerRange.isBefore(100));
        System.assertEquals(false, integerRange.isBefore(90));
        System.assertEquals(false, integerRange.isBefore(null));
        System.assertEquals(true, dateRange.isBefore(Date.today().addDays(11)));
        System.assertEquals(false, dateRange.isBefore(Date.today().addDays(10)));
        System.assertEquals(false, dateRange.isBefore(null));
    }

    /**
     *@description
     * Range.elementCompareTo() checks position of the element to the Range and returns -1, 0 or 1
     */
    @IsTest
    static void testElementComparedto() {
        System.assertEquals(0, integerRange.elementCompareTo(0));
        System.assertEquals(0, integerRange.elementCompareTo(-100));
        System.assertEquals(0, integerRange.elementCompareTo(100));
        System.assertEquals(-1, integerRange.elementCompareTo(-101));
        System.assertEquals(1, integerRange.elementCompareTo(101));
    }

    /**
     *@description
     * Range.containsRange(Range other) checks whether other range is within boundaries of the range.
     */
    @IsTest
    static void testContainsRange() {
        System.assertEquals(true, integerRange.containsRange(Range.between(-90, 90)));
        System.assertEquals(true, integerRange.containsRange(Range.between(-50, 100)));
        System.assertEquals(true, integerRange.containsRange(Range.between(-100, -99)));
        System.assertEquals(false, integerRange.containsRange(Range.between(-101, -99)));
    }

    /**
     *@description
     * Range.isAfterRange() checks whether current range is completely after other range
     */
    @IsTest
    static void testIsAfterRange() {
        System.assertEquals(true, integerRange.isAfterRange(Range.between(-200, -101)));
        System.assertEquals(false, integerRange.isAfterRange(Range.between(-200, -100)));
        System.assertEquals(false, integerRange.isAfterRange(Range.between(-99, 100)));
    }

    /**
     *@description
     * Range.isBeforeRange() checks whether current range is completely before other range
     */
    @IsTest
    static void testIsBeforeRange() {
        System.assertEquals(true, integerRange.isBeforeRange(Range.between(101, 200)));
        System.assertEquals(false, integerRange.isBeforeRange(Range.between(100, 105)));
        System.assertEquals(false, integerRange.isBeforeRange(Range.between(0, 200)));
    }

    /**
     *@description
     * Range.isOverlappedBy() checks whether this range is overlapped by the other.
     */
    @IsTest
    static void testIsOverlappedBy() {
        System.assertEquals(false, integerRange.isOverlappedBy(Range.between(-200, -150)));
        System.assertEquals(true, integerRange.isOverlappedBy(Range.between(-200, -50)));
        System.assertEquals(true, integerRange.isOverlappedBy(Range.between(-200, 200)));
        System.assertEquals(true, integerRange.isOverlappedBy(Range.between(-50, 50)));
        System.assertEquals(true, integerRange.isOverlappedBy(Range.between(-50, 200)));
        System.assertEquals(false, integerRange.isOverlappedBy(Range.between(-200, -150)));
        System.assertEquals(false, integerRange.isOverlappedBy(Range.between(150, 200)));
    }

    /**
     *@description
     * Range.intersectionWith() returns intersection between this and other range.
     */
    @IsTest
    static void testIntersectionWith() {
        Range intersection = integerRange.intersectionWith(Range.between(50, 200));
        System.assertEquals(50, intersection.getMinimum());
        System.assertEquals(100, intersection.getMaximum());

        intersection = integerRange.intersectionWith(Range.between(-150, 50));
        System.assertEquals(-100, intersection.getMinimum());
        System.assertEquals(50, intersection.getMaximum());

        intersection = integerRange.intersectionWith(Range.between(-30, 30));
        System.assertEquals(-30, intersection.getMinimum());
        System.assertEquals(30, intersection.getMaximum());
    }

    @IsTest
    static void testEquals() {
        System.assertEquals(true, integerRange.equals(Range.between(-100, 100)));
        System.assertEquals(true, dateRange.equals(Range.between(Date.today().addDays(-10), Date.today().addDays(10))));
        System.assertEquals(false, integerRange.equals(null));
        System.assertEquals(false, integerRange.equals(new Account()));
    }
}