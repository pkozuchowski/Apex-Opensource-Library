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
 * @dependency:
  * @see Runtime
 *  @see Stringifier
 */
public with sharing class Logger {
    private Stringifier stringifier = new Stringifier();
    private Boolean immediate;
    private List<Log__c> logs = new List<Log__c>();

    /**
     * Default constructor works in immediate mode.
     * This is preferred mode for controllers and async apex.
     */
    public Logger() {
        this(true);
    }

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
    public void info(String referenceId, RestRequest request, RestResponse response) {
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
    public void warn(String referenceId, RestRequest request, RestResponse response) {
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
    public void error(String referenceId, RestRequest request, RestResponse response) {
        log(LoggingLevel.ERROR, referenceId, request, response);
    }


    /**
     * Logs ERROR log when condition is not met.
     *
     * @param condition When false, error is logged
     * @param log Message to record
     */
    public void assert(Boolean condition, Log__c log) {
        if (!condition) {
            log(LoggingLevel.ERROR, log);
        }
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
            Message__c = stringifier.toString(ex),
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
                stringifier.toString(request),
                stringifier.toString(response)
            }, '\n\n')
        ));
    }

    /**
     * Formats and logs Http request and response (null-safe).
     */
    public void log(LoggingLevel loggingLevel, String referenceId, RestRequest request, RestResponse response) {
        log(loggingLevel, new Log__c(
            ReferenceId__c = referenceId,
            Message__c = String.join(new List<String>{
                '<Request>\n' + stringifier.toString(request),
                '<Response>\n' + stringifier.toString(response)
            }, '\n\n')
        ));
    }


    /**
     * Logs log object with given logging level
     */
    public void log(LoggingLevel loggingLevel, Log__c log) {
        if (LoggerSettings.shouldCreateLog(loggingLevel)) {
            log.ApexClass__c = Runtime.getCaller().apexClassMethod;
            log.LoggingLevel__c = loggingLevel.name();
            logs.add(log);
            System.debug(loggingLevel, JSON.serializePretty(log));

            if (immediate == true) {
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
}