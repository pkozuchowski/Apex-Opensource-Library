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
private class FormatterTest {
    private final static Formatter formatter = new Formatter();


    @IsTest
    static void testFormattingException() {

        try {
            try {
                throw new CalloutException('test');
            } catch (Exception ex) {
                throw new CalloutException(ex);
            }
        } catch (Exception ex) {
            System.assertEquals(
                    'System.CalloutException: Script-thrown exception\n'
                            + 'Class.FormatterTest.testFormattingException: line 36, column 1\n'
                            + '\n'
                            + 'Caused by\n'
                            + 'System.CalloutException: test\n'
                            + 'Class.FormatterTest.testFormattingException: line 34, column 1',
                    formatter.format(ex)
            );
        }
    }

    @IsTest
    static void testFormattingHttpRequest() {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('https://www.example.com');
        request.setBody('{"value":"test"}');

        System.assertEquals(
                'GET https://www.example.com\n'
                        + '{"value":"test"}',
                formatter.format(request)
        );
    }

    @IsTest
    static void testFormattingHttpResponse() {
        HttpResponse response = new HttpResponse();
        response.setStatus('OK');
        response.setStatusCode(200);
        response.setBody('success');

        System.assertEquals(
                        '200 OK\n' +
                        'success',
                formatter.format(response)
        );
    }

    @IsTest
    static void testFormattingRESTRequest() {
        RestRequest request = new RestRequest();
        request.httpMethod = 'GET';
        request.resourcePath = 'https://www.example.com?param=value';
        request.addParameter('param', 'value');
        request.requestBody = Blob.valueOf('request');

        System.assertEquals(
                'GET https://www.example.com?param=value'
                        + '\nParams:'
                        + '\n"param" : "value"'
                        + '\nBody:\n'
                        + 'request',
                formatter.format(request)
        );

    }

    @IsTest
    static void testFormattingRESTResponse() {
        RestResponse response = new RestResponse();
        response.statusCode = 200;
        response.responseBody = Blob.valueOf('success');

        System.assertEquals(
                'Response:\n' +
                        '200' +
                        '\nBody:\n' +
                        'success',
                formatter.format(response)
        );
    }

    @IsTest
    static void testFormattingBlob() {
        Blob b = Blob.valueOf('test');

        System.assertEquals('test', formatter.format(b));
    }
}