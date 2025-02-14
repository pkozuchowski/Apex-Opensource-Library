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

    public final static Map<Schema.SoapType, System.Comparator<Object>> comparatorsByFieldType = new Map<SoapType, System.Comparator<Object>>{
        SoapType.ID => (System.Comparator<Object>) new StringComparator(),
        SoapType.STRING => (System.Comparator<Object>) new StringComparator(),
        SoapType.DATE => (System.Comparator<Object>) new DateTimeComparator(),
        SoapType.DATETIME => (System.Comparator<Object>) new DateTimeComparator(),
        SoapType.INTEGER => (System.Comparator<Object>) new LongComparator(),
        SoapType.LONG => (System.Comparator<Object>) new LongComparator(),
        SoapType.DECIMAL => (System.Comparator<Object>) new DoubleComparator(),
        SoapType.DOUBLE => (System.Comparator<Object>) new DoubleComparator(),
        SoapType.BOOLEAN => (System.Comparator<Object>) new BooleanComparator(),
        SoapType.TIME => (System.Comparator<Object>) new TimeComparator()
    };

    public static System.Comparator<Object> getByField(SObjectField field) {
        SoapType soapType = field.getDescribe().getSoapType();
        System.Comparator<Object> comparator = (System.Comparator<Object>) comparatorsByFieldType
            .get(soapType);
        return comparator == null ? new Comparators.AnyComparator() : comparator;
    }

    public static System.Comparator<Object> getForPrimitive(Object o1) {
        if (o1 instanceof Id) return (System.Comparator<Object>) new StringComparator();
        if (o1 instanceof String) return (System.Comparator<Object>) new StringComparator();
        if (o1 instanceof Datetime) return (System.Comparator<Object>) new DateTimeComparator();
        if (o1 instanceof Time) return (System.Comparator<Object>) new TimeComparator();
        if (o1 instanceof Integer) return (System.Comparator<Object>) new LongComparator();
        if (o1 instanceof Decimal) return (System.Comparator<Object>) new DoubleComparator();
        if (o1 instanceof Double) return (System.Comparator<Object>) new DoubleComparator();
        if (o1 instanceof Long) return (System.Comparator<Object>) new LongComparator();
        if (o1 instanceof Boolean) return (System.Comparator<Object>) new BooleanComparator();

        return new AnyComparator();
    }

    public class AnyComparator implements System.Comparator<Object> {
        public Integer compare(Object thisItem, Object otherItem) {
            String a = thisItem == null ? '' : '' + thisItem;
            String b = otherItem == null ? '' : '' + otherItem;
            return a.compareTo(b);
        }
    }
    public class BooleanComparator implements System.Comparator<Boolean> {
        public Integer compare(Object thisItem, Object otherItem) {
            Boolean a = (Boolean) thisItem, b = (Boolean) otherItem;
            return a == b ? 0 : 1;
        }
    }
    public class DateTimeComparator implements System.Comparator<Datetime> {
        public Integer compare(Datetime a, Datetime b) {
            return a == b ? 0 : a > b ? 1 : -1;
        }
    }
    public class DoubleComparator implements System.Comparator<Double> {
        public Integer compare(Double a, Double b) {
            return a == b ? 0 : a > b ? 1 : -1;
        }
    }
    public class LongComparator implements System.Comparator<Long> {
        public Integer compare(Long a, Long b) {
            return a == b ? 0 : a > b ? 1 : -1;
        }
    }
    public class StringComparator implements System.Comparator<String> {
        public Integer compare(String a, String b) {
            return a == b ? 0 : a > b ? 1 : -1;
        }
    }
    public class TimeComparator implements System.Comparator<Time> {
        public Integer compare(Time a, Time b) {
            return a == b ? 0 : a > b ? 1 : -1;
        }
    }

    /**
     * Compares records by values of the SObject field.
     */
    public class SObjectComparator implements System.Comparator<SObject> {
        private SObjectField field;
        private Integer direction;
        private System.Comparator<Object> comparator;

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