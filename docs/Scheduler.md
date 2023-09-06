# Scheduler
*Shorthand for easy scheduling.*

[Scheduler](https://github.com/pkozuchowski/Apex-Opensource-Library/blob/master/force-app/commons/batch/Scheduler.cls)

```bash
sf project deploy start -m "ApexClass:Scheduler*" -o sfdxOrg
```
---
## Documentation
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