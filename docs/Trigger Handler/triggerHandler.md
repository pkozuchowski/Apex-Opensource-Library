# Table of Contents

1. [Description](#description)
1. [Overview](#overview)
    - [Trigger Handler](#trigger-handler)
    - [Trigger Dispatcher](#trigger-dispatcher)
    - [Trigger Context](#trigger-context)
    - [Trigger Settings](#trigger-settings)
    - [Interfaces](#interfaces)
    - [Custom Metadata](#custom-metadata)
    - [Custom Settings](#custom-settings)
1. [Basic Usage](#basic-usage)
1. [Multi-Tenant Environments](#multi-tenant-environments)

<br/>

# Description

Trigger Handler is apex design pattern which solves a few problems which arouse around apex triggers:

1. If there's more than one trigger per SObject in org, order of trigger execution is not deterministic. Recommended practice is to have one trigger per SObject
   and delegate logic execution inside of it.
1. If above is implemented without Trigger Handler framework, each trigger file would have repeated code for checking trigger operation, ex:

```apex
 switch on Trigger.operationType {
   when BEFORE_INSERT {
      new AccountContactLinker().linkContactsToAccount(Trigger.new);
      /*...*/
   }
   when BEFORE_UPDATE {
      /*...*/
   }
   when BEFORE_DELETE {
      /*...*/
   }
   when AFTER_INSERT {
      /*...*/
   }
   when AFTER_UPDATE {
      /*...*/
   }
   when AFTER_DELETE {
      /*...*/
   }
   when AFTER_UNDELETE {
      /*...*/
   }
}
```

Trigger Handler frameworks encapsulates this implementation and provide easy to extend virtual class with `onBeforeInsert(List<SObject> newRecords)` methods.

3. Trigger file is not treated as a class, but as block of apex code - similarly to anonymous apex. Therefore it cannot extend any virtual class on it's own, it
   has to delegate everything to fully-fledged class -Trigger Handler.

<br/>
<br/>

# Overview

### Trigger Handler

This virtual class is the heart of framework. It contains virtual methods which should be overwritten, each one corresponding to trigger event:

```apex
public virtual void onBeforeInsert(List<SObject> triggerNew, TriggerContext tc) {}
public virtual void onAfterInsert(List<SObject> triggerNew, TriggerContext tc) {}

public virtual void onBeforeUpdate(List<SObject> triggerNew, TriggerContext tc) {}
public virtual void onAfterUpdate(List<SObject> triggerNew, TriggerContext tc) {}

public virtual void onBeforeDelete(List<SObject> triggerOld, TriggerContext tc) {}
public virtual void onAfterDelete(List<SObject> triggerOld, TriggerContext tc) {}

public virtual void onAfterUndelete(List<SObject> triggerNew, TriggerContext tc) {}
```

Concrete trigger handler (ex. `AccountTriggerHandler`) should extend this class and override methods it needs to handle and then delegate execution of logic to
dedicated service classes.


TODO: Move this digression
I believe TriggerHandler shouldn't have any other logic exception for delegation, since it violates Single Responsibility Principle. Record filtering for
processing is semantically closer to the business class, than it is to the Trigger Handler (it's part of business requirement).

To prove it, we can interpolate solution to infinity and check if it's still maintainable. On one side, we will have a infinite number of one purpose classes
which each filter records they need, plus unit tests. On other side, we have trigger handler with infinite number of filtering methods, plus service classes,
plus tests for TriggerHandler filtering. <br/>
By comparison, we can see that it is easier to add, remove or edit code when TH only does delegation and it's easier to maintain it in VCS.

<br/>
<br/>
<br/>

### Trigger Dispatcher

Entry point of every trigger. This class encapsulates trigger context variables into TriggerContext instance and dispatches execution to correct Trigger Handler
method. It may use Trigger Handler instance provided by developer or pull logic to run from custom metadata.

It contains 2 methods:

* `public static void runMetadataDefinedTriggers()` which runs triggers defined in custom metadata.
* `public static void run(TriggerHandler triggerHandler)` which runs concrete TriggerHandler class.

and 2 methods that are visible only in unit tests and provide ability to mock TriggerContext:

* `private static void runMetadataDefinedTriggers(TriggerContext triggerContext)`
* `private static void run(TriggerHandler triggerHandler, TriggerContext triggerContext)`

Trigger should contain only one line of code which executes trigger handler:

```apex
trigger AccountTrigger on Account (before insert, after insert, before update, after update, before delete, after delete, after undelete ) {
    TriggerDispatcher.run(new AccountTriggerHandler());
}
```

<br/>
<br/>

### Trigger Context

This class serves following purposes:

1. It encapsulates Trigger variables into an immutable object that can be passed down to other classes.
1. It's used as marker interface which indicates that this particular method is run in Trigger context - similarly
   to `SchedulableContext, QueueableContext and BatchableContext`,
1. It contains methods that make record filtering easier and more verbose:

```apex
SObject[] getRecords();
Map<Id, SObject> getRecordsMap();
Set<Id> getRecordsIds();
SObject getOld(SObject record);
Map<Id, SObject> getOldMap();
Boolean isNew();
Boolean isChanged();
Boolean isChanged(SObject record, SObjectField field);
Boolean isChangedTo(SObject record, SObjectField field, Object toValue);
Boolean isChangedFrom(SObject record, SObjectField field, Object fromValue);
Boolean isChangedFromTo(SObject record, SObjectField field, Object fromValue, Object toValue);
```

<br/>
<br/>

### Trigger Settings

Settings class for manipulating trigger execution and mocking in tests. Using this class, developer can turn off trigger execution for batch data fix for
example.

1. Toggling trigger execution for SObject type:

```apex
TriggerSettings.disableTrigger(Account.SObject);
// Do Something without triggers running
TriggerSettings.enableTrigger(Account.SObject);
```

<br/>

2. Toggling all logic on custom setting level for current user. Methods below perform DML to update LogicSwitch__c custom setting for current user.

```apex
TriggerSettings.disableAllLogic();
TriggerSettings.enableAllLogic();
```

3. Mocking custom metadata defined triggers:

```apex
TriggerSettings.mockMetadata(new List<TriggerLogic__mdt>{
    new TriggerLogic__mdt(Enabled__c = true, BeforeInsert__c = true, ApexClass__c = 'AccountAssistantContactLinker.cls')
});

//or mock whole selector class for more granular control

TriggerSettings.mockSelector(new CustomTriggerLogicSelector());
```

<br/>
<br/>

### Interfaces

Framework provides 2 interfaces that should be implemented in business logic classes. It's not a requirement, but it streamlines the code and is a good
practice.

###### TriggerHandler.Logic

```apex
public interface Logic {
    void execute(List<SObject> records, TriggerContext ctx);
}
```

TriggerHandler.Logic represents single business requirement implementing class. TriggerContext marker interface indicates that this method runs in Trigger and
may have to filter records for processing. TriggerContext contains methods that make filtering simpler and more verbose:

```apex
List<Account> filtered = new List<Account>();

for (Account acc : (Account[]) records) {
    if (ctx.isNew() || ctx.isChanged(acc, Account.Email__c)) {
        filtered.add(acc);
    }
}
```

<br/>
<br/>

###### TriggerHandler.AsyncLogic

```apex
public interface AsyncLogic {
    List<SObject> filter(List<SObject> records, TriggerContext ctx);
    void execute(List<SObject> records, QueueableContext ctx);
}
```

This interface marks classes which should execute asynchronously (using Queueable) on trigger event. Implementing classes does not have to implement Queueable
interface, but may do that if needed.

It's similar to TriggerHandler.Logic, but it has additional method `filter(List<SObject> records, TriggerContext ctx);` which checks if Queueable should be
queued. If method does not return any records, queueable is not scheduled.

<br/>
<br/>

###### TriggerHandler.Parameterizable

```apex
public interface Parameterizable {
    void setParameters(String parameters);
}
```

This interface marks classes which can be parametrized through TriggerLogic__mdt.Parameters__c field. Value of the field will be passed to setParameters method.

This may come handy if we use [Custom Metadata](#custom-metadata) and want to parametrize the class - for example if we want to reuse one generic class for many
sObjects types and pass different SObjectField as parameter, we can do that through this interface.

Example:
Generic class that copies one field to another in before trigger.

Custom Metadata:
![image](https://user-images.githubusercontent.com/4470967/118978167-4bddb580-b977-11eb-921c-494de754ccf3.png)

*Code:*

```apex
public with sharing class FieldCopier implements TriggerHandler.Logic, TriggerHandler.Parameterizable {
    private String sourceField, targetField;

    public void setParameters(String parameters) {
        String[] fields = parameters.split(',');
        this.sourceField = fields[0].trim();
        this.targetField = fields[1].trim();
    }

    public void execute(List<SObject> records, TriggerContext ctx) {
        for (SObject sobj : records) {
            sobj.put(targetField, sobj.get(sourceField));
        }
    }
}
```

### Custom Metadata

TriggerLogic__mdt is used to define classes to run in Trigger without creating coupling/dependency between them. In standard code approach, different teams may
have to edit same Trigger/TriggerHandler file to introduce new logic, but with custom metadata each team can inject their own custom metadata without touching
any common code.

| Field            | Type           | Description  |
| ------           | ------         | ------------ |
| AfterDelete__c   | Checkbox       |              |
| AfterInsert__c   | Checkbox       |              |
| AfterUndelete__c | Checkbox       |              |
| AfterUpdate__c   | Checkbox       |              |
| ApexClass__c     | Text(255)      | Name of apex class - must be public. It can be inner class - ex. AccountFieldSetters.NameSetter             |
| Async__c         | Checkbox       | Should this logic run in Queueable? |
| BeforeDelete__c  | Checkbox       |              |
| BeforeInsert__c  | Checkbox       |              |
| BeforeUpdate__c  | Checkbox       |              |
| Description__c   | Text Area(255) |              |
| Enabled__c       | Checkbox       |              |
| Order__c         | Number(18, 0)  | Order of execution             |
| Package__c       | Text(63)       | Name/Prefix of package or workstream, used for ordering. Code is first executed by package order, then by Order field             |
| Parameters__c    | Text Area(255) | Parameters injected to the class             |
| SObject__c       | Text(255)      | API Name of SObject             |

### Custom Settings

# Basic Usage

If you are not working in Multi-Tenant environment, the easiest way to start is by extending TriggerHandler class and running it using TriggerDispatcher. Let's
consider this example on Account Trigger.

First

# Multi-Tenant Environments

##### Defining logic in custom metadata

##### Parameterizing logic

# Components

| Type           | Name                  | Description  |
| ------         | ------                | ------------ |
| Apex Class     | TriggerContext        | Encapsulation of Trigger variables for current run, Marker interface         |
| Apex Class     | TriggerDispatcher     | Entry point to the trigger execution. Dispatches trigger execution to concrete TriggerHandler instance or custom metadata defined triggers          |
| Apex Class     | TriggerDispatcherTest | Unit Tests and examples for all trigger handler scenarios         |
| Apex Class     | TriggerHandler        | Virtual class         |
| Apex Class     | TriggerLogicSelector  | Selector class for querying and instantiating concrete classes of TriggerHandler.Logic defined in custom metadata         |
| Apex Class     | TriggerSettings       | This class can be used to disable/enable trigger for specific SObject type or mock metadata defined logic         |
| Custom Setting | LogicSwitch__c        | Hierarchy custom setting which controls whether triggers / validation rules / flows should be ran for current user         |
| Custom Object  | TriggerLogic__mdt     | Custom metadata used to define trigger logic to be run without concrete TriggerHandler. In Multi-Tenant environments, this approach decouples Trigger Handler dependency between teams/packages          |
