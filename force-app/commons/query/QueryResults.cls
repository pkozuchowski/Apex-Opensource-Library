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

    protected List<SObject> result;
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
        List<SObject> result = executeQuery();
        return result.isEmpty() ? null : result.get(0);
    }


    /**
     * @return List of SObjects for given conditions
     */
    public virtual SObject[] getList() {
        return executeQuery();
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

        for (SObject record : getList()) {
            String key = '' + record.get(field);
            resultMap.put(key, record);
        }

        return resultMap;
    }

    protected virtual SObject[] executeQuery() {
        this.result = (SObject[]) getMock() ?? result;

        if (accessType != null) {
            SObjectAccessDecision decision = Security.stripInaccessible(accessType, result);
            this.result = decision.getRecords();
        }

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