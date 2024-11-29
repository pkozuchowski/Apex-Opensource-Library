# Scheduler
*Shorthand for easy scheduling.*

[Source](https://github.com/pkozuchowski/Apex-Opensource-Library/blob/master/force-app/commons/batch/Scheduler.cls)

```bash
sf project deploy start -m "ApexClass:Scheduler*" -o sfdxOrg
```
---
# Documentation
Scheduler is utility for easy job scheduling:

```apex | Interface
public static List<Id> scheduleEveryXMinutes(String jobName, Integer everyMinutes, Schedulable job);
public static Id scheduleHourly(String jobName, Integer minute, Schedulable job);
public static Id scheduleDaily(String jobName, Integer hour, Integer minute, Schedulable job);
public static Id scheduleWeekly(String jobName, Integer hour, String dayOfWeek, Schedulable job);
public static Id scheduleMonthly(String jobName, Integer hour, String dayOfMonth, Schedulable job);

public static Id schedule(
	String jobName,
	String seconds,
	String minutes,
	String hour,
	String dayOfMonth,
	String month,
	String dayOfWeek,
	String optionalYear,
	Schedulable job);
```

```apex | Usage | The job will run everyday at 12:00
Scheduler.scheduleDaily('Data Cleaner', 12, 00, new DataCleaningSchedulable());
```

---
# Specification

## scheduleEveryXMinutes(jobName, everyMinutes, job)
```apex
public static List<Id> scheduleEveryXMinutes(
	String jobName,
	Integer everyMinutes,
	Schedulable job
);
```
Schedules multiple schedulable jobs to run every X minutes in an hour.  
Returns scheduled jobs IDs (CronTrigger IDs) in chronological order.
#### Parameters
- `String jobName` - Base name for the job, each job will have minutes concatenated to the name.
- `Integer everyMinutes` - Every how many minutes in hour the job should run.  
  Ex. for value 15 the job will be scheduled on 0, 15, 30 and 45 minutes of every hour.
- `Schedulable job` - Schedulable to run.
#### Usage
The following code will schedule 6 jobs to run every hour, every 10 minutes.
```apex
Scheduler.scheduleEveryXMinutes('MySchedulableJob', 10, new MySchedulable());
```

## scheduleHourly(jobName, minute, job)
```apex
public static Id scheduleHourly(
	String jobName,
	Integer minute,
	Schedulable job
);
```
Schedules a job to run every hour at specified minutes.  
Returns Scheduled job ID (CronTrigger ID).
#### Parameters
- `String jobName` - Base name for the job, each job will have minutes concatenated to the name.
- `Integer minute` - Minute in hour. ex: `30` will mean that the job will run at every hour at xx:30
- `Schedulable job` - Schedulable to run.
#### Usage
```apex
Scheduler.schedulerHourly('HourlyDataClean', 0, new DataCleanerJob());
```

## scheduleDaily(jobName, hour, minute, job)
```apex
public static Id scheduleDaily(String jobName, Integer hour, Integer minute, Schedulable job);
```
Schedules a job to run every day at specified time.  
Returns Scheduled job ID (CronTrigger ID).
#### Parameters
- `String jobName` - Base name for the job, each job will have minutes concatenated to the name.
- `Integer hour` - Hour in a day when the job will run.
- `Integer minute` - Minute in hour. ex: `30` will mean that the job will run at every hour at xx:30
- `Schedulable job` - Schedulable to run.
#### Usage
Schedule a daily job at 1 am:
```apex
Scheduler.scheduleDaily('DataCleaner', 1, 0, new DataCleanerJob());
```

## scheduleWeekly(jobName, hour, dayOfWeek, job)
```apex
public static Id scheduleWeekly(String jobName, Integer hour, String dayOfWeek, Schedulable job);
```
Schedules a job to run every day on specified day of the week.
#### Parameters
- `String jobName` - Base name for the job, each job will have minutes concatenated to the name.
- `Integer hour` - Hour in a day when the job will run.
- `Integer dayOfWeek` - 1-7 or one of the following: [SUN, MON, TUE, WED, THU, FRI, SAT]
- `Schedulable job` - Schedulable to run.
#### Usage
Runs a job every monday at 12.
```apex
Scheduler.scheduleWeekly('DataCleaner', 12, 'MON', new DataCleanerJob());
```

## scheduleMonthly(jobName, hour, dayOfMonth, job)
```apex
public static Id scheduleMonthly(String jobName, Integer hour, String dayOfMonth, Schedulable job);
```
Schedules a job to run every month on specified day of the month.

#### Parameters
- `String jobName` - Base name for the job, each job will have minutes concatenated to the name.
- `Integer hour` - Hour in a day when the job will run.
- `Integer dayOfMonth` - Possible values:  
  1-31 Runs on specific day of month  
  1,10,15 Runs on 1st, 10th and 15th day of month   
  1-15 Runs from 1st to 15th day of month  
  1/5 Runs on every 5th day of month, starting on the first of the month     
  L Runs on last day of month   
  20W Runs on nearest weekday of the given day
- `Schedulable job` - Schedulable to run.
#### Usage
Schedule a job at 12 on the first day of the month.
```apex
Scheduler.scheduleMonthly('DataCleaner', 12, '1', new DataCleanerJob());
```

## schedule(jobName, seconds, minutes, hour, dayOfMonth, month, dayOfWeek, optionalYear, job)
```apex
 public static Id schedule(
	String jobName,
	String seconds,
	String minutes,
	String hour,
	String dayOfMonth,
	String month,
	String dayOfWeek,
	String optionalYear,
	Schedulable job);
```
Helper method that breaks down cron expression into parameters.



