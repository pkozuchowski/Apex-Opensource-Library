# Batch Schedulable
*Schedule batches without boilerplate code.*
[Source](https://github.com/pkozuchowski/Apex-Opensource-Library/blob/master/force-app/commons/batch/BatchSchedulable.cls)

```bash
sf project deploy start -m "ApexClass:BatchSchedulable*" -o sfdxOrg
```

---
# Documentation

BatchSchedulable is a generic Schedulable class that will take type of the batch class and run it for you.  
With this utility, there's no need to implement Schedulable interface for each Batch class.

Also, since the batch is instantiated through reflection, the class will never be blocked with `This Apex class has batch or future jobs pending or in progress`
error.

```apex | Interface
class BatchSchedulable implements Schedulable {
    BatchSchedulable(Type batchClass) {}
    BatchSchedulable(Type batchClass, Integer batchSize) {}
}
```

```apex | Usage | The job will run everyday at 12:00 and execute SObjectCleanerBatch batch.
Scheduler.scheduleDaily('SObject Cleaner', 12, 00,
    new BatchSchedulable(SObjectCleanerBatch.class)
);
```