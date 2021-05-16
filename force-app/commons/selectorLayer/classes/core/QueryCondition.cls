/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2021 Piotr Kożuchowski
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 * /
 * *
 *  Please find newest source code at https://github.com/amorek/Apex-Opensource-Library
 * /
 */

public abstract class QueryCondition {

    /**
     * @return String representation of WHERE condition.
     * Example: 'AccountId IN :recordIds'
     */
    public abstract String toSOQL();

    /**
     * @return Map of variables to bind to WHERE condition
     * Example for 'AccountId IN :recordIds':
     * <pre>
     *     new Map<String,Object>{
     *         'recordIds' => new Map<Id, Account>(accounts).keySet();
     *     }
     * </pre>
     */
    public abstract Map<String, Object> getQueryParameters();


    /**
     * Represents WHERE clause condition expression that can be used in caching mechanism
     */
    public interface Cacheable {
        /**
         * @return True if condition can be used in cache mechanism
         */
        Boolean isCacheable();

        /**
         * @return Key under which Cache saves value-record pairs. Usually it's a field API Name.
         */
        String getCacheKey();

        /**
         * @return Key value udner which SObject instance is cached - usually unique id field value.
         */
        Object getCacheValue();

        /**
         * @param remainder Cache values that did not have cached records.
         * @return Instance of QueryCondition that can retrieve records that were not found in cache.
         */
        QueryCondition getRemainderCondition(List<Object> remainder);
    }



    /**
     * Represents lack of WHERE clause expressions
     */
    public class NullExpr extends QueryCondition {
        public override String toSOQL() { return ''; }
        public override Map<String, Object> getQueryParameters() { return new Map<String, Object>(); }
    }


    /**
     * Generic WHERE expression which may have content and params freely defined.
     */
    public class GenericExpr extends QueryCondition {
        private String whereString;
        private Map<String, Object> params;

        public GenericExpr(String whereString, Map<String, Object> params) {
            this.whereString = whereString;
            this.params = params;
        }

        public override String toSOQL() { return whereString; }
        public override Map<String, Object> getQueryParameters() { return params; }
    }


    /**
     * Composite WHERE clause that concatenates other conditions with AND
     */
    public class ANDExpr extends CompositeExpr {
        public ANDExpr(QueryCondition[] conditions) { super(conditions); }
        protected override String getSeparator() { return ' AND '; }
    }

    public class ORExpr extends CompositeExpr {
        public ORExpr(QueryCondition[] conditions) { super(conditions); }
        protected override String getSeparator() { return ' OR '; }
    }


    private static Integer valueCounter = 0;

    /**
     * Composite WHERE condition for group of conditions joined by boolean AND/OR
     */
    private abstract class CompositeExpr extends QueryCondition {
        protected QueryCondition[] conditions;
        private String soql;
        private Map<String, Object> values;
        private Boolean isCompiled = false;

        protected CompositeExpr(QueryCondition[] conditions) {
            this.conditions = conditions;
            this.values = new Map<String, Object>();
        }

        public override String toSOQL() {
            if (!isCompiled) compile();
            return this.soql;
        }

        public override Map<String, Object> getQueryParameters() {
            if (!isCompiled) compile();
            return this.values;
        }

        public void add(QueryCondition c) { this.conditions.add(c); }
        public QueryCondition get(Integer i) { return this.conditions.get(i); }
        public Integer size() { return this.conditions.size(); }

        private void compile() {
            List<String> wheresStrings = new List<String>();

            for (QueryCondition condition : conditions) {
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
    public class FieldExprFactory {
        private String field;

        public FieldExprFactory(String field) {
            this.field = field;
        }

        public FieldExpr equals(Object value) { return new FieldExpr(field, '=', value); }
        public FieldExpr notEquals(Object value) { return new FieldExpr(field, '!=', value); }
        public FieldExpr greaterThan(Object value) { return new FieldExpr(field, '>', value); }
        public FieldExpr greaterEqualsThan(Object value) { return new FieldExpr(field, '>=', value); }
        public FieldExpr lessThan(Object value) { return new FieldExpr(field, '<', value); }
        public FieldExpr lessEqualsThan(Object value) { return new FieldExpr(field, '<=', value); }
        public FieldExpr isIn(Object values) { return new FieldExpr(field, 'IN', values); }
        public FieldExpr isNotIn(Object values) { return new FieldExpr(field, 'NOT IN', values); }
        public FieldExpr isLike(String value) { return new FieldExpr(field, 'LIKE', value); }
        public FieldExpr includes(String value) { return new FieldExpr(field, 'INCLUDES', value); }
        public FieldExpr excludes(String value) { return new FieldExpr(field, 'EXCLUDES', value); }
    }

    /**
     * WHERE clause for simple field filter
     */
    public class FieldExpr extends QueryCondition implements Cacheable {
        public String field { get; private set; }
        public String operator { get; private set; }
        public Object value { get; private set; }

        public FieldExpr(SObjectField field, String operator, Object value) {
            this('' + field, operator, value);
        }

        public FieldExpr(String field, String operator, Object value) {
            this.field = field;
            this.operator = operator;
            this.value = value;
        }

        public override String toSOQL() {
            return '(' + field + ' ' + operator + ' :value' + ')';
        }

        public override Map<String, Object> getQueryParameters() {
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

        public QueryCondition getRemainderCondition(List<Object> remainder) {
            return new FieldExpr(field, operator, remainder);
        }
    }


    /**
     * Composite WHERE clause which negates inner conditions
     */
    public class NotExpr extends QueryCondition {
        private QueryCondition innerWhere;

        public NotExpr(QueryCondition innerWhere) {
            this.innerWhere = innerWhere;
        }

        public override String toSOQL() {
            return 'NOT (' + innerWhere.toSOQL() + ')';
        }

        public override Map<String, Object> getQueryParameters() {
            return innerWhere.getQueryParameters();
        }
    }
}