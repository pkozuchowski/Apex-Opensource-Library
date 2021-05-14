/**
* MIT License
*
* Copyright (c) 2021 Piotr Kożuchowski
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
 * Factory class for Condition implementations.
 */
public abstract inherited sharing class Conditions {
    private final static Comparators.ComparisionOperator
            EQUALS = new Comparators.Equals(),
            NOT_EQUALS = new Comparators.NotEquals(),
            GREATER_THAN = new Comparators.GreaterThan(),
            GREATER_EQUAL_THAN = new Comparators.GreaterEqualsThan(),
            LESS_THAN = new Comparators.LessThan(),
            LESS_EQUAL_THAN = new Comparators.LessEqualsThan();

    /**
     * Creates filter which returns true if all of the filters return true
     */
    public static Condition ANDs(Condition f1, Condition f2) {
        return ANDs(f1, f2, null);
    }
    public static Condition ANDs(Condition f1, Condition f2, Condition f3) {
        return ANDs(f1, f2, f3, null);
    }
    public static Condition ANDs(Condition f1, Condition f2, Condition f3, Condition f4) {
        return ANDs(f1, f2, f3, f4, null);
    }
    public static Condition ANDs(Condition f1, Condition f2, Condition f3, Condition f4, Condition f5) {
        return new ANDCondition(f1, f2, f3, f4, f5);
    }


    /**
     * Creates filter which returns true if any of the filters return true
     */
    public static Condition ORs(Condition f1, Condition f2) {
        return ORs(f1, f2, null);
    }
    public static Condition ORs(Condition f1, Condition f2, Condition f3) {
        return ORs(f1, f2, f3, null);
    }
    public static Condition ORs(Condition f1, Condition f2, Condition f3, Condition f4) {
        return ORs(f1, f2, f3, f4, null);
    }
    public static Condition ORs(Condition f1, Condition f2, Condition f3, Condition f4, Condition f5) {
        return new ORCondition(f1, f2, f3, f4, f5);
    }


    /**
     * Creates filter by field value
     */
    public static FieldValueConditionFactory field(String field) {
        return new FieldValueConditionFactory(field);
    }
    public static FieldValueConditionFactory field(SObjectField field) {
        return new FieldValueConditionFactory('' + field);
    }


    /**
     * Returns true if any of the composite filters return true;
     */
    private class ANDCondition implements Condition {
        private Condition f1, f2, f3, f4, f5;

        public ANDCondition(Condition f1, Condition f2, Condition f3, Condition f4, Condition f5) {
            this.f1 = f1;
            this.f2 = f2;
            this.f3 = f3;
            this.f4 = f4;
            this.f5 = f5;
        }

        public Boolean isTrue(Object item) {
            return f1?.isTrue(item) != false
                    && f2?.isTrue(item) != false
                    && f3?.isTrue(item) != false
                    && f4?.isTrue(item) != false
                    && f5?.isTrue(item) != false;
        }
    }

    /**
     * Returns true if all of the composite filters return true;
     */
    private class ORCondition implements Condition {
        private Condition f1, f2, f3, f4, f5;

        public ORCondition(Condition f1, Condition f2, Condition f3, Condition f4, Condition f5) {
            this.f1 = f1;
            this.f2 = f2;
            this.f3 = f3;
            this.f4 = f4;
            this.f5 = f5;
        }

        public Boolean isTrue(Object item) {
            return f1?.isTrue(item) == true
                    || f2?.isTrue(item) == true
                    || f3?.isTrue(item) == true
                    || f4?.isTrue(item) == true
                    || f5?.isTrue(item) == true;
        }
    }


    /**
     * Creates instance of Field Filter using operator parameter
     */
    public class FieldValueConditionFactory {
        private String field;

        public FieldValueConditionFactory(String field) {
            this.field = field;
        }

        public Condition equals(Object value) { return new FieldValueCondition(field, EQUALS, value); }
        public Condition notEquals(Object value) { return new FieldValueCondition(field, NOT_EQUALS, value); }
        public Condition greaterThan(Object value) { return new FieldValueCondition(field, GREATER_THAN, value); }
        public Condition greaterEqualsThan(Object value) { return new FieldValueCondition(field, GREATER_EQUAL_THAN, value); }
        public Condition lessThan(Object value) { return new FieldValueCondition(field, LESS_THAN, value); }
        public Condition lessEqualsThan(Object value) { return new FieldValueCondition(field, LESS_EQUAL_THAN, value); }
        public Condition isIn(Set<Object> values) { return new FieldValuesCondition(field, true, values); }
        public Condition isIn(List<Object> values) { return new FieldValuesCondition(field, true, values); }
        public Condition isNotIn(Set<Object> values) { return new FieldValuesCondition(field, false, values); }
        public Condition isNotIn(List<Object> values) { return new FieldValuesCondition(field, false, values); }
        public Condition relatedTo(List<SObject> parents) { return new RelationCondition(parents, field); }
        public Condition containing(String value) { return new FilterFieldContaining(field, value); }
    }


    /**
     * Filters List of SObject by field value.
     */
    private class FieldValueCondition implements Condition, QueryCondition {
        private Object value;
        private String field;
        private Comparator comparator;
        private final Comparators.ComparisionOperator expectedResult;

        public FieldValueCondition(String field, Comparators.ComparisionOperator expectedResult, Object value) {
            this.field = field;
            this.value = value;
            this.expectedResult = expectedResult;
            this.comparator = Comparators.getForPrimitive(value);
        }

        public Boolean isTrue(Object record) {
            Object fieldValue = ((SObject) record).get(field);
            Integer outcome = comparator.compare(fieldValue, value);

            return expectedResult.isTrue(outcome);
        }

        public String toSOQL() {
            return '';
        }

        public Map<String, Object> getQueryParameters() {
            return null;
        }
    }

    /**
     * Filters SObject collection by SObject prototype.
     * Collection sobject that have the same field values as prototype are accepted.
     */
    private class SimilarityCondition implements Condition {
        private Map<String, Object> fieldsValues;

        public SimilarityCondition(SObject prototype) {
            this.fieldsValues = prototype.getPopulatedFieldsAsMap();
        }

        public Boolean isTrue(Object item) {
            SObject record = (SObject) item;

            for (String field : fieldsValues.keySet()) {
                if (record.get(field) != fieldsValues.get(field)) {
                    return false;
                }
            }

            return true;
        }
    }

    /**
     * Filters List of SObject by one of many possible field values.
     */
    private class FieldValuesCondition implements Condition {
        private Set<Object> values;
        private String field;
        private Boolean valueIn;

        public FieldValuesCondition(String field, Boolean valueIn, List<Object> values) {
            this(field, valueIn, new Set<Object>(values));
        }

        public FieldValuesCondition(String field, Boolean valueIn, Set<Object> values) {
            this.values = values;
            this.field = field;
            this.valueIn = valueIn;
        }

        public Boolean isTrue(Object record) {
            return valueIn == (values.contains(((SObject) record).get(field)));
        }
    }

    /**
     * Filters SObject list to those related to given parents by given relationship field.
     */
    private class RelationCondition implements Condition {
        private Map<Id, SObject> parents;
        private String relationshipField;

        public RelationCondition(List<SObject> parents, String relationshipField) {
            this.parents = new Map<Id, SObject>(parents);
            this.relationshipField = relationshipField;
        }

        public Boolean isTrue(Object record) {
            return parents.containsKey((Id) ((SObject) record).get(relationshipField));
        }
    }

    /**
     * Filters SObject list to those related to given parents by given relationship field.
     */
    private class FilterFieldContaining implements Condition {
        private String field;
        private String value;

        public FilterFieldContaining(String field, String value) {
            this.field = field;
            this.value = value;
        }

        public Boolean isTrue(Object record) {
            String fieldValue = (String) ((SObject) record).get(field);
            return fieldValue.contains(value);
        }
    }
}