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
@IsTest(IsParallel=true)
private class HttpCalloutMockRouterTest {

    @IsTest
    static void coverage() {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('https://example.com');

        new HttpCalloutMockRouter()
                .registerMock('GET', 'https://example.com', 200, 'OK', 'success')
                .registerStaticResourceMock('POST', 'https://example.com', 200, 'OK', 'StaticResourceName')
                .handles(request);
    }

    @IsTest
    static void testRouter() {
        Test.startTest();

        /*
        Default mocks can be registered directly in Router of each API,
        but I decided to explicitly register all mocks in this example.

        In reality, you could have only overrides here + top most mock for whole organization.
        */
        Test.setMock(HttpCalloutMock.class,
                new HttpCalloutMockRouter()
                        .registerMock(
                        new AcmeMocksRouter()
                                .registerMock('POST', '.*/auth', 200, 'OK', 'sessionToken: abc')
                                .registerMock(new AcmeGetAccountsMock())
                                .registerMock('POST', '.*/accounts', 200, 'OK', '{"success":"true"}'))

                        .registerMock(
                        new ExampleMocksRouter()
                                .registerMock('POST', '.*/auth', 200, 'OK', 'sessionToken: xyz')
                                .registerMock(new ExampleGetAccountsMock())
                                .registerMock('POST', '.*/accounts', 200, 'OK', '{"success":"true"}'))
        );


        /*Acme Requests*/
        System.assertEquals('sessionToken: abc', doCallout('POST', 'www.acme.com/rest/auth', null, null));

        List<Account> acmeAccounts = (List<Account>) doCallout('GET', 'www.acme.com/rest/accounts', null, Account[].class);
        System.assertEquals(3, acmeAccounts.size());

        for (Account account : acmeAccounts) {
            System.assert(account.Name.contains('ACME'));
        }

        System.assertEquals('{"success":"true"}', doCallout('POST', 'www.acme.com/rest/accounts', acmeAccounts, null));


        /*
        * Example requests
        * */
        System.assertEquals('sessionToken: xyz', doCallout('POST', 'www.example.com/rest/auth', null, null));

        List<Account> exampleAccounts = (List<Account>) doCallout('GET', 'www.example.com/rest/accounts', null, Account[].class);
        System.assertEquals(3, exampleAccounts.size());

        for (Account account : exampleAccounts) {
            System.assert(account.Name.contains('Example'));
        }


        System.assertEquals('{"success":"true"}', doCallout('POST', 'www.example.com/rest/accounts', null, null));


        /*Other Requests*/
        try {
            doCallout('POST', 'www.test.com', null, null);
            System.assert(false, 'Router did not throw exception for unhandled request.');
        } catch (HttpCalloutMockRouter.HttpCalloutChainMockBaseException ex) {
        }
        Test.stopTest();
    }

    private static Object doCallout(String method, String endpoint, Object body, Type responseBodyType) {
        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        request.setEndpoint(endpoint);

        if (body != null) request.setBody(JSON.serialize(body));
        HttpResponse response = new Http().send(request);

        if (responseBodyType != null) {
            return JSON.deserialize(response.getBody(), responseBodyType);
        } else {
            return response.getBody();
        }
    }


    /**
    * Mock Router for ACME callouts.
    * */
    private class AcmeMocksRouter extends HttpCalloutMockRouter {

        public override Boolean handles(HttpRequest request) {
            return request.getEndpoint().contains('acme.com/rest');
        }
    }

    private class AcmeGetAccountsMock implements HttpCalloutChainMock {

        public Boolean handles(HttpRequest request) {
            return request.getEndpoint().contains('/accounts') && request.getMethod() == 'GET';
        }

        public HttpResponse respond(HttpRequest param1) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody(JSON.serialize(new Account[]{
                    new Account(Name = 'ACME Account 1'),
                    new Account(Name = 'ACME Account 2'),
                    new Account(Name = 'ACME Account 3')
            }));

            return response;
        }
    }


    /**
    * Mock Router for Example company service callouts.
    * */
    private class ExampleMocksRouter extends HttpCalloutMockRouter {
        public override Boolean handles(HttpRequest request) {
            return request.getEndpoint().contains('example.com/rest');
        }
    }

    private class ExampleGetAccountsMock implements HttpCalloutChainMock {

        public Boolean handles(HttpRequest request) {
            return request.getEndpoint().contains('/accounts') && request.getMethod() == 'GET';
        }

        public HttpResponse respond(HttpRequest param1) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody(JSON.serialize(new Account[]{
                    new Account(Name = 'Example Account 1'),
                    new Account(Name = 'Example Account 2'),
                    new Account(Name = 'Example Account 3')
            }));

            return response;
        }
    }
}