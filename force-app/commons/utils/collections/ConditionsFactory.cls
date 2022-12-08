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
public inherited sharing class ConditionsFactory {

    /**
     * Creates filter which returns true if all of the filters return true
     */
    public Condition ANDs(Condition f1, Condition f2) {
        return ANDs(new List<Condition>{f1, f2});
    }
    public Condition ANDs(Condition f1, Condition f2, Condition f3) {
        return ANDs(new List<Condition>{f1, f2, f3});
    }
    public Condition ANDs(Condition f1, Condition f2, Condition f3, Condition f4) {
        return ANDs(new List<Condition>{f1, f2, f3, f4});
    }
    public Condition ANDs(Condition f1, Condition f2, Condition f3, Condition f4, Condition f5) {
        return ANDs(new List<Condition>{f1, f2, f3, f4, f5});
    }
    public Condition ANDs(Condition[] conditions) {
        return new ANDCondition(conditions);
    }

    /**
     * Creates filter which returns true if any of the filters return true
     */
    public Condition ORs(Condition f1, Condition f2) {
        return ORs(new List<Condition>{f1, f2});
    }
    public Condition ORs(Condition f1, Condition f2, Condition f3) {
        return ORs(new List<Condition>{f1, f2, f3});
    }
    public Condition ORs(Condition f1, Condition f2, Condition f3, Condition f4) {
        return ORs(new List<Condition>{f1, f2, f3, f4});
    }
    public Condition ORs(Condition f1, Condition f2, Condition f3, Condition f4, Condition f5) {
        return ORs(new List<Condition>{f1, f2, f3, f4, f5});
    }
    public Condition ORs(Condition[] conditions) {
        return new ORCondition(conditions);
    }


    /**
     * Creates filter by field value
     */
    public FieldValueConditionFactory field(String field) {
        return new FieldValueConditionFactory(field);
    }
    public FieldValueConditionFactory field(SObjectField field) {
        return new FieldValueConditionFactory('' + field);
    }


    /**
     * @return Condition returns true if item has the same field values set as prototype.
     * ex.
     * <pre>
     * Conditions.alike(new Account(
     *     RecordTypeId = Constant.RecordTypeId_Account_PersonAccount,
     *     BillingCity = 'London'
     * ))
     * </pre>
     *
     * Above would be true for all accounts that have these 2 fields set with same values.
     */
    public Condition alike(SObject prototype) {
        return new SimilarityCondition(prototype);
    }


    /**
     * Composite Condition used for creating nested AND and ORs conditions
     */
    private abstract class CompositeCondition implements Condition {
        protected Condition[] conditions;

        public CompositeCondition(Condition[] conditions) {
            this.conditions = conditions;
        }
    }

    /**
     * Returns true if any of the composite filters return true;
     */
    private class ANDCondition extends CompositeCondition {

        public ANDCondition(Condition[] conditions) {
            super(conditions);
        }

        public Boolean isTrue(Object item) {
            for (Integer i = 0, j = conditions.size(); i < j; ++i) {
                if (!conditions[i].isTrue(item)) return false;
            }

            return true;
        }
    }

    /**
     * Returns true if all of the composite filters return true;
     */
    private class ORCondition extends CompositeCondition {

        public ORCondition(Condition[] conditions) {
            super(conditions);
        }

        public Boolean isTrue(Object item) {
            for (Integer i = 0, j = conditions.size(); i < j; ++i) {
                if (conditions[i].isTrue(item)) return true;
            }

            return false;
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

        public Condition equals(Object value) { return new FieldValueCondition(field, new IntegerEquals(), value); }
        public Condition notEquals(Object value) { return new FieldValueCondition(field, new IntegerNotEquals(), value); }
        public Condition greaterThan(Object value) { return new FieldValueCondition(field, new IntegerGreaterThan(), value); }
        public Condition greaterEqualsThan(Object value) { return new FieldValueCondition(field, new IntegerGreaterEqualsThan(), value); }
        public Condition lessThan(Object value) { return new FieldValueCondition(field, new IntegerLessThan(), value); }
        public Condition lessEqualsThan(Object value) { return new FieldValueCondition(field, new IntegerLessEqualsThan(), value); }
        public Condition isIn(Set<Object> values) { return new FieldValuesCondition(field, true, values); }
        public Condition isIn(List<Object> values) { return new FieldValuesCondition(field, true, values); }
        public Condition isNotIn(Set<Object> values) { return new FieldValuesCondition(field, false, values); }
        public Condition isNotIn(List<Object> values) { return new FieldValuesCondition(field, false, values); }
        public Condition relatedTo(List<SObject> parents) { return new RelationCondition(parents, field); }
        public Condition contains(String value) { return new FilterFieldContaining(field, value); }
    }


    /**
     * Filters List of SObject by field value.
     */
    private class FieldValueCondition implements Condition {
        private Object value;
        private String field;
        private Comparator comparator;
        private final Condition expectedResult;

        public FieldValueCondition(String field, Condition expectedResult, Object value) {
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


    private class IntegerEquals implements Condition {
        public Boolean isTrue(Object i) { return i == 0; }
    }
    private class IntegerNotEquals implements Condition {
        public Boolean isTrue(Object i) { return i != 0; }
    }
    private class IntegerGreaterThan implements Condition {
        public Boolean isTrue(Object i) { return (Integer) i > 0; }
    }
    private class IntegerGreaterEqualsThan implements Condition {
        public Boolean isTrue(Object i) { return (Integer) i >= 0; }
    }
    private class IntegerLessThan implements Condition {
        public Boolean isTrue(Object i) { return (Integer) i < 0; }
    }
    private class IntegerLessEqualsThan implements Condition {
        public Boolean isTrue(Object i) { return (Integer) i <= 0; }
    }
}