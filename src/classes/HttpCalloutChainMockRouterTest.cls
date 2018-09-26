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
private class HttpCalloutChainMockRouterTest {


    @IsTest
    static void testRouter() {
        Test.startTest();

        /*
        Default mocks can be registered directly in Router of each API,
        but I decided to explicitly register all mocks in this example.

        In reality, you could have only overrides here + top most mock for whole organization.
        */
        Test.setMock(HttpCalloutMock.class,
                new HttpCalloutChainMockRouter()
                        .registerMock(
                        new AcmeMocksRouter()
                                .registerMock(new AcmeAuthenticationMock())
                                .registerMock(new AcmeGetAccountsMock())
                                .registerMock(new AcmePostAccountsMock()))

                        .registerMock(
                        new ExampleMocksRouter()
                                .registerMock(new ExampleAuthenticationMock())
                                .registerMock(new ExampleGetAccountsMock())
                                .registerMock(new ExamplePostAccountsMock()))
        );

        Http http = new Http();

        /*Acme Requests*/
        HttpRequest acmeAuthRequest = new HttpRequest();
        acmeAuthRequest.setEndpoint('www.acme.com/rest/auth');
        System.assertEquals('sessionToken: abc', http.send(acmeAuthRequest).getBody());


        HttpRequest acmeGetAccountsRequest = new HttpRequest();
        acmeGetAccountsRequest.setMethod('GET');
        acmeGetAccountsRequest.setEndpoint('www.acme.com/rest/accounts');

        HttpResponse acmeGetAccountsResponse = http.send(acmeGetAccountsRequest);
        List<Account> acmeAccounts = (List<Account>) JSON.deserialize(acmeGetAccountsResponse.getBody(), Account[].class);
        System.assertEquals(3, acmeAccounts.size());

        for (Account account : acmeAccounts) {
            System.assert(account.Name.contains('ACME'));
        }


        HttpRequest acmePostAccountsRequest = new HttpRequest();
        acmePostAccountsRequest.setMethod('POST');
        acmePostAccountsRequest.setEndpoint('www.acme.com/rest/accounts');
        acmePostAccountsRequest.setBody(JSON.serialize(acmeAccounts));
        System.assertEquals('{"success":"true"}', http.send(acmePostAccountsRequest).getBody());


        /*
        * Example requests
        * */
        HttpRequest exampleAuthRequest = new HttpRequest();
        exampleAuthRequest.setEndpoint('www.example.com/rest/auth');
        System.assertEquals('sessionToken: xyz', http.send(exampleAuthRequest).getBody());


        HttpRequest exampleGetAccountsRequest = new HttpRequest();
        exampleGetAccountsRequest.setMethod('GET');
        exampleGetAccountsRequest.setEndpoint('www.example.com/rest/accounts');

        HttpResponse exampleGetAccountsResponse = http.send(exampleGetAccountsRequest);
        List<Account> exampleAccounts = (List<Account>) JSON.deserialize(exampleGetAccountsResponse.getBody(), Account[].class);
        System.assertEquals(3, exampleAccounts.size());

        for (Account account : exampleAccounts) {
            System.assert(account.Name.contains('Example'));
        }


        HttpRequest examplePostAccountsRequest = new HttpRequest();
        examplePostAccountsRequest.setMethod('POST');
        examplePostAccountsRequest.setEndpoint('www.example.com/rest/accounts');
        examplePostAccountsRequest.setBody(JSON.serialize(exampleAccounts));
        System.assertEquals('{"success":"true"}', http.send(examplePostAccountsRequest).getBody());


        /*Other Requests*/
        HttpRequest otherRequest = new HttpRequest();
        otherRequest.setMethod('POST');
        otherRequest.setEndpoint('www.test.com');

        try {
            http.send(otherRequest);
            System.assert(false, 'Router did not throw exception for unhandled request.');
        } catch (HttpCalloutChainMockRouter.HttpCalloutChainMockBaseException ex) {
        }

        Test.stopTest();
    }


    /**
    * Mock Router for ACME callouts.
    * */
    private class AcmeMocksRouter extends HttpCalloutChainMockRouter {

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

    private class AcmePostAccountsMock implements HttpCalloutChainMock {

        public Boolean handles(HttpRequest request) {
            return request.getEndpoint().contains('/accounts') && request.getMethod() == 'POST';
        }

        public HttpResponse respond(HttpRequest param1) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"success":"true"}');

            return response;
        }
    }


    /**
    * Mock Router for Dacme callouts.
    * */
    private class ExampleMocksRouter extends HttpCalloutChainMockRouter {

        public override Boolean handles(HttpRequest request) {
            return request.getEndpoint().contains('example.com/rest');
        }
    }

    private class ExampleAuthenticationMock implements HttpCalloutChainMock {

        public Boolean handles(HttpRequest request) {
            return request.getEndpoint().contains('/auth');
        }

        public HttpResponse respond(HttpRequest param1) {
            HttpResponse response = new HttpResponse();
            response.setBody('sessionToken: xyz');
            response.setStatusCode(200);

            return response;
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

    private class ExamplePostAccountsMock implements HttpCalloutChainMock {

        public Boolean handles(HttpRequest request) {
            return request.getEndpoint().contains('/accounts') && request.getMethod() == 'POST';
        }

        public HttpResponse respond(HttpRequest param1) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"success":"true"}');

            return response;
        }
    }

}