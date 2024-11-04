/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2022 Piotr Kożuchowski
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
*/
@IsTest(IsParallel=true)
private class LogStringifierTest {


    @IsTest
    static void testStringifyException() {

        try {
            try {
                throw new CalloutException('test');
            } catch (Exception ex) {
                throw new CalloutException(ex);
            }
        } catch (Exception ex) {
            String[] str = LogStringifier.toString(ex).split('\n');
            System.assertEquals(str[0], 'System.CalloutException: Script-thrown exception');
            System.assert(str[1].startsWith('Class.LogStringifierTest.testStringifyException: line '));
            System.assertEquals(str[3], 'Caused by');
            System.assertEquals(str[4], 'System.CalloutException: test');
            System.assert(str[5].startsWith('Class.LogStringifierTest.testStringifyException:'));
        }
        Exception ex2 = null;
        System.assertEquals(LogStringifier.toString(ex2), '');
    }

    @IsTest
    static void testStringifyHttpRequest() {
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint('https://yourInstance.salesforce.com/services/data/v20.0/sobjects/Account/');
        request.setHeader('Authorization', 'Bearer XXX');
        request.setHeader('Content-Type', 'application/json');
        request.setBody('{"Name":"Test Account}');

        System.assertEquals(
            'POST /services/data/v20.0/sobjects/Account/\n'
                + 'Host: yourInstance.salesforce.com\n'
                + 'Content-Type: application/json\n'
                + '\n'
                + '{"Name":"Test Account}',
            LogStringifier.toString(request)
        );
        request = null;
        System.assertEquals(LogStringifier.toString(request), '');
    }

    @IsTest
    static void testStringifyHttpResponse() {
        HttpResponse response = new HttpResponse();
        response.setStatus('OK');
        response.setStatusCode(200);
        response.setBody('success');

        System.assertEquals(
            '200 OK\n\n' +
                'success',
            LogStringifier.toString(response)
        );
        response = null;
        System.assertEquals(LogStringifier.toString(response), '');
    }

    @IsTest
    static void testStringifyRESTRequest() {
        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.resourcePath = '/services/data/v20.0/sobjects/Account/';
        request.addParameter('id', '001000000000000');
        request.addParameter('checkonly', 'true');
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('request body');

        System.assertEquals('POST /services/data/v20.0/sobjects/Account/\n' +
            '\t?id=001000000000000\n' +
            '\t&checkonly=true\n' +
            'Host: ' + Url.getOrgDomainUrl().getHost() + '\n' +
            'Content-Type: application/json\n' +
            '\n' +
            'request body',

            LogStringifier.toString(request)
        );
        request = null;
        System.assertEquals(LogStringifier.toString(request), '');
    }

    @IsTest
    static void testStringifyRESTResponse() {
        RestResponse response = new RestResponse();
        response.statusCode = 200;
        response.responseBody = Blob.valueOf('success');
        response.headers.put('Content-Type', 'application/json');

        System.assertEquals('200\n'
            + 'Content-Type: application/json\n'
            + '\n'
            + 'success',
            LogStringifier.toString(response)
        );
        response = null;
        System.assertEquals(LogStringifier.toString(response), '');
    }

    @IsTest
    static void testStringifyBlob() {
        Blob b = Blob.valueOf('test');

        System.assertEquals('test', LogStringifier.toString(b));
        b = null;
        System.assertEquals(LogStringifier.toString(b), '');
    }
}