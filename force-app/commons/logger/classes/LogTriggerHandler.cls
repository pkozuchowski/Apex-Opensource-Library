/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2024 Piotr Kożuchowski
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
 */
public with sharing class LogTriggerHandler {
    private List<LoggerDataMaskPattern__mdt> dataMasks = [
        SELECT Pattern__c
        FROM LoggerDataMaskPattern__mdt
        WHERE Active__c = TRUE
    ];

    public void insertLogs(List<LoggingEvent__e> events) {
        List<Log__c> logs = new List<Log__c>();

        for (LoggingEvent__e loggingEvent : events) {
            logs.add(new Log__c(
                Source__c = loggingEvent.Source__c,
                ExecutionTime__c = loggingEvent.ExecutionTime__c,
                Severity__c = loggingEvent.Severity__c,
                ReferenceId__c = loggingEvent.ReferenceId__c,
                Request__c = getSanitizedString(loggingEvent.Request__c),
                RequestId__c = loggingEvent.RequestId__c,
                Quiddity__c = loggingEvent.Quiddity__c,
                Response__c = getSanitizedString(loggingEvent.Response__c),
                User__c = loggingEvent.UserId__c
            ));
        }

        insert logs;
    }

    private String getSanitizedString(String value) {
        String newValue = value;
        if (String.isNotBlank(newValue)) {
            for (LoggerDataMaskPattern__mdt mdt : dataMasks) {
                newValue = newValue.replaceAll(mdt.Pattern__c, 'XXX');
            }
        }
        return newValue;
    }
}