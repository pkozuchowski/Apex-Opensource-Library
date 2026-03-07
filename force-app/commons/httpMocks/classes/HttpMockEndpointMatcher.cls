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
    private String matchingHeader;
    private HttpCalloutMock mock;

    /**
     * @param methods HTTP methods separated by coma ex. "POST,PUT"
     * @param endpointPattern Regexp pattern for Endpoint
     * @param matchingHeaders - When provided, matches header during routing
     * @param mock Mock to respond with.
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public HttpMockEndpointMatcher(String methods, String endpointPattern, String matchingHeader,
        HttpCalloutMock mock) {
        this.methods = new Set<String>(methods.toUpperCase().split(','));
        this.endpointPattern = Pattern.compile(endpointPattern);
        this.mock = mock;
        this.matchingHeader = matchingHeader;
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
        if (String.isNotBlank(matchingHeader)) {
            List<String> header = matchingHeader.split(':', 2);
            String headerKey = header[0].trim();
            String headerValue = header[1].trim();

            return request.getHeader(headerKey) == headerValue
                || (String.isBlank(headerValue) && request.getHeader(headerKey) == null);
        }
        return true;
    }
}