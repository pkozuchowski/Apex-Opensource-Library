# Database Service
*Intermediate layer between Database system class and business logic, which allows DML mocking and selecting
sharing context in runtime.*

[Source](https://github.com/pkozuchowski/Apex-Opensource-Library/tree/master/force-app/commons/database)
[Install In Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04t08000000ga9OAAQ)
[Install In Production](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t08000000ga9OAAQ)

```bash
sf project deploy start -d "force-app/commons/database" -o sfdxOrg
```

---
# Documentation

DatabaseService encapsulates `System.Database` methods and allow for altering behaviour of the DMLs:
- `with sharing` and `without sharing` context can be set on the DatabaseService class
- DML options can be set once and reused in all DMLs done by the DatabaseService
- DMLs can be mocked in unit tests

```apex | Usage | MyService performs update "without sharing" even though the class itself is "with sharing"
public with sharing class MyService {
	private DatabaseService databaseService = new DatabaseService()
		.withoutSharing();

	public void updateContacts(List<Contact> contacts) {
		databaseService.updateRecords(contacts);
	}
}

```

## Setting DML options
Provided DML options are applied to all DMLs. Developer can set them through setDmlOptions() method and there's short-hand
method for allOrNone() parameter. DML Options can be constructed with builder class:

```apex
DatabaseService databaseService = new DatabaseService()
	.setDMLOptions(new DMLOptionsBuilder()
		.allowDuplicates(false)
		.allowFieldTruncation(false)
		.allOrNone(false)
		.build()
	);

//Shortcut for All or None option
DatabaseService databaseService = new DatabaseService().allOrNone(false);
```


## Changing sharing context
Database Service can switch between inherited, with sharing and without sharing context:

```apex
DatabaseService databaseService = new DatabaseService()
	.withSharing()
	.insertRecords(accounts);

DatabaseService databaseService = new DatabaseService()
	.withoutSharing()
	.updateRecords(accounts);
```



---
# Mocking DMLs

Pure Apex Tests are tests that do not commit anything to the database and mock all queries.  
These tests are much more efficient than standard tests and allow us to test more exotic scenarios, but comes at cost of harder setup (require DML and SOQL
mocking)
and doesn't test interaction between classes in a trigger.

To mock DMLs, our business class should have instance of DatabaseService, through which it performs DMLs.  
Database Service instance should be visible to the tests.

For example purposes, let's assume this class does some inserts and updates;

```apex
public class AccountService {
	@TestVisible private DatabaseService databaseService = new DatabaseService();

	public void doBusinessLogic() {
		// Create Account
		Account account = new Account(Name = 'Test Account');
		account.BillingCountry = 'USA';
		databaseService.insertRecord(account);

		// Create Contact
		Contact contact = new Contact(LastName = 'Doe', AccountId = account.Id);
		databaseService.insertRecord(contact);

		// Create Opportunities
		DatabaseService.insertRecords(new List<Opportunity>{
			new Opportunity(AccountId = account.Id, Name = 'Opportunity 1'),
			new Opportunity(AccountId = account.Id, Name = 'Opportunity 2'),
			new Opportunity(AccountId = account.Id, Name = 'Opportunity 3')
		});

		// Update Contact field on Account
		account.Contact__c = contact.Id;
		databaseService.updateRecord(account);
	}
}
```

Now, to mock DMLs we need to call `databaseService.useMock()` in our unit test. It will return `DatabaseMock` class which be used
to check inserted/updated/deleted/undeleted records or simulate DML error on a record.

This is how it should look like in unit test:

```apex
@IsTest
static void testX() {
	AccountService accountService = new AccountService();
	DatabaseMock dbMock = accountService.databaseService.useMock();


	Test.startTest();
	accountService.doBusinessLogic();
	Test.stopTest();


	// Now we can check inserted and updated records:
	Assert.areEqual(4, dbMock.insertedRecords.size());
	Assert.areEqual(1, dbMock.updatedRecords.size());
}
```

We can reach to dbMock lists to check all records on which DML were performed.

Mock behaves similarly to the database - it will generate and assign fake Id, so relationships are preserved.

```apex
Contact c = (Contact) db.insertedRecords.get(1);

Assert.areEqual('Doe', c.LastName);
Assert.areEqual(childAccount.Id, c1.AccountId);
Assert.isNotNull(c1.Id);
Assert.areEqual(Contact.SObjectType, c.Id.getSobjectType());
```

Fake ids will look, depending on sObject, like this:
`001000000000001, 001000000000002, 003000000000003`

## Mocking DML Exceptions

To test all possible scenarios for our code, we need possibility to check how the code behaves on DML exception.  
This can be mocked using DatabaseMock class using following methods.

```apex
public DatabaseMock mockDmlError(DmlType dmlType);

/*****************/

DatabaseMock dbMock = accountService.databaseService.useMock();
dbMock.mockDmlError(DmlType.INSERT_DML);
dbMock.mockDmlError(DmlType.UPDATE_DML);
```

This will cause all inserts and updates to fail. If we want ALL dmls to fail, we should call this method with `ANY_DML` parameter.  
`dbMock.mockDmlError(DmlType.ANY_DML);`

If we need more precision, we can also provide matching record to specify which records should fail.     
The interface and usage looks as follows:

```apex
public DatabaseMock mockDmlError(SObject matcherRecord);
public DatabaseMock mockDmlError(DmlType dmlType, SObject matcherRecord);

/*****************/

DatabaseMock dbMock = accountService.databaseService.useMock();

// All Contact DMLs will fail on ANY dml. Empty record matches all with the same sobject type.
dbMock.mockDmlError(new Contact());

// Contacts with LastName = 'DOE' will fail on ANY dml. 
dbMock.mockDmlError(new Contact(LastName = 'Doe'));


// Contacts with LastName = 'DOE' AND blank AccountId will fail on INSERT dml.
dbMock.mockDmlError(DmlType.INSERT_DML, new Contact(AccountId = null, LastName = 'Doe'));
```

## Notes

Query mocks are not supported via DatabaseMock right now, but they are supported via selector layer - Query package.
I will cover them there.

---
# Interface

```apex

class DatabaseService {
	static Id getFakeId(SObjectType sObjectType);

	DatabaseService withSharing();
	DatabaseService withoutSharing();
	DatabaseService setDMLOptions(Database.DMLOptions options);
	DatabaseService allOrNone(Boolean allOrNone);

	DatabaseMock useMock();

	List<SObject> query(String query);
	List<SObject> query(String query, Map<String, Object> boundVars);

	Database.QueryLocator getQueryLocator(String query);
	Database.QueryLocator getQueryLocator(String query, Map<String, Object> boundVars);

	Database.SaveResult insertRecord(SObject record);
	Database.SaveResult updateRecord(SObject record);
	Database.UpsertResult upsertRecord(SObject record, SObjectField field);
	Database.DeleteResult deleteRecord(SObject record);
	Database.UndeleteResult undeleteRecord(SObject record);

	List<Database.SaveResult> insertRecords(List<SObject> records);
	List<Database.SaveResult> updateRecords(List<SObject> records);
	List<Database.UpsertResult> upsertRecords(List<SObject> records, SObjectField field);
	List<Database.DeleteResult> deleteRecords(List<SObject> records);
	List<Database.UndeleteResult> undeleteRecords(List<SObject> records);
}
```

```apex | DatabaseMock
public with sharing class DatabaseMock {
	List<SObject> insertedRecords;
	List<SObject> updatedRecords;
	List<SObject> upsertedRecords;
	List<SObject> deletedRecords;
	List<SObject> undeletedRecords;

	DatabaseMock mockDmlError(SObject matcherRecord);
	DatabaseMock mockDmlError(DmlType dmlType);
	DatabaseMock mockDmlError(DmlType dmlType, SObject matcherRecord);
	DatabaseMock mockDmlError(DmlType dmlType, SObject matcherRecord, String errorMsg);
	List<DatabaseService.DmlError> getDMLErrors(DmlType issuedDML, SObject record);
```