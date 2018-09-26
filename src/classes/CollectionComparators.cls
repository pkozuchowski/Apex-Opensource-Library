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
public class CollectionComparators {
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

    public static Collection.Comparator getComparatorByField(SObjectField field) {
        Collection.Comparator comparator = comparatorsByFieldType.get(field.getDescribe().getSoapType());

        if (comparator == null) {
            comparator = new AnyComparator();
        }

        return comparator;
    }


    public class AnyComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            String a = thisItem == null ? '' : '' + thisItem;
            String b = otherItem == null ? '' : '' + otherItem;

            return a.compareTo(b);
        }
    }
    public class BooleanComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Boolean a = (Boolean) thisItem, b = (Boolean) otherItem;
            return a == b ? 0 : 1;
        }
    }
    public class DateComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Date a = (Date) thisItem, b = (Date) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    public class DateTimeComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Datetime a = (Datetime) thisItem, b = (Datetime) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    public class DecimalComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Decimal a = (Decimal) thisItem, b = (Decimal) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    public class DoubleComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Double a = (Double) thisItem, b = (Double) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    public class IntegerComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Integer a = (Integer) thisItem, b = (Integer) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    public class StringComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            String a = (String) thisItem, b = (String) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    public class TimeComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Time a = (Time) thisItem, b = (Time) otherItem;
            return a == b ? 0 : 1;
        }
    }


    /**
     * Compares records by values of the SObject field.
     */
    public class ByField implements Collection.Comparator {
        private SObjectField field;
        private Integer direction;
        private Collection.Comparator comparator;

        public ByField(SObjectField field, Boolean isAscending) {
            this.field = field;
            this.direction = isAscending ? 1 : -1;
            this.comparator = getComparatorByField(field);
        }

        public Integer compare(Object thisItem, Object otherItem) {
            Object thisValue = ((SObject) thisItem).get(field);
            Object otherValue = ((SObject) otherItem).get(field);

            return comparator.compare(thisValue, otherValue) * direction;
        }
    }


    /**
     * Compares SObjects by distance to given geolocation.
     */
    public class ByDistance implements Collection.Comparator {
        private SObjectField field;
        private Integer direction;
        private Integer nullsPosition = 1;
        private Location target;
        private Map<Id, Double> distanceCache;

        /**
         * @param field Location field
         * @param geoLocation Target geolocation. Records are sorted by distance to this location.
         * @param closestFirst true - Closest are first / false - farthest first
         */
        public ByDistance(SObjectField field, Location geoLocation, Boolean closestFirst, Boolean nullFirst) {
            this.distanceCache = new Map<Id, Double>();
            this.field = field;
            this.direction = closestFirst ? -1 : 1;
            this.nullsPosition = nullFirst ? -1 : 1;
            this.target = geoLocation;
        }

        public Integer compare(Object thisItem, Object otherItem) {
            Double thisDistance = getDistance((SObject) thisItem);
            if (thisDistance == null) return nullsPosition;

            Double otherDistance = getDistance((SObject) otherItem);
            if (otherDistance == null) return -nullsPosition;

            return direction * (thisDistance > otherDistance ? 1 :
                    thisDistance < otherDistance ? -1
                            : 0);
        }

        private Double getDistance(SObject record) {
            if (distanceCache.containsKey(record.Id)) {
                return distanceCache.get(record.Id);
            }

            Location loc = (Location) record.get(field);
            if (loc == null) {
                return null;
            }

            Double distance = this.target.getDistance((Location) record.get(field), 'km');
            distanceCache.put(record.Id, distance);

            return distance;
        }
    }
}