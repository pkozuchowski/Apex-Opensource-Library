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
private class StringifierTest {
    private final static Stringifier stringifier = new Stringifier();


    @IsTest
    static void testStringifyException() {

        try {
            try {
                throw new CalloutException('test');
            } catch (Exception ex) {
                throw new CalloutException(ex);
            }
        } catch (Exception ex) {
            System.assertEquals(
                    ('System.CalloutException: Script-thrown exception\n'
                            + 'Class.StringifierTest.testStringifyException: line 36, column 1\n'
                            + '\n'
                            + 'Caused by\n'
                            + 'System.CalloutException: test\n'
                            + 'Class.StringifierTest.testStringifyException: line 34, column 1'),
                    stringifier.toString(ex)
            );
        }
        Exception ex2 = null;
        System.assertEquals(stringifier.toString(ex2), '');
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
                        + 'Authorization: Bearer XXX\n'
                        + 'Content-Type: application/json\n'
                        + '\n'
                        + '{"Name":"Test Account}',
                stringifier.toString(request)
        );
        request = null;
        System.assertEquals(stringifier.toString(request), '');
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
                stringifier.toString(response)
        );
        response = null;
        System.assertEquals(stringifier.toString(response), '');
    }

    @IsTest
    static void testStringifyRESTRequest() {
        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.resourcePath = '/services/data/v20.0/sobjects/Account/';
        request.addParameter('id', '001000000000000');
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{request}');

        System.assertEquals('POST /services/data/v20.0/sobjects/Account/\n' +
                'Host: ' + Url.getOrgDomainUrl().getHost() + '\n' +
                'Content-Type: application/json\n' +
                '\n' +
                'URL Parameters:\n' +
                'id: 001000000000000\n' +
                '\n' +
                '{request}',

                stringifier.toString(request)
        );
        request = null;
        System.assertEquals(stringifier.toString(request), '');
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
                stringifier.toString(response)
        );
        response = null;
        System.assertEquals(stringifier.toString(response), '');
    }

    @IsTest
    static void testStringifyBlob() {
        Blob b = Blob.valueOf('test');

        System.assertEquals('test', stringifier.toString(b));
        b = null;
        System.assertEquals(stringifier.toString(b), '');
    }
}