# Trigger Handler
*Orchestrator for Apex Trigger Logic*

[Source](https://github.com/pkozuchowski/Apex-Opensource-Library/tree/master/force-app/commons/triggerHandler) 
[Install In Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04t08000000UK6aAAG) 
[Install In Production](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t08000000UK6aAAG)

```bash
sf project deploy start -d "force-app/commons/triggerHandler" -o sfdxOrg
```

---
# Documentation
Trigger Handler is an apex design pattern that solves a few problems which arouse around apex triggers:

1. If there's more than one trigger per SObject in org, order of trigger execution is not deterministic.  
   Recommended practice is to have one trigger per SObject and delegate logic execution inside it.
1. Trigger file is not treated as a class, but as a block of apex code — similarly to anonymous apex. It cannot extend any virtual class on its own, it has to
   delegate everything to a fully-fledged class - Trigger Handler.
1. Triggers will have repeated switch logic for checking context

## Trigger Dispatcher
Entry point of every trigger. This class encapsulates trigger context variables into TriggerContext instance
and dispatches execution to correct Trigger Handler method.

It contains method:
* `public static void run(TriggerHandler triggerHandler)` which runs concrete TriggerHandler class.

and another that is visible only in unit tests and provides an ability to mock TriggerContext:
* `@TestVisible private static void run(TriggerHandler triggerHandler, TriggerContext triggerContext)`

Trigger should contain only one line of code which executes trigger handler:
```apex
trigger AccountTrigger on Account (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
	TriggerDispatcher.run(new AccountTriggerHandler());
}
```

```apex | TriggerDispatcher
public static void run(TriggerHandler triggerHandler);
@TestVisible private static void run(TriggerHandler triggerHandler, TriggerContext triggerContext);
```

## Trigger Handler
This virtual class is the heart of framework. It contains virtual methods which should be overwritten, each one corresponding to the trigger event.
Each sObject should have a concrete trigger handler class, which extends TriggerHandler class, and override method it wants to handle in the trigger execution.

```apex | TriggerHandler
public virtual void beforeInsert(List<SObject> triggerNew, TriggerContext tc);
public virtual void afterInsert(List<SObject> triggerNew, TriggerContext tc);

public virtual void beforeUpdate(List<SObject> triggerNew, TriggerContext tc);
public virtual void afterUpdate(List<SObject> triggerNew, TriggerContext tc);

public virtual void beforeDelete(List<SObject> triggerOld, TriggerContext tc);
public virtual void afterDelete(List<SObject> triggerOld, TriggerContext tc);

public virtual void afterUndelete(List<SObject> triggerNew, TriggerContext tc);
```

<details>
	<summary>Example</summary>

```apex | Example implementation
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
</details>

## Trigger Context
This class serves the following purposes:

1. It encapsulates Trigger variables into an immutable object that can be passed down to other classes.
1. It's used as marker interface which indicates that this particular method is run in Trigger context—similarly
   to `SchedulableContext, QueueableContext and BatchableContext`,
1. It contains methods that make record filtering easier and more verbose:

<details>
	<summary>Methods</summary>

```apex
SObject[] getRecords();                 // returns Trigger.old in DELETE triggers and Trigger.new in all other cases
Map<Id, SObject> getRecordsMap();       // returns Map of records from getRecords()
Set<Id> getRecordsIds();                // returns Set of record ids or empty set in BEFORE INSERT
SObject getOld(SObject record);         // returns Old version of the record in update trigger context and null in any other context.
Map<Id, SObject> getOldMap();           // returns Trigger.oldMap

Boolean isNew();                        // true if record is being inserted.
Boolean isChanged();                    // true if record is being updated.

// True if trigger is in update context and if given field was changed on the given record.
Boolean isChanged(SObject record, SObjectField field);

// True if trigger is in update context and if given field was changed to the value on the given record.
Boolean isChangedTo(SObject record, SObjectField field, Object toValue);

// True if trigger is in update context and if given field was changed from the value on the given record.
Boolean isChangedFrom(SObject record, SObjectField field, Object fromValue);

//  True if trigger is in update context and if given field was changed from one value to another on the given record.
Boolean isChangedFromTo(SObject record, SObjectField field, Object fromValue, Object toValue);

// returns records where the field changed
List<SObject> getChanged(SObjectField sObjectField);

// returns list of records which had the specified field changed to any of the accepted values
List<SObject> getChangedToValue(SObjectField sObjectField, Set<Object> values);

// returns list of records which had the specified field changed from any of the provided values
List<SObject> getChangedFromValue(SObjectField sObjectField, Set<Object> values);

/**
 * @param featureName Name of class or feature that is calling this method.
 * It is used to cover scenario where record did not initially meet criteria to process, but was updated by flow/another DML to meet the criteria.
 * @param recordId Id of record in trigger
 * @return True if record is executed in the trigger for the first time.
 * If this is second (recurrent) run of a trigger for same records and you execute this method in after trigger,
 * it will return true.
 */
Boolean isFirstRun(String featureName, Id recordId);

// Increments processed counter for given feature name and record
void setExecuted(String featureName, Id recordId);

// How many times this record was in given trigger phase (ex. how many times record was in TriggerOperation.AFTER_UPDATE)
Integer getExecutionCount(String featureName, Id recordId);
```
</details>

##### Process records once
To make sure that record is not needlessly processed number of times, a developer can use `isFirstRun()` method as follows:
```apex
	public class AccountAddressPopulator {
	public void populateDefaultAddress(List<Account> records, TriggerContext ctx) {
		String thisFeature = AccountAddressPopulator.class.getName();

		for (Account acc : (Account[]) records) {
			if (ctx.isFirstRun(thisFeature, acc.Id)) {
				// Increment to test trigger recursion
				acc.NumberOfEmployees = acc.NumberOfEmployees == null ? 1 : acc.NumberOfEmployees + 1;
				ctx.setExecuted(thisFeature, acc.Id);
			}
		}
	}
}
```
Using `isFirstRun()`/`getExecutionCount()` and setExecuted() lets us control how many times this logic will be executed.  
The `featureName` parameter corresponds to class name or feature name and is used to cover a scenario where record did not initially meet criteria to process,
but was updated by flow or subsequent DML to meet the criteria.
If record satisfies condition for being processed in trigger, `ctx.setExecuted()` method should be called to flag record as processed.

## Trigger Settings
Settings class for manipulating trigger execution.

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

4. Toggling all logic on custom setting level for current user. The methods below perform DML to update LogicSwitch__c custom setting for current user.
   ```apex
   TriggerSettings.disableAllLogic();
   TriggerSettings.enableAllLogic();
   ```

---
# Logic Switch

Frameworks comes with `LogicSwitch__c` hierarchy custom settings for toggling logic for particular user or profile with the following capabilities:
1. Disable Triggers
2. Disable Flows
3. Disable Validation Rules
4. Disable Process Builders
5. Disable Workflow Rules

Disable Triggers functionality is implemented in the framework, but to use all toggles for declarative tools, you have to include the toggle in each process.  
For example, this is how VRs should include the switch:

```text
AND(
   NOT($Setup.LogicSwitch__c.DisableValidationRules__c),
   // Validation rule error formula
)
```

All toggles are defined as negatives (Disable X vs Enable X) because that makes them enabled by default — both in real usage and in unit tests. 
You won't have to insert them in every test class or remember about manual steps to enable custom setting.

---
# Change Log

### v1.0.2
* Fixed a bug where isDelete could report incorrect value during UNDELETE trigger operation in mocked tests.