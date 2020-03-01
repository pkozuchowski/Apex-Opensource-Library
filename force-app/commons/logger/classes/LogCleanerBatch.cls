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
 * This batch is responsible for deleting logs past retention date.
 */
public without sharing class LogCleanerBatch implements Database.Batchable<SObject>, Schedulable {
    @TestVisible
    private static String SCHEDULE_JOB_NAME = 'Log Cleaner Batch';

    /**
     * Schedules batch to run daily at 2 am.
     */
    public static void scheduleDailyRun() {
        System.schedule(SCHEDULE_JOB_NAME, '0 0 2 * * ?', new LogCleanerBatch());
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(this);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date infoDate = LoggerSettings.getRetentionDate(LoggingLevel.INFO);
        Date warnDate = LoggerSettings.getRetentionDate(LoggingLevel.WARN);
        Date errorDate = LoggerSettings.getRetentionDate(LoggingLevel.ERROR);


        return Database.getQueryLocator('SELECT ID' +
                ' FROM Log__c' +
                ' WHERE (LoggingLevel__c = \'INFO\' AND CreatedDate < :infoDate)' +
                '    OR (LoggingLevel__c = \'WARN\' AND CreatedDate < :warnDate)' +
                '    OR (LoggingLevel__c = \'ERROR\' AND CreatedDate < :errorDate)'
        );
    }

    public void execute(Database.BatchableContext bc, List<Log__c> logs) {
        delete logs;
    }

    public void finish(Database.BatchableContext bc) {
    }
}