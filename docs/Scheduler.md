# Scheduler & Batch Schedulable
This utility cuts down number of Schedulables in organization to one. With this, you don't need to implement schedulable for each new batch:

Example:  
Given that we have batch class named SObjectCleanerBatch that we want to run daily
```apex
Scheduler.scheduleDaily('SObject Cleaner', 12, 00,
    new BatchSchedulable(SObjectCleanerBatch.class)
);

// The job will run everyday at 12:00 and execute SObjectCleanerBatch batch.
```

BatchSchedulable is generic schedulable class that will execute given batch class. No need to implement new schedulables.  
Scheduler is utility for easy job scheduling:

```apex
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