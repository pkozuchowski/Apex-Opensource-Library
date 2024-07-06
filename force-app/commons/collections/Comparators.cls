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

    public final static Map<Schema.SoapType, Comparator<Object>> comparatorsByFieldType = new Map<SoapType, Comparator<Object>>{
        SoapType.ID => (Comparator<Object>) new StringComparator(),
        SoapType.STRING => (Comparator<Object>) new StringComparator(),
        SoapType.DATE => (Comparator<Object>) new DateTimeComparator(),
        SoapType.DATETIME => (Comparator<Object>) new DateTimeComparator(),
        SoapType.INTEGER => (Comparator<Object>) new LongComparator(),
        SoapType.LONG => (Comparator<Object>) new LongComparator(),
        SoapType.DECIMAL => (Comparator<Object>) new DoubleComparator(),
        SoapType.DOUBLE => (Comparator<Object>) new DoubleComparator(),
        SoapType.BOOLEAN => (Comparator<Object>) new BooleanComparator(),
        SoapType.TIME => (Comparator<Object>) new TimeComparator()
    };

    public static Comparator<Object> getByField(SObjectField field) {
        SoapType soapType = field.getDescribe().getSoapType();
        Comparator<Object> comparator = (Comparator<Object>) comparatorsByFieldType
            .get(soapType);
        return comparator == null ? new Comparators.AnyComparator() : comparator;
    }

    public static Comparator<Object> getForPrimitive(Object o1) {
        if (o1 instanceof Id) return (Comparator<Object>) new StringComparator();
        if (o1 instanceof String) return (Comparator<Object>) new StringComparator();
        if (o1 instanceof Datetime) return (Comparator<Object>) new DateTimeComparator();
        if (o1 instanceof Time) return (Comparator<Object>) new TimeComparator();
        if (o1 instanceof Integer) return (Comparator<Object>) new LongComparator();
        if (o1 instanceof Decimal) return (Comparator<Object>) new DoubleComparator();
        if (o1 instanceof Double) return (Comparator<Object>) new DoubleComparator();
        if (o1 instanceof Long) return (Comparator<Object>) new LongComparator();
        if (o1 instanceof Boolean) return (Comparator<Object>) new BooleanComparator();

        return new AnyComparator();
    }

    public class AnyComparator implements Comparator<Object> {
        public Integer compare(Object thisItem, Object otherItem) {
            String a = thisItem == null ? '' : '' + thisItem;
            String b = otherItem == null ? '' : '' + otherItem;
            return a.compareTo(b);
        }
    }
    public class BooleanComparator implements Comparator<Boolean> {
        public Integer compare(Object thisItem, Object otherItem) {
            Boolean a = (Boolean) thisItem, b = (Boolean) otherItem;
            return a == b ? 0 : 1;
        }
    }
    public class DateTimeComparator implements Comparator<Datetime> {
        public Integer compare(Datetime a, Datetime b) {
            return a == b ? 0 : a > b ? 1 : -1;
        }
    }
    public class DoubleComparator implements Comparator<Double> {
        public Integer compare(Double a, Double b) {
            return a == b ? 0 : a > b ? 1 : -1;
        }
    }
    public class LongComparator implements Comparator<Long> {
        public Integer compare(Long a, Long b) {
            return a == b ? 0 : a > b ? 1 : -1;
        }
    }
    public class StringComparator implements Comparator<String> {
        public Integer compare(String a, String b) {
            return a == b ? 0 : a > b ? 1 : -1;
        }
    }
    public class TimeComparator implements Comparator<Time> {
        public Integer compare(Time a, Time b) {
            return a == b ? 0 : a > b ? 1 : -1;
        }
    }

    /**
     * Compares records by values of the SObject field.
     */
    public class SObjectComparator implements Comparator<SObject> {
        private SObjectField field;
        private Integer direction;
        private Comparator<Object> comparator;

        public SObjectComparator(SObjectField field, Integer direction) {
            this.field = field;
            this.direction = direction;
            this.comparator = Comparators.getByField(field);
        }

        public Integer compare(SObject a, SObject b) {
            Object thisValue = a.get(field);
            Object otherValue = b.get(field);

            return comparator.compare(thisValue, otherValue) * direction;
        }
    }
}