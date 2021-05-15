/**
* MIT License
*
* Copyright (c) 2020 Piotr Kożuchowski
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
 * Encapsulation for SOQL condition - field, operator and value
 * ex. Account.Name IN (values)
 */
public with sharing class QueryWheres {
    private static Integer valueCounter = 0;

    /**
     * Represents lack of WHERE clause expressions
     */
    public class NullExpr implements QueryObject.ConditionExpr {
        public String toSOQL() { return ''; }
        public Map<String, Object> getQueryParameters() { return new Map<String, Object>(); }
    }


    /**
     * Generic WHERE expression which may have content and params freely defined.
     */
    public class GenericExpr implements QueryObject.ConditionExpr {
        private String whereString;
        private Map<String, Object> params;

        public GenericExpr(String whereString, Map<String, Object> params) {
            this.whereString = whereString;
            this.params = params;
        }

        public String toSOQL() { return whereString; }
        public Map<String, Object> getQueryParameters() { return params; }
    }


    /**
     * Composite WHERE clause that concatenates other conditions with AND
     */
    public class ANDWhere extends CompositeWhere {
        public ANDWhere(QueryObject.Condition[] conditions) { super(conditions); }
        protected override String getSeparator() { return ' AND '; }
    }

    public class ORWhere extends CompositeWhere {
        public ORWhere(QueryObject.Condition[] conditions) { super(conditions); }
        protected override String getSeparator() { return ' AND '; }
    }

    /**
     * Composite WHERE condition for group of conditions joined by boolean AND/OR
     */
    private abstract class CompositeWhere implements QueryObject.Condition {
        protected QueryObject.Condition[] conditions;
        private String soql;
        private Map<String, Object> values;
        private Boolean isCompiled = false;

        protected CompositeWhere(QueryObject.Condition[] conditions) {
            this.conditions = conditions;
            this.values = new Map<String, Object>();
        }

        public String toSOQL() {
            if (!isCompiled) compile();
            return this.soql;
        }

        public Map<String, Object> getQueryParameters() {
            if (!isCompiled) compile();
            return this.values;
        }

        public void add(QueryObject.Condition c) { this.conditions.add(c); }
        public Integer size() { return this.conditions.size(); }

        private void compile() {
            List<String> wheresStrings = new List<String>();

            for (QueryObject.Condition condition : conditions) {
                String conditionString = condition.toSOQL();
                Map<String, Object> conditionValues = condition.getQueryParameters();

                for (String varName : conditionValues.keySet()) {
                    Object varValue = conditionValues.get(varName);

                    Integer varUniqueId = valueCounter++;
                    String newVarName = varName + varUniqueId;

                    conditionString = conditionString.replaceAll(':' + varName, ':' + newVarName);
                    values.put(newVarName, varValue);
                }

                wheresStrings.add(conditionString);
            }

            this.soql = '(' + String.join(wheresStrings, getSeparator()) + ')';
            this.isCompiled = true;
        }

        protected abstract String getSeparator();
    }


    /**
     * Provides interface for building field WHERE clause.
     */
    public class FieldWhereFactory {
        private String field;

        public FieldWhereFactory(String field) {
            this.field = field;
        }

        public FieldWhere equals(Object value) { return new FieldWhere(field, '=', value); }
        public FieldWhere notEquals(Object value) { return new FieldWhere(field, '!=', value); }
        public FieldWhere greaterThan(Object value) { return new FieldWhere(field, '>', value); }
        public FieldWhere greaterEqualsThan(Object value) { return new FieldWhere(field, '>=', value); }
        public FieldWhere lessThan(Object value) { return new FieldWhere(field, '<', value); }
        public FieldWhere lessEqualsThan(Object value) { return new FieldWhere(field, '<=', value); }
        public FieldWhere isIn(Set<Object> values) { return new FieldWhere(field, 'IN', values); }
        public FieldWhere isIn(List<Object> values) { return new FieldWhere(field, 'IN', values); }
        public FieldWhere isNotIn(Set<Object> values) { return new FieldWhere(field, 'NOT IN', values); }
        public FieldWhere isNotIn(List<Object> values) { return new FieldWhere(field, 'NOT IN', values); }
        public FieldWhere isLike(String value) { return new FieldWhere(field, 'LIKE', value); }
        public FieldWhere includes(String value) { return new FieldWhere(field, 'INCLUDES', value); }
        public FieldWhere excludes(String value) { return new FieldWhere(field, 'EXCLUDES', value); }
    }

    /**
     * WHERE clause for simple field filter
     */
    public class FieldWhere implements QueryObject.CacheableCondition {
        public String field { get; private set; }
        public String operator { get; private set; }
        public Object value { get; private set; }

        public FieldWhere(SObjectField field, String operator, Object value) {
            this('' + field, operator, value);
        }

        public FieldWhere(String field, String operator, Object value) {
            this.field = field;
            this.operator = operator;
            this.value = value;
        }

        public String toSOQL() {
            return '(' + field + ' ' + operator + ' :value' + ')';
        }

        public Map<String, Object> getQueryParameters() {
            return new Map<String, Object>{
                'value' => value
            };
        }

        public Boolean isCacheable() {
            return (operator == '=' || operator == 'IN')
                && value != null
                && value != '';
        }

        public String getCacheKey() {
            return field;
        }

        public Object getCacheValue() {
            return value;
        }
    }


    /**
     * Composite WHERE clause which negates inner conditions
     */
    public class NotWhere implements QueryObject.Condition {
        private QueryObject.Condition innerWhere;

        public NotWhere(QueryObject.Condition innerWhere) {
            this.innerWhere = innerWhere;
        }

        public String toSOQL() {
            return 'NOT (' + innerWhere.toSOQL() + ')';
        }

        public Map<String, Object> getQueryParameters() {
            return innerWhere.getQueryParameters();
        }
    }
}