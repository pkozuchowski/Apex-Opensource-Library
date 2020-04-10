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

/**
 * Simple mock constructed with given Http status and response body
 */
public virtual with sharing class HttpSimpleMock implements HttpCalloutMock {
    private HttpResponse response = new HttpResponse();

    /**
     * Creates JSON response mock
     */
    public static HttpCalloutMock fromJSON(Integer statusCode, String status, Object jsonObject) {
        return new HttpSimpleMock(statusCode, status, JSON.serialize(jsonObject));
    }

    /**
     * Creates Http response from static resource
     */
    public static HttpCalloutMock fromStaticResource(Integer statusCode, String status, String staticResource) {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(statusCode);
        mock.setStatus(status);
        mock.setStaticResource(staticResource);

        return (HttpCalloutMock) mock;
    }


    /**
     * Creates Http mock which responds with given status and body.
     */
    public HttpSimpleMock(Integer statusCode, String status, String body) {
        this.response.setStatusCode(statusCode);
        this.response.setStatus(status);
        this.response.setBody(body);
    }

    public HttpResponse respond(HttpRequest request) {
        return response;
    }
}