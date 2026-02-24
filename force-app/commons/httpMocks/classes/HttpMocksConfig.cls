/**
* SPDX-License-Identifier: MIT
* Copyright 2023 Piotr Kożuchowski
* apexlibra.org
*/

/**
 * Configuration class for managing HTTP callout mocks defined in custom metadata.
 * Provides access to HttpCalloutMock__mdt records for testing HTTP integrations.
 */
public with sharing class HttpMocksConfig {
    private static Map<String, HttpCalloutMock__mdt> mocks = HttpCalloutMock__mdt.getAll();
    private static Boolean isMocked = false;

    /**
     * Returns all configured HTTP callout mock metadata records.
     * @return List of all HttpCalloutMock__mdt records
     */
    public static List<HttpCalloutMock__mdt> getMocks() {
        return mocks.values();
    }

    /**
     * Retrieves a specific HTTP callout mock by developer name.
     * If the Response__c field exceeds 255 characters, queries the full record to avoid Salesforce's text truncation.
     * @param developerName The developer name of the HttpCalloutMock__mdt record
     * @return The HttpCalloutMock__mdt record with complete response data
     */
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

    /**
     * Mocks custom metadata records in tests.
     */
    @TestVisible static void mock(List<HttpCalloutMock__mdt> mocks) {
        Map<String, HttpCalloutMock__mdt> mocksMap = new Map<String, HttpCalloutMock__mdt>();
        for (HttpCalloutMock__mdt mock : mocks) {
            mocksMap.put(mock.DeveloperName, mock);
        }
        HttpMocksConfig.mocks = mocksMap;
        HttpMocksConfig.isMocked = true;
    }
}