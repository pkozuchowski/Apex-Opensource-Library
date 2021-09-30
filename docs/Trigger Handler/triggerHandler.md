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

[Link to Code](../../force-app/commons/triggerHandler) <br/>
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

Trigger Handler frameworks encapsulates this implementation and provide easy to extend virtual class with `onBeforeInsert(List<SObject> newRecords)` methods.

3. Trigger file is not treated as a class, but as block of apex code - similarly to anonymous apex. Therefore it cannot extend any virtual class on it's own, it
   has to delegate everything to fully-fledged class -Trigger Handler.

<br/>
<br/>

# Documentation

### API
###### TriggerDispatcher
```apex
public static void runMetadataDefinedTriggers();
public static void run(TriggerHandler triggerHandler);

@TestVisible private static void runMetadataDefinedTriggers(TriggerContext triggerContext)
@TestVisible private static void run(TriggerHandler triggerHandler, TriggerContext triggerContext)
```

###### TriggerHandler
```apex
public virtual void onBeforeInsert(List<SObject> triggerNew, TriggerContext tc);
public virtual void onAfterInsert(List<SObject> triggerNew, TriggerContext tc);
public virtual void onBeforeUpdate(List<SObject> triggerNew, TriggerContext tc);
public virtual void onAfterUpdate(List<SObject> triggerNew, TriggerContext tc);
public virtual void onBeforeDelete(List<SObject> triggerOld, TriggerContext tc);
public virtual void onAfterDelete(List<SObject> triggerOld, TriggerContext tc);
public virtual void onAfterUndelete(List<SObject> triggerNew, TriggerContext tc);

public void execute(List<SObject> records, TriggerContext tc, List<Logic> triggerLogics);

public interface Logic {
   void execute(List<SObject> records, TriggerContext ctx);
}

public interface Parameterizable {
   void setParameters(String parameters);
}
```

###### Trigger Settings
```apex
public static void disableTriggers();
public static void enableTriggers();
public static void disableTrigger(SObjectType sObjectType);
public static void enableTrigger(SObjectType sObjectType);
public static Boolean isSObjectTriggerEnabled(SObjectType sObjectType);
public static TriggerLogicSelector getLogicSelector();
public static void disableAllLogic();
public static void enableAllLogic();
```


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

### Trigger Handler

This virtual class is the heart of framework. It contains virtual methods which should be overwritten, each one corresponding to the trigger event.
Each sObject should have a concrete trigger handler class, which extends TriggerHandler class, and override method it wants to handle in the trigger execution.
Example:
```apex
public inherited sharing class AccountTriggerHandler extends TriggerHandler {

    //Using TriggerHandler.Logic implementing classes
    public override void onAfterInsert(List<SObject> triggerNew, TriggerContext tc) {
        this.execute(triggerNew, tc, new List<Logic>{
            new AccountContactLinker()
        });
    }

    //without interface
    public override void onAfterUpdate(List<SObject> triggerNew, TriggerContext tc) {
       new AccountContactLinker().linkContactsToAccount(triggerNew, tc);
    }

}
```

<br/>
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

TriggerHandler.Logic is a class that's implementing single business requirement. TriggerContext marker interface indicates that this method runs in Trigger and
may have to filter records for processing. TriggerContext contains methods that make filtering simpler and more verbose:

```apex
public inherited sharing class AccountContactLinker implements TriggerHandler.Logic {

   public void execute(List<SObject> records, TriggerContext ctx) {
      for (Account acc : (Account[]) records){
         if(ctx.isNew() || ctx.isChanged(acc, Account.Phone)){
            //... do logic here
            // ex. link Contacts with same phone number
         }
      }
   }
}
```

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

*Example parametrizable code:*

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
Logic Switch custom settings can be used to disable automation from executing for selected Profiles or Users.


| Field            | Type           | Description  |
| ------           | ------         | ------------ |
| DisableProcessBuilders__c | Checkbox | Disables Process Builders (PBs have to check for this setting as first step) |
| DisableTriggers__c        | Checkbox | Disables all triggers from executing |
| DisableValidationRules__c | Checkbox | Disables Validation Rules (VRs have to check for this setting) |
| DisableWorkflowRules__c   | Checkbox | Disables Workflow Rules (WRs have to check for this setting as first step) |
