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
 * @see HttpCalloutChainMockRouterTest
 */
public virtual class HttpCalloutChainMockRouter implements HttpCalloutChainMock {
    private List<HttpCalloutChainMock> registeredMocks = new List<HttpCalloutChainMock>{
            new UnsupportedRequest()
    };


    /**
    * Register HttpCalloutChainMock implementation.
    * Each registered mock in queue will be asked if it can handle the request, until the first mock that can handle.
    * New mocks are registered at the beginning of the mock queue.
    * */
    public HttpCalloutChainMockRouter registerMock(HttpCalloutChainMock handler) {
        registeredMocks.add(0, handler);
        return this;
    }


    /**
     * Responds with first registered mock which can handle the request.
     * If none if the registered mocks can handle the request, then exception is thrown.
     */
    public HttpResponse respond(HttpRequest request) {

        for (HttpCalloutChainMock mock : registeredMocks) {
            if (mock.handles(request)) {
                return mock.respond(request);
            }
        }

        return null;
    }


    /**
     * @return Boolean whether this mock class can handle the request.
     */
    public virtual Boolean handles(HttpRequest request) {
        return true;
    }


    /**
     * Last Mock in the queue. If request was not handled by now, then exception is thrown.
     */
    private class UnsupportedRequest implements HttpCalloutChainMock {

        public Boolean handles(HttpRequest request) {
            return true;
        }

        public HttpResponse respond(HttpRequest param1) {
            throw new HttpCalloutChainMockBaseException('Unhandled request');
        }
    }

    private class HttpCalloutChainMockBaseException extends Exception {
    }
}