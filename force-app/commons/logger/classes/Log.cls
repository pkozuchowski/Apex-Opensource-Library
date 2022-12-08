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
 * /
 * *
 *  Please find newest source code at https://github.com/pkozuchowski/Apex-Opensource-Library
 * /
 */

/**
 * Log encapsulated information to be logged.
 * This class can be extended to provide context-specific logs.
 */
public with sharing class Log {
    private static Long t1 = System.currentTimeMillis();
    private LoggingEvent__e log = new LoggingEvent__e();
    private Map<String, Object> parameters = new Map<String, Object>();

    /**
     * Constructs log from simple string message.
     * @param message String to be logged
     */
    public Log(String message) {
        this(new LoggingEvent__e(
            RecordTypeId__c = RecordTypes.LOG_APPLICATION.id,
            Message__c = message
        ));
    }

    /**
     * Constructs log from an Exception.
     * @param ex Exception to be logged, along with all causes.
     */
    public Log(Exception ex) {
        this(new LoggingEvent__e(
            RecordTypeId__c = RecordTypes.LOG_APPLICATION.id,
            Message__c = Stringifier.toString(ex)
        ));
    }

    /**
     * Constructs log from outbound Http callout.
     * @param request Outbound HTTP callout
     * @param response Response from external service
     */
    public Log(HttpRequest request, HttpResponse response) {
        this(new LoggingEvent__e(
            RecordTypeId__c = RecordTypes.LOG_CALLOUT.id,
            Outbound__c = true,
            Request__c = Stringifier.toString(request),
            Response__c = Stringifier.toString(response),
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
            RecordTypeId__c = RecordTypes.LOG_CALLOUT.id,
            Outbound__c = false,
            Request__c = Stringifier.toString(request),
            Response__c = Stringifier.toString(response),
            HttpStatus__c = '' + response.statusCode
        ));
    }

    private Log(LoggingEvent__e log) {
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

    public Log withParameter(String param, Object value) {
        this.parameters.put(param, value);
        return this;
    }

    /**
     * Saves parameters of the logged method.
     */
    public Log withParameters(Map<String, Object> parameters) {
        this.parameters.putAll(parameters);
        return this;
    }

    public Log withTimeMetric() {
        this.log.ExecutionTime__c = System.currentTimeMillis() - t1;
        return this;
    }

    /**
     * Saves Execution time for performance metrics
    */
    public Log withTimeMetric(Long timeMs) {
        this.log.ExecutionTime__c = timeMs;
        return this;
    }

    /**
     * Saves Execution time since given start time.
     */
    public Log withTimeMetric(Datetime startTime) {
        this.log.ExecutionTime__c = System.currentTimeMillis() - startTime.getTime();
        return this;
    }

    /**
     * @return Log__c record constructed from the data.
     */
    public LoggingEvent__e getLogRecord() {
        if (!parameters.isEmpty()) {
            this.log.Parameters__c = JSON.serializePretty(parameters);
        }
        return this.log;
    }
}