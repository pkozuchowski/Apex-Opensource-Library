/**
* SPDX-License-Identifier: MIT
* Copyright 2018 Piotr Kożuchowski
* apexlibra.org
*/
@IsTest(IsParallel=true)
private class HttpCalloutMockRouterTest {
    private final static String ACCOUNT_ID = '001D000000IqhSLIAZ';
    private final static String ACCOUNT_NAME = 'Test Account';

    private class OrgMocks extends HttpCalloutMockRouter {
        public OrgMocks() {
            mock('Salesforce APIs', new SalesforceRestAPIMocks());
            mock('Azure APIs', new AzureMocks());
        }
    }

    private class SalesforceRestAPIMocks extends HttpCalloutMockRouter {

        public SalesforceRestAPIMocks() {
            mock('Query', 'GET', 'callout:SF_API/query\\?q=.*',
                HttpMocks.staticResource(200, 'OK', 'StaticResourceWithResponse')
            );

            mock('Create Account', 'POST', 'callout:SF_API/sobjects/Account/',
                HttpMocks.json(201, 'Created', new CreateRecordResult(true))
            );

            mock('Get Account', 'GET', 'callout:SF_API/sobjects/Account/.*',
                HttpMocks.json(200, 'OK',
                    new Account(Id = ACCOUNT_ID, Name = ACCOUNT_NAME))
            );

            mock('Delete Account', 'DELETE', 'callout:SF_API/sobjects/Account/.*',
                HttpMocks.response(204, 'No Content')
            );
        }
    }

    private class AzureMocks extends HttpCalloutMockRouter {
        public AzureMocks() {
            mock('Get Account', 'GET', 'callout:AWS/Account',
                HttpMocks.response(200, 'OK')
                    .body('{"name":"Test"}')
            );
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

    static {
        HttpConfigMocks.mock(new List<HttpCalloutMock__mdt>{
            new HttpCalloutMock__mdt(
                DeveloperName = 'SF_REST_Query',
                Default__c = true,
                Methods__c = 'GET',
                Endpoint__c = 'callout:SF_API/query\\?q=.*',
                Response__c = '{ "totalSize": 2, ' +
                    '"done": true, ' +
                    '"records": [' +
                    '{"Name": "Test 1"}, ' +
                    '{"Name": "Test 2"}] }',

                StatusCode__c = 200,
                Status__c = 'OK',
                Headers__c = 'Header1:Value1\n' +
                    'Header2:Value2'
            ),
            new HttpCalloutMock__mdt(
                DeveloperName = 'SF_REST_Not_Found',
                Default__c = false,
                Methods__c = 'GET',
                Endpoint__c = 'callout:SF_API/query\\?q=.*',
                Response__c = '',
                StatusCode__c = 404,
                Status__c = 'Not Found'
            ),
            new HttpCalloutMock__mdt(
                DeveloperName = 'SF_REST_Query_Redirect',
                Default__c = true,
                Methods__c = 'GET',
                Endpoint__c = 'https://salesforce.com/api/test',
                Response__c = '',
                StatusCode__c = 301,
                Status__c = 'OK',
                Headers__c = 'Location: https://salesforce.com/goaway'
            )
        });
    }


    @IsTest
    static void testAWSCallout() {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('callout:AWS/Account');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OrgMocks());
        HttpResponse response = new Http().send(request);
        Test.stopTest();


        Assert.areEqual('{"name":"Test"}', response.getBody());
    }


    @IsTest
    static void testSuccessfulCreateAccountCall() {
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint('callout:SF_API/sobjects/Account/');
        request.setBody('{"Name":"Test Account}');


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesforceRestAPIMocks());
        HttpResponse response = new Http().send(request);
        Test.stopTest();


        Assert.areEqual(201, response.getStatusCode());
        Assert.areEqual('Created', response.getStatus());

        CreateRecordResult result = (CreateRecordResult) JSON.deserialize(response.getBody(), CreateRecordResult.class);
        Assert.areEqual(true, result.success);
    }


    @IsTest
    static void testErrorCreateAccountCall() {
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint('callout:SF_API/sobjects/Account/');
        request.setBody('{"Name":"Test Account}');


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesforceRestAPIMocks()
            .overrideMock('Create Account',
                HttpMocks.json(401, 'Unauthorized', new List<Error>{
                    new Error('Session expired or invalid', 'INVALID_SESSION_ID')
                }))
        );
        HttpResponse response = new Http().send(request);
        Test.stopTest();


        Assert.areEqual(401, response.getStatusCode());
        Assert.areEqual('Unauthorized', response.getStatus());
        Assert.isTrue(response.getBody().contains('INVALID_SESSION_ID'));
    }


    @IsTest
    static void testGetAccountCall() {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('callout:SF_API/sobjects/Account/' + ACCOUNT_ID);


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesforceRestAPIMocks());
        HttpResponse response = new Http().send(request);
        Test.stopTest();


        Assert.areEqual(200, response.getStatusCode());
        Assert.areEqual('OK', response.getStatus());
        Assert.isTrue(response.getBody().contains('"Name":"' + ACCOUNT_NAME + '"'));
    }

    @IsTest
    static void testDeleteAccountCall() {
        HttpRequest request = new HttpRequest();
        request.setMethod('DELETE');
        request.setEndpoint('callout:SF_API/sobjects/Account/' + ACCOUNT_ID);


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesforceRestAPIMocks());
        HttpResponse response = new Http().send(request);
        Test.stopTest();


        Assert.areEqual(204, response.getStatusCode());
        Assert.areEqual('No Content', response.getStatus());
    }


    /**
     * When there is no registered mock which could handle request, exception is thrown.
     */
    @IsTest
    static void testUnhandledException() {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('callout:SF_API/sobjects/User/005D0000001KyEIIA0');
        Exception ex;


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesforceRestAPIMocks());

        try {
            new Http().send(request);
        } catch (HttpCalloutMockRouter.HttpCalloutMockRouterException e) {
            ex = e;
        }
        Test.stopTest();


        Assert.areNotEqual(null, ex);
        Assert.isTrue(ex.getMessage().contains('Unhandled request'));
    }


    /**
     * Coverage for static resource mocks (not included in library, therefore it would leads to exception)
     */
    @IsTest
    static void testStaticResourceCoverage() {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('callout:SF_API/sobjects/Account/' + ACCOUNT_ID);


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OrgMocks()
            .mock('Salesforce API', new SalesforceRestAPIMocks()
                .overrideMock('Delete Account', HttpMocks.response(401, 'Unauthorized', ''))
                .overrideMock('Query', HttpMocks.staticResource(200, 'OK', 'OtherStaticResource'))
            ));

        try {
            new Http().send(request);
        } catch (Exception e) {
        }
        Test.stopTest();
    }


    @IsTest
    static void testConfigurationBasedRouter() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, HttpMocks.config());

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('callout:SF_API/query?q=SELECT+name+from+Account');

        HttpResponse response = new Http().send(request);
        Test.stopTest();


        Assert.areEqual(200, response.getStatusCode());
        Assert.areEqual(
            '{ "totalSize": 2, "done": true, "records": [{"Name": "Test 1"}, {"Name": "Test 2"}] }',
            response.getBody()
        );
        Assert.areEqual('Value1', response.getHeader('Header1'));
        Assert.areEqual('Value2', response.getHeader('Header2'));
    }

    @IsTest
    static void shouldHandleHeaderWithColons() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, HttpMocks.config()
            .overrideMock('SF_REST_Query', 'SF_REST_Query_Redirect'));

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('callout:SF_API/query?q=SELECT+Name+FROM+Account');

        HttpResponse response = new Http().send(request);
        Test.stopTest();


        Assert.areEqual('https://salesforce.com/goaway', response.getHeader('Location'));
    }

    @IsTest
    static void shouldStoreHandledRequestsAndResponses() {
        shouldHandleHeaderWithColons();
        Assert.areEqual(1, HttpMocks.getRequests().size());
        Assert.areEqual(1, HttpMocks.getResponses().size());
        Assert.areEqual(
            'callout:SF_API/query?q=SELECT+Name+FROM+Account',
            HttpMocks.getRequests().get(0).getEndpoint());
        Assert.areEqual(301, HttpMocks.getResponses().get(0).getStatusCode());
    }

    public class TestMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setBody('Apex Class Response');
            return res;
        }
    }

    @IsTest
    static void shouldRespondWithApexClass() {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('callout:SF_API/query?q=SELECT+Name+FROM+Account');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, HttpMocks.config()
            .overrideMock('SF_REST_Query', HttpMocks.config(new HttpCalloutMock__mdt(
                DeveloperName = 'SF_REST_Query',
                Methods__c = 'GET',
                Endpoint__c = 'callout:SF_API/query\\?q=.*',
                Type__c = 'Apex Class',
                Response__c = '' + TestMock.class
            ))));
        HttpResponse response = new Http().send(request);
        Test.stopTest();

        Assert.areEqual(200, response.getStatusCode());
        Assert.areEqual('OK', response.getStatus());
        Assert.areEqual('Apex Class Response', response.getBody());
    }

    @IsTest
    static void shouldMutateResponse() {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('callout:SF_API/query?q=SELECT+name+from+Account');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, HttpMocks.config()
            .mutateResponse()
            .status(201, 'Created')
            .replaceInBody('Test 1', 'Test 3')
            .replaceInBody('Test 2', 'Test 4'));

        HttpResponse response = new Http().send(request);
        Test.stopTest();


        Assert.areEqual(201, response.getStatusCode());
        Assert.areEqual('Created', response.getStatus());
        Assert.areEqual('{ "totalSize": 2, "done": true, "records": [{"Name": "Test 3"}, {"Name": "Test 4"}] }', response.getBody());
    }

    @IsTest
    static void shouldAllowBuildingResponseFromConfig() {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('callout:SF_API/query?q=SELECT+name+from+Account');


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, HttpMocks.config()
            .overrideMock('SF_REST_Query', 'SF_REST_Not_Found')
        );
        HttpResponse response = new Http().send(request);
        Test.stopTest();


        Assert.areEqual(404, response.getStatusCode());
        Assert.areEqual('Not Found', response.getStatus());
    }

    @IsTest
    static void shouldReplaceJSONPartsByPath() {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('callout:SF_API/query?q=SELECT+name+from+Account');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, HttpMocks.config()
            .mutateResponse()
            .header('apiVersion', 'v1')
            .replaceInBody('', '')
            .replaceInJSON('.totalSize', 1)
            .replaceInJSON('.done', false)
            .replaceInJSON('.records.[0].Name', 'Replacement')
        );
        HttpResponse response = new Http().send(request);
        Test.stopTest();

        System.debug(response.getBody());
        Map<String, Object> responseJson = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        List<Object> items = (List<Object>) responseJson.get('records');
        Map<String, Object> item = (Map<String, Object>) items[0];

        Assert.areEqual(1, responseJson.get('totalSize'));
        Assert.areEqual(false, responseJson.get('done'));
        Assert.areEqual('Replacement', item.get('Name'));
        Assert.areEqual('v1', response.getHeader('apiVersion'));
    }

    @IsTest
    static void shouldThrowExceptionOnUnhandledRequest() {
        try {
            HttpRequest request = new HttpRequest();
            request.setMethod('GET');
            request.setEndpoint('callout:SF_API/none');


            Test.startTest();
            Test.setMock(HttpCalloutMock.class, HttpMocks.config()
                .overrideMock('SF_REST_Query', 'SF_REST_Not_Found')
            );
            new Http().send(request);
            Test.stopTest();

            Assert.fail();
        } catch (Exception e) {
            Assert.isInstanceOfType(e, HttpCalloutMockRouter.HttpCalloutMockRouterException.class);
        }
    }

    @IsTest
    static void shouldUseStaticResourceMock() {
        try {
            HttpConfigMocks.mock(new List<HttpCalloutMock__mdt>{
                new HttpCalloutMock__mdt(
                    DeveloperName = 'SF_REST_StaticResource',
                    Default__c = true,
                    Methods__c = 'GET',
                    Endpoint__c = 'callout:SF_API/static_resource',
                    Type__c = 'Static Resource',
                    Response__c = 'TEST_shouldUseStaticResourceMock',
                    StatusCode__c = 200,
                    Status__c = 'OK'
                )
            });

            HttpRequest request = new HttpRequest();
            request.setMethod('GET');
            request.setEndpoint('callout:SF_API/static_resource');

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, HttpMocks.config());
            new Http().send(request);
            Test.stopTest();

        } catch (Exception e) {
            Assert.isInstanceOfType(e, NullPointerException.class);
        }
    }
}