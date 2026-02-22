/**
* MIT License
*
* Copyright (c) 2019 Piotr Kożuchowski
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
@SuppressWarnings('PMD.ApexAssertionsShouldIncludeMessage')
@IsTest(IsParallel=true)
private class LoggerTest {

    @IsTest
    static void testLogMessage() {

        Test.startTest();
        Logger.info(new Log('INFO'));
        Logger.warn(new Log('WARN'));
        Logger.error(new Log('ERROR'));
        Test.getEventBus().deliver();
        Test.stopTest();


        Log__c[] logs = [SELECT Source__c, ReferenceId__c, Response__c, Severity__c FROM Log__c];
        Assert.areEqual(3, logs.size(), '3 Logs should be created');

        for (Log__c log : logs) {
            Assert.areEqual(LoggerTest.class.getName() + '.testLogMessage', log.Source__c);
            Assert.areEqual(log.Response__c, log.Severity__c);
        }
    }


    /**
     * logger.error() method can take exception as argument.
     * Logs message should contain exception's message, stack trace and cause.
     */
    @SuppressWarnings('PMD.UnusedLocalVariable')
    @IsTest
    static void testLogException() {
        Test.startTest();
        try {
            Date d = (Date) Datetime.now();
        } catch (Exception ex) {
            Logger.error(new Log(ex)
                .withInput('test', 'test')
                .withInputs(1)
                .withInputs(1, 2)
                .withInputs(1, 2, 3)
                .withInputs(new Map<String, Object>{
                    'other' => 'param'
                })
                .withReferenceId('test')
                .withExecutionTime(Datetime.now()) //Just for coverage
                .withExecutionTime(10));
        }
        Test.stopTest();


        Log__c log = [
            SELECT Source__c, ReferenceId__c, Response__c, Severity__c, ExecutionTime__c
            FROM Log__c
            LIMIT 1
        ];
        Assert.isTrue(log.Response__c.contains('Invalid conversion from runtime type Datetime to Date'), 'Message should contain exception message');
        Assert.isTrue(log.Response__c.contains('LoggerTest.testLogException'), 'Message should contain stack trace');
        Assert.areEqual(10, log.ExecutionTime__c, 'Should measure how much time execution of the method took');
        Assert.areEqual(LoggerTest.class.getName() + '.testLogException', log.Source__c);
    }


    /**
     * Logger should be able to format and log HttpRequest and Responses
     */
    @IsTest
    static void testLogHttp() {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('https://www.example.com');
        request.setBody('{"value":"test"}');

        HttpResponse response = new HttpResponse();
        response.setStatus('OK');
        response.setStatusCode(200);
        response.setBody('success');


        Test.startTest();
        Logger.info(new Log(request, response));
        Test.stopTest();


        Log__c log = [SELECT Response__c, Request__c FROM Log__c WHERE Severity__c = 'INFO' LIMIT 1];
        Assert.isTrue(log.Response__c.contains('200 OK'));
        Assert.isTrue(log.Request__c.contains('{"value":"test"}'));
    }


    /**
     * Logger should be able to format and log HttpRequest and Responses
     */
    @IsTest
    static void testLogREST() {
        RestRequest request = new RestRequest();
        request.httpMethod = 'GET';
        request.resourcePath = 'https://www.example.com?param=value';
        request.addParameter('param', 'value');
        request.requestBody = Blob.valueOf('request');

        RestResponse response = new RestResponse();
        response.statusCode = 200;
        response.responseBody = Blob.valueOf('success');


        Test.startTest();
        Logger.info(new Log(request, response).withSource('TestAPI'));
        Test.stopTest();


        Log__c log = [SELECT Request__c, Response__c, Source__c FROM Log__c WHERE Severity__c = 'INFO' LIMIT 1];
        Assert.isTrue(log.Response__c.contains('200'));
        Assert.isTrue(log.Response__c.contains('success'));
        Assert.isTrue(log.Request__c.contains('request'));
        Assert.isTrue(log.Request__c.contains('?param=value'));
        Assert.areEqual('TestAPI', log.Source__c);
    }

    @IsTest
    static void testDataMasking() {
        Test.startTest();
        Logger.info(new Log('My SSN is 078-05-1120, wives is 123454891 ' +
            'and my CC card number is 5500 0000 0000 0004'));
        Test.stopTest();

        Log__c log = [SELECT Response__c FROM Log__c LIMIT 1];
        Assert.isFalse(log.Response__c.contains('078-05-1120'));
        Assert.isFalse(log.Response__c.contains('123454891'));
        Assert.isFalse(log.Response__c.contains('5500 0000 0000 0004'));
    }

    @IsTest
    static void testLoggerInvocableMethod() {
        LogActions.FlowLogRequest request = new LogActions.FlowLogRequest();
        request.severity = 'ERROR';
        request.flowName = 'Test Flow';
        request.message = 'The flow tried to update these records.';

        Test.startTest();
        LogActions.log(new List<LogActions.FlowLogRequest>{
            request
        });
        Test.stopTest();

        Log__c log = [SELECT Source__c, Response__c, Severity__c FROM Log__c LIMIT 1];
        Assert.areEqual(request.severity, log.Severity__c);
        Assert.areEqual(request.flowName, log.Source__c);
        Assert.areEqual(request.message, log.Response__c);
    }

    @IsTest
    static void testLoggerAuraEnabledMethod() {
        Test.startTest();
        LogActions.log('ERROR', 'myComponent', 'My Message', 'referenceId', null);
        Test.stopTest();

        Log__c log = [SELECT Source__c, Response__c, Severity__c FROM Log__c LIMIT 1];
        Assert.areEqual('ERROR', log.Severity__c);
        Assert.areEqual('myComponent', log.Source__c);
        Assert.areEqual('My Message', log.Response__c);
    }
}