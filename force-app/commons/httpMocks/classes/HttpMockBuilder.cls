/**
* HttpMockBuilder class for constructing HTTP callout mock responses with fluent API.
* Allows step-by-step configuration of status codes, headers, and response bodies.
*/
public virtual class HttpMockBuilder implements HttpCalloutMock {
    private HttpCalloutMock mock;
    private Map<String, String> headers = new Map<String, String>();
    private Integer statusCode;
    private String status;
    private String body;

    public HttpMockBuilder() {}

    /**
     * Creates Http mock which responds with given status and body.
     */
    public HttpMockBuilder(HttpCalloutMock mock) {
        this.mock = mock;
    }

    /**
     * Sets the HTTP status code and status message for the response.
     */
    public HttpMockBuilder status(Integer statusCode, String status) {
        this.statusCode = statusCode;
        this.status = status;
        return this;
    }

    /**
     * Adds a header to the HTTP response.
     */
    public HttpMockBuilder header(String key, String value) {
        this.headers.put(key, value);
        return this;
    }

    /**
     * Sets the response body content as a string.
     * @param body The response body content
     */
    public HttpMockBuilder body(String body) {
        this.body = body;
        return this;
    }

    /**
     * Serializes an object to JSON format and sets it as the response body.
     * @param toSerialize The object to be serialized to JSON
     */
    public HttpMockBuilder json(Object toSerialize) {
        this.body = JSON.serialize(toSerialize, true);
        return this;
    }

    /**
     * Builds response from applied
     */
    public virtual HttpResponse respond(HttpRequest request) {
        HttpResponse response = this.mock?.respond(request) ?? new HttpResponse();

        if (this.statusCode != null) {
            response.setStatusCode(this.statusCode);
            response.setStatus(this.status);
        }

        for (String key : this.headers.keySet()) {
            response.setHeader(key, this.headers.get(key));
        }

        if (this.body != null) {
            response.setBody(this.body);
        }

        return response;
    }
}