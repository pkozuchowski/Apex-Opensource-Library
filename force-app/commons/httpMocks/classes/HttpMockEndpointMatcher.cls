/**
* SPDX-License-Identifier: MIT
* Copyright 2018 Piotr Kożuchowski
* apexlibra.org
*/

/**
* Routes HttpCalloutChainMock to given method and endpoint pattern.
*/
public virtual with sharing class HttpMockEndpointMatcher implements HttpCalloutChainMock {
    private Pattern endpointPattern;
    private Set<String> methods;
    private Map<String, String> matchingHeaders = new Map<String, String>();
    private HttpCalloutMock mock;

    /**
     * @param methods HTTP methods separated by coma ex. "POST,PUT"
     * @param endpointPattern Regexp pattern for Endpoint
     * @param mock Mock to respond with.
     */
    public HttpMockEndpointMatcher(String methods, String endpointPattern, HttpCalloutMock mock) {
        this(methods, endpointPattern, '', mock);
    }

    /**
     * @param matchingHeaders - When provided, matches header during routing
     */
    public HttpMockEndpointMatcher(String methods, String endpointPattern, String matchingHeader,
        HttpCalloutMock mock) {
        this.methods = new Set<String>(methods.toUpperCase().split(','));
        this.endpointPattern = Pattern.compile(endpointPattern);
        this.mock = mock;
        this.matchingHeaders = matchingHeaders;
    }

    public virtual Boolean handles(HttpRequest request) {
        return (this.methods.contains('*') || this.methods.contains(request.getMethod().toUpperCase()))
            && endpointPattern.matcher(request.getEndpoint()).matches()
            && hasMatchingHeaders(request);
    }

    public virtual HttpResponse respond(HttpRequest request) {
        return mock.respond(request);
    }

    private Boolean hasMatchingHeaders(HttpRequest request) {
        if (!matchingHeaders.isEmpty()) {
            Integer matchingHeaderCount = 0;
            for (String expectedHeader : matchingHeaders.keySet()) {
                if (request.getHeader(expectedHeader) == matchingHeaders.get(expectedHeader)) {
                    matchingHeaderCount++;
                }
            }
            return matchingHeaderCount == matchingHeaders.size();
        }
        return true;
    }
}