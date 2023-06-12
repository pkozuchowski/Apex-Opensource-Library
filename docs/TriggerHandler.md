# Table of Contents

1. [Description](#description)
1. [Documentation](#documentation)
    - [API](#api)
    - [Trigger Dispatcher](#trigger-dispatcher)
    - [Trigger Handler](#trigger-handler)
    - [Trigger Context](#trigger-context)
    - [Trigger Settings](#trigger-settings)
    - [Interfaces](#interfaces)
    - [Custom Metadata](#custom-metadata)
    - [Custom Settings](#custom-settings)

<br/>

[Link to Code](../force-app/commons/triggerHandler) <br/>
[Link to Examples](examples)

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

Trigger Handler frameworks encapsulates this implementation and provide easy to extend virtual class with `beforeInsert(List<SObject> newRecords)` methods.

3. Trigger file is not treated as a class, but as block of apex code - similarly to anonymous apex. Therefore, it cannot extend any virtual class on its own,
   it has to delegate everything to fully-fledged class - Trigger Handler.

<br/>

# Documentation

### API

###### TriggerDispatcher

```apex
public static void run(TriggerHandler triggerHandler);
@TestVisible private static void run(TriggerHandler triggerHandler, TriggerContext triggerContext);
```

###### TriggerHandler

```apex
public virtual void beforeInsert(List<SObject> triggerNew, TriggerContext tc);
public virtual void afterInsert(List<SObject> triggerNew, TriggerContext tc);

public virtual void beforeUpdate(List<SObject> triggerNew, TriggerContext tc);
public virtual void afterUpdate(List<SObject> triggerNew, TriggerContext tc);

public virtual void beforeDelete(List<SObject> triggerOld, TriggerContext tc);
public virtual void afterDelete(List<SObject> triggerOld, TriggerContext tc);

public virtual void afterUndelete(List<SObject> triggerNew, TriggerContext tc);
```

###### Trigger Settings

```apex
public static void disableTriggers();
public static void enableTriggers();

public static Boolean isSObjectTriggerEnabled(SObjectType sObjectType);
public static void disableTrigger(SObjectType sObjectType);
public static void enableTrigger(SObjectType sObjectType);

public static void disableTriggerHandler(Type triggerHandlerType);
public static void enableTriggerHandler(Type triggerHandlerType);

public static void disableAllLogic();
public static void enableAllLogic();
```

### Trigger Dispatcher

Entry point of every trigger. This class encapsulates trigger context variables into TriggerContext instance
and dispatches execution to correct Trigger Handler method.

It contains method:

* `public static void run(TriggerHandler triggerHandler)` which runs concrete TriggerHandler class.

and another that is visible only in unit tests and provide ability to mock TriggerContext:

* `@TestVisible private static void run(TriggerHandler triggerHandler, TriggerContext triggerContext)`

Trigger should contain only one line of code which executes trigger handler:

```apex
trigger AccountTrigger on Account (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    TriggerDispatcher.run(new AccountTriggerHandler());
}
```

<br/>
<br/>

### Trigger Handler

This virtual class is the heart of framework. It contains virtual methods which should be overwritten, each one corresponding to the trigger event.
Each sObject should have a concrete trigger handler class, which extends TriggerHandler class, and override method it wants to handle in the trigger execution.
Example:

```apex
public inherited sharing class AccountTriggerHandler extends TriggerHandler {

    public override void afterInsert(List<SObject> triggerNew, TriggerContext tc) {
        Accounts accounts = new Accounts(triggerNew);
        accounts.linkToStore(tc);
        accounts.preventDuplicateAccounts(tc);
        accounts.updatePersonContact(tc);
        accounts.createAccountShares(tc);
    }

    public override void afterUpdate(List<SObject> triggerNew, TriggerContext tc) {
        Accounts accounts = new Accounts(triggerNew);
        accounts.linkToStore(tc);
        accounts.syncChangesWithCustomerService();
        accounts.createCustomerCareNotes();
    }
}
```

<br/>
<br/>

### Trigger Context

This class serves the following purposes:

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

List<SObject> getChanged(SObjectField sObjectField);
List<SObject> getChangedToValue(SObjectField sObjectField, Set<Object> values);
List<SObject> getChangedFromValue(SObjectField sObjectField, Set<Object> values);

Boolean isFirstExecution(String featureName, Id recordId);
void setExecuted(String featureName, Id recordId);
Integer getExecutionCount(String featureName, Id recordId);
```
<br/>

##### Process records once
To make sure that record is not needlessly processed number of times, developer can use isFirstExecution() method as follows:
```apex
    public class AccountAddressPopulator {
    public void populateDefaultAddress(List<Account> records, TriggerContext ctx) {
        String thisFeature = AccountAddressPopulator.class.getName();

        for (Account acc : (Account[]) records) {
            if (ctx.isFirstExecution(thisFeature, acc.Id)) {
                // Increment to test trigger recursion
                acc.NumberOfEmployees = acc.NumberOfEmployees == null ? 1 : acc.NumberOfEmployees + 1;
                ctx.setExecuted(thisFeature, acc.Id);
            }
        }
    }
}
```
Using `isFirstExecution()`/`getExecutionCount()` and setExecuted() lets us control how many times this logic will be executed.  
The `featureName` parameter corresponds to class name or feature name and is used to cover a scenario where record did not initially meet criteria to process, but
was updated by flow or subsequent DML to meet the criteria.
If record satisfies condition for being processed in trigger, `ctx.setExecuted()` method should be called to flag record as processed.


<br/>
<br/>

### Trigger Settings~~~~

Settings class for manipulating trigger execution and mocking in tests. Using this class, developer can turn off trigger execution for batch data fix for
example.

1. Toggling trigger execution for SObject type:

```apex
TriggerSettings.disableTrigger(Account.SObject);
// Do Something without triggers running
TriggerSettings.enableTrigger(Account.SObject);
```

2. Toggling specific Trigger Handler
```apex
TriggerSettings.disableTriggerHandler(AccountTriggerHandler.class);
// Do Something without triggers running
TriggerSettings.enableTriggerHandler(AccountTriggerHandler.class);
```

3. Toggling all trigger:

```apex
TriggerSettings.disableTriggers();
TriggerSettings.enableTriggers();
```

4Toggling all logic on custom setting level for current user. Methods below perform DML to update LogicSwitch__c custom setting for current user.

```apex
TriggerSettings.disableAllLogic();
TriggerSettings.enableAllLogic();
```

# Metadata Driven Trigger Handlers
In the previous version of the trigger handler, I was providing support for configurable approach where classes could have been
configured to run in a trigger through custom metadata. This feature was removed to simplify the code, but also because
metadata driven trigger handlers introduce a number of issues that outweigh the gains:
1. Contrary to code, custom metadata is additive deployment.
   That means that configuration may stay in system even if it's removed from the repository or after refresh. This behavior may introduce bugs that are hard to track down.
2. It's harder to track what is actually executed. It takes longer to traverse the trigger code.
3. It's harder to parametrize classes and reuse code.

Due to the above, I'm taking down these features. They can still be found in old metadata-trigger branch, but I advise to use code instead.