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
 * Mock Router class which provides ability to easily associate mock with given HTTP Method and Endpoint,
 * has shorthand for creating Static Resource, JSON, String or HttpCalloutMock mocks.
 * There is also an option to override default API responses in particular unit tests with different response.
 */
public virtual class HttpCalloutMockRouter implements HttpCalloutChainMock {
    private Map<String, String> variables = new Map<String, String>();
    private Map<String, HttpCalloutChainMock> registeredMocks = new Map<String, HttpCalloutChainMock>();
    private Map<String, HttpCalloutMock> mocksOverrides = new Map<String, HttpCalloutMock>();


    /**
     * Registers static resource response for given endpoint.
     * @param name Unique name of the mock, used to override the default mock in tests
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
     * @param name Unique name of the mock, used to override the default mock in tests
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
     * @param name Unique name of the mock, used to override the default mock in tests
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
    * @param name Unique name of the mock, used to override the default mock in tests
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
     * @param name Unique name of the mock, used to override the default mock in tests
     * @param statusCode Status code of the response
     * @param status Status of the response
     * @param resource Name of static resource file, which contains body of the response.
     */
    public HttpCalloutMockRouter overrideMockWithStaticResource(String name, Integer statusCode, String status, String resource) {
        return overrideMock(name, HttpSimpleMock.fromStaticResource(statusCode, status, resource));
    }

    /**
     * @param name Unique name of the mock, used to override the default mock in tests
     * @param methods Comma separated list of methods ('GET,POST')
     * @param endpointPattern Regexp pattern for endpoint
     * @param statusCode Status code of the response
     * @param status Status of the response
     * @param objectToSerialize Object to serialize as response's body
     */
    public HttpCalloutMockRouter overrideJsonMock(String name, Integer statusCode, String status, Object objectToSerialize) {
        return overrideMock(name, HttpSimpleMock.fromJSON(statusCode, status, objectToSerialize));
    }

    /**
     * @param name Unique name of the mock, used to override the default mock in tests
     * @param statusCode Status code of the response
     * @param status Status of the response
     * @param body Body of the response
     */
    public HttpCalloutMockRouter overrideMock(String name, Integer statusCode, String status, String body) {
        return overrideMock(name, new HttpSimpleMock(statusCode, status, body));
    }

    /**
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
     * Registers regexp variable which will can be referenced in endpoint:
     * <pre>
     * router.registerEndpointVariable('endpoint', 'https://api.sf.com/rest'); // Regexp for API endpoint
     * router.registerEndpointVariable('id', '([a-z0-9]{32}') // Regexp for external id
     *
     * router.registerStaticResourceMock('GET','{{endpoint}}/accounts/{{id}}', 200, 'OK', 'Mock_GetAccountResource');
     * </pre>
     *
     * @param name Unique name of the mock, used to override the default mock in tests
     * @param regexp Regexp of the variable
     */
    public HttpCalloutMockRouter registerEndpointVariable(String name, String regexp) {
        variables.put(name, regexp);
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

        for (String expressionName : variables.keySet()) {
            String variable = '{{' + expressionName + '}}';
            endpointWithVariables = endpointWithVariables.replace(variable, variables.get(expressionName));
        }

        return endpointWithVariables;
    }


    public class HttpCalloutMockRouterException extends Exception {
    }
}