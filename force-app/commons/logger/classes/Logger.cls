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
 * Logs persistent messages in custom object records and emits platform event.
 *
 * @dependency commmons.core.Apex
 * @see Apex
 */
public with sharing class Logger {
    private Boolean immediate;
    private List<Log__c> logs = new List<Log__c>();

    /**
     * Default constructor works in immediate mode.
     * This is preferred mode for controllers and async apex.
     */
    public Logger() {
        this(true);
    }

    /**
     * @param immediate If true, flushes logs immediately after logging action.
     * Immediate mode is preferred in situation of multiple subsequent callouts
     * and when you want to reuse one logger (trigger?)
     */
    public Logger(Boolean immediate) {
        this.immediate = immediate;
    }

    /**
     * Logs message with INFO logging level
     */
    public void info(String message) {
        info(null, message);
    }
    public void info(String referenceId, String message) {
        log(LoggingLevel.INFO, referenceId, message);
    }
    public void info(Log__c log) {
        log(LoggingLevel.INFO, log);
    }
    public void info(String referenceId, Exception ex) {
        log(LoggingLevel.INFO, referenceId, ex);
    }
    public void info(String referenceId, HttpRequest request, HttpResponse response) {
        log(LoggingLevel.INFO, referenceId, request, response);
    }

    /**
     * Logs message with WARNING logging level
     */
    public void warn(String message) {
        warn(null, message);
    }
    public void warn(String referenceId, String message) {
        log(LoggingLevel.WARN, referenceId, message);
    }
    public void warn(Log__c log) {
        log(LoggingLevel.WARN, log);
    }
    public void warn(String referenceId, Exception ex) {
        log(LoggingLevel.WARN, referenceId, ex);
    }
    public void warn(String referenceId, HttpRequest request, HttpResponse response) {
        log(LoggingLevel.WARN, referenceId, request, response);
    }

    /**
     * Logs message with WARNING logging level
     */
    public void error(String message) {
        error(null, message);
    }
    public void error(String referenceId, String message) {
        log(LoggingLevel.ERROR, referenceId, message);
    }
    public void error(Log__c log) {
        log(LoggingLevel.ERROR, log);
    }
    public void error(Exception ex) {
        error(null, ex);
    }
    public void error(String referenceId, Exception ex) {
        log(LoggingLevel.ERROR, referenceId, ex);
    }
    public void error(String referenceId, HttpRequest request, HttpResponse response) {
        log(LoggingLevel.ERROR, referenceId, request, response);
    }


    /**
     * Logs message with given logging level
     */
    public void log(LoggingLevel loggingLevel, String message) {
        log(loggingLevel, null, message);
    }
    public void log(LoggingLevel loggingLevel, String referenceId, String message) {
        log(loggingLevel, new Log__c(
                ReferenceId__c = referenceId,
                Message__c = message
        ));
    }

    /**
     * Logs exception with given logging level
     */
    public void log(LoggingLevel loggingLevel, String referenceId, Exception ex) {
        log(loggingLevel, new Log__c(
                Message__c = format(ex),
                ReferenceId__c = referenceId
        ));
    }

    /**
     * Formats and logs Http request and response (null-safe).
     */
    public void log(LoggingLevel loggingLevel, String referenceId, HttpRequest request, HttpResponse response) {
        log(loggingLevel, new Log__c(
                ReferenceId__c = referenceId,
                Message__c = String.join(new List<String>{
                        format(request),
                        format(response)
                }, '\n\n')
        ));
    }


    /**
     * Logs log object with given logging level
     */
    public void log(LoggingLevel loggingLevel, Log__c log) {
        if (LoggingSettings.shouldCreateLog(loggingLevel)) {
            log.ApexClass__c = getApexClass();
            log.LoggingLevel__c = loggingLevel.name();
            logs.add(log);

            if (immediate) {
                flush();
            }
        }
    }


    /**
     * Publishes all recorded logs and clears log buffer.
     * When logging is done in-between callouts, flush should be made after all callouts are finished.
     *
     * Logs are translated to Platform Event and then back from events to records to maintain logs created before unhandled exception.
     * This is mainly for AuraEnabled methods which may have to throw AuraHandledException for proper aura handling,
     * but would not be able to save logs under normal circumstances.
     */
    public void flush() {
        List<LoggingEvent__e> loggingEvents = new List<LoggingEvent__e>();

        for (Log__c log : logs) {
            loggingEvents.add(new LoggingEvent__e(
                    ApexClass__c = log.ApexClass__c,
                    LoggingLevel__c = log.LoggingLevel__c,
                    Message__c = log.Message__c,
                    ReferenceId__c = log.ReferenceId__c,
                    UserId__c = UserInfo.getUserId()
            ));
        }

        EventBus.publish(loggingEvents);
        logs.clear();
    }


    /**
     * @return Name of the first class in stack trace which is not Logger.
     */
    private String getApexClass() {
        List<Apex.StackTraceLine> stackTraceLines = Apex.getStackTrace();

        for (Integer i = 0; i < stackTraceLines.size(); i++) {
            if (stackTraceLines[i].apexClass != 'Logger') {
                return stackTraceLines[i].method;
            }
        }

        return '';
    }

    private String format(Exception ex) {
        if (ex != null) {
            return ex.getTypeName() + ': ' + ex.getMessage()
                    + '\n' + ex.getStackTraceString().substringBefore('Caused by')
                    + (ex.getCause() != null ? '\nCaused by\n' + format(ex.getCause()) : '');

        } else {
            return '';
        }
    }

    private String format(HttpRequest request) {
        if (request != null) {
            return request.getMethod() + ' ' + request.getEndpoint() + '\n'
                    + request.getBody();
        } else {
            return '';
        }
    }

    private String format(HttpResponse response) {
        if (response != null) {
            List<String> requestHeaders = new List<String>();
            for (String header : response.getHeaderKeys()) {
                requestHeaders.add(header + ':' + response.getHeader(header));
            }

            return 'Response:\n'
                    + response.getStatusCode() + ' ' + response.getStatus()
                    + '\n' + String.join(requestHeaders, '\n')
                    + '\n\n' + response.getBody();
        } else {
            return '';
        }
    }
}