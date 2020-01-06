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
public with sharing class SelectorQuery {
    private static Map<String, SelectorQueryMock> mocks = new Map<String, SelectorQueryMock>();
    protected DatabaseService databaseService = new DatabaseService();

    private String selectorName;
    private Map<String, Object> boundVars;
    private Set<String> fields;
    private String fromObject = '';
    private String orderBy = '';
    private String groupBy = '';
    private String havingConditions = '';
    private String whereConditions = '';
    private String limitQueryPart = '';
    private String offsetQueryPart = '';

    /**
     * Mocks query result for given selector type
     */
    public static void setMock(Type selectorType, SelectorQueryMock mock) {
        if (Test.isRunningTest()) {
            mocks.put('' + selectorType, mock);
        } else {
            throw new QueryException('.setMock() can only be called from test methods');
        }
    }

    public SelectorQuery() {
        this(null);
    }

    public SelectorQuery(Selector selector) {
        this.boundVars = new Map<String, Object>();
        this.fields = new Set<String>{};
        if (selector != null) {
            this.selectorName = ApexService.getRunningTypeName(selector);
        }
    }

    /**
     * Sets sharing mode on Database Service:
     * - With Sharing
     * - Without Sharing
     * - Inherited Sharing (default)
     */
    public SelectorQuery setSharing(Sharing sharing) {
        this.databaseService.setSharing(sharing);
        return this;
    }

    /**
     * Builds and returns SOQL query
     */
    public String toSOQL() {
        String fieldsQueryPart = 'SELECT ' + String.join(new List<String>(fields), ', ');

        String[] query = new String[]{
                fieldsQueryPart,
                fromObject,
                whereConditions,
                groupBy,
                havingConditions,
                orderBy,
                limitQueryPart,
                offsetQueryPart
        };

        return String.join(query, ' ').trim();
    }

    /**
     * Builds and executes dynamic SOQL query
     */
    public SObject[] execute() {
        if (mocks.containsKey(selectorName)) {
            return mockResponse();

        } else {
            return databaseService.query(toSOQL(), boundVars);
        }
    }

    public SelectorQuery bindVariable(String name, Object value) {
        this.boundVars.put(name, value);
        return this;
    }

    public SelectorQuery bindVariables(Map<String, Object> boundVars) {
        this.boundVars.putAll(boundVars);
        return this;
    }

    public SelectorQuery selectField(SObjectField field) {
        this.fields.add('' + field);
        return this;
    }

    public SelectorQuery selectField(String field) {
        this.fields.add(field);
        return this;
    }

    public SelectorQuery selectFields(SObjectField[] fields) {
        for (SObjectField sObjectField : fields) {
            this.fields.add('' + sObjectField);
        }
        return this;
    }

    public SelectorQuery selectFields(String[] fields) {
        this.fields.addAll(fields);
        return this;
    }


    public SelectorQuery addSubquery(SelectorQuery subqueryBuilder) {
        String subQuery = String.join(
                new String[]{
                        '(', subqueryBuilder.toSOQL(), ')'
                }, ' ');

        this.fields.add(subQuery);
        return this;
    }

    public SelectorQuery addChildFields(List<SObjectField> fields, String relationshipField) {
        return addSubquery(new SelectorQuery()
                .selectFields(fields)
                .fromObject(relationshipField)
        );
    }

    public SelectorQuery addParentFields(List<SObjectField> fields, SObjectField relationshipField) {
        String relation = relationshipField.getDescribe().getRelationshipName() + '.';

        for (SObjectField field : fields) {
            selectField(relation + field);
        }

        return this;
    }

    public SelectorQuery fromObject(SObjectType fromObject) {
        return fromObject('' + fromObject);
    }

    public SelectorQuery fromObject(String fromObject) {
        this.fromObject = 'FROM ' + fromObject;
        return this;
    }


    public SelectorQuery setWhere(String condition) {
        this.whereConditions = 'WHERE ' + condition;
        return this;
    }

    public SelectorQuery setGroupBy(String groupBy) {
        this.groupBy = 'GROUP BY ' + groupBy;
        return this;
    }

    public SelectorQuery setHaving(String havingConditionExpression) {
        this.havingConditions = 'HAVING ' + havingConditionExpression;
        return this;
    }

    public SelectorQuery setOrderBy(String orderBy) {
        this.orderBy = 'ORDER BY ' + orderBy;
        return this;
    }

    public SelectorQuery setLimit(Integer limitOf) {
        this.limitQueryPart = 'LIMIT ' + limitOf;
        return this;
    }

    public SelectorQuery setOffset(Integer offsetOf) {
        this.offsetQueryPart = 'OFFSET ' + offsetOf;
        return this;
    }

    private SObject[] mockResponse() {
        String selectorMethod, caller, callerMethod;

        for (ApexService.StackTraceLine line : ApexService.getStackTrace()) {
            if (line.apexClass == selectorName || line.apexClass == Selector.class.getName()) {
                selectorMethod = line.method;

            } else if (String.isNotBlank(selectorMethod)) {
                caller = line.apexClass;
                callerMethod = line.method;
            }
        }

        SelectorQueryMock mock = mocks.get(selectorName);
        return mock.handleQuery(caller, callerMethod, selectorName, selectorMethod, boundVars, databaseService.query(toSOQL(), boundVars));
    }
}