/**
* SPDX-License-Identifier: MIT
* Copyright 2018 Piotr Kożuchowski
* apexlibra.org
*/

/**
 * Mock Router class which provides ability to easily associate mock with given HTTP Method and Endpoint,
 * has shorthand for creating Static Resource, JSON, String or HttpCalloutMock mocks.
 * There is also an option to override default API responses in particular unit tests with different response.
 */
public virtual class HttpCalloutMockRouter implements HttpCalloutChainMock {
    public final static List<HttpRequest> REQUESTS = new List<HttpRequest>();
    public final static List<HttpResponse> RESPONSES = new List<HttpResponse>();

    private Map<String, String> replacements = new Map<String, String>();
    private Map<String, HttpCalloutChainMock> registeredMocks = new Map<String, HttpCalloutChainMock>();
    private Map<String, HttpCalloutMock> mocksOverrides = new Map<String, HttpCalloutMock>();


    /**
     * @return Loads Mocks from custom metadata
     */
    public HttpCalloutMockRouter loadConfiguration() {
        for (HttpCalloutMock__mdt mockMdt : HttpMocksConfig.getMocks()) {
            if (mockMdt.Default__c) {
                mock(mockMdt.DeveloperName, mockMdt.Methods__c, mockMdt.Endpoint__c, HttpMocks.config(mockMdt));
            }
        }

        return this;
    }


    /**
    * Register HttpCalloutMock for given Http method and endpoint pattern.
    * @param name Unique name of the mock, used to override the default mock in tests
    * @param methods Comma separated list of methods ('GET,POST')
    * @param endpointPattern Regexp pattern for endpoint
    * @param mock Mock to respond with
    * */
    public HttpCalloutMockRouter mock(String name, String methods, String endpointPattern, HttpCalloutMock mock) {
        return mock(name, new HttpMockEndpointMatcher(methods, endpointPattern, mock));
    }

    /**
    * Register HttpCalloutChainMock implementation.
    * Each registered mock in queue will be asked if it can handle the request, until the first mock that can handle.
    * New mocks are registered at the beginning of the mock queue.
    * */
    public HttpCalloutMockRouter mock(String name, HttpCalloutChainMock handler) {
        registeredMocks.put(name, handler);
        return this;
    }

    /**
     * Replaces mock registered under given name with different mock loaded from custom metadata
     * @param name Unique name of the mock, used to override the default mock in tests.
     * @param overrideMetadataName DeveloperName of custom metadata to override with.
     */
    public HttpCalloutMockRouter overrideMock(String name, String overrideMetadataName) {
        return overrideMock(name, HttpMocks.config(overrideMetadataName));
    }

    /**
     * Replaces mock registered under given name with different mock
     * @param name Unique name of the mock, used to override the default mock in tests
     * @param mock Mock to respond with
     */
    public HttpCalloutMockRouter overrideMock(String name, HttpCalloutMock mock) {
        if (registeredMocks.containsKey(name)) {
            mocksOverrides.put(name, mock);
            return this;

        } else {
            throw new HttpCalloutMockRouterException('There is no mock to override with given name (' + name + ')');
        }
    }

    /**
     * Replaces each substring of a target string in response body
     * with the specified literal replacement sequence replacement.
     * @param target Text to replace
     * @param replacement Replacement
     * @return
     */
    public HttpCalloutMockRouter replaceInResponse(String target, String replacement) {
        replacements.put(target, replacement);
        return this;
    }

    /**
     * Responds with first registered mock which can handle the request.
     * If none if the registered mocks can handle the request, then exception is thrown.
     */
    public HttpResponse respond(HttpRequest request) {

        for (String name : registeredMocks.keySet()) {
            HttpCalloutChainMock mock = registeredMocks.get(name);

            if (mock.handles(request)) {
                HttpCalloutMock respondent = mocksOverrides.get(name) ?? mock;
                HttpResponse response = respondent.respond(request);
                applyReplacements(response);
                REQUESTS.add(request);
                RESPONSES.add(response);

                return response;
            }
        }

        throw new HttpCalloutMockRouterException('Unhandled request: ' + request);
    }


    /**
     * @return Boolean whether this mock class can handle the request.
     */
    public virtual Boolean handles(HttpRequest request) {
        for (HttpCalloutChainMock mock : registeredMocks.values()) {
            if (mock.handles(request)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Applies substring replacements in body and header.
     */
    private void applyReplacements(HttpResponse response) {
        String body = response.getBody();

        if (String.isNotBlank(body)) {
            for (String target : replacements.keySet()) {
                body = body.replace(target, replacements.get(target));
            }
            response.setBody(body);
        }

        applyReplacementsInHeaders(response);
    }

    private void applyReplacementsInHeaders(HttpResponse response) {
        for (String headerKey : response.getHeaderKeys()) {
            String headerValue = response.getHeader(headerKey);
            if (String.isNotBlank(headerValue)) {
                for (String target : replacements.keySet()) {
                    headerValue = headerValue.replace(target, replacements.get(target));
                }
                response.setHeader(headerKey, headerValue);
            }
        }
    }

    public class HttpCalloutMockRouterException extends Exception {}
}