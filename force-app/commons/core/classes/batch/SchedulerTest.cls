/**
* MIT License
*
* Copyright (c) 2018 Piotr Kożuchowski
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
@IsTest
private class SchedulerTest {

    @IsTest
    static void testScheduleEvery5Minutes() {
        Test.startTest();
        List<Id> jobIds = new Scheduler().scheduleEveryXMinutes('Test every X schedule', 5, new TestSchedulable());
        Test.stopTest();


        List<CronTrigger> triggers = [SELECT NextFireTime FROM CronTrigger WHERE Id IN :jobIds];
        for (Integer i = 0; i < triggers.size(); i++) {
            System.assertEquals(i * 5, triggers[i].NextFireTime.minute());
        }
    }

    @IsTest
    static void testScheduleEvery15Minutes() {
        Test.startTest();
        List<Id> jobIds = new Scheduler().scheduleEveryXMinutes('Test every X schedule', 15, new TestSchedulable());
        Test.stopTest();


        List<CronTrigger> triggers = [SELECT NextFireTime FROM CronTrigger WHERE Id IN :jobIds];
        System.assertEquals(0, triggers[0].NextFireTime.minute());
        System.assertEquals(15, triggers[1].NextFireTime.minute());
        System.assertEquals(30, triggers[2].NextFireTime.minute());
        System.assertEquals(45, triggers[3].NextFireTime.minute());
    }

    @IsTest
    static void testScheduleEvery30Minutes() {
        Test.startTest();
        List<Id> jobIds = new Scheduler().scheduleEveryXMinutes('Test every X schedule', 30, new TestSchedulable());
        Test.stopTest();


        List<CronTrigger> triggers = [SELECT NextFireTime FROM CronTrigger WHERE Id IN :jobIds];
        System.assertEquals(0, triggers[0].NextFireTime.minute());
        System.assertEquals(30, triggers[1].NextFireTime.minute());
    }

    @IsTest
    static void testScheduleEvery45Minutes() {
        try {
            Test.startTest();
            List<Id> jobIds = new Scheduler().scheduleEveryXMinutes('Test every X schedule', 45, new TestSchedulable());
            Test.stopTest();

            System.assert(false);
        } catch (Scheduler.SchedulerException ex) {
        }
    }

    @IsTest
    static void testScheduleHourly() {
        Test.startTest();
        Id jobId = new Scheduler().scheduleHourly('Test hourly schedule', 30, new TestSchedulable());
        Test.stopTest();

        Datetime now = Datetime.now();
        Datetime expected = Datetime.newInstance(
                now.year(),
                now.month(),
                now.day(),
                now.minute() > 30 ? (now.hour() + 1) : now.hour(),
                30,
                0
        );

        System.assertEquals(expected, getNextFireTime(jobId));
    }

    @IsTest
    static void testScheduleDaily() {
        Test.startTest();
        Id jobId = new Scheduler().scheduleDaily('Test daily schedule', 12, 15, new TestSchedulable());
        Test.stopTest();


        Datetime now = Datetime.now();
        Datetime expected = Datetime.newInstance(
                now.year(),
                now.month(),
                (now.hour() > 12 || (now.hour() == 12 && now.minute() > 15)) ? now.day() + 1 : now.day(),
                12,
                15,
                0
        );

        System.assertEquals(expected, getNextFireTime(jobId));
    }

    @IsTest
    static void testScheduleWeekly() {
        User usr = new User(
                Id = UserInfo.getUserId(),
                TimeZoneSidKey = 'GMT',
                LocaleSidKey = 'pl'
        );
        update usr;

        System.runAs(usr) {
            Test.startTest();
            Id jobId = new Scheduler().scheduleWeekly('Test weekly schedule', 'MON', new TestSchedulable());
            Test.stopTest();

            Date today = Date.today();
            Date nextMonday = today.toStartOfWeek().addDays(7);

            System.assertEquals(nextMonday, getNextFireTime(jobId).date());
        }
    }

    @IsTest
    static void testScheduleMonthly() {
        Test.startTest();
        Id jobId = new Scheduler().scheduleMonthly('Test monthly schedule', '1', new TestSchedulable());
        Test.stopTest();

        Date today = Date.today();
        Date startOfMonth = today.toStartOfMonth().addMonths(1);

        System.assertEquals(startOfMonth, getNextFireTime(jobId).date());
    }

    private static Datetime getNextFireTime(Id jobId) {
        return [SELECT NextFireTime FROM CronTrigger WHERE Id = :jobId].NextFireTime;
    }

    private class TestSchedulable implements Schedulable {
        public void execute(SchedulableContext param1) {
        }
    }
}