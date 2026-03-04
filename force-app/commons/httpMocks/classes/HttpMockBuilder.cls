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
    private Map<String, String> replacements = new Map<String, String>();
    private Map<String, Object> jsonReplacements = new Map<String, Object>();

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
     * Replaces each substring of a target string in response body
     * with the specified literal replacement sequence replacement.
     * @param target Text to replace
     * @param replacement Replacement
     * @return
     */
    public HttpMockBuilder replaceInBody(String target, String replacement) {
        replacements.put(target, replacement);
        return this;
    }

    /**
     * Replaces a JSON node at the specified path with the provided object.
     * The response body will be deserialized, modified, and serialized back.
     * @param jsonPath The path to the JSON node to replace (e.g., '.data.records.[0].user.name')
     * @param replacement The object to replace the node with
     * @return
     */
    public HttpMockBuilder replaceInJSON(String jsonPath, Object replacement) {
        jsonReplacements.put(jsonPath, replacement);
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

        applyReplacements(response);

        return response;
    }

    /**
     * Applies substring replacements in body and header.
     */
    private void applyReplacements(HttpResponse response) {
        String body = response.getBody();

        if (String.isNotBlank(body)) {
            for (String target : replacements.keySet()) {
                body = body.replace(target, replacements.get(target));
            }

            if (!jsonReplacements.isEmpty()) {
                Object jsonBody = JSON.deserializeUntyped(body);

                for (String jsonPath : jsonReplacements.keySet()) {
                    setValueAtPath(jsonBody, jsonPath, jsonReplacements.get(jsonPath));
                }

                body = JSON.serialize(jsonBody);
            }

            response.setBody(body);
        }
    }

    /**
     * Sets a value at the specified JSON path in the provided map.
     * @param jsonMap The JSON map to modify
     * @param path The path to the node (e.g., '.data.users.[0].name')
     * @param value The value to set at the path
     */
    private void setValueAtPath(Object jsonBody, String path, Object value) {
        List<String> keys = path.split('\\.');
        Object current = jsonBody;

        for (Integer i = 0; i < keys.size(); i++) {
            String key = keys[i].trim();
            Boolean isLast = i == keys.size() - 1;

            if (String.isNotBlank(key)) {
                // Handle array index notation like 'items[0]'
                if (key.contains('[') && key.contains(']')) {
                    Integer arrayIndex = Integer.valueOf(key.substringBetween('[', ']'));
                    List<Object> items = (List<Object>) current;

                    if (isLast) {
                        items[arrayIndex] = value;
                    } else {
                        current = items[arrayIndex];
                    }

                } else {
                    Map<String, Object> item = (Map<String, Object>) current;

                    if (isLast) {
                        item.put(key, value);
                    } else {
                        current = item.get(key);
                    }
                }
            }
        }
    }
}