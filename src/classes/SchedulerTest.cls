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

        System.debug(JSON.serializePretty([SELECT NextFireTime,CronExpression FROM CronTrigger WHERE Id = :jobId]));

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
        Test.startTest();
        Id jobId = new Scheduler().scheduleWeekly('Test weekly schedule', 'MON', new TestSchedulable());
        Test.stopTest();

        Date today = Date.today();
        Date nextMonday = today.toStartOfWeek().addDays(7);

        System.assertEquals(nextMonday, getNextFireTime(jobId).date());
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