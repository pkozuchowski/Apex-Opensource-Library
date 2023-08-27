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
public virtual with sharing class HttpMocks {

    /**
     * Creates JSON response mock
     */
    public static HttpCalloutMock json(Integer statusCode, String status, Object jsonObject) {
        return new SimpleMock(statusCode, status, JSON.serialize(jsonObject));
    }

    /**
     * Creates Http response from static resource
     */
    public static HttpCalloutMock staticResource(Integer statusCode, String status, String staticResource) {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(statusCode);
        mock.setStatus(status);
        mock.setStaticResource(staticResource);

        return (HttpCalloutMock) mock;
    }

    /**
     * Creates Http response from plain text
     */
    public static HttpCalloutMock text(Integer statusCode, String status, String body) {
        return new SimpleMock(statusCode, status, body);
    }

    /**
     * Responds with status and code defined in HttpCalloutMock__mdt custom metadata
     */
    public static HttpCalloutMock config(String customMetadataName) {
        return new ConfigMock(HttpCalloutMock__mdt.getInstance(customMetadataName));
    }

    /**
     * Responds with status and code defined in HttpCalloutMock__mdt custom metadata
     */
    public static HttpCalloutMock config(HttpCalloutMock__mdt customMetadata) {
        return new ConfigMock(customMetadata);
    }


    private class SimpleMock implements HttpCalloutMock {
        private HttpResponse response = new HttpResponse();

        /**
         * Creates Http mock which responds with given status and body.
         */
        private SimpleMock(Integer statusCode, String status, String body) {
            this.response.setStatusCode(statusCode);
            this.response.setStatus(status);
            this.response.setBody(body);
        }

        public HttpResponse respond(HttpRequest request) {
            return response;
        }
    }


    @TestVisible
    private virtual class ConfigMock implements HttpCalloutMock {
        private HttpCalloutMock__mdt config;

        public ConfigMock(HttpCalloutMock__mdt config){
            this.config = config;
        }

        public HttpResponse respond(HttpRequest request) {
            HttpCalloutMock mock;

            if (String.isNotBlank(config.StaticResource__c)) {
                mock = staticResource((Integer) config.StatusCode__c, config.Status__c, config.StaticResource__c);

            } else {
                config = getResponseBody();
                mock = text((Integer) config.StatusCode__c, config.Status__c, config.Response__c);
            }

            HttpResponse response = mock.respond(request);
            if (String.isNotBlank(config.Headers__c)) {
                setHeaders(config, response);
            }

            return response;
        }

        protected HttpCalloutMock__mdt getResponseBody() {
            if (!HttpCalloutMockRouter.configurationMocked) {
                return [
                    SELECT Status__c, StatusCode__c, Response__c, StaticResource__c, Headers__c
                    FROM HttpCalloutMock__mdt
                    WHERE DeveloperName = :config.DeveloperName
                ];
            }
            return config;
        }

        private void setHeaders(HttpCalloutMock__mdt mdt, HttpResponse response) {
            List<String> headers = mdt.Headers__c.split('\n');

            for (String keyValue : headers) {
                List<String> keyValueSplit = keyValue.split(':');
                response.setHeader(keyValueSplit[0], keyValueSplit[1]);
            }
        }
    }
}