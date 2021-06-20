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

/**
 * Created by piotr on 19.06.2021.
 */
public with sharing class QueryConditionFactory {

    /**
    * Composite query condition that joins inner where clauses with AND operator
    */
    public Query.Condition ANDs(Query.Condition w1, Query.Condition w2) {
        return new ANDExpr(new List<Query.Condition>{w1, w2});
    }
    public Query.Condition ANDs(Query.Condition w1, Query.Condition w2, Query.Condition w3) {
        return new ANDExpr(new List<Query.Condition>{w1, w2, w3});
    }
    public Query.Condition ANDs(Query.Condition w1, Query.Condition w2, Query.Condition w3, Query.Condition w4) {
        return new ANDExpr(new List<Query.Condition>{w1, w2, w3, w4});
    }
    public Query.Condition ANDs(Query.Condition w1, Query.Condition w2, Query.Condition w3, Query.Condition w4, Query.Condition w5) {
        return new ANDExpr(new List<Query.Condition>{w1, w2, w3, w4, w5});
    }
    public Query.Condition ANDs(Query.Condition[] conditions) {
        return new ANDExpr(conditions);
    }

    /**
    * Composite query condition that joins inner where clauses with OR operator
    */
    public Query.Condition ORs(Query.Condition w1, Query.Condition w2) {
        return new ORExpr(new List<Query.Condition>{w1, w2});
    }
    public Query.Condition ORs(Query.Condition w1, Query.Condition w2, Query.Condition w3) {
        return new ORExpr(new List<Query.Condition>{w1, w2, w3});
    }
    public Query.Condition ORs(Query.Condition w1, Query.Condition w2, Query.Condition w3, Query.Condition w4) {
        return new ORExpr(new List<Query.Condition>{w1, w2, w3, w4});
    }
    public Query.Condition ORs(Query.Condition w1, Query.Condition w2, Query.Condition w3, Query.Condition w4, Query.Condition w5) {
        return new ORExpr(new List<Query.Condition>{w1, w2, w3, w4, w5});
    }
    public Query.Condition ORs(Query.Condition[] conditions) {
        return new ORExpr(conditions);
    }


    /**
     * Creates field WHERE condition
     */
    public FieldExprFactory field(SObjectField field) {
        return field('' + field);
    }
    public FieldExprFactory field(String field) {
        return new FieldExprFactory(field);
    }
    public Query.Condition field(String field, String operator, Object value) {
        return new FieldExpr(field, operator, value);
    }
    public Query.Condition field(SObjectField field, String operator, Object value) {
        return new FieldExpr(field, operator, value);
    }

    /**
     * Negates passed WHERE clause with NOT keyword
     */
    public Query.Condition NOTs(Query.Condition condition) {
        return new NotExpr(condition);
    }


    /**
     * @return Generic where condition defined by whereString and values to bind
     */
    public Query.Condition wheres(String whereString, Map<String, Object> params) {
        return new GenericExpr(whereString, params);
    }


    /**
     * @return No query condition - used internally.
     */
    public Query.Condition blank() {
        return new NullExpr();
    }


    /**
     * Represents lack of WHERE clause expressions
     */
    private class NullExpr implements Query.Condition {
        public String toSOQL() { return ''; }
        public Map<String, Object> getQueryParameters() { return new Map<String, Object>(); }
    }


    /**
     * Generic WHERE expression which may have content and params freely defined.
     */
    private class GenericExpr implements Query.Condition {
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
    private class ANDExpr extends CompositeExpr {
        public ANDExpr(Query.Condition[] conditions) { super(conditions); }
        protected override String getSeparator() { return ' AND '; }
    }

    private class ORExpr extends CompositeExpr {
        public ORExpr(Query.Condition[] conditions) { super(conditions); }
        protected override String getSeparator() { return ' OR '; }
    }


    private static Integer valueCounter = 0;

    /**
     * Composite WHERE condition for group of conditions joined by boolean AND/OR
     */
    private abstract class CompositeExpr implements Query.Condition {
        protected Query.Condition[] conditions;
        private String soql;
        private Map<String, Object> values;
        private Boolean isCompiled = false;

        protected CompositeExpr(Query.Condition[] conditions) {
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

        public void add(Query.Condition c) { this.conditions.add(c); }
        public Query.Condition get(Integer i) { return this.conditions.get(i); }
        public Integer size() { return this.conditions.size(); }

        private void compile() {
            List<String> wheresStrings = new List<String>();

            for (Query.Condition condition : conditions) {
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

        public Query.Condition equals(Object value) { return new FieldExpr(field, '=', value); }
        public Query.Condition notEquals(Object value) { return new FieldExpr(field, '!=', value); }
        public Query.Condition greaterThan(Object value) { return new FieldExpr(field, '>', value); }
        public Query.Condition greaterEqualsThan(Object value) { return new FieldExpr(field, '>=', value); }
        public Query.Condition lessThan(Object value) { return new FieldExpr(field, '<', value); }
        public Query.Condition lessEqualsThan(Object value) { return new FieldExpr(field, '<=', value); }
        public Query.Condition isIn(Object values) { return new FieldExpr(field, 'IN', values); }
        public Query.Condition isNotIn(Object values) { return new FieldExpr(field, 'NOT IN', values); }
        public Query.Condition isLike(String value) { return new FieldExpr(field, 'LIKE', value); }
        public Query.Condition includes(String value) { return new FieldExpr(field, 'INCLUDES', value); }
        public Query.Condition excludes(String value) { return new FieldExpr(field, 'EXCLUDES', value); }
    }

    /**
     * WHERE clause for simple field filter
     */
    private class FieldExpr implements Query.Condition, Query.CacheableCondition {
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

        public Query.Condition getRemainderCondition(List<Object> remainder) {
            return new FieldExpr(field, operator, remainder);
        }
    }


    /**
     * Composite WHERE clause which negates inner conditions
     */
    private class NotExpr implements Query.Condition {
        private Query.Condition innerWhere;

        public NotExpr(Query.Condition innerWhere) {
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