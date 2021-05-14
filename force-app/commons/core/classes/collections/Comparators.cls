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

public with sharing class Comparators {

    public final static Map<Schema.SoapType, Comparator> comparatorsByFieldType = new Map<SoapType, Comparator>{
            SoapType.ID => new Comparators.StringComparator(),
            SoapType.STRING => new Comparators.StringComparator(),
            SoapType.DATE => new Comparators.DatetimeComparator(),
            SoapType.DATETIME => new Comparators.DateTimeComparator(),
            SoapType.INTEGER => new Comparators.IntegerComparator(),
            SoapType.DECIMAL => new Comparators.DecimalComparator(),
            SoapType.DOUBLE => new Comparators.DoubleComparator(),
            SoapType.BOOLEAN => new Comparators.BooleanComparator(),
            SoapType.TIME => new Comparators.BooleanComparator()
    };

    public static Comparator getByField(SObjectField field) {
        Comparator comparator = comparatorsByFieldType.get(field.getDescribe().getSoapType());
        return comparator == null ? new Comparators.AnyComparator() : comparator;
    }

    public static Comparator getForPrimitive(Object o1) {
        if (o1 instanceof Id) return new StringComparator();
        if (o1 instanceof String) return new StringComparator();
        if (o1 instanceof Datetime) return new DateTimeComparator();
        if (o1 instanceof Time) return new TimeComparator();
        if (o1 instanceof Integer) return new IntegerComparator();
        if (o1 instanceof Decimal) return new DecimalComparator();
        if (o1 instanceof Double) return new DoubleComparator();
        if (o1 instanceof Long) return new IntegerComparator();
        if (o1 instanceof Boolean) return new BooleanComparator();

        return new AnyComparator();
    }

    public class AnyComparator implements Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            String a = thisItem == null ? '' : '' + thisItem;
            String b = otherItem == null ? '' : '' + otherItem;
            return a.compareTo(b);
        }
    }
    public class BooleanComparator implements Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Boolean a = (Boolean) thisItem, b = (Boolean) otherItem;
            return a == b ? 0 : 1;
        }
    }
    public class DateTimeComparator implements Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Datetime a = (Datetime) thisItem, b = (Datetime) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    public class DecimalComparator implements Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Decimal a = (Decimal) thisItem, b = (Decimal) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    public class DoubleComparator implements Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Double a = (Double) thisItem, b = (Double) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    public class IntegerComparator implements Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Integer a = (Integer) thisItem, b = (Integer) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    public class StringComparator implements Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            String a = (String) thisItem, b = (String) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    public class TimeComparator implements Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Time a = (Time) thisItem, b = (Time) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
}