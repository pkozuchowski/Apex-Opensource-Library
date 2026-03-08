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
*/

/**
 * This class can be used to create complex query conditions.
 * Example:
 * <pre>
 * QueryConditions c = new QueryConditions();
 *
 * Query.Accounts.wheres(
 *     c.ORs(
 *         c.field(Account.Name).equals('John Doe'),
 *         c.field(Account.BillingCity).equals('Warsaw')
 *     ))
 *     .getList();
 * </pre>
 */
@SuppressWarnings('PMD')
public with sharing class QueryConditions {
    private static final String SEPARATOR_OR = ' OR ';
    private static final String SEPARATOR_AND = ' AND ';

    /**
     * Represents SOQL WHERE/HAVING clause condition
     */
    public interface Condition {

        /**
         * @return String representation of WHERE condition.
         * Example: 'AccountId IN :recordIds'
         */
        String toSOQL(QueryBindings bindings);
    }

    /**
     * Represents WHERE clause condition expression that can be used in caching mechanism
     */
    public interface CacheableCondition {
        /**
         * @return True if condition can be used in cache mechanism
         */
        Boolean isCacheable();

        /**
         * @return Key under which Cache saves value-record pairs. Usually it's a field API Name.
         */
        String getCacheKey();

        /**
         * @return Key value under which SObject instance is cached - usually unique id field value.
         */
        Object getCacheValue();

        /**
         * @param remainder Cache values that did not have cached records.
         * @return Instance of Query.Condition that can retrieve records that were not found in cache.
         */
        Condition getRemainderCondition(List<Object> remainder);
    }


    /**
     * Composite condition that joins inner where clauses with logic string, the same as ListViews
     * '{0} AND ({1} OR {2})
     */
    public Condition logic(String logic, Condition[] conditions) {
        return new LogicExpression(logic, conditions);
    }

    /**
    * Composite query condition that joins inner where clauses with AND operator
    */
    public Condition ANDs(Condition w1, Condition w2) {
        return new CompositeExpr(new List<Condition>{w1, w2}, SEPARATOR_AND);
    }
    public Condition ANDs(Condition w1, Condition w2, Condition w3) {
        return new CompositeExpr(new List<Condition>{w1, w2, w3}, SEPARATOR_AND);
    }
    public Condition ANDs(Condition w1, Condition w2, Condition w3, Condition w4) {
        return new CompositeExpr(new List<Condition>{w1, w2, w3, w4}, SEPARATOR_AND);
    }
    public Condition ANDs(Condition w1, Condition w2, Condition w3, Condition w4, Condition w5) {
        return new CompositeExpr(new List<Condition>{w1, w2, w3, w4, w5}, SEPARATOR_AND);
    }
    public Condition ANDs(Condition[] conditions) {
        return new CompositeExpr(conditions, SEPARATOR_AND);
    }

    /**
    * Composite query condition that joins inner where clauses with OR operator
    */
    public Condition ORs(Condition w1, Condition w2) {
        return new CompositeExpr(new List<Condition>{w1, w2}, SEPARATOR_OR);
    }
    public Condition ORs(Condition w1, Condition w2, Condition w3) {
        return new CompositeExpr(new List<Condition>{w1, w2, w3}, SEPARATOR_OR);
    }
    public Condition ORs(Condition w1, Condition w2, Condition w3, Condition w4) {
        return new CompositeExpr(new List<Condition>{w1, w2, w3, w4}, SEPARATOR_OR);
    }
    public Condition ORs(Condition w1, Condition w2, Condition w3, Condition w4, Condition w5) {
        return new CompositeExpr(new List<Condition>{w1, w2, w3, w4, w5}, SEPARATOR_OR);
    }
    public Condition ORs(Condition[] conditions) {
        return new CompositeExpr(conditions, SEPARATOR_OR);
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

    public Condition field(SObjectField field, String operator, Object value) {
        return field('' + field, operator, value);
    }
    public Condition field(String field, String operator, Object value) {
        return new FieldExpr(field, operator, value);
    }


    /**
     * Negates passed WHERE clause with NOT keyword
     */
    public Condition NOTs(Condition condition) {
        return new NotExpr(condition);
    }


    /**
     * @return Generic where condition defined by whereString and values to bind
     */
    public Condition wheres(String whereString, Map<String, Object> params) {
        return new GenericExpr(whereString, params);
    }


    /**
     * @return No query condition - used internally.
     */
    public Condition blank() {
        return new NullExpr();
    }


    /**
     * Represents lack of WHERE clause expressions
     */
    private class NullExpr implements Condition {
        public String toSOQL(QueryBindings bindings) { return ''; }
    }


    /**
     * Generic WHERE expression which may have content and params freely defined.
     */
    private class GenericExpr implements Condition {
        private String whereString;
        private Map<String, Object> params;

        public GenericExpr(String whereString, Map<String, Object> params) {
            this.whereString = whereString;
            this.params = params;
        }

        public String toSOQL(QueryBindings bindings) {
            return bindings.replaceReferences(whereString, params);
        }
    }


    /**
     * Composite WHERE condition for group of conditions joined by boolean AND/OR
     */
    private class CompositeExpr implements Condition {
        private Condition[] conditions;
        private String separator;

        public CompositeExpr(Condition[] conditions, String separator) {
            this.conditions = conditions;
            this.separator = separator;
        }

        public String toSOQL(QueryBindings bindings) {
            List<String> wheresStrings = new List<String>();

            for (Condition condition : conditions) {
                String conditionSOQL = condition.toSOQL(bindings);

                if (!conditionSOQL.startsWith('(')) {
                    conditionSOQL = '(' + conditionSOQL + ')';
                }

                wheresStrings.add(conditionSOQL);
            }

            return '(' + String.join(wheresStrings, separator) + ')';
        }
    }


    /**
     * Provides interface for building field WHERE clause.
     */
    @SuppressWarnings('PMD.OverrideBothEqualsAndHashcode')
    public class FieldExprFactory {
        private String field;

        public FieldExprFactory(String field) {
            this.field = field;
        }

        public Condition equals(Object value) { return new FieldExpr(field, '=', value); }
        public Condition notEquals(Object value) { return new FieldExpr(field, '!=', value); }
        public Condition greaterThan(Object value) { return new FieldExpr(field, '>', value); }
        public Condition greaterEqualsThan(Object value) { return new FieldExpr(field, '>=', value); }
        public Condition lessThan(Object value) { return new FieldExpr(field, '<', value); }
        public Condition lessEqualsThan(Object value) { return new FieldExpr(field, '<=', value); }
        public Condition isIn(Object values) { return new FieldExpr(field, 'IN', values); }
        public Condition isNotIn(Object values) { return new FieldExpr(field, 'NOT IN', values); }
        public Condition isLike(String value) { return new FieldExpr(field, 'LIKE', value); }
        public Condition includes(String value) { return new FieldExpr(field, 'INCLUDES', value); }
        public Condition excludes(String value) { return new FieldExpr(field, 'EXCLUDES', value); }
    }

    /**
     * WHERE clause for simple field filter
     */
    private class FieldExpr implements Condition, CacheableCondition {
        public String field { get; private set; }
        public String operator { get; private set; }
        public Object value { get; private set; }

        public FieldExpr(String field, String operator, Object value) {
            this.field = field;
            this.operator = operator;
            this.value = value;
        }

        public String toSOQL(QueryBindings bindings) {
            String binding = bindings.registerBinding(value);
            return '(' + field + ' ' + operator + ' ' + binding + ')';
        }

        public Boolean isCacheable() {
            return (operator == '=' || operator == 'IN')
                && value != null
                && value != ''
                && (
                value instanceof Id
                || value instanceof String
                || value instanceof Iterable<Id>
                || value instanceof Iterable<String>
            );
        }

        public String getCacheKey() {
            return field;
        }

        public Object getCacheValue() {
            return value;
        }

        public Condition getRemainderCondition(List<Object> remainder) {
            return new FieldExpr(field, operator, remainder);
        }
    }


    /**
     * Composite WHERE clause which negates inner conditions
     */
    private class NotExpr implements Condition {
        private Condition innerWhere;

        public NotExpr(Condition innerWhere) {
            this.innerWhere = innerWhere;
        }

        public String toSOQL(QueryBindings bindings) {
            return 'NOT (' + innerWhere.toSOQL(bindings) + ')';
        }
    }

    /**
     * Composite WHERE clause with custom logic presented as String:
     * '{0} OR ({1} AND {2})
     */
    private class LogicExpression implements Condition {
        private String logic;
        private Condition[] conditions;

        public LogicExpression(String logic, Condition[] conditions) {
            this.logic = logic;
            this.conditions = conditions;
        }

        public String toSOQL(QueryBindings bindings) {
            List<String> conditionClauses = new List<String>();

            for (Condition c : conditions) {
                conditionClauses.add(c.toSOQL(bindings));
            }

            return String.format(logic, conditionClauses);
        }
    }
}