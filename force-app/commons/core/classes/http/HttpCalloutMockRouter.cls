/**
* MIT License
*
* Copyright (c) 2018 Piotr Kożuchowski
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
 * Base Router class for HttpCalloutChainMocks based on Chain of Responsibility design pattern.
 * This class iterates through registered HttpCalloutChainMocks and responds
 * with the first mock that can handle the request.
 * Other routers can also be registered, therefore it's possible to create a whole hierarchy of mocks for
 * entire organization:
 * <pre>
 *     HttpCalloutChainMockRouter
 *         - Integration #1 Router
 *              - Auth Mock
 *              - Other Mocks...
 *
 *         - Integration #2 Router
 *              - Auth Mock
 *              - Other Mocks...
 *
 *         - Integration #3 Router
 *              - Auth Mock
 *              - Other Mocks...
 *
 *
 * </pre>
 *
 * Mocks are stored in LIFO queue, the most recently added mock will be the first to handle the request.
 * This way, routers can have predefined list of default registered mocks, which can be overridden
 * in partial unit tests with custom response mocks.
 * @see HttpCalloutMockRouterTest
 */
public virtual class HttpCalloutMockRouter implements HttpCalloutChainMock {
    private Map<String, String> expressions = new Map<String, String>();
    private Map<String, HttpCalloutChainMock> registeredMocks = new Map<String, HttpCalloutChainMock>();
    private Map<String, HttpCalloutMock> mocksOverrides = new Map<String, HttpCalloutMock>();


    /**
     * Registers static resource response for given endpoint.
     * @param methods Comma separated list of methods ('GET,POST')
     * @param endpointPattern Regexp pattern for endpoint
     * @param statusCode Status code of the response
     * @param status Status of the response
     * @param resource Name of static resource file, which contains body of the response.
     */
    public HttpCalloutMockRouter registerStaticResourceMock(String name, String methods, String endpointPattern, Integer statusCode, String status, String resource) {
        return registerMock(name, methods, endpointPattern, HttpSimpleMock.fromStaticResource(statusCode, status, resource));
    }

    /**
     * Registers JSON response for given endpoint.
     * @param methods Comma separated list of methods ('GET,POST')
     * @param endpointPattern Regexp pattern for endpoint
     * @param statusCode Status code of the response
     * @param status Status of the response
     * @param objectToSerialize Object to serialize as response's body
     */
    public HttpCalloutMockRouter registerJsonMock(String name, String methods, String endpointPattern, Integer statusCode, String status, Object objectToSerialize) {
        return registerMock(name, methods, endpointPattern, statusCode, status, JSON.serialize(objectToSerialize));
    }

    /**
     * Registers string response for given endpoint.
     * @param methods Comma separated list of methods ('GET,POST')
     * @param endpointPattern Regexp pattern for endpoint
     * @param statusCode Status code of the response
     * @param status Status of the response
     * @param body Body of the response
     */
    public HttpCalloutMockRouter registerMock(String name, String methods, String endpointPattern, Integer statusCode, String status, String body) {
        return registerMock(name, methods, endpointPattern, new HttpSimpleMock(statusCode, status, body));
    }

    /**
    * Register HttpCalloutMock for given Http method and endpoint pattern.
    * @param methods Comma separated list of methods ('GET,POST')
    * @param endpointPattern Regexp pattern for endpoint
    * @param mock Mock to respond with
    * */
    public HttpCalloutMockRouter registerMock(String name, String methods, String endpointPattern, HttpCalloutMock mock) {
        return registerMock(name, new HttpMockEndpointRouter(methods, replaceVariables(endpointPattern), mock));
    }

    /**
    * Register HttpCalloutChainMock implementation.
    * Each registered mock in queue will be asked if it can handle the request, until the first mock that can handle.
    * New mocks are registered at the beginning of the mock queue.
    * */
    public HttpCalloutMockRouter registerMock(String name, HttpCalloutChainMock handler) {
        registeredMocks.put(name, handler);
        return this;
    }


    /**
     * Overrides previously registered mock with given name with supplied substitute.
     * This method is used when main mock class for given API defines "happy path" success responses, but developer
     * has to test error response in one of the tests.
     *
     * Override uses Method and Endpoint routing (or handles method of HttpCalloutChainMock) of original mock.
     *
     * @param name User defined identifier of the endpoint (ex. 'token', 'GET Account', 'Update Order')
     * @param statusCode Status code of the response
     * @param status Status of the response
     * @param resource Name of static resource file, which contains body of the response.
     */
    public HttpCalloutMockRouter overrideMockWithStaticResource(String name, Integer statusCode, String status, String resource) {
        return overrideMock(name, HttpSimpleMock.fromStaticResource(statusCode, status, resource));
    }

    /**
     * @param methods Comma separated list of methods ('GET,POST')
     * @param endpointPattern Regexp pattern for endpoint
     * @param statusCode Status code of the response
     * @param status Status of the response
     * @param objectToSerialize Object to serialize as response's body
     */
    public HttpCalloutMockRouter overrideJsonMock(String name, Integer statusCode, String status, Object objectToSerialize) {
        return overrideMock(name, statusCode, status, JSON.serialize(objectToSerialize));
    }

    /**
     * @param name User defined identifier of the endpoint (ex. 'token', 'GET Account', 'Update Order')
     * @param statusCode Status code of the response
     * @param status Status of the response
     * @param body Body of the response
     */
    public HttpCalloutMockRouter overrideMock(String name, Integer statusCode, String status, String body) {
        return overrideMock(name, new HttpSimpleMock(statusCode, status, body));
    }

    /**
     * @param name User defined identifier of the endpoint (ex. 'token', 'GET Account', 'Update Order')
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
     * Registers regexp expression which will can be referenced in endpoint:
     * <pre>
     * router.registerEndpointExpression('endpoint', 'https://api.sf.com/rest'); // Regexp for API endpoint
     * router.registerEndpointExpression('id', '([a-z0-9]{32}') // Regexp for external id
     *
     * router.registerStaticResourceMock('GET','{{endpoint}}/accounts/{{id}}', 200, 'OK', 'Mock_GetAccountResource');
     * </pre>
     *
     * @param name Name of variable to be used in endpoints
     * @param regexp Regexp of the variable
     */
    public HttpCalloutMockRouter registerEndpointExpression(String name, String regexp) {
        expressions.put(name, regexp);
        return this;
    }


    /**
     * Responds with first registered mock which can handle the request.
     * If none if the registered mocks can handle the request, then exception is thrown.
     */
    public HttpResponse respond(HttpRequest request) {

        for (String name : registeredMocks.keySet()) {
            HttpCalloutChainMock mock = registeredMocks.get(name);
            HttpCalloutMock mockOverride = mocksOverrides.get(name);


            if (mock.handles(request)) {
                return (mockOverride != null ? mockOverride : mock).respond(request);
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
     * Replaces expression variables in endpoint
     */
    private String replaceVariables(String endpoint) {
        String endpointWithVariables = endpoint;

        for (String expressionName : expressions.keySet()) {
            String variable = '{{' + expressionName + '}}';
            endpointWithVariables = endpointWithVariables.replace(variable, expressions.get(expressionName));
        }

        return endpointWithVariables;
    }


    private class HttpCalloutMockRouterException extends Exception {
    }
}