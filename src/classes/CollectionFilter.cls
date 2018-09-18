public class CollectionFilter {

    public final static Map<String, Set<Integer>> COMPARATOR_OUTCOMES = new Map<String, Set<Integer>>{
            Collection.GREATER_THAN => new Set<Integer>{
                    1
            },
            Collection.GREATER_EQUAL_THAN => new Set<Integer>{
                    0, 1
            },
            Collection.LESS_THAN => new Set<Integer>{
                    -1
            },
            Collection.LESS_EQUAL_THAN => new Set<Integer>{
                    0, -1
            },
            Collection.EQUALS => new Set<Integer>{
                    0
            },
            Collection.NOT_EQUALS => new Set<Integer>{
                    1, -1
            }
    };

    public class FilterByFieldValue implements Collection.Filter {
        private Object value;
        private String field;
        private String operator;
        private Collection.Comparator comparator;
        private final Set<Integer> acceptedCompareValues;

        public FilterByFieldValue(SObjectField field, String operator, Object value) {
            this.field = '' + field;
            this.operator = operator;
            this.value = value;
            this.acceptedCompareValues = COMPARATOR_OUTCOMES.get(operator);
            this.comparator = CollectionComparator.getComparatorByField(field);
        }

        public Boolean accepts(Object record) {
            Object fieldValue = ((SObject) record).get(field);
            Integer outcome = comparator.compare(fieldValue, value);

            return acceptedCompareValues.contains(outcome);
        }
    }

    public class FilterByFieldValues implements Collection.Filter {
        private Set<Object> values;
        private String field;
        private Boolean valueIn;

        public FilterByFieldValues(String field, String operator, Set<Object> values) {
            this.values = values;
            this.field = field;
            this.valueIn = operator == Collection.VALUE_IN;
        }

        public FilterByFieldValues(SObjectField field, String operator, Set<Object> values) {
            this.values = values;
            this.field = '' + field;
            this.valueIn = operator == Collection.VALUE_IN;
        }

        public Boolean accepts(Object record) {
            return valueIn == (values.contains(((SObject) record).get(field)));
        }
    }

    public class FilterRelatedTo implements Collection.Filter {
        private Map<Id, SObject> parents;
        private SObjectField relationshipField;

        public FilterRelatedTo(List<SObject> parents, SObjectField relationshipField) {
            this(new Map<Id, SObject>(parents), relationshipField);
        }

        public FilterRelatedTo(Map<Id, SObject> parents, SObjectField relationshipField) {
            this.parents = new Map<Id, SObject>(parents);
            this.relationshipField = relationshipField;
        }

        public Boolean accepts(Object record) {
            return parents.containsKey((Id) ((SObject) record).get(relationshipField));
        }
    }

    public class FilterFieldChanged implements Collection.UpdateFilter {
        private Object fromValue;
        private Object toValue;
        private SObjectField field;

        public FilterFieldChanged(SObjectField field) {
            this.field = field;
            this.fromValue = this.toValue = Collection.ANY_VALUE;
        }

        public FilterFieldChanged(SObjectField field, Object fromValue, Object toValue) {
            this.field = field;
            this.fromValue = fromValue;
            this.toValue = toValue;
        }

        public Boolean accepts(SObject record, SObject old) {
            Object currentValue = record.get(field),
                    oldValue = old.get(field);

            if (fromValue === Collection.ANY_VALUE && toValue === Collection.ANY_VALUE) {
                return currentValue != oldValue;

            } else if (fromValue !== Collection.ANY_VALUE && toValue === Collection.ANY_VALUE) {
                return oldValue == fromValue;

            } else if (fromValue === Collection.ANY_VALUE && toValue !== Collection.ANY_VALUE) {
                return currentValue == toValue;

            } else {
                return oldValue == fromValue && currentValue == toValue;
            }
        }
    }
}