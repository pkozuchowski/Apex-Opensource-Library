@IsTest(IsParallel=true)
private class HttpCalloutChainMockRouterTest {


    @IsTest
    static void testRouter() {
        Test.startTest();

        Test.setMock(HttpCalloutMock.class,
                new HttpCalloutChainMockRouter()
                        .registerMock(
                        new AcmeMocks()
                                .registerMock(new AcmeAuthenticationMock())
                                .registerMock(new AcmeGetAccountsMock())
                                .registerMock(new AcmePostAccountsMock()))

                        .registerMock(
                        new DacmeMocks()
                                .registerMock(new DacmeAuthenticationMock())
                                .registerMock(new DacmeGetAccountsMock())
                                .registerMock(new DacmePostAccountsMock()))
        );

        Http http = new Http();

        HttpRequest request = new HttpRequest();
        request.setEndpoint('www.acme.com/rest/auth');
        System.assertEquals('sessionToken: abc', http.send(request).getBody());


        Test.stopTest();
    }


    /**
    * Mock Router for ACME callouts.
    * */
    private class AcmeMocks extends HttpCalloutChainMockRouter {

        public override Boolean handles(HttpRequest request) {
            return request.getEndpoint().contains('acme.com/rest');
        }
    }

    private class AcmeAuthenticationMock implements HttpCalloutChainMock {

        public Boolean handles(HttpRequest request) {
            return request.getEndpoint().contains('/auth');
        }

        public HttpResponse respond(HttpRequest param1) {
            HttpResponse response = new HttpResponse();
            response.setBody('sessionToken: abc');
            response.setStatusCode(200);

            return response;
        }
    }

    private class AcmeGetAccountsMock implements HttpCalloutChainMock {

        public Boolean handles(HttpRequest request) {
            return request.getEndpoint().contains('/accounts') && request.getMethod() == 'GET';
        }

        public HttpResponse respond(HttpRequest param1) {
            return null;
        }
    }

    private class AcmePostAccountsMock implements HttpCalloutChainMock {

        public Boolean handles(HttpRequest request) {
            return request.getEndpoint().contains('/accounts') && request.getMethod() == 'POST';
        }

        public HttpResponse respond(HttpRequest param1) {
            return null;
        }
    }


    /**
    * Mock Router for Dacme callouts.
    * */
    private class DacmeMocks extends HttpCalloutChainMockRouter {

        public override Boolean handles(HttpRequest request) {
            return request.getEndpoint().contains('dacme.com/rest');
        }
    }

    private class DacmeAuthenticationMock implements HttpCalloutChainMock {

        public Boolean handles(HttpRequest request) {
            return request.getEndpoint().contains('/auth');
        }

        public HttpResponse respond(HttpRequest param1) {
            return null;
        }
    }

    private class DacmeGetAccountsMock implements HttpCalloutChainMock {

        public Boolean handles(HttpRequest request) {
            return request.getEndpoint().contains('/accounts') && request.getMethod() == 'GET';
        }

        public HttpResponse respond(HttpRequest param1) {
            return null;
        }
    }

    private class DacmePostAccountsMock implements HttpCalloutChainMock {

        public Boolean handles(HttpRequest request) {
            return request.getEndpoint().contains('/accounts') && request.getMethod() == 'POST';
        }

        public HttpResponse respond(HttpRequest param1) {
            return null;
        }
    }

}