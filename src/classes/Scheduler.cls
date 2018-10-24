/**
 * Scheduling helper class for the most common schedule patterns.
 */
public class Scheduler {
    public Integer
            defaultSecond = 0,
            defaultMinute = 0,
            defaultHour = 0;

    /**
     * Schedules a few jobs to run every X minutes in an hour.
     * @param jobName Base name for the job, each job will have minutes concatenated to the name.
     * @param everyMinutes Every how many minutes in hour the job should run. Ex. for value 15,
     * the job will be scheduled on 0, 15, 30 and 45 minute of every hour.
     *
     * @return Scheduled jobs IDs (CronTrigger IDs) in chronological order.
     */
    public List<Id> scheduleEveryXMinutes(String jobName, Integer everyMinutes, Schedulable job) {
        expect(everyMinutes <= 30, 'Cannot schedule jobs to run less than twice an hour, ' +
                'use sheduleHourly() instead.');

        List<Id> jobIds = new List<Id>();

        for (Integer minute = 0; minute < 60; minute += everyMinutes) {
            Id jobId = scheduleHourly(jobName + ' \'' + minute, minute, job);
            jobIds.add(jobId);
        }

        return jobIds;
    }


    /**
     * Schedules job to run every hour at specified minutes.
     * @return Scheduled job ID (CronTrigger ID).
     */
    public Id scheduleHourly(String jobName, Integer minute, Schedulable job) {
        return schedule(jobName, '0', '' + minute, '*', '?', '*', '*', '*', job);
    }


    /**
     * Schedules job to run every day at specified time.
     * @return Scheduled job ID (CronTrigger ID).
     */
    public Id scheduleDaily(String jobName, Integer hour, Integer minute, Schedulable job) {
        return schedule(jobName, '0', '' + minute, '' + hour, '?', '*', '*', '*', job);
    }


    /**
     * Schedules job to run every day on specified day of the week.
     * @param dayOfWeek 1-7 or one of the following: [SUN, MON, TUE, WED, THU, FRI, SAT]
     * @return Scheduled job ID (CronTrigger ID).
     */
    public Id scheduleWeekly(String jobName, String dayOfWeek, Schedulable job) {
        return schedule(jobName, '0', '0', '0', '?', '*', dayOfWeek, '*', job);
    }


    /**
     * Schedules job to run every month on specified day of the month.
     *
     * @param dayOfMonth Possible values:<br/>
     * 1-31 Runs on specific day of month<br/>
     * 1,10,15 Runs on 1st, 10th and 15th day of month <br/>
     * 1-15  Runs from 1st to 15th day of month<br/>
     * 1/5 Runs on every 5th day of month, starting on the first of the month   <br/>
     * L Runs on last day of month <br/>
     * 20W Runs on nearest weekday of the given day<br/>
     *
     * @return Scheduled job ID (CronTrigger ID).
     */
    public Id scheduleMonthly(String jobName, String dayOfMonth, Schedulable job) {
        return schedule(jobName, '0', '0', '0', dayOfMonth, '*', '?', '*', job);
    }


    /**
     * Schedules job to run
     * @return Scheduled job ID (CronTrigger ID).
     */
    public Id schedule(
            String jobName,
            String seconds,
            String minutes,
            String hour,
            String dayOfMonth,
            String month,
            String dayOfWeek,
            String optionalYear,
            Schedulable job) {

        String cronExpr = String.join(new List<String>{
                '' + seconds,
                '' + minutes,
                '' + hour,
                dayOfMonth,
                month,
                dayOfWeek,
                optionalYear
        }, ' ');

        return System.schedule(jobName, cronExpr, job);
    }


    private void expect(Boolean condition, String message) {
        if (!condition) {
            throw new SchedulerException(message);
        }
    }
    private class SchedulerException extends Exception {
    }
}