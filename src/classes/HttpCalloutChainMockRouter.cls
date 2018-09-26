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