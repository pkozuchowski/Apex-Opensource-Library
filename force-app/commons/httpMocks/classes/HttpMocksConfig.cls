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
 *  Please find newest source code at https://github.com/pkozuchowski/Apex-Opensource-Library
 * /
 */

public with sharing class HttpMocksConfig {
    private static Map<String, HttpCalloutMock__mdt> mocks = HttpCalloutMock__mdt.getAll();
    private static Map<String, String> variables = new Map<String, String>();
    private static Boolean isMocked = false;


    static {
        for (HttpCalloutMockVariable__mdt var : HttpCalloutMockVariable__mdt.getAll().values()) {
            variables.put(var.DeveloperName, var.Pattern__c);
        }
    }

    /**
     * @return Map of Variables - Pattern by DeveloperName
     */
    public static Map<String, String> getVariables() {
        return variables;
    }

    public static List<HttpCalloutMock__mdt> getMocks() {
        return mocks.values();
    }

    public static HttpCalloutMock__mdt getResponse(String developerName) {
        HttpCalloutMock__mdt mock = mocks.get(developerName);

        if (isMocked || mock.Response__c.length() < 255) {
            return mock;

        } else {
            //Salesforce trims long texts to 255
            return [
                SELECT DeveloperName, ApexClass__c, ApexClassNamespace__c,
                    Status__c, StatusCode__c, Response__c,
                    StaticResource__c, Headers__c
                FROM HttpCalloutMock__mdt
                WHERE DeveloperName = :developerName
                WITH USER_MODE
            ];
        }
    }

    @TestVisible static void mock(List<HttpCalloutMock__mdt> mocks) {
        Map<String, HttpCalloutMock__mdt> mocksMap = new Map<String, HttpCalloutMock__mdt>();
        for (HttpCalloutMock__mdt mock : mocks) {
            mocksMap.put(mock.DeveloperName, mock);
        }
        HttpMocksConfig.mocks = mocksMap;
        HttpMocksConfig.isMocked = true;
    }

    @TestVisible static void mockVariables(Map<String, String> variables) {
        HttpMocksConfig.variables.putAll(variables);
    }
}