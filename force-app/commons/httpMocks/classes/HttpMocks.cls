/**
* SPDX-License-Identifier: MIT
* Copyright 2019 Piotr Kożuchowski
* apexlibra.org
*/

/**
 * Simple mock constructed with given Http status and response body
 */
@SuppressWarnings('PMD.CognitiveComplexity')
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
        return new HttpConfigMocks.ConfigRouter();
    }

    /**
     * Responds with status and code defined in HttpCalloutMock__mdt custom metadata
     */
    public static HttpMockBuilder config(String customMetadataName) {
        return new HttpMockBuilder(new HttpConfigMocks.ConfigMock(customMetadataName));
    }

    /**
     * Responds with status and code defined in HttpCalloutMock__mdt custom metadata
     */
    public static HttpMockBuilder config(HttpCalloutMock__mdt customMetadata) {
        return new HttpMockBuilder(new HttpConfigMocks.ConfigMock(customMetadata));
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
}