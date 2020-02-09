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
    private final static String ACCOUNT_ID = '001D000000IqhSLIAZ';
    private final static String ACCOUNT_NAME = 'Test Account';

    private class SalesforceRestAPIMocks extends HttpCalloutMockRouter {

        public SalesforceRestAPIMocks() {
            this.registerEndpointVariable('endpoint', 'https://yourInstance.salesforce.com/services/data/v47.0');
            this.registerEndpointVariable('id', '([0-9a-zA-Z]{15,18})');

            this.registerStaticResourceMock('Query', 'GET', '{{endpoint}}/query/?q=.*', 200, 'OK', 'StaticResourceWithResponse');
            this.registerJsonMock('Create Account', 'POST', '{{endpoint}}/sobjects/Account/', 201, 'Created', new CreateRecordResult(true));
            this.registerJsonMock('Get Account', 'GET', '{{endpoint}}/sobjects/Account/{{id}}', 200, 'OK', new Account(Id = ACCOUNT_ID, Name = ACCOUNT_NAME));
            this.registerMock('Delete Account', 'DELETE', '{{endpoint}}/sobjects/Account/{{id}}', 204, 'No Content', '');
            this.registerStaticResourceMock('Query', 'GET', '{{endpoint}}/query/?q=.*', 200, 'OK', 'StaticResourceWithResponse');
        }
    }

    private class CreateRecordResult {
        public String id;
        public Boolean success;

        public CreateRecordResult(Boolean success) {
            this.id = ACCOUNT_ID;
            this.success = success;
        }
    }

    private class Error {
        public String message;
        public String errorCode;

        public Error(String message, String errorCode) {
            this.message = message;
            this.errorCode = errorCode;
        }
    }


    @IsTest
    static void testSuccessfulCreateAccountCall() {
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint('https://yourInstance.salesforce.com/services/data/v47.0/sobjects/Account/');
        request.setBody('{"Name":"Test Account}');


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesforceRestAPIMocks());
        HttpResponse response = new Http().send(request);
        Test.stopTest();


        System.assertEquals(201, response.getStatusCode());
        System.assertEquals('Created', response.getStatus());

        CreateRecordResult result = (CreateRecordResult) JSON.deserialize(response.getBody(), CreateRecordResult.class);
        System.assertEquals(true, result.success);
    }

    @IsTest
    static void testErrorCreateAccountCall() {
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint('https://yourInstance.salesforce.com/services/data/v47.0/sobjects/Account/');
        request.setBody('{"Name":"Test Account}');


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesforceRestAPIMocks()
                .overrideJsonMock('Create Account', 401, 'Unauthorized', new List<Error>{
                        new Error('Session expired or invalid', 'INVALID_SESSION_ID')
                })
        );
        HttpResponse response = new Http().send(request);
        Test.stopTest();


        System.assertEquals(401, response.getStatusCode());
        System.assertEquals('Unauthorized', response.getStatus());
        System.assert(response.getBody().contains('INVALID_SESSION_ID'));
    }


    @IsTest
    static void testGetAccountCall() {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('https://yourInstance.salesforce.com/services/data/v47.0/sobjects/Account/' + ACCOUNT_ID);


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesforceRestAPIMocks());
        HttpResponse response = new Http().send(request);
        Test.stopTest();


        System.assertEquals(200, response.getStatusCode());
        System.assertEquals('OK', response.getStatus());
        System.assert(response.getBody().contains('"Name":"' + ACCOUNT_NAME + '"'));
    }

    @IsTest
    static void testDeleteAccountCall() {
        HttpRequest request = new HttpRequest();
        request.setMethod('DELETE');
        request.setEndpoint('https://yourInstance.salesforce.com/services/data/v47.0/sobjects/Account/' + ACCOUNT_ID);


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesforceRestAPIMocks());
        HttpResponse response = new Http().send(request);
        Test.stopTest();


        System.assertEquals(204, response.getStatusCode());
        System.assertEquals('No Content', response.getStatus());
    }


    /**
     * When there is no registered mock which could handle request, exception is thrown.
     */
    @IsTest
    static void testUnhandledException() {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('https://yourInstance.salesforce.com/services/data/v47.0/sobjects/User/005D0000001KyEIIA0');
        Exception ex;


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesforceRestAPIMocks());

        try {
            new Http().send(request);
        } catch (HttpCalloutMockRouter.HttpCalloutMockRouterException e) {
            ex = e;
        }
        Test.stopTest();


        System.assertNotEquals(null, ex);
        System.assert(ex.getMessage().contains('Unhandled request'));
    }


    /**
     * Coverage for static resource mocks (not included in library, therefore it would leads to exception)
     */
    @IsTest
    static void testStaticResourceCoverage() {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('https://yourInstance.salesforce.com/services/data/v47.0/sobjects/Account/' + ACCOUNT_ID);


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockRouter()
                .registerMock('Salesforce API', new SalesforceRestAPIMocks()
                        .overrideMock('Delete Account', 401, 'Unauthorized', '')
                        .overrideMockWithStaticResource('Query', 200, 'OK', 'OtherStaticResource')
                ));

        try {
            new Http().send(request);
        } catch (Exception e) {
        }
        Test.stopTest();
    }
}