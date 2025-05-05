/**
* MIT License
*
* Copyright (c) 2019 Piotr Kożuchowski
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
 * Very simple query builder used in Selector layer
 */
public inherited sharing class QueryBuilder {
    private Set<String> fields = new Set<String>();
    private Set<String> subqueries = new Set<String>();
    private String fromObject = '';
    private List<String> orderBy = new List<String>();
    private String groupBy = '';
    private String havingConditions = '';
    private String whereConditions = '';
    private String limitQueryPart = '';
    private String offsetQueryPart = '';
    private String forPart = '';


    /**
     * Builds and returns SOQL query
     */
    public String toSOQL() {
        List<String> fieldsList = new List<String>(fields);
        if (!subqueries.isEmpty()) {
            fieldsList.add(String.join(subqueries, ', '));
        }

        String fields = String.join(fieldsList, ', ');

        if (String.isBlank(fields)) {
            fields = 'Id';
        }

        return 'SELECT '
            + fields
            + ' ' + fromObject
            + (String.isBlank(whereConditions) ? '' : ' ' + whereConditions)
            + (String.isBlank(groupBy) ? '' : ' ' + groupBy)
            + (String.isBlank(havingConditions) ? '' : ' ' + havingConditions)
            + (String.isBlank(limitQueryPart) ? '' : ' ' + limitQueryPart)
            + (String.isBlank(offsetQueryPart) ? '' : ' ' + offsetQueryPart)
            + (orderBy.isEmpty() ? '' : ' ORDER BY ' + String.join(orderBy, ', '))
            + (String.isBlank(forPart) ? '' : ' ' + forPart);
    }

    public QueryBuilder addField(SObjectField field) {
        this.fields.add('' + field);
        return this;
    }

    public QueryBuilder addField(String field) {
        this.fields.add(field);
        return this;
    }

    public QueryBuilder addFields(SObjectField[] fields) {
        for (SObjectField sObjectField : fields) {
            this.fields.add('' + sObjectField);
        }
        return this;
    }

    public QueryBuilder addFields(Iterable<String> fields) {
        if (fields instanceof List<String>) {
            this.fields.addAll((List<String>) fields);

        } else if (fields instanceof Set<String>) {
            this.fields.addAll((Set<String>) fields);
        }
        return this;
    }

    public QueryBuilder addFields(String relationshipName, Iterable<Object> parentFields) {
        for (Object parentField : parentFields) {
            this.fields.add(relationshipName + '.' + parentField);
        }
        return this;
    }

    public QueryBuilder setFields(Set<String> fields) {
        this.fields = fields;
        return this;
    }

    public QueryBuilder removeFields(List<String> fields) {
        this.fields.removeAll(fields);
        return this;
    }

    public QueryBuilder addSubquery(QueryBuilder subqueryBuilder) {
        String subQuery = String.join(
            new String[]{
                '(', subqueryBuilder.toSOQL(), ')'
            }, ' ');

        this.subqueries.add(subQuery);
        return this;
    }

    public QueryBuilder addSubquery(String subquery) {
        String soql = subquery;

        if (!subquery.startsWith('(')) {
            soql = '(' + subquery + ')';
        }

        this.subqueries.add(soql);
        return this;
    }

    public QueryBuilder addSubquery(List<String> fields, String relationshipField) {
        return addSubquery(new QueryBuilder()
            .addFields(fields)
            .fromObject(relationshipField)
        );
    }

    public QueryBuilder addSubquery(List<SObjectField> fields, String relationshipField) {
        return addSubquery(new QueryBuilder()
            .addFields(fields)
            .fromObject(relationshipField)
        );
    }

    public QueryBuilder fromObject(SObjectType fromObject) {
        return fromObject('' + fromObject);
    }

    public QueryBuilder fromObject(String fromObject) {
        this.fromObject = 'FROM ' + fromObject;
        return this;
    }


    public QueryBuilder setWhere(String condition) {
        if (String.isNotEmpty(condition)) {
            this.whereConditions = 'WHERE ' + condition;
        }
        return this;
    }

    public QueryBuilder setGroupBy(String groupBy) {
        this.groupBy = 'GROUP BY ' + groupBy;
        return this;
    }

    public QueryBuilder setHaving(String havingConditionExpression) {
        if (String.isNotEmpty(havingConditionExpression)) {
            this.havingConditions = 'HAVING ' + havingConditionExpression;
        }
        return this;
    }

    public QueryBuilder orderBy(String orderBy) {
        this.orderBy.add(orderBy);
        return this;
    }

    public QueryBuilder setLimit(Integer limitOf) {
        this.limitQueryPart = 'LIMIT ' + limitOf;
        return this;
    }

    public QueryBuilder setOffset(Integer offsetOf) {
        this.offsetQueryPart = 'OFFSET ' + offsetOf;
        return this;
    }

    public QueryBuilder setFor(String forPart) {
        this.forPart = forPart;
        return this;
    }
}