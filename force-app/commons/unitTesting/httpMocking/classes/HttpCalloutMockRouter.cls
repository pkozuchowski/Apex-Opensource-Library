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
    private static List<HttpCalloutMock__mdt> configuration {
        get {
            if (configuration == null) {
                configuration = HttpCalloutMock__mdt.getAll().values();
            }
            return configuration;
        }
        set;
    }
    public static Boolean configurationMocked = false;
    private Map<String, String> variables = new Map<String, String>();
    private Map<String, HttpCalloutChainMock> registeredMocks = new Map<String, HttpCalloutChainMock>();
    private Map<String, HttpCalloutMock> mocksOverrides = new Map<String, HttpCalloutMock>();


    /**
     * @return Loads Mocks from custom metadata
     */
    public HttpCalloutMockRouter loadConfiguration() {
        for (HttpCalloutMock__mdt mockMdt : configuration) {
            if (mockMdt.Default__c) {
                mock(mockMdt.DeveloperName, mockMdt.Methods__c, mockMdt.Endpoint__c, HttpMocks.config(mockMdt));
            }
        }

        return this;
    }

    @TestVisible static void mockConfiguration(List<HttpCalloutMock__mdt> config) {
        configuration = config;
        configurationMocked = true;
    }


    /**
    * Register HttpCalloutMock for given Http method and endpoint pattern.
    * @param name Unique name of the mock, used to override the default mock in tests
    * @param methods Comma separated list of methods ('GET,POST')
    * @param endpointPattern Regexp pattern for endpoint
    * @param mock Mock to respond with
    * */
    public HttpCalloutMockRouter mock(String name, String methods, String endpointPattern, HttpCalloutMock mock) {
        return mock(name, new HttpMockEndpointMatcher(methods, replaceVariables(endpointPattern), mock));
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
     * router.variable('endpoint', 'https://api.sf.com/rest'); // Regexp for API endpoint
     * router.variable('id', '([a-z0-9]{32}') // Regexp for external id
     *
     * router.registerStaticResourceMock('GET','{{endpoint}}/accounts/{{id}}', 200, 'OK', 'Mock_GetAccountResource');
     * </pre>
     *
     * @param name Unique name of the mock, used to override the default mock in tests
     * @param regexp Regexp of the variable
     */
    public HttpCalloutMockRouter variable(String name, String regexp) {
        variables.put(name, regexp);
        return this;
    }

    public HttpCalloutMockRouter variables(Map<String, String> vars) {
        variables.putAll(vars);
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


    public class HttpCalloutMockRouterException extends Exception {}
}