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
    private final Map<SObjectType, QueryMock> mocks = new Map<SObjectType, QueryMock>();

    public static QueryMocker getInstance(){
        return instance;
    }

    private QueryMocker(){
    }

    /**
     * Mocks query result for given selector type
     */
    public static void setMock(SObjectType sObjectType, QueryMock mock) {
        if (Test.isRunningTest()) {
            mocks.put(sObjectType, mock);

        } else {
            throw new QueryException('.setMock() can only be called from test methods');
        }
    }


    /**
    * @return True, if given sObjectType should be mocked
    */
    public Boolean isMocked(SObjectType sObjectType) {
        return mocks.containsKey(sObjectType);
    }


    /**
    * This method checks context of execution (which class called selector, in which method,
    * what method on which selector etc.) and mocks the response.
    */
    public SObject[] mockResponse(QueryObject queryObject, SObjectType sObjectType, Map<String, Object> queryVariables, SObject[] result) {
        String selectorName = Runtime.getTypeName(queryObject);
        String selectorMethod, caller, callerMethod;

        for (Runtime.StackTraceLine line : Runtime.getStackTrace()) {
            if (line.apexClass == selectorName || line.apexClass == QueryObject.class.getName()) {
                selectorMethod = line.method;

            } else if (String.isNotBlank(selectorMethod)) {
                caller = line.apexClass;
                callerMethod = line.method;
            }
        }

        QueryMock mock = mocks.get(sObjectType);
        return mock.handleQuery(
                caller,
                callerMethod,
                selectorName,
                selectorMethod,
                queryVariables,
                result
        );
    }
}