/**
* SPDX-License-Identifier: MIT
* Copyright 2019 Piotr Kożuchowski
* apexlibra.org
*/

/**
 * Routes HttpCalloutChainMock to given method and endpoint pattern.
 */
public virtual with sharing class HttpMockEndpointMatcher implements HttpCalloutChainMock {
    private Pattern endpointPattern;
    private Set<String> methods;
    private HttpCalloutMock mock;

    /**
     * @param methods HTTP methods separated by coma ex. "POST,PUT"
     * @param endpointPattern Regexp pattern for Endpoint
     * @param mock Mock to respond with.
     */
    public HttpMockEndpointMatcher(String methods, String endpointPattern, HttpCalloutMock mock) {
        this.methods = new Set<String>(methods.toUpperCase().split(','));
        this.endpointPattern = Pattern.compile(endpointPattern);
        this.mock = mock;
    }

    public virtual Boolean handles(HttpRequest request) {
        return (this.methods.contains('*') || this.methods.contains(request.getMethod().toUpperCase()))
                && endpointPattern.matcher(request.getEndpoint()).matches();
    }

    public virtual HttpResponse respond(HttpRequest request) {
        return mock.respond(request);
    }
}