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
 * @dependency core/Apex
 */
public with sharing class Logger {
    private Boolean immediate;
    private List<Log__c> logs = new List<Log__c>();

    public Logger() {
        this(false);
    }

    public Logger(Boolean immediate) {
        this.immediate = immediate;
    }

    /**
     * Logs message with INFO logging level
     */
    public void info(String message) {
        log(LoggingLevel.INFO, message);
    }
    public void info(Log__c log) {
        log(LoggingLevel.INFO, log);
    }


    /**
     * Logs message with WARNING logging level
     */
    public void warn(String message) {
        log(LoggingLevel.WARN, message);
    }
    public void warn(Log__c log) {
        log(LoggingLevel.WARN, log);
    }


    /**
     * Logs message with WARNING logging level
     */
    public void error(String message) {
        log(LoggingLevel.ERROR, message);
    }
    public void error(Log__c log) {
        log(LoggingLevel.ERROR, log);
    }
    public void error(Exception ex) {
        log(LoggingLevel.ERROR, ex, null);
    }
    public void error(Exception ex, Id referenceId) {
        log(LoggingLevel.ERROR, ex, referenceId);
    }


    /**
     * Logs message with given logging level
     */
    public void log(LoggingLevel loggingLevel, String message) {
        log(loggingLevel, new Log__c(
                Message__c = message
        ));
    }

    /**
     * Logs exception with given logging level
     */
    public void log(LoggingLevel loggingLevel, Exception ex, Id referenceId) {
        log(loggingLevel, new Log__c(
                Message__c = ex.getMessage() + '\n' + ex.getStackTraceString(),
                ReferenceId__c = referenceId
        ));
    }

    /**
     * Logs log object with given logging level
     */
    public void log(LoggingLevel loggingLevel, Log__c log) {
        log.ApexClass__c = Apex.getRunningClass();
        log.LoggingLevel__c = loggingLevel.name();
        logs.add(log);

        if (immediate) {
            flush();
        }
    }


    /**
     * Publishes all recorded logs and clears log buffer.
     * When logging is done in-between callouts, flush should be made after all callouts are finished.
     */
    public void flush() {
        insert logs;
        logs.clear();
    }
}