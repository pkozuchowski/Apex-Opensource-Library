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

@SuppressWarnings('PMD.ApexAssertionsShouldIncludeMessage')
@IsTest
private class LogCleanerBatchTest {
    private final static Integer BATCH_SIZE = 200;

    @TestSetup
    static void testSetup() {
        List<Log__c> logsToInsert = new List<Log__c>();

        for (Integer i = 0; i < BATCH_SIZE; i++) {
            Decimal random = Math.random();

            logsToInsert.add(new Log__c(
                Response__c = 'Test',
                Severity__c = random < 0.33 ? 'INFO' : random < 0.66 ? 'WARN' : 'ERROR',
                Source__c = 'LogCleanerBatchTest'
            ));
        }

        insert logsToInsert;


        for (Log__c log : logsToInsert) {
            Integer randomUpTo100 = Math.round(Math.random() * 100);
            Test.setCreatedDate(log.Id, Date.today().addDays(-randomUpTo100));
        }
    }


    /**
     * LoggerSetting__mdt custom metadata contains configuration for how many days logs of each severity should be retained.
     * Logs which pass retention date counted since CreateDate should be deleted by daily batch.
     */
    @IsTest
    static void testLogsShouldBeDeletedAfterPassingRetentionDate() {
        LoggerSettings.settingByLoggingLevel = new Map<String, LoggerSetting__mdt>{
            LoggingLevel.INFO.name() => new LoggerSetting__mdt(RetentionDays__c = 7),
            LoggingLevel.WARN.name() => new LoggerSetting__mdt(RetentionDays__c = 21),
            LoggingLevel.ERROR.name() => new LoggerSetting__mdt(RetentionDays__c = 60)
        };


        Test.startTest();
        Database.executeBatch(new LogCleanerBatch(), BATCH_SIZE);
        Test.stopTest();


        Assert.areEqual(0, getLogCount('INFO', -7));
        Assert.areEqual(0, getLogCount('WARN', -21));
        Assert.areEqual(0, getLogCount('ERROR', -60));
    }

    private static Integer getLogCount(String severity, Integer daysOffset) {
        return [SELECT COUNT() FROM Log__c WHERE CreatedDate < :Date.today().addDays(daysOffset) AND Severity__c = :severity];
    }


    @IsTest
    static void testSchedule() {
        Test.startTest();
        LogCleanerBatch.scheduleDailyRun();
        Test.stopTest();


        Assert.areEqual(1, [SELECT COUNT() FROM CronJobDetail WHERE Name = :LogCleanerBatch.SCHEDULE_JOB_NAME]);
    }
}