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

/**
 * Log encapsulated information to be logged.
 * This class can be extended to provide context-specific logs.
 */
public with sharing class Log {
    private LoggingEvent__e log = new LoggingEvent__e();
    private Map<String, Object> inputs = new Map<String, Object>();

    /**
     * Constructs log from simple string message.
     * @param message String to be logged
     */
    public Log(String message) {
        this(new LoggingEvent__e(
            Response__c = message
        ));
    }

    /**
     * Constructs log from an Exception.
     * @param ex Exception to be logged, along with all causes.
     */
    public Log(Exception ex) {
        this(new LoggingEvent__e(
            Response__c = LogStringifier.toString(ex)
        ));
    }

    /**
     * Constructs log from outbound Http callout.
     * @param request Outbound HTTP callout
     * @param response Response from external service
     */
    public Log(HttpRequest request, HttpResponse response) {
        this(new LoggingEvent__e(
            Request__c = LogStringifier.toString(request),
            Response__c = LogStringifier.toString(response),
            HttpStatus__c = '' + response.getStatusCode()
        ));
    }

    /**
     * Populates log fields from inbound REST request
     * @param request Inbound REST request
     * @param response Response for the request
     */
    public Log(RestRequest request, RestResponse response) {
        this(new LoggingEvent__e(
            Request__c = LogStringifier.toString(request),
            Response__c = LogStringifier.toString(response),
            HttpStatus__c = '' + response.statusCode
        ));
    }

    public Log(LoggingEvent__e log) {
        this.log = log;
        this.log.UserId__c = UserInfo.getUserId();
    }

    /**
     * Saves reference Id on the log.
     */
    public Log withReferenceId(String referenceId) {
        this.log.ReferenceId__c = referenceId;
        return this;
    }

    /**
     * Saves called method parameter.
     */
    public Log withInput(String param, Object value) {
        if (String.isNotBlank(param)) {
            this.inputs.put(param, value);
        }
        return this;
    }

    public Log withInputs(Object param1) {
        return withInputs(new List<Object>{param1});
    }

    public Log withInputs(Object param1, Object param2) {
        return withInputs(new List<Object>{param1, param2});
    }

    public Log withInputs(Object param1, Object param2, Object param3) {
        return withInputs(new List<Object>{param1, param2, param3});
    }

    public Log withInputs(List<Object> params) {
        for (Integer i = 0; i < params.size(); i++) {
            withInput('' + i, params[i]);
        }
        return this;
    }

    /**
     * Saves parameters of the logged method.
     */
    public Log withInputs(Map<String, Object> parameters) {
        if (parameters != null) {
            this.inputs.putAll(parameters);
        }
        return this;
    }

    /**
     * Saves Execution time for performance metrics.
    */
    public Log withExecutionTime(Long timeMs) {
        this.log.ExecutionTime__c = timeMs;
        return this;
    }

    /**
     * Saves Execution time since given start time.
     */
    public Log withExecutionTime(Datetime startTime) {
        this.log.ExecutionTime__c = System.currentTimeMillis() - startTime.getTime();
        return this;
    }

    /**
     * Sets log's source (ex. Apex Class which created the log or callout)
     */
    public Log withSource(String source) {
        this.log.Source__c = source;
        return this;
    }

    /**
     * @return Log__c record constructed from the data.
     */
    public LoggingEvent__e getLogRecord() {
        if (!inputs.isEmpty()) {
            this.log.Request__c = JSON.serializePretty(inputs);
        }
        return this.log;
    }
}