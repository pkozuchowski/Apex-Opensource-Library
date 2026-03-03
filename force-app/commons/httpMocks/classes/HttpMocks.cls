/**
* SPDX-License-Identifier: MIT
* Copyright 2019 Piotr Kożuchowski
* apexlibra.org
*/

/**
 * Simple mock constructed with given Http status and response body
 */
public virtual with sharing class HttpMocks {

    /**
     * @return List of handled HttpRequests in the order they were issued.
     */
    public static List<HttpRequest> getRequests() {
        return HttpCalloutMockRouter.REQUESTS;
    }

    /**
     * @return List of returned HttpResponses in order they were returned.
     */
    public static List<HttpResponse> getResponses() {
        return HttpCalloutMockRouter.RESPONSES;
    }

    /**
     * @return Router with all custom metadata mocks loaded.
     */
    public static HttpCalloutMockRouter config() {
        return new HttpMocksConfigRouter();
    }

    /**
     * Responds with status and code defined in HttpCalloutMock__mdt custom metadata
     */
    public static HttpMockBuilder config(String customMetadataName) {
        return new HttpMockBuilder(new ConfigMock(HttpMocksConfigRouter.getMock(customMetadataName)));
    }

    /**
     * Responds with status and code defined in HttpCalloutMock__mdt custom metadata
     */
    public static HttpMockBuilder config(HttpCalloutMock__mdt customMetadata) {
        return new HttpMockBuilder(new ConfigMock(customMetadata));
    }

    /**
     * Creates a new HttpCalloutMock HttpMockBuilder with the specified HTTP status code and status message.
     * This is the starting point for building a custom HTTP mock response.
     * 
     * @param statusCode The HTTP status code to return (e.g., 200, 404, 500)
     * @param status The HTTP status message (e.g., 'OK', 'Not Found', 'Internal Server Error')
     * @return A HttpMockBuilder instance that can be further configured with headers, body, or other response properties
     * 
     * @example
     * HttpCalloutMock mock = HttpMocks.response(200, 'OK')
     *     .body('{"result": "success"}')
     *     .header('Content-Type', 'application/json');
     */
    public static HttpMockBuilder response(Integer statusCode, String status) {
        return new HttpMockBuilder().status(statusCode, status);
    }

    /**
     * Creates a new HttpCalloutMock with the specified HTTP status code, status message, and response body.
     * This is a convenience method for quickly building a complete HTTP mock response.
     *
     * @example
     * HttpCalloutMock mock = HttpMocks.response(200, 'OK', '{"result": "success"}');
     */
    public static HttpMockBuilder response(Integer statusCode, String status, String body) {
        return new HttpMockBuilder().status(statusCode, status).body(body);
    }

    /**
     * Creates a new HttpCalloutMock with the specified HTTP status code, status message, and JSON-serialized response body.
     * The provided object will be automatically serialized to JSON format.
     * 
     * @example
     * Map<String, Object> data = new Map<String, Object>{'result' => 'success'};
     * HttpCalloutMock mock = HttpMocks.json(200, 'OK', data);
     */
    public static HttpMockBuilder json(Integer statusCode, String status, Object toSerialize) {
        return new HttpMockBuilder().status(statusCode, status).json(toSerialize);
    }

    /**
     * Creates a new HttpCalloutMock with the specified HTTP status code, status message, and response body from a Static Resource.
     * The response body content will be loaded from the specified Static Resource.
     * 
     * @example
     * HttpCalloutMock mock = HttpMocks.staticResource(200, 'OK', 'MockResponseData');
     */
    public static HttpMockBuilder staticResource(Integer statusCode, String status, String staticResource) {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(staticResource);

        return new HttpMockBuilder(mock).status(statusCode, status);
    }


    /**
     * Mock implementation that uses HttpCalloutMock__mdt custom metadata to configure HTTP responses.
     * Supports multiple response types: direct body content, static resources, or custom Apex class implementations.
     */
    @TestVisible
    private virtual class ConfigMock implements HttpCalloutMock {
        private HttpCalloutMock__mdt config;

        /**
         * Constructs a ConfigMock with the specified custom metadata configuration.
         * @param config The HttpCalloutMock__mdt record containing the mock response configuration
         */
        public ConfigMock(HttpCalloutMock__mdt config) {
            this.config = config;
        }

        /**
         * Generates an HTTP response based on the configuration defined in HttpCalloutMock__mdt.
         * The response can be sourced from: Response__c field, StaticResource__c, or custom ApexClass__c.
         * @param request The incoming HTTP request (may be used by custom Apex class implementations)
         * @return HttpResponse configured according to the custom metadata settings
         */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response;

            if (String.isNotBlank(config.StaticResource__c)) {
                StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
                mock.setStaticResource(config.StaticResource__c);
                response = mock.respond(request);

            } else if (String.isNotBlank(config.ApexClass__c)) {
                HttpCalloutMock mock = (HttpCalloutMock) Type.forName(
                    config.ApexClassNamespace__c,
                    config.ApexClass__c
                ).newInstance();
                response = mock.respond(request);

            } else {
                config = getFullConfig(config.DeveloperName);
                response = new HttpResponse();
                response.setBody(config.Response__c);
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