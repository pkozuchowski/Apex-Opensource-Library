/**
 *  MIT License
 *
 *  Copyright (c) 2023 Piotr Kożuchowski
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

public virtual class Callout {
    private static final Http http = new Http();

    public CalloutConditions match = new CalloutConditions();
    public CalloutHandlers action = new CalloutHandlers();

    protected HttpRequest request = new HttpRequest();
    protected HttpResponse response;
    protected String loggedName;
    protected Type responseType;

    private CalloutHandlersList onBeforeCalloutHandlers;
    private CalloutHandlersList onAfterCalloutHandlers;
    private Boolean paramsSet = false;
    private List<String> queryParams = new List<String>();
    private Long duration { get; private set; }
    private CalloutException ex;

    /**
     * Represents an action performed on callout
     */
    public interface Handler {
        Object handle(Callout c);
    }

    public Callout() {}

    /**
     * @return Callout Handlers run before callout
     */
    public CalloutHandlersList onBeforeCallout() {
        initHandlers();
        return onBeforeCalloutHandlers;
    }

    /**
     * @return Callout Handlers run after callout
     */
    public CalloutHandlersList onAfterCallout() {
        initHandlers();
        return onAfterCalloutHandlers;
    }

    /**
     * Handlers are lazily loaded, because some handlers may want to use variables set on the callout
     * ex. responseType.
     *
     * This approach allows setting values on the callout, before handlers are initialized.
     */
    private void initHandlers() {
        if (onBeforeCalloutHandlers == null) {
            this.onBeforeCalloutHandlers = new CalloutHandlersList();
            this.onAfterCalloutHandlers = new CalloutHandlersList();
            setupHandlers();
        }
    }

    protected virtual void setupHandlers() {
        onAfterCallout()
            .add(match.onUnauthorized(), action.retry(1))
            .add(match.onTimeout(), action.retry(1))
            .slot('beforeValidation')
            .add(match.onAnyErrorCode(), action.logCallout(LoggingLevel.ERROR))
            .add(match.onAnyErrorCode(), action.throwEx())
            .add(match.onSuccess(), action.logCallout(LoggingLevel.INFO))
            .add(match.onSuccess(), action.returnJSON(responseType));
    }

    /**
     * Sets HTTP Method (GET, POST, DELETE, HEAD, PATCH, PUT, TRACE)
     */
    public void setMethod(String method) {
        this.request.setMethod(method);
    }

    /**
     * Specifies the endpoint for this request.
     */
    public void setEndpoint(String endpoint) {
        this.request.setEndpoint(endpoint);
    }

    /**
     * Sets a timeout for the request between 1 and 120,000 milliseconds.
     * The timeout is the maximum time to wait for establishing the HTTP connection.
     */
    public void setTimeout(Integer timeout) {
        this.request.setTimeout(timeout);
    }

    /**
     * Sets the contents of the request header.
     */
    public void setHeader(String header, String value) {
        if (String.isNotEmpty(value)) {
            this.request.setHeader(header, value);
        }
    }

    /**
     * Sets headers from map
     */
    public void setHeaders(Map<String, String> headersMap) {
        for (String headerKey : headersMap.keySet()) {
            setHeader(headerKey, headersMap.get(headerKey));
        }
    }

    /**
     * Sets the contents of the body for this request.
     */
    public void setBody(String body) {
        this.request.setBody(body);
    }

    /**
     * Serializes object to string and sets it as body of this request.
     */
    public void setBodyJSON(Object o, Boolean suppressNulls) {
        setHeader('Content-Type', 'application/json');
        setBody(JSON.serialize(o, suppressNulls));
    }

    /**
     * @return Identifier of class/source that created log.
     */
    public String getLogName() {
        return String.isBlank(loggedName)
            ? String.format('{0} {1}', new List<Object>{
                request.getMethod(),
                request.getEndpoint()?.substringBefore('?')
            })
            : loggedName;
    }

    /**
     * Sets ApexClass field on log. If not specified, it will default to endpoint before query parameters.
     */
    public void setLogName(String logName) {
        this.loggedName = logName;
    }

    /**
     * Sets query params from given map. Value can be either String or List<String>
     */
    public void setParams(Map<String, Object> params, Boolean urlEncode) {
        for (String param : params.keySet()) {
            Object val = params.get(param);

            if (val instanceof List<Object>) {
                setParams(param, (List<String>) val, urlEncode);
            } else {
                setParam(param, '' + val, urlEncode);
            }
        }
    }

    /**
     * Adds query parameter to url
     */
    public void setParam(String name, Object value, Boolean urlEncode) {
        String valueStr = value == null ? '' : ('' + value);
        valueStr = urlEncode ? EncodingUtil.urlEncode(valueStr, 'UTF-8') : valueStr;
        queryParams.add(name + '=' + valueStr);
    }

    /**
     * Adds query list parameter as follows:
     * ?id=xx1&id=xx2&id=xx3...
     */
    public void setParams(String name, List<Object> values, Boolean urlEncode) {
        for (Object val : values) {
            setParam(name, val, urlEncode);
        }
    }


    /**
     * Success response will deserialize body to this type and return it from execute
     */
    public void setResponseType(Type apexType) {
        this.responseType = apexType;
    }

    /**
     * @return Latest HttpResponse of the callout
     */
    public HttpResponse getResponse() {
        return response;
    }

    /**
     * @return HttpRequest of the callout
     */
    public HttpRequest getRequest() {
        return request;
    }

    /**
     * @return Callout Exception for the latest
     */
    public CalloutException getCalloutException() {
        return ex;
    }


    /**
     * Executes callout and before/after callout handlers.
     * @return If any handler returned something else than null, then that value is returned.
     * If responseType is set, then response body is deserialized to that type.
     * In other cases, HttpResponse is returned.
     */
    public virtual Object execute() {
        setParams();
        onBeforeCallout().execute(this);
        this.response = sendCallout();
        Object handlerResponse = onAfterCallout().execute(this);
        return getResult(handlerResponse);
    }

    private void setParams() {
        if (paramsSet == false && !queryParams.isEmpty()) {
            setEndpoint(request.getEndpoint() + '?' + String.join(queryParams, '&'));
            paramsSet = true;
        }
    }

    /**
     * Sends http request and saves duration and exception
     */
    private HttpResponse sendCallout() {
        Long startTime = System.currentTimeMillis();
        try {
            this.ex = null;
            return http.send(request);

        } catch (CalloutException e) {
            this.ex = e;
            return null;

        } finally {
            this.duration = System.currentTimeMillis() - startTime;
        }
    }

    /**
     * Returns callout result - handler's value, deserialized response or http response
     */
    private Object getResult(Object handlerResponse) {
        if (handlerResponse != null) {
            return handlerResponse;

        } else if (responseType != null) {
            return JSON.deserialize(response.getBody(), responseType);

        } else {
            return response;
        }
    }
}