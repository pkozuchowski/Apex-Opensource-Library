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
    private final static Map<SObjectType, Map<String, Object>> MOCKS
        = new Map<SObjectType, Map<String, Object>>();

    protected Object result;
    protected SObjectType sObjType;
    protected String mockId = '';
    protected AccessType accessType = null;


    /**
     * Mocks query results for a specific SObjectType and mock identifier.
     * @param sobjType The SObject type to mock
     * @param mockIdOrClientName Mock identifier or client class name and method
     * @param result The mocked query result to return
     */
    public static void mock(SObjectType sobjType, String mockIdOrClientName, Object result) {
        Map<String, Object> sobjectMocks = QueryResults.MOCKS.get(sobjType) ?? new Map<String, Object>();
        sobjectMocks.put(mockIdOrClientName, result);
        QueryResults.MOCKS.put(sobjType, sobjectMocks);
    }

    /**
     * Mocks query results for generic SObject lists.
     * Iterates over records in a list and adds them to the mock for their respective SObject types.
     */
    public static void mock(String mockIdOrClientName, List<SObject> records) {
        for (SObject record : records) {
            SObjectType sobjType = record.getSObjectType();
            Map<String, Object> sobjectMocks = QueryResults.MOCKS.get(sobjType) ?? new Map<String, Object>();
            List<SObject> existingRecords = (List<SObject>) (
                sobjectMocks.get(mockIdOrClientName)
                    ?? Type.forName('List<' + sobjType + '>').newInstance());
            existingRecords.add(record);

            sobjectMocks.put(mockIdOrClientName, existingRecords);
            QueryResults.MOCKS.put(sobjType, sobjectMocks);
        }
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
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
        Map<String, SObject> resultMap = (Map<String, SObject>)
            Type.forName('Map<String,' + sObjType + '>').newInstance();

        List<SObject> records = getList();
        for (Integer i = 0; i < records.size(); i++) {
            SObject record = records[i];
            String key = '' + record.get(field);
            resultMap.put(key, record);
        }

        return resultMap;
    }

    /** Returns unique set of values for given field. */
    public Set<Object> getValues(String field) {
        return new Set<Object>(getValues(field, new List<Object>()));
    }

    /**
     * @return Ids for SObjects
     */
    public Set<Id> getIds() {
        return getMapById().keySet();
    }

    /** Returns unique set of Ids for given SObjectField. */
    public Set<Id> getIds(SObjectField field) {
        return getIds('' + field);
    }

    /** Returns unique set of Ids for given field name. */
    public Set<Id> getIds(String field) {
        return new Set<Id>((List<Id>) getValues(field, new List<Id>()));
    }

    /** Returns unique set of Strings for given SObjectField. */
    public Set<String> getStrings(SObjectField field) {
        return getStrings('' + field);
    }

    /** Returns unique set of Strings for given field name. */
    public Set<String> getStrings(String field) {
        return new Set<String>((List<String>) getValues(field, new List<String>()));
    }

    /** Returns unique set of Dates for given SObjectField. */
    public Set<Date> getDates(SObjectField field) {
        return getDates('' + field);
    }

    /** Returns unique set of Dates for given field name. */
    public Set<Date> getDates(String field) {
        return new Set<Date>((List<Date>) getValues(field, new List<Date>()));
    }

    /** Returns unique set of Datetimes for given SObjectField. */
    public Set<Datetime> getDatetimes(SObjectField field) {
        return getDatetimes('' + field);
    }

    /** Returns unique set of Datetimes for given field name. */
    public Set<Datetime> getDatetimes(String field) {
        return new Set<Datetime>((List<Datetime>) getValues(field, new List<Datetime>()));
    }

    /** Returns unique set of Integers for given SObjectField. */
    public Set<Integer> getIntegers(SObjectField field) {
        return getIntegers('' + field);
    }

    /** Returns unique set of Integers for given field name. */
    public Set<Integer> getIntegers(String field) {
        return new Set<Integer>((List<Integer>) getValues(field, new List<Integer>()));
    }

    /** Returns unique set of Integers for given SObjectField. */
    public Set<Decimal> getDecimals(SObjectField field) {
        return getDecimals('' + field);
    }

    /** Returns unique set of Decimals for given field name. */
    public Set<Decimal> getDecimals(String field) {
        return new Set<Decimal>((List<Decimal>) getValues(field, new List<Decimal>()));
    }

    protected virtual List<Object> getValues(String field, List<Object> resultSet) {
        List<SObject> records = getList();
        for (Integer i = 0; i < records.size(); i++) {
            SObject record = records[i];
            resultSet.add(record.get(field));
        }
        return resultSet;
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
        if (Test.isRunningTest() && MOCKS.containsKey(this.sObjType)) {
            Map<String, Object> sobjectMocks = MOCKS.get(this.sObjType);

            if (String.isNotBlank(mockId) && sobjectMocks.containsKey(mockId)) {
                return sobjectMocks.get(mockId);

            } else {
                String[] stackTraceLines = new DmlException().getStackTraceString().split('\n');

                for (Integer i = stackTraceLines.size() - 1; i >= 0; i--) {
                    String classAndMethod = stackTraceLines[i].substringBetween('Class.', ':');

                    Object mockResult = sobjectMocks.get(classAndMethod) ??
                        getMockByPattern(sobjectMocks, classAndMethod);

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