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
 * Name of the apex class is resolved automatically using Runtime class.
 */
public with sharing class Logger {

    /**
     * Logs message with INFO logging level
     */
    public static void info(Log log) {
        log(LoggingLevel.INFO, log);
    }

    /**
     * Logs message with WARNING logging level
     */
    public static void warn(Log log) {
        log(LoggingLevel.WARN, log);
    }

    /**
     * Logs message with WARNING logging level
     */
    public static void error(Log log) {
        log(LoggingLevel.ERROR, log);
    }

    /**
     * Logs message with given logging level
     */
    public static void log(LoggingLevel loggingLevel, Log log) {
        if (LoggerSettings.shouldCreateLog(loggingLevel)) {
            LoggingEvent__e logRecord = log.getLogRecord();
            if (String.isBlank(logRecord.ApexClass__c)) {
                logRecord.ApexClass__c = Runtime.getCaller().apexClassMethod;
            }
            logRecord.LoggingLevel__c = loggingLevel.name();
            System.debug(loggingLevel, JSON.serializePretty(logRecord));

            emitLogEvent(logRecord);
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
    private static void emitLogEvent(LoggingEvent__e log) {
        EventBus.publish(log);
    }

    private Logger() {}
}