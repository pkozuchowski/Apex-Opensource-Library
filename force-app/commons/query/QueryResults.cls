/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2025 Piotr Kożuchowski
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
 */

/**
 * Mockable wrapper for query results
 */
public virtual class QueryResults {
    private final static Map<SObjectType, Map<String, Object>> mocks = new Map<SObjectType, Map<String, Object>>();

    protected Object result;
    protected SObjectType sObjType;
    protected String mockId = '';
    protected AccessType accessType = null;

    /**
     * @see Query.mock
     */
    public static void mock(SObjectType sobjType, String mockIdOrClientName, Object result) {
        Map<String, Object> sobjectMocks = QueryResults.mocks.get(sobjType) ?? new Map<String, Object>();
        sobjectMocks.put(mockIdOrClientName, result);
        QueryResults.mocks.put(sobjType, sobjectMocks);
    }


    protected QueryResults() {}

    public QueryResults(List<SObject> result) {
        this.result = result;
        this.sObjType = result.getSObjectType();
    }

    /**
     * Enforces Object and Field level security on records.
     * Inaccessible fields are stripped from result and inaccessible objects throws exception.
     *
     * @throws System.NoAccessException No access to entity when user does not have READ permission to sOObject
     */
    public QueryResults stripInaccessible(AccessType accessType) {
        this.accessType = accessType;
        return this;
    }

    /**
     * @return Id of first record or null if list has no results
     */
    public Id getFirstIdOrNull() {
        return getFirstOrNull()?.Id;
    }

    /**
     * Give this query unique name, which can be referenced in Unit Tests to mock results for named query.
     */
    public QueryResults withMockId(String mockId) {
        this.mockId = mockId;
        return this;
    }

    /**
     * @return Field of first record or null if list has no results
     */
    public Object getFirstFieldOrNull(SObjectField field) {
        return getFirstOrNull()?.get(field);
    }

    /**
     * @return Field of first record or fallback value if list has no results
     */
    public Object getFirstFieldOrFallback(SObjectField field, Object fallbackValue) {
        return getFirstOrNull()?.get(field) ?? fallbackValue;
    }


    /**
     * @return First and only record returned by query
     * @throws System.ListException if query did not return results
     */
    public virtual SObject getFirst() {
        return getList().get(0);
    }

    /**
     * @return First record or null if list has no results
     */
    public virtual SObject getFirstOrNull() {
        List<SObject> result = (List<SObject>) executeQuery();
        return result.isEmpty() ? null : result.get(0);
    }

    /**
     * @return Populated Fields from records or AggregatedResults.
     */
    public virtual List<Map<String, Object>> getPopulatedFieldsList() {
        Object result = executeQuery();

        if (result instanceof List<Map<String, Object>>) {
            return (List<Map<String, Object>>) result;
        }

        List<SObject> records = (List<SObject>) result;
        List<Map<String, Object>> aggregateResults = new List<Map<String, Object>>();

        for (Integer i = 0; i < records.size(); i++) {
            aggregateResults.add(records[i].getPopulatedFieldsAsMap());
        }

        return aggregateResults;
    }

    /**
     * @return Mockable wrapper for Schema.AggregateResult
     */
    public virtual List<Query.AggregateResult> getAggregatedResults() {
        Object result = executeQuery();

        if (result instanceof List<Query.AggregateResult>) {
            return (List<Query.AggregateResult>) result;
        }

        List<AggregateResult> records = (List<AggregateResult>) result;
        List<Query.AggregateResult> aggregateResults = new List<Query.AggregateResult>();

        for (Integer i = 0; i < records.size(); i++) {
            aggregateResults.add(new Query.AggregateResult(records[i]));
        }

        return aggregateResults;
    }


    /**
     * @return List of SObjects for given conditions
     */
    public virtual SObject[] getList() {
        return (SObject[]) executeQuery();
    }


    /**
     * @return Ids for SObjects
     */
    public Set<Id> getIds() {
        return getMapById().keySet();
    }

    /**
     * @return SObject map by Ids
     */
    public Map<Id, SObject> getMapById() {
        Map<Id, SObject> resultMap = (Map<Id, SObject>) Type.forName('Map<Id,' + sObjType + '>').newInstance();
        resultMap.putAll(getList());

        return resultMap;
    }

    /**
     * @return SObject map by unique string
     */
    public Map<String, SObject> getMapByString(SObjectField field) {
        return getMapByString('' + field);
    }

    /**
     * @return SObject map by unique string
     */
    public Map<String, SObject> getMapByString(String field) {
        Map<String, SObject> resultMap = (Map<String, SObject>) Type.forName('Map<String,' + sObjType + '>')
            .newInstance();

        List<SObject> records = getList();
        for (Integer i = 0; i < records.size(); i++) {
            SObject record = records[i];
            String key = '' + record.get(field);
            resultMap.put(key, record);
        }

        return resultMap;
    }

    protected virtual Object executeQuery() {
        try {
            this.result = getMock() ?? result ?? getQueryResult();
            stripInaccessible();
            return result;

        } catch (Exception e) {
            QueryException queryException = new QueryException();
            queryException.setMessage(e.getMessage() + '\n' + this.toString());
            throw queryException;
        }
    }

    protected virtual void stripInaccessible() {
        if (accessType != null && (result instanceof List<SObject>)) {
            SObjectAccessDecision decision = Security.stripInaccessible(accessType, (List<SObject>) result);
            result = decision.getRecords();
        }
    }

    protected virtual Object getQueryResult() {
        return result;
    }

    /**
    * @return Mocked query results, if sObject was mocked and class that invoked query is mocked.
    */
    protected Object getMock() {
        if (Test.isRunningTest() && mocks.containsKey(this.sObjType)) {
            Map<String, Object> sobjectMocks = mocks.get(this.sObjType);

            if (String.isNotBlank(mockId) && sobjectMocks.containsKey(mockId)) {
                return sobjectMocks.get(mockId);

            } else {
                Runtime.StackTraceLine[] stackTraceLines = Runtime.getStackTrace();

                for (Integer i = stackTraceLines.size() - 1; i >= 0; i--) {
                    Runtime.StackTraceLine line = stackTraceLines.get(i);

                    Object mockResult = sobjectMocks.get(line.apexClassMethod) ??
                        getMockByPattern(sobjectMocks, line.apexClassMethod);

                    if (mockResult != null) {
                        return mockResult;
                    }
                }
            }
        }

        return null;
    }

    private Object getMockByPattern(Map<String, Object> sobjectMocks, String classAndMethodName) {
        for (String mockKey : sobjectMocks.keySet()) {
            if (Pattern.matches(mockKey, classAndMethodName)) {
                return sobjectMocks.get(mockKey);
            }
        }

        return null;
    }
}