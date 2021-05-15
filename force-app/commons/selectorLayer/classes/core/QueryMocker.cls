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
* This class is responsible for mocking Query response
*/
public with sharing class QueryMocker {
    private final static QueryMocker instance = new QueryMocker();
    private final Map<Type, QueryMock> mocksByQueryClass = new Map<Type, QueryMock>();

    public static QueryMocker getInstance() {
        return instance;
    }

    private QueryMocker() {
    }


    /**
     * Mocks selector method with given results
     */
    public QueryMock getMock(Type queryClass) {
        return this.mocksByQueryClass.get(queryClass);
    }

    /**
     * Mocks selector method with given results
     */
    public void setMock(Type queryClass, SObject[] mockRecords) {
        this.mocksByQueryClass.put(queryClass, new SimpleQueryMock(mockRecords));
    }

    /**
     * Mocks query result for given selector type
     */
    public void setMock(Type queryClass, QueryMock mock) {
        if (Test.isRunningTest()) {
            getInstance().mocksByQueryClass.put(queryClass, mock);

        } else {
            throw new QueryException('Query mock can be only set in test methods');
        }
    }


    /**
     * Removes mocks set on given SObjectType
     */
    public void removeMock(Type queryClass) {
        mocksByQueryClass.remove(queryClass);
    }


    /**
    * @return True, if given sObjectType should be mocked
    */
    public Boolean isMocked(Type queryClass) {
        return mocksByQueryClass.containsKey(queryClass);
    }


    /**
     * Mocks selector's method with given result.
     */
    private class SimpleQueryMock implements QueryMock {
        private SObject[] mockRecords;

        private SimpleQueryMock(SObject[] mockRecords) {
            this.mockRecords = mockRecords;
        }

        public SObject[] handleQuery(Type queryObject, QueryObject.Condition[] criteria, SObject[] queryResult) {
            return mockRecords;
        }
    }
}