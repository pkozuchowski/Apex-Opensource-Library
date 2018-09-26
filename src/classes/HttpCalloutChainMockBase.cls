public virtual class HttpCalloutChainMockBase implements HttpCalloutChainMock {
    private List<HttpCalloutChainMock> registeredMocks = new List<HttpCalloutChainMock>{
    };


    /**
    * Register mock to Salesforce REST API callout.
    * Each registered mock in queue will be asked if it can handle the request, until the first mock that can handle.
    * New mocks are registered at the beginning of the mock queue.
    * */
    public HttpCalloutChainMockBase registerMock(HttpCalloutChainMock handler) {
        registeredMocks.add(0, handler);
        return this;
    }


    /**
     * Responds with first registered mock which can handle the request
     */
    public HttpResponse respond(HttpRequest request) {

        for (HttpCalloutChainMock mock : registeredMocks) {
            if (mock.handles(request)) {
                return mock.respond(request);
            }
        }

        throw new HttpCalloutChainMockBaseException('Unhandled request');
    }


    public virtual Boolean handles(HttpRequest request) {
        return true;
    }


    private class HttpCalloutChainMockBaseException extends Exception {
    }
}