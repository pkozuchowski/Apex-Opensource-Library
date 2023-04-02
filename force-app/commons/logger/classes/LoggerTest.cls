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


        Log__c[] logs = [SELECT ApexClass__c, ReferenceId__c, Message__c, LoggingLevel__c FROM Log__c];
        System.assertEquals(3, logs.size(), '3 Logs should be created');

        for (Log__c log : logs) {
            System.assertEquals('LoggerTest.testLogMessage', log.ApexClass__c);
            System.assertEquals(log.Message__c, log.LoggingLevel__c);
        }
    }


    /**
     * logger.error() method can take exception as argument.
     * Logs message should contain exception's message, stack trace and cause.
     */
    @IsTest
    static void testLogException() {
        Datetime startTime = Datetime.now();
        Test.startTest();
        try {
            Date d = (Date) Datetime.now();
        } catch (Exception ex) {
            Logger.error(new Log(ex)
                .withParameter('test', 'test')
                .withParameters(new Map<String, Object>{
                    'other' => 'param'
                })
                .withReferenceId('test')
                .withTimeMetric(startTime));
        }
        Test.stopTest();


        Log__c log = [
            SELECT ApexClass__c, ReferenceId__c, Message__c, LoggingLevel__c, ExecutionTime__c
            FROM Log__c
            LIMIT 1
        ];
        System.assert(log.Message__c.contains('Invalid conversion from runtime type Datetime to Date'), 'Message should contain exception message');
        System.assert(log.Message__c.contains('LoggerTest.testLogException'), 'Message should contain stack trace');
        System.assert(log.ExecutionTime__c > 0, 'Should measure how much time execution of the method took');
        System.assertEquals('LoggerTest.testLogException', log.ApexClass__c);
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


        Log__c log = [SELECT Response__c, Request__c FROM Log__c WHERE LoggingLevel__c = 'INFO' LIMIT 1];
        System.assert(log.Response__c.contains('200 OK'));
        System.assert(log.Request__c.contains('{"value":"test"}'));
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
        Logger.info(new Log(request, response).withApexClass('TestAPI'));
        Test.stopTest();


        Log__c log = [SELECT Request__c, Response__c, ApexClass__c FROM Log__c WHERE LoggingLevel__c = 'INFO' LIMIT 1];
        System.assert(log.Response__c.contains('200'));
        System.assert(log.Response__c.contains('success'));
        System.assert(log.Request__c.contains('request'));
        System.assert(log.Request__c.contains('?param=value'));
        System.assertEquals('TestAPI', log.ApexClass__c);
    }

}