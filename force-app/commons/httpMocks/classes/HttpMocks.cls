/**
* SPDX-License-Identifier: MIT
* Copyright 2019 Piotr Kożuchowski
* apexlibra.org
*/

/**
 * Simple mock constructed with given Http status and response body
 */
public virtual with sharing class HttpMocks {

    /**
     * @return List of handled HttpRequests in the order they were issued.
     */
    public static List<HttpRequest> getRequests() {
        return HttpCalloutMockRouter.REQUESTS;
    }

    /**
     * @return List of returned HttpResponses in order they were returned.
     */
    public static List<HttpResponse> getResponses() {
        return HttpCalloutMockRouter.RESPONSES;
    }

    /**
     * @return Router with all custom metadata mocks loaded.
     */
    public static HttpCalloutMockRouter config() {
        return new HttpMocksConfigRouter();
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

    /**
     * @return Http Mock Builder
     */
    public static Builder builder() {
        return new Builder();
    }

    /**
     * Creates JSON response mock
     */
    public static HttpCalloutMock json(Integer statusCode, String status, Object jsonObject) {
        return new Builder(statusCode, status, JSON.serialize(jsonObject));
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
        return new Builder(statusCode, status, body);
    }


    public class Builder implements HttpCalloutMock {
        private HttpResponse response = new HttpResponse();

        private Builder() {}

        /**
         * Creates Http mock which responds with given status and body.
         */
        private Builder(Integer statusCode, String status, String body) {
            this.response.setStatusCode(statusCode);
            this.response.setStatus(status);
            this.response.setBody(body == null ? '' : body);
        }

        public Builder status(Integer statusCode, String status) {
            this.response.setStatusCode(statusCode);
            this.response.setStatus(status);
            return this;
        }

        public Builder header(String key, String value) {
            this.response.setHeader(key, value);
            return this;
        }

        public Builder body(String body) {
            this.response.setBody(body);
            return this;
        }

        public Builder json(Object toSerialize) {
            this.response.setBody(JSON.serialize(toSerialize));
            return this;
        }

        public HttpResponse respond(HttpRequest request) {
            return response;
        }
    }


    @TestVisible
    private virtual class ConfigMock implements HttpCalloutMock {
        private HttpCalloutMock__mdt config;

        public ConfigMock(HttpCalloutMock__mdt config) {
            this.config = config;
        }

        public HttpResponse respond(HttpRequest request) {
            HttpCalloutMock mock;

            if (String.isNotBlank(config.StaticResource__c)) {
                mock = staticResource((Integer) config.StatusCode__c, config.Status__c, config.StaticResource__c);

            } else if (String.isNotBlank(config.ApexClass__c)) {
                mock = (HttpCalloutMock) Type.forName(
                    config.ApexClassNamespace__c,
                    config.ApexClass__c
                ).newInstance();

            } else {
                if (String.isNotBlank(config.Response__c)) {
                    config = getResponse(config.DeveloperName);
                }
                mock = text((Integer) config.StatusCode__c, config.Status__c, config.Response__c);
            }

            HttpResponse response = mock.respond(request);
            if (String.isNotBlank(config.Headers__c)) {
                setHeaders(config, response);
            }

            return response;
        }

        /**
         * Retrieves a specific HTTP callout mock by developer name.
         * If the Response__c field exceeds 255 characters, queries the full record to avoid Salesforce's text truncation.
         * @param developerName The developer name of the HttpCalloutMock__mdt record
         * @return The HttpCalloutMock__mdt record with complete response data
         */
        private HttpCalloutMock__mdt getResponse(String developerName) {
            Boolean isMocked = String.isBlank(config.Id);

            if (isMocked || config.Response__c.length() < 255) {
                return config;

            } else {
                //Salesforce trims long texts to 255
                return [
                    SELECT DeveloperName, ApexClass__c, ApexClassNamespace__c,
                        Status__c, StatusCode__c, Response__c,
                        StaticResource__c, Headers__c
                    FROM HttpCalloutMock__mdt
                    WHERE DeveloperName = :developerName
                    WITH USER_MODE
                ];
            }
        }

        private void setHeaders(HttpCalloutMock__mdt mdt, HttpResponse response) {
            List<String> headers = mdt.Headers__c.split('\n');

            for (String keyValue : headers) {
                List<String> keyValueSplit = keyValue.split(':', 2);
                response.setHeader(keyValueSplit[0].trim(), keyValueSplit[1].trim());
            }
        }
    }
}