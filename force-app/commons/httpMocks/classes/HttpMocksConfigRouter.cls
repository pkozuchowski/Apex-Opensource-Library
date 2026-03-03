/**
* SPDX-License-Identifier: MIT
* Copyright 2023 Piotr Kożuchowski
* apexlibra.org
*/

/**
 * Configuration class for managing HTTP callout mocks defined in custom metadata.
 * Provides access to HttpCalloutMock__mdt records for testing HTTP integrations.
 */
public with sharing class HttpMocksConfigRouter extends HttpCalloutMockRouter {
    private static Map<String, HttpCalloutMock__mdt> mocks = HttpCalloutMock__mdt.getAll();

    /**
     * @return Loads Mocks from custom metadata
     */
    public HttpMocksConfigRouter() {
        for (HttpCalloutMock__mdt mockMdt : mocks.values()) {
            if (mockMdt.Default__c) {
                mock(
                    mockMdt.DeveloperName,
                    mockMdt.Methods__c,
                    mockMdt.Endpoint__c,
                    HttpMocks.config(mockMdt)
                );
            }
        }
    }

    public static HttpCalloutMock__mdt getMock(String name) {
        return mocks.get(name);
    }

    /**
     * Mocks custom metadata records in tests.
     */
    @TestVisible static void mock(List<HttpCalloutMock__mdt> mocks) {
        Map<String, HttpCalloutMock__mdt> mocksMap = new Map<String, HttpCalloutMock__mdt>();
        for (HttpCalloutMock__mdt mock : mocks) {
            mocksMap.put(mock.DeveloperName, mock);
        }
        HttpMocksConfigRouter.mocks = mocksMap;
    }
}