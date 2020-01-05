/**
* MIT License
*
* Copyright (c) 2019 Piotr Kożuchowski
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

/**
 * Routes HttpCalloutChainMock to given method and endpoint pattern.
 */
public virtual with sharing class HttpMockEndpointRouter implements HttpCalloutChainMock {
    private Pattern endpointPattern;
    private Set<String> methods;
    private HttpCalloutMock mock;

    /**
     * @param methods HTTP methods separated by coma ex. "POST,PUT"
     * @param endpointPattern Regexp pattern for Endpoint
     * @param mock Mock to respond with.
     */
    public HttpMockEndpointRouter(String methods, String endpointPattern, HttpCalloutMock mock) {
        this.methods = new Set<String>(methods.toUpperCase().split(','));
        this.endpointPattern = Pattern.compile(endpointPattern);
        this.mock = mock;
    }

    public virtual Boolean handles(HttpRequest request) {
        return this.methods.contains(request.getMethod().toUpperCase())
                && endpointPattern.matcher(request.getEndpoint()).matches();
    }

    public virtual HttpResponse respond(HttpRequest request) {
        return mock.respond(request);
    }
}