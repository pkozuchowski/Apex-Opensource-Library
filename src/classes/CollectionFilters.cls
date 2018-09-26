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
public class CollectionFilters {

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

    /**
     * Filters List of SObject by field value.
     * Operators:
     * <ul>
     *  <li>'==' or Collection.EQUALS</li>
     *  <li>'!=' or Collection.NOT_EQUALS</li>
     *  <li>'>' or Collection.GREATER_THAN</li>
     *  <li>'>=' or Collection.GREATER_EQUAL_THAN</li>
     *  <li>'<' or Collection.LESS_THAN</li>
     *  <li>'<=' or Collection.LESS_EQUAL_THAN</li>
     * </ul>
     *
     * @example
     * <pre>
     *     new Collection(accounts).filter(new CollectionFilter.ByFieldValue(Account.CreatedDate,'>=', Date.today().addDays(-1)));
     *     Collection.filter(accounts, new CollectionFilter.ByFieldValue(Account.CreatedDate,'>=', Date.today().addDays(-1) ));
     * </pre>
     */
    public class ByFieldValue implements Collection.Filter {
        private Object value;
        private String field;
        private String operator;
        private Collection.Comparator comparator;
        private final Set<Integer> acceptedCompareValues;

        public ByFieldValue(SObjectField field, String operator, Object value) {
            this.field = '' + field;
            this.operator = operator;
            this.value = value;
            this.acceptedCompareValues = COMPARATOR_OUTCOMES.get(operator);
            this.comparator = CollectionComparators.getComparatorByField(field);
        }

        public Boolean accepts(Object record) {
            Object fieldValue = ((SObject) record).get(field);
            Integer outcome = comparator.compare(fieldValue, value);

            return acceptedCompareValues.contains(outcome);
        }
    }


    /**
     *Filters SObject collection by SObject prototype.
     * Collection sobject that have the same field values as prototype are accepted.
     *
     * @example
     * <pre>
     *     new ByPrototype(new Opportunity(Name = 'Test Opportunity', StageNem='Analysis'))
     *     would return Opportunities with Name = 'Test Opportunity' and Stage Analysis.
     * </pre>
     */
    public class ByPrototype implements Collection.Filter {
        private Map<String, Object> fieldsValues;

        public ByPrototype(SObject prototype) {
            this.fieldsValues = prototype.getPopulatedFieldsAsMap();
        }

        public Boolean accepts(Object item) {
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
     * Operators:
     * <ul>
     *  <li>'IN' or Collection.VALUE_IN</li>
     *  <li>'NOT IN' or Collection.VALUE_NOT_IN</li>
     * </ul>
     *
     * @example
     * <pre>
     *     new Collection(accounts).filter(new CollectionFilter.ByFieldValues(Account.Name,'IN',new Set<Object>{'Test Account', 'Other Account'}));
     * </pre>
     */
    public class ByFieldValues implements Collection.Filter {
        private Set<Object> values;
        private String field;
        private Boolean valueIn;

        public ByFieldValues(SObjectField field, String operator, Set<Object> values) {
            this('' + field, operator, values);
        }

        public ByFieldValues(String field, String operator, Set<Object> values) {
            this.values = values;
            this.field = field;
            this.valueIn = operator == Collection.VALUE_IN;
        }


        public Boolean accepts(Object record) {
            return valueIn == (values.contains(((SObject) record).get(field)));
        }
    }


    /**
     * Filters SObject list to those related to given parents by given relationship field.
     *
     * @example
     * <pre>
     *     Collection.filter(contacts, new CollectionFilter.RelatedTo(accounts, Contact.AccountId));
     * </pre>
     */
    public class RelatedTo implements Collection.Filter {
        private Map<Id, SObject> parents;
        private SObjectField relationshipField;

        public RelatedTo(List<SObject> parents, SObjectField relationshipField) {
            this(new Map<Id, SObject>(parents), relationshipField);
        }

        public RelatedTo(Map<Id, SObject> parents, SObjectField relationshipField) {
            this.parents = new Map<Id, SObject>(parents);
            this.relationshipField = relationshipField;
        }

        public Boolean accepts(Object record) {
            return parents.containsKey((Id) ((SObject) record).get(relationshipField));
        }
    }


    /**
     * Filters SObjects by distance to given Geolocation.
     */
    public class ByDistance implements Collection.Filter {
        private Location targetLocation;
        private String field;
        private String unit;
        private Double maxDistance;

        /**
         * @param locationField Geolocation field to filter by.
         * @param targetLocation Target geolocation to filter by distance to.
         * @param maxDistance Max. distance from the target location
         * @param unit Distance unit 'km'/'mi'
         */
        public ByDistance(SObjectField locationField, Location targetLocation, Double maxDistance, String unit) {
            this.field = '' + locationField;
            this.targetLocation = targetLocation;
            this.unit = unit;
            this.maxDistance = maxDistance;
        }

        public Boolean accepts(Object record) {
            Location fieldValue = (Location) ((SObject) record).get(field);
            return Location.getDistance(fieldValue, targetLocation, unit) <= maxDistance;
        }
    }


    /**
     * Filter records that changed field value to other value.
     * Developer can specify any value by using Collection.ANY_VALUE, keep in mind though
     * that using "true" or "false" will not work.
     *
     * @example
     * <pre>
     *     new Collection(accounts).filter(new CollectionFilter.FieldChanged(Opportunity.StageName, Collection.ANY_VALUE, 'Closed'));
     * </pre>
     */
    public class FieldChanged implements Collection.UpdateFilter {
        private Object fromValue;
        private Object toValue;
        private SObjectField field;

        public FieldChanged(SObjectField field) {
            this.field = field;
            this.fromValue = this.toValue = Collection.ANY_VALUE;
        }

        public FieldChanged(SObjectField field, Object fromValue, Object toValue) {
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