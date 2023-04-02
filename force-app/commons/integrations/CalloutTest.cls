/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2023 Piotr Kożuchowski
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 * /
 * *
 *  Please find newest source code at https://github.com/amorek/Apex-Opensource-Library
 * /
 */

@IsTest(IsParallel=true)
private class CalloutTest {
    private static HttpRequest request;
    private static Integer requests = 0;

    /**
     * Callout configured with common actions for Acme APIs
     */
    private class AcmeApiCallout extends Callout {
        private AcmeAPIAuthHandler authorizationHandler = new AcmeAPIAuthHandler();

        protected override CalloutHandlersList onBeforeCalloutInit() {
            return new CalloutHandlersList()
                .add(match.once(), authorizationHandler)
                .add(match.onUnauthorized(), authorizationHandler);
        }

        protected override CalloutHandlersList onAfterCalloutInit() {
            return new CalloutHandlersList()
                .add(match.onUnauthorized(), action.retry(1))
                .add(match.onTimeout(), action.retry(1))
                .slot('beforeValidation')
                .add(match.onBadRequest(), action.throwResponseEx(UpdateErrorException.class))
                .add(match.onAnyErrorCode(), action.logCallout(LoggingLevel.ERROR))
                .add(match.onAnyErrorCode(), action.throwEx())
                .add(match.onSuccess(), action.logCallout(LoggingLevel.INFO))
                .add(match.onSuccess(), action.returnJSON(responseType));
        }
    }

    /**
     * Adds Oauth token to callouts
     */
    private class AcmeAPIAuthHandler implements Callout.Handler {
        public Object handle(Callout c) {
            c.setHeader('Authorization', 'Bearer XXX');
            return null;
        }
    }

    /**
     * Client-facing collection of exposed API methods:
     */
    private class AcmeAccountAPI {

        public List<Account> getAccounts(List<String> accountIds) {
            Callout c = new AcmeApiCallout()
                .config(new Map<String, Object>{
                    'method' => 'GET',
                    'endpoint' => 'callout:MyCredential/api/Account',
                    'params' => new Map<String, Object>{
                        'debug' => true,
                        'id' => accountIds
                    },
                    'responseType' => List<Account>.class
                });

            c.onAfterCallout()
                .addToSlot('beforeValidation', c.match.onNotFound(), c.action.returns(new List<Account>()));


            return (List<Account>) c.execute();
        }

        public Account updateAccount(Account account) {
            Callout c = new AcmeApiCallout()
                .config(new Map<String, Object>{
                    'method' => 'POST',
                    'endpoint' => 'callout:MyCredential/api/Account/' + account.Id,
                    'data' => account,
                    'responseType' => Account.class
                });

            return (Account) c.execute();
        }
    }

    private class Mock implements HttpCalloutMock {
        private HttpResponse response = new HttpResponse();

        public Mock(Integer statusCode, String status, Object obj) {
            this(statusCode, status, JSON.serialize(obj));
        }

        public Mock(Integer statusCode, String status, String body) {
            response.setBody(body);
            response.setStatusCode(statusCode);
            response.setStatus(status);
        }

        public HttpResponse respond(HttpRequest req) {
            requests++;
            request = req;
            return response;
        }
    }

    private class UpdateErrorException extends CalloutResponseException {
        public String errorCode;
        public String errorMessage;
    }


    /**
     * Tests
     */


    @IsTest
    static void shouldReturnAccountOnSuccess() {
        AcmeAccountAPI accountAPI = new AcmeAccountAPI();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock(200, 'OK', new List<Account>{
            new Account(Name = 'Test Account')
        }));

        List<Account> callResults = accountAPI.getAccounts(new List<Id>{'001000000000000'});
        Test.stopTest();


        Assert.areEqual(1, callResults.size());
        Assert.areEqual('Test Account', callResults.get(0).Name);
    }

    /**
     * Callout should return empty account list, because it had handler added to match 404 status code.
     */
    @IsTest
    static void shouldReturnEmptyListOnNotFound() {
        AcmeAccountAPI accountAPI = new AcmeAccountAPI();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock(404, 'NOT FOUND', new Map<String, String>{
            'error' => 'No results'
        }));

        List<Account> callResults = accountAPI.getAccounts(new List<Id>{'001000000000000'});
        Test.stopTest();

        Assert.isTrue(callResults.isEmpty(), 'Should return empty list according to added handler');
    }

    @IsTest
    static void shouldExecuteAuthorizationHandlerBeforeCallout() {
        AcmeAccountAPI accountAPI = new AcmeAccountAPI();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock(200, 'OK', new List<Account>{
            new Account(Name = 'Test Account')
        }));

        accountAPI.getAccounts(new List<Id>{'001000000000000'});
        Test.stopTest();

        Assert.areEqual(request.getHeader('Authorization'), 'Bearer XXX');
    }

    @IsTest
    static void shouldThrowExceptionOnInternalServerError() {
        AcmeAccountAPI accountAPI = new AcmeAccountAPI();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock(500, 'Internal Server Error',
            new Map<String, String>{
                'error' => 'Internal Server Error'
            }));

        try {
            accountAPI.getAccounts(new List<Id>{'001000000000000'});
            Assert.fail('Exception should be thrown');

        } catch (CalloutResponseException e) {
            Assert.isNotNull(e.getHttpResponse());
            Assert.areEqual(500, e.getStatusCode());
            Assert.areEqual('Internal Server Error', e.getStatus());
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldRetryOnAuthenticationError() {
        AcmeAccountAPI accountAPI = new AcmeAccountAPI();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock(401, 'Unauthorized',
            new Map<String, String>{
                'error' => 'Unauthorized'
            }));

        try {
            accountAPI.updateAccount(new Account());
            Assert.fail('Exception should be thrown');
        } catch (CalloutResponseException e) {
            Assert.areEqual(401, e.getStatusCode());
        }
        Test.stopTest();

        Assert.areEqual(2, requests, 'Should retry callout on unauthorized');
    }

    @IsTest
    static void shouldRetryOnTimeout() {
        AcmeAccountAPI accountAPI = new AcmeAccountAPI();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock(408, 'Request Timeout',
            new Map<String, String>{
                'error' => 'Timeout'
            }));

        try {
            accountAPI.updateAccount(new Account());
            Assert.fail('Exception should be thrown');
        } catch (CalloutResponseException e) {
            Assert.areEqual(408, e.getStatusCode());
        }
        Test.stopTest();

        Assert.areEqual(2, requests, 'Should retry callout on timeout');
    }

    @IsTest
    static void shouldHaveErrorResponseOnBadRequest() {
        AcmeAccountAPI accountAPI = new AcmeAccountAPI();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock(400, 'Bad Request',
            new Map<String, String>{
                'errorCode' => 'DML_ISSUE',
                'errorMessage' => 'Duplicate External Id'
            }));

        try {
            accountAPI.updateAccount(new Account());
            Assert.fail('Exception should be thrown');

        } catch (UpdateErrorException e) {
            Assert.areEqual('DML_ISSUE', e.errorCode);
            Assert.areEqual('Duplicate External Id', e.errorMessage);
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldAddQueryParameters() {
        AcmeAccountAPI api = new AcmeAccountAPI();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock(200, 'OK', new List<Account>{}));

        api.getAccounts(new List<String>{'1', '2', '3'});
        Test.stopTest();

        String endpoint = request.getEndpoint();
        Assert.isTrue(endpoint.contains('?debug=true'));
        Assert.isTrue(endpoint.contains('&id=1'));
        Assert.isTrue(endpoint.contains('&id=2'));
        Assert.isTrue(endpoint.contains('&id=3'));
    }

    @IsTest
    static void shouldAddHeaders() {
        Callout c = new Callout(new Map<String, Object>{
            'method' => 'GET',
            'endpoint' => 'callout:MyCredential/api/Account',
            'headers' => new Map<String, String>{
                'Authorization' => 'Bearer XXX'
            },
            'timeout' => 12000
        });

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock(200, 'OK', new List<Account>{}));
        c.execute();
        Test.stopTest();

        HttpRequest request = c.getRequest();
        Assert.areEqual(request.getHeader('Authorization'), 'Bearer XXX');
    }

    @IsTest
    static void coverageHandlerMethods() {
        CalloutConditions match = new CalloutConditions();
        CalloutHandlers action = new CalloutHandlers();

        AcmeApiCallout c = new AcmeApiCallout();
        c.setMethod('GET');
        c.setEndpoint('callout:MyCredential/api/Account');
        c.setLogName('coverageHandlerMethods');
        c.onBeforeCallout()
            .add('someHandler', match.onSuccess(), action.throwEx())
            .add(match.onException(), action.logCallout(LoggingLevel.ERROR))
            .add(match.onClientError(), action.logCallout(LoggingLevel.ERROR))
            .add(match.onServerError(), action.logCallout(LoggingLevel.ERROR))
            .add(match.always(), action.logCallout(LoggingLevel.INFO))
            .replace('someHandler', action.retry(2))
            .remove('someHandler')
            .clear();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock(200, 'OK', new List<Account>{}));
        c.execute();
        Test.stopTest();


        Log__c[] logs = [SELECT Id FROM Log__c WHERE ApexClass__c = 'coverageHandlerMethods'];
        Assert.areEqual(1, logs.size());
    }

    @IsTest
    static void shouldMatchRegexp() {
        CalloutConditions match = new CalloutConditions();
        CalloutHandlers action = new CalloutHandlers();

        AcmeApiCallout c = new AcmeApiCallout();
        c.setMethod('GET');
        c.setEndpoint('callout:MyCredential/api/Account');
        c.onAfterCallout()
            .clear()
            .add(match.onRegexMatch('.*"errorCode".*'), action.returns('my return value'));

        Test.startTest();
        Test.setMock(HttpCalloutMock.class,
            new Mock(400, 'Bad Request',
                new Map<String, String>{
                    'message' => 'Account ID: id value of incorrect type: 001900K0001pPuOAAU',
                    'errorCode' => 'MALFORMED_ID'
                }
            )
        );
        Object response = c.execute();
        Test.stopTest();


        Assert.areEqual('my return value', response,
            'Regexp handler should trigger when response body matches given regexp');
    }

    @IsTest
    static void shouldMatchSubstring() {
        AcmeApiCallout c = new AcmeApiCallout();
        c.setMethod('GET');
        c.setEndpoint('callout:MyCredential/api/Account');
        c.onAfterCallout()
            .clear()
            .add(c.match.onContains('"odata.error"'),
                c.action.replaceAll('"odata\\.error"', '"odata_error"'))
            .add(c.match.onDeserializableTo(ErrorResponseException.class), c.action.throwResponseEx(ErrorResponseException.class));


        Test.startTest();
        Test.setMock(HttpCalloutMock.class,
            new Mock(404, 'Not Found', '{"odata.error":{"code":"ResourceNotFound","message":{"lang":"en-US","value":"The specified resource does not exist"}}}')
        );

        try {
            c.execute();
            Assert.fail();

        } catch (Exception e) {
            Assert.isInstanceOfType(e, ErrorResponseException.class);
            ErrorResponseException error = (ErrorResponseException) e;
            Assert.isNotNull(error.odata_error);
            Assert.areEqual('ResourceNotFound', error.odata_error.code);
        }
        Test.stopTest();
    }

    private class ErrorResponseException extends CalloutResponseException {
        public OdataError odata_error;
    }

    private class OdataError {
        public String code;
        public Map<String, String> message;
    }
}