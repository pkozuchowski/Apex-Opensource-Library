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
     * Composite WHERE condition for boolean
     */
    private abstract class CompositeWhere implements QueryWhere {
        protected QueryWhere[] conditions;
        private String soql;
        private Map<String, Object> values;
        private Boolean isCompiled = false;

        protected CompositeWhere(QueryWhere[] conditions) {
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

        public void add(QueryWhere c) { this.conditions.add(c); }
        public Integer size() { return this.conditions.size(); }

        private void compile() {
            List<String> wheresStrings = new List<String>();

            for (QueryWhere condition : conditions) {
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
     * Composite WHERE clause that concatenates other conditions with AND
     */
    public class ANDWhere extends CompositeWhere {
        public ANDWhere(QueryWhere[] conditions) { super(conditions); }
        protected override String getSeparator() { return ' AND '; }
    }

    public class ORWhere extends CompositeWhere {
        public ORWhere(QueryWhere[] conditions) { super(conditions); }
        protected override String getSeparator() { return ' AND '; }
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
    public class FieldWhere implements QueryWhere {
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
    }


    /**
     * Composite WHERE clause which negates inner conditions
     */
    public class NotWhere implements QueryWhere {
        private QueryWhere innerWhere;

        public NotWhere(QueryWhere innerWhere) {
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