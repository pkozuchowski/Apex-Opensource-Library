# Database Service

Intermediate layer between Database system class and business logic, which allows DML mocking and selecting
sharing context.

### Interface

```apex
public static Id getFakeId(SObjectType sObjectType);

public DatabaseService();

public DatabaseService withSharing();
public DatabaseService withoutSharing();
public DatabaseService setDMLOptions(Database.DMLOptions options);
public DatabaseService allOrNone(Boolean allOrNone);

public DatabaseMock useMock();

public List<SObject> query(String query);
public List<SObject> query(String query, Map<String, Object> boundVars);

public Database.QueryLocator getQueryLocator(String query);
public Database.QueryLocator getQueryLocator(String query, Map<String, Object> boundVars);

public Database.SaveResult insertRecord(SObject record);
public Database.SaveResult updateRecord(SObject record);
public Database.UpsertResult upsertRecord(SObject record, SObjectField field);
public Database.DeleteResult deleteRecord(SObject record);
public Database.UndeleteResult undeleteRecord(SObject record);

public List<Database.SaveResult> insertRecords(List<SObject> records);
public List<Database.SaveResult> updateRecords(List<SObject> records);
public List<Database.UpsertResult> upsertRecords(List<SObject> records, SObjectField field);
public List<Database.DeleteResult> deleteRecords(List<SObject> records);
public List<Database.UndeleteResult> undeleteRecords(List<SObject> records);
```

### Setting DML options:

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

///////////////////////////////
DatabaseService databaseService = new DatabaseService().allOrNone(false);
```

### Changing sharing context:

Database Service can switch between inherited, with sharing and without sharing DMLs:

```apex
DatabaseService databaseService = new DatabaseService()
    .withSharing();

DatabaseService databaseService = new DatabaseService()
    .withoutSharing();
```

<br/>

### Mocking DMLs - Pure Apex Tests

Pure Apex Tests are tests that do not commit anything to database and mock all queries.  
These tests are much more efficient than standard tests and allow us to test more exotic scenarios, but comes at cost of harder setup (DML/Query mocking)
and doesn't test interaction between classes in a trigger.

To mock DMLs, our business class should have instance of DatabaseService, through which it performs DMLS.  
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

<br/>

#### Mocking DML Exceptions

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


### Notes

Query mocks are not supported via DatabaseMock right now, but they are supported via selector layer - Query package.
I will cover them there.