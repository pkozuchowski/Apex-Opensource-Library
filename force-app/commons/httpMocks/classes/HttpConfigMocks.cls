/**
* SPDX-License-Identifier: MIT
* Copyright 2023 Piotr Kożuchowski
* apexlibra.org
*/

/**
 * Configuration class for managing HTTP callout mocks defined in custom metadata.
 * Provides access to HttpCalloutMock__mdt records for testing HTTP integrations.
 */
public with sharing class HttpConfigMocks {
    private static Map<String, HttpCalloutMock__mdt> mocks = HttpCalloutMock__mdt.getAll();

    /**
         * Mocks custom metadata records in tests.
         */
    @TestVisible static void mock(List<HttpCalloutMock__mdt> mocks) {
        Map<String, HttpCalloutMock__mdt> mocksMap = new Map<String, HttpCalloutMock__mdt>();
        for (HttpCalloutMock__mdt mock : mocks) {
            mocksMap.put(mock.DeveloperName, mock);
        }
        HttpConfigMocks.mocks = mocksMap;
    }


    /**
     * @return Loads Mocks from custom metadata
     */
    public class ConfigRouter extends HttpCalloutMockRouter {
        public ConfigRouter() {
            for (HttpCalloutMock__mdt mockMdt : mocks.values()) {
                if (mockMdt.Default__c) {
                    mock(
                        mockMdt.DeveloperName,
                        mockMdt.Methods__c,
                        mockMdt.Endpoint__c,
                        new ConfigMock(mockMdt)
                    );
                }
            }
        }
    }

    /**
    * Mock implementation that uses HttpCalloutMock__mdt custom metadata to configure HTTP responses.
    * Supports multiple response types: direct body content, static resources, or custom Apex class implementations.
    */
    public virtual class ConfigMock extends HttpCalloutMockRouter.HttpMockEndpointMatcher {
        private HttpCalloutMock__mdt config;

        /**
         * Constructs a ConfigMock with the specified custom metadata configuration.
         */
        public ConfigMock(String customMetadataName) {
            this(mocks.get(customMetadataName));
        }

        /**
         * Constructs a ConfigMock with the specified custom metadata configuration.
         * @param config The HttpCalloutMock__mdt record containing the mock response configuration
         */
        public ConfigMock(HttpCalloutMock__mdt config) {
            super(config.Methods__c, config.Endpoint__c, config.MatchingHeader__c, null);
            this.config = config;
        }

        /**
         * Generates an HTTP response based on the configuration defined in HttpCalloutMock__mdt.
         * The response can be sourced from plain body, static resource or apex class.
         * @param request The incoming HTTP request (may be used by custom Apex class implementations)
         * @return HttpResponse configured according to the custom metadata settings
         */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response;

            switch on config.Type__c {
                when 'Static Resource' {
                    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
                    mock.setStaticResource(config.Response__c);
                    response = mock.respond(request);
                }
                when 'Apex Class' {
                    String[] className = config.Response__c.split('__');
                    if (className.size() == 1) {
                        className.add(0, '');
                    }

                    Type typeForName = Type.forName(className[0], className[1]);
                    HttpCalloutMock mock = (HttpCalloutMock) typeForName.newInstance();
                    response = mock.respond(request);
                }
                when else {
                    config = getFullConfig(config.DeveloperName);
                    response = new HttpResponse();
                    response.setBody(config.Response__c);
                }
            }

            if (config.StatusCode__c != null) {
                response.setStatus(config.Status__c);
                response.setStatusCode((Integer) config.StatusCode__c);
            }

            if (String.isNotBlank(config.Headers__c)) {
                setHeaders(config, response);
            }

            return response;
        }

        /**
         * Retrieves a specific HTTP callout mock by developer name.
         * If the Response__c field exceeds 255 characters, queries the full record to avoid Salesforce's text truncation.
         * @param developerName The developer name of the HttpCalloutMock__mdt record
         * @return The HttpCalloutMock__mdt record with complete response data
         */
        private HttpCalloutMock__mdt getFullConfig(String developerName) {
            Boolean isMocked = String.isBlank(config.Id);

            if (isMocked || config.Response__c.length() < 255) {
                return config;

            } else {
                //Salesforce trims long texts to 255
                return [
                    SELECT DeveloperName, Status__c, StatusCode__c,
                        Type__c, Response__c, Headers__c
                    FROM HttpCalloutMock__mdt
                    WHERE DeveloperName = :developerName
                    WITH USER_MODE
                ];
            }
        }

        /**
         * Parses and applies headers from custom metadata to the HTTP response.
         * Headers should be formatted as "Key: Value" pairs, separated by newlines.
         * @param mdt The HttpCalloutMock__mdt record containing header configuration
         * @param response The HttpResponse object to which headers will be added
         */
        private void setHeaders(HttpCalloutMock__mdt mdt, HttpResponse response) {
            List<String> headers = mdt.Headers__c.split('\n');

            for (String keyValue : headers) {
                List<String> keyValueSplit = keyValue.split(':', 2);
                response.setHeader(keyValueSplit[0].trim(), keyValueSplit[1].trim());
            }
        }
    }
}