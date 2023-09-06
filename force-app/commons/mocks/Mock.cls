/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2023 Piotr Kożuchowski
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
 * Simple utility class for mocking response of the methods with as few lines as possible.
 * @example
 * AccountService accountService = new AccountService();
 *     accountService.accountSelector = (AccountSelector) Mock.response( AccountSelector.class,
 *      'getById', new Account(Name = 'Test Name')
 *     );
 */
@IsTest
public with sharing class Mock {

    /**
     * @returns Mock that will return predefined response when any of it's methods is called.
     * If outcome is an exception, it will be thrown.
     */
    public static Object response(Type apexType, Object outcome) {
        return response(apexType, '*', outcome);
    }

    /**
     * @returns Mock that will return predefined response when method is called.
     * If outcome is an exception, it will be thrown.
     */
    public static Object response(Type apexType, String method, Object outcome) {
        return response(apexType, new Map<String, Object>{
            method => outcome
        });
    }

    /**
     * @returns Mock that will return predefined response for methods defined in map.
     * If outcome is an exception, it will be thrown.
     */
    public static Object response(Type apexType, Map<String, Object> methodToOutcome) {
        return Test.createStub(apexType, new SimpleMock(methodToOutcome));
    }


    private class SimpleMock implements StubProvider {
        private Map<String, Object> returnMap = new Map<String, Object>();
        private Map<String, Integer> calledMethods = new Map<String, Integer>();

        private SimpleMock(Map<String, Object> returnMap){
            this.returnMap = returnMap;
        }

        public Object handleMethodCall(Object stubbedObject,
            String stubbedMethodName,
            System.Type returnType,
            List<System.Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {

            Object returnValue = getReturnValue(stubbedMethodName);

            if (returnValue instanceof Exception) {
                Exception ex = (Exception) returnValue;
                throw ex;

            } else {
                return returnValue;
            }
        }

        private Object getReturnValue(String stubbedMethodName) {
            if (returnMap.containsKey('*')) {
                return returnMap.get('*');

            } else {
                Integer count = calledMethods.get(stubbedMethodName);
                count = count == null ? 1 : count;
                calledMethods.put(stubbedMethodName, count + 1);
                String methodNameWithCounter = stubbedMethodName + '#' + count;

                return returnMap.containsKey(methodNameWithCounter) ?
                    returnMap.get(methodNameWithCounter)
                    : returnMap.get(stubbedMethodName);
            }
        }
    }
}