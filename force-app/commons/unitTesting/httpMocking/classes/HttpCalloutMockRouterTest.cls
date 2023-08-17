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

    public class OrgMocks extends HttpCalloutMockRouter {
        public OrgMocks(){
            mock('Salesforce APIs', new SalesforceRestAPIMocks());
            mock('Azure APIs', new AzureMocks());
        }
    }

    private class SalesforceRestAPIMocks extends HttpCalloutMockRouter {

        public SalesforceRestAPIMocks() {
            variables(new Map<String, String>{
                'endpoint' => 'https://yourInstance.salesforce.com/services/data/v\\d+.0',
                'id' => '([0-9a-zA-Z]{15,18})'
            });

            mock('Query', 'GET', '{{endpoint}}/query/?q=.*', HttpMocks.staticResource(200, 'OK', 'StaticResourceWithResponse'));
            mock('Create Account', 'POST', '{{endpoint}}/sobjects/Account/', HttpMocks.json(201, 'Created', new CreateRecordResult(true)));
            mock('Get Account', 'GET', '{{endpoint}}/sobjects/Account/{{id}}', HttpMocks.json(200, 'OK', new Account(Id = ACCOUNT_ID, Name = ACCOUNT_NAME)));
            mock('Delete Account', 'DELETE', '{{endpoint}}/sobjects/Account/{{id}}', HttpMocks.text(204, 'No Content', ''));
            mock('Delete Account', 'DELETE', '{{endpoint}}/sobjects/Account/{{id}}', HttpMocks.text(204, 'No Content', ''));
        }
    }

    private class AzureMocks extends HttpCalloutMockRouter {
        public AzureMocks() {
            variable('endpoint', 'https://aws.com/amazing/services/.*');

            mock('Get Account', 'GET', '{{endpoint}}/Account',
                HttpMocks.text(200, 'OK', '{"name":"Test"}'));
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
    static void testAWSCallout() {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('https://aws.com/amazing/services/Account');

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
            .overrideMock('Create Account', HttpMocks.json(401, 'Unauthorized', new List<Error>{
                new Error('Session expired or invalid', 'INVALID_SESSION_ID')
            }))
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
        Test.setMock(HttpCalloutMock.class, new OrgMocks()
            .mock('Salesforce API', new SalesforceRestAPIMocks()
                .overrideMock('Delete Account', HttpMocks.text(401, 'Unauthorized', ''))
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
        HttpCalloutMockRouter.configuration = new List<HttpCalloutMock__mdt>{
            new HttpCalloutMock__mdt(
                DeveloperName = 'SF_REST_Query',
                Default__c = true,
                Methods__c = 'GET',
                Endpoint__c = '{{sfRestEndpoint}}/data/v\\d+.0/query/.*',
                Response__c = '{"records":["Name":"Test 1"},{"Name":"Test 2"}]}',
                StatusCode__c = 200,
                Status__c = 'OK',
                Headers__c = 'Header1:Value1\n' +
                    'Header2:Value2'
            )
        };


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockRouter()
            .variables(new Map<String, String>{
                'sfRestEndpoint' => 'https://' + DomainCreator.getOrgMyDomainHostname() + '/services'
            })
            .loadConfiguration());

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('https://' + DomainCreator.getOrgMyDomainHostname() + '/services/data/v47.0/query/?q=SELECT+name+from+Account');

        HttpResponse response = new Http().send(request);
        Test.stopTest();


        Assert.areEqual(200, response.getStatusCode());
        Assert.areEqual('{"records":["Name":"Test 1"},{"Name":"Test 2"}]}', response.getBody());
        Assert.areEqual('Value1', response.getHeader('Header1'));
        Assert.areEqual('Value2', response.getHeader('Header2'));
    }
}