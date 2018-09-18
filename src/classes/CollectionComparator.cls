public class CollectionComparator {
    private final static Map<Schema.SoapType, Collection.Comparator> comparatorsByFieldType = new Map<SoapType, Collection.Comparator>{
            SoapType.STRING => new StringComparator(),
            SoapType.DATE => new DateComparator(),
            SoapType.DATETIME => new DateTimeComparator(),
            SoapType.INTEGER => new IntegerComparator(),
            SoapType.DECIMAL => new DecimalComparator(),
            SoapType.BOOLEAN => new BooleanComparator()
    };

    public static Collection.Comparator getComparatorByField(SObjectField field) {
        return comparatorsByFieldType.get(field.getDescribe().getSoapType());
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
    public class StringComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            String a = (String) thisItem, b = (String) otherItem;
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
    public class DecimalComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Decimal a = (Decimal) thisItem, b = (Decimal) otherItem;
            if (a > b) return 1;
            if (a < b) return -1;
            return 0;
        }
    }
    public class BooleanComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Boolean a = (Boolean) thisItem, b = (Boolean) otherItem;
            return a == b ? 0 : 1;
        }
    }


    public class SObjectFieldComparator implements Collection.Comparator {
        private SObjectField field;
        private Integer direction;
        private Collection.Comparator comparator;

        public SObjectFieldComparator(SObjectField field, Boolean isAscending) {
            this.field = field;
            this.direction = isAscending ? 1 : -1;
            this.comparator = getComparatorByField(field);
            if (comparator == null) {
                this.comparator = comparatorsByFieldType.get(SoapType.STRING);
            }
        }

        public Integer compare(Object thisItem, Object otherItem) {
            Object thisValue = ((SObject) thisItem).get(field);
            Object otherValue = ((SObject) otherItem).get(field);

            return comparator.compare(thisValue, otherValue) * direction;
        }
    }
}