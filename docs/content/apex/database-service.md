# Database Service
*Intermediate layer between Database system class and business logic, which allows DML mocking and selecting
sharing context in runtime.*

[Source](https://github.com/pkozuchowski/Apex-Opensource-Library/tree/master/force-app/commons/database)
[Install In Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04tJ6000000Li8zIAC)
[Install In Production](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tJ6000000Li8zIAC)

```bash
sf project deploy start -d "force-app/commons/database" -o sfdxOrg
```

---
# Documentation

## Description
The DatabaseService class is a framework designed to facilitate database operations. It provides methods for creating, updating, and deleting records, as
well as for executing queries and managing database transactions. The class is designed to be flexible and supports different execution modes, such
as user mode and system mode, to control the level of access and permissions applied during database operations.
The features include:
- Setting Access Level for all issued operations
- Setting `with sharing` and `without sharing` context
- Setting DML options
- Tracking issued database operations, touched records and results in unit tests
- Mocking all or selected DML operation results
- Providing streamlined Result and Error class

## Key Features

### Execution Modes
The class supports various execution modes to control how database operations are executed:
- `asUser()`: Enforces the object permissions, field-level security, and sharing rules of the current user. Always runs in "with sharing" context.
- `asSystem()`: Ignores object and field-level permissions, inherits sharing rules from the calling class.
- `asSystemWithSharing()`: Ignores object and field-level permissions but enforces record sharing rules.
- `asSystemWithoutSharing()`: Ignores both object and field-level permissions and record sharing rules.

Mode can be switched at any point of time.
```apex | Usage | MyService performs update "without sharing" even though the class itself is "with sharing"
public with sharing class MyService {
    private DatabaseService databaseService = new DatabaseService()
        .allOrNone(true)
        .asSystemWithoutSharing();

    public void updateContacts(List<Contact> contacts) {
        databaseService.updateRecords(contacts);
    }
}
```

```apex
DatabaseService databaseService = new DatabaseService()
    .asUser()
    .insertRecords(accounts);

DatabaseService databaseService = new DatabaseService()
    .asSystemWithoutSharing()
    .asSystemWithSharing();
```

### DML Operations and query execution:
The class provides the same methods as System.Database class:
- Methods for performing DML operations such as `insert`, `update`, `upsert`, `delete`, `undelete`, `merge` and `convertLead`.  
  Each operation has corresponding methods to handle single record and list of records.
- Query operations such as `query`, `getQueryLocator` and `getCursor`.

[See list of all methods.](/apex/database-service/interface)


### Streamlined DML Results
Database Service maps Database.*Result results into custom DML.Result and DML.Error classes with the same properties.

Standard Database.*Result classes are troublesome because:
- Despite having the same properties, there's no common abstract result class.
  It's challenging to implement methods that will work against Database.Result classes, without duplicating methods for each result class.
- Standard classes are not constructible in unit tests.
- Standard classes cause problems with serialization - can't be returned in @AuraEnabled methods or stored in stateful batch classes.

```apex
public class DML {

    public virtual class Result {
        @AuraEnabled public Boolean success;
        @AuraEnabled public Id id;
        @AuraEnabled public List<Error> errors;
        @AuraEnabled public DML.Type dmlType;
    }

    public virtual class Error {
        @AuraEnabled public List<String> fields;
        @AuraEnabled public String message;
        @AuraEnabled public StatusCode statusCode;
    }
}
```

### Tracking DMLs in Unit Tests
When run in Unit Test context, DatabaseService will register all issued DML operations.
Developers can reference to check issued Database operations, DML rows and results.

```apex | Operations Registry
class DatabaseService {
    @TestVisible DML.Register register;
}

class DML.Register {
    public DML.InsertDML[] inserts;
    public DML.UpdateDML[] updates;
    public DML.UpsertDML[] upserts;
    public DML.DeleteDML[] deletes;
    public DML.UndeleteDML[] undeletes;
    public DML.MergeDML[] merges;
    public DML.QueryOperation[] queries;

    public SObject[] inserted;
    public SObject[] updated;
    public SObject[] upserted;
    public SObject[] deleted;
    public SObject[] undeleted;
}
```

Each operation is tracked as independent entry in a list and consists of records and results. Developers can access issued operations through "register"
property.
```apex
databaseService.register.inserts.size(); // Returns how many times insert operation were called.
Account parentAccount = (Account) databaseService.register.inserts[0].records[0]; // returns first record from first Insert
databaseService.register.inserts[0].results[0]; // returns result for first record
databaseService.register.inserted[0]; //returns first successfully inserted record, regardless in which operation
```

### Mocking Queries and DMLs
DatabaseService provides a variety of ways to mock DMLs:
- Queries can be mocked by passing `mockId` parameter to `query()` method, or through SObjectType if it doesn't make difference for unit test for mock all
  queries against the sObjectType.
- All operations can be mocked using `.mockDmls()` method. In this mode, no DMLs will actually hit Database. Results are faked as success and fake Ids are
  assigned to inserted and upserted records.
- Particular DML Operation can be mocked to have predetermined success or error response.
- DML Operations against particular SObject or subset of records can be mocked
- Combination of above

[See more in Mocking DMLs Tab](/apex/database-service/mocking-dmls)


### Setting DML options
Provided DML options are applied to all DMLs.
Developers can set them through withDmlOptions() method and there's shorthand method for allOrNone() parameter.
DML Options can be constructed with builder class:

```apex
DatabaseService databaseService = new DatabaseService()
    .withDMLOptions(new DMLOptionsBuilder()
        .allOrNone(false)
        .allowDuplicates(false)
        .allowFieldTruncation(false)
        .build()
    );

//Shortcut for All or None option
DatabaseService databaseService = new DatabaseService().allOrNone(false);
```

---
# Architecture

![UML](/img/database-service-uml.svg)
![UML](/img/database-service-uml-2.svg)


---
# Unit of Work

## Description
The Unit of Work is an enterprise architectural pattern that ensures a series of DML operations on different sObjects are treated as a single, cohesive
transaction.
It acts as a boundary that tracks DMLs (inserts, updates, deletes) of records within a single transaction, so developers do not have to care about bulkification
and relationship tracking.

`DatabaseUnitOfWork` class extends `DatabaseService` class and can use all of its capabilities to modify DML behavior:
- Execution Modes
- DML Options
- All Or None with a rollback mechanism for all DML operations
- Mocking DMLs

## Resolving relationships
Unit of Work provides methods to relate SObjects with each other in a Parent-Child relationship.
When a Parent record is inserted, all child records related to that parent will have their lookup fields populated.
This is especially helpful when creating multi-level relationships, because client class does not have to keep track of lookups and ids.

```apex | Methods
DatabaseUnitOfWork relate(SObject record, SObjectField lookupField, SObject parent);
void insertRecord(SObject record, SObjectField lookupField, SObject parent);
void updateRecord(SObject record, SObjectField lookupField, SObject parent);
void upsertRecord(SObject record, SObjectField extId, SObjectField lookupField, SObject parent);

/* Plus all  methods inherited from DatabaseService */
DatabaseService asUser();
DatabaseService asUserWithPermissionSetId(Id permissionSetId);
DatabaseService asSystem();
DatabaseService asSystemWithSharing();
DatabaseService asSystemWithoutSharing();

DML.Result insertRecord(SObject record);
DML.Result updateRecord(SObject record);
DML.Result upsertRecord(SObject record);
DML.Result deleteRecord(SObject record);
DML.Result undeleteRecord(SObject record);
DML.Result mergeRecords(SObject record);
//... etc.
```

```apex | Example of usage
DatabaseUnitOfWork uow = new DatabaseUnitOfWork();

for (Integer i = 0; i < 10; i++) {
    Account account = new Account(Name = 'Test');
    uow.insertRecord(account);

    Contact childContact = new Contact(LastName = 'Doe');
    uow.insertRecord(childContact, Contact.AccountId, account);
}

uow.commitWork();
```

In this example, UoW will execute 2 DMLs – one insert on Accounts and one insert on Contacts, each operation with 10 records inserted.
AccountId on Contacts will be populated.

## Order of DMLs
By default, Unit of Work will track the order of issued DML Operations and will execute them in the same order.

For example, call the following:
- insertRecord(**account**)
- insertRecord(_contact_)
- insertRecord(**account**)
- insertRecord(_contact_)
- insertRecord(opportunity)
- updateRecord(_contact_);
- commitWork();

It will result in the following operation order:
- insert Accounts
- insert Contacts
- insert Opportunities
- update Contacts

It is possible to customize the order of the operations using constructors:
- `public DatabaseUnitOfWork()`  
  DMLs are ordered in order they are issued.
- `public DatabaseUnitOfWork(List<SObjectType> sObjectTypes)`  
  DMLs are ordered by specified SObjectType order and the following operation order:
    1. INSERT
    2. UPSERT
    3. UPDATE
    4. MERGE
    5. CONVERT LEAD
    6. DELETE
    7. UNDELETE

- `public DatabaseUnitOfWork(List<DML.Order> order)`
  DMLs will follow specified SObject, Operation and Upsert Field order:
```apex
DatabaseUnitOfWork uow = (DatabaseUnitOfWork) new DatabaseUnitOfWork(new List<DML.Order>{
    new DML.Order(User.SObjectType, DML.UPSERT_DML, Schema.User.Username),
    new DML.Order(User.SObjectType, DML.UPSERT_DML, Schema.User.FederationIdentifier),
    new DML.Order(Contact.SObjectType, DML.INSERT_DML),
    new DML.Order(Opportunity.SObjectType, DML.DELETE_DML),
    new DML.Order(Opportunity.SObjectType, DML.INSERT_DML)
});
```

## Failure Handling
When Unit of Work operates in `"All or None"` mode, this mode applies to entire Unit of Work. When any of the operations fails,
all operations are rolled back.

---
# UoW Invocable

## Invocable Action for Flows

The **Unit of Work** feature now includes an **Invocable Action** that enables the registration of DML operations within Flows. This enhancement allows DMLs to
be queued throughout various parts of a Flow and executed collectively when the `Commit` operation is invoked.

By leveraging this action, updates to the same record—across multiple Flows—are consolidated into a single DML operation, ensuring all field changes are applied
in one atomic transaction.

## Key Guidelines

- Always invoke the `Commit` operation at the end of the flow, or in case of Record-Triggered flows as the last Flow, to ensure all registered DMLs are
  executed.
- After `Commit` is called, any new DML operations will be tracked in a new Unit of Work instance.
- Commit Action can be configured to run in User Mode, System With Sharing or System Without Sharing mode. Flow's Run Mode is ignored.

## How to Use

1. **Create a Record Variable**  
   Define a new Flow variable of type **Record** and use an **Assignment** element to set the fields you want to update.

2. **Register the DML Operation**  
   Add the **Database Unit of Work Operation** action to your Flow. Specify the desired DML operation and pass in the input record variable.

3. **Invoke Commit**  
   Create a separate **Record-Triggered Flow** (configured to run last) and include the **Commit** action to finalize the DML execution.

## Important Notes

- The Unit of Work mechanism attempts to **deduplicate** record operations using record Id or Upsert Field. If the same record is updated in multiple places, it
  will be registered as a single update with all modified fields.
- To avoid unintended overwrites, ensure that only the fields with actual changes are included in the **Assignment** element.
- DML operations are executed in the order they are registered, following the same rules as the `DatabaseUnitOfWork` class.

## Roadmap
- Support for "**Relate**" method and adding parent records directly in insert/upsert/update operation.
  When a parent record is provided, parent is inserted first, and then child records are inserted with the lookup field populated.
- Support for setting fields directly in the action, instead of using a Record variable and Assignment element.
- Support for **Discard Work** action to clear all registered DMLs without executing them.

![db-uow-flow-1.png](/img/db-uow-flow-1.png)
![db-uow-flow-2.png](/img/db-uow-flow-2.png)
![db-uow-flow-3.png](/img/db-uow-flow-3.png)
![db-uow-flow-3.png](/img/db-uow-flow-4.png)
![db-uow-flow-3.png](/img/db-uow-flow-5.png)




---
# Mocking

## Prerequisites
To mock DMLs, our business class should have a `@TestVisible` instance of DatabaseService, through which it performs DMLs.  
For example purposes, let's assume this class does some inserts and updates;

```apex | Example Class with Database Service
public class AccountService {
    @TestVisible static DatabaseService databaseService = new DatabaseService().asUser();

    public void doBusinessLogic() {
        // Query Account
        Account account = (Account) databaseService.query('SELECT Id FROM Account Limit 1');

        // Create Contact
        Contact contact = new Contact(
            AccountId = account.Id,
            LastName = 'Doe'
        );
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

## Mocking all DMLs
Calling `.mockDmls()` will ensure that no operation will actually hit a database. For each record in the DML, a success result with no error will be returned.

Additionally, insert and upsert operations will generate fake ID for each record. Fake ids will look, depending on sObject, like this:
`001000000000001, 001000000000002, 003000000000003`

```apex | Unit Test
DatabaseService db = AccountService.databaseService.mockDmls();

service.doBusinessLogic();
```

## Partial mocking
Framework can apply mock only to selected records and perform actual (or mocked) operations against the rest. This can be done using the following methods:
```apex
mockDmlError(SObject);
mockDmlError(DML.Type dmlType);
mockDmlError(DML.Type dmlType, SObject record);
mockDmlResultById(DML.Type dmlType, Id recordId, Boolean success);
mockDmlResult(DML.Type dmlType, SObject record, Boolean success);
mockDmlResult(DML.Type dmlType, SObject record, DML.Result result);
mockDmlResult(DML.DmlResultMock mock);
```

## Mock Parameters
1. **DML.Type** refers to DML Type available in DML class:
    - DML.Type.INSERT_DML - will match inserts
    - DML.Type.UPDATE_DML - will match updates
    - etc.
    - null matches all operations.
2. **Id** - is for matching records by Id.
3. **SObject** - is for matching sObject:
    - `new Account()` will match all accounts
    - `new Account(Name='Test')` will match all accounts with specified fields – in this case, accounts with Name equals "Test".
    - null matches all records
4. **Boolean success** - True, if result should be mocked as a success result or false for error result. If false, DML.GENERIC_ERROR will be used as error
   message.
5. **DML.Result** - Provided result will be returned for DMLs. This result is cloned and customized with record ID for each row.

## Query Mocking
Query can be mocked using mockId or by sObjectType:

```apex | All Account Queries will return following list of Accounts
DatabaseService db = AccountService.databaseService
    .mockQuery(new List<Account>{
        new Account()
    });
```

```apex | All Account Queries will return following list of Accounts
// Service:
Integer cnt = databaseService.countQuery('SELECT Id FROM Account');

// Test
DatabaseService db = AccountService.databaseService
    .mockQuery(Account.SObjectType, 5);
```

```apex | Mock query using mockId
// Service:
Integer cnt = databaseService.countQuery('getCount', 'SELECT Id FROM Account');

// Test
DatabaseService db = AccountService.databaseService
    .mockQuery('getCount', 5);
```

## Examples
```apex | Example 1 | DMLs will be executed against Database, but DML on Opportunities will fail with error on 2nd opportunity.
DatabaseService db = AccountService.databaseService
    .mockDmls()
    .mockDmlError(new Opportunity(Name = 'Opportunity 2'));
```

```apex | Example 2 | DMLs will be executed against Database, 2 opportunities will be inserted, one will have mocked error.
DatabaseService db = AccountService.databaseService
    .allOrNone(false)
    .mockDmlError(new Opportunity(Name = 'Opportunity 2'));
```

```apex | Example 3 | DMLs will be executed against Database, no opportunities will be inserted, becaues one will have a mocked error.
DatabaseService db = AccountService.databaseService
    .allOrNone(true)
    .mockDmlError(new Opportunity(Name = 'Opportunity 2'));
```

```apex | Example 4 | Database.Result instance will have the same properties as provided + record Id will be filled in.
DatabaseService db = AccountService.databaseService
    .mockDmlResult(DML.Type.INSERT_DML, new Opportunity(Name = 'Opportunity 2'),
        new DML.Result(null, false, new List<Error>{
            new Error('Some Error Message')
        }));
```

```apex | Example 5 - Mock by DML Type | All Inserts will fail.
DatabaseService db = AccountService.databaseService
    .mockDmlError(DML.INSERT_DML);
```

---
# Interface

```apex | DatabaseService
public class DatabaseService {
    @TestVisible DML.Register register;

    public static Id getFakeId(SObjectType sObjectType);

    public DatabaseService() {}

    public DatabaseService asUser();
    public DatabaseService asUserWithPermissionSetId(Id permissionSetId);
    public DatabaseService asSystem();
    public DatabaseService asSystemWithSharing();
    public DatabaseService asSystemWithoutSharing();
    public DatabaseService withAccessLevel(AccessLevel level);

    public DatabaseService withDMLOptions(Database.DMLOptions options);
    public DatabaseService allOrNone(Boolean allOrNone);

    public List<SObject> query(String query);
    public List<SObject> query(String query, Map<String, Object> boundVars);
    public List<SObject> query(String mockId, String query, Map<String, Object> boundVars);

    public Integer countQuery(String query);
    public Integer countQuery(String query, Map<String, Object> boundVars);
    public Integer countQuery(String mockId, String query, Map<String, Object> boundVars);

    public Database.Cursor getCursor(String query, Map<String, Object> boundVars);

    public Database.QueryLocator getQueryLocator(String query);
    public Database.QueryLocator getQueryLocator(String query, Map<String, Object> boundVars);


    public DML.Result insertRecord(SObject record);
    public DML.Result updateRecord(SObject record);
    public DML.Result upsertRecord(SObject record, SObjectField field);
    public DML.Result deleteRecord(Id recordId);
    public DML.Result deleteRecord(SObject record);
    public DML.Result undeleteRecord(Id recordId);
    public DML.Result undeleteRecord(SObject record);

    public List<DML.Result> insertRecords(List<SObject> records);
    public List<DML.Result> updateRecords(List<SObject> records);
    public List<DML.Result> upsertRecords(List<SObject> records, SObjectField field);
    public List<DML.Result> deleteRecords(List<Id> recordIds);
    public List<DML.Result> deleteRecords(List<SObject> records);
    public List<DML.Result> undeleteRecords(List<Id> recordIds);
    public List<DML.Result> undeleteRecords(List<SObject> records);

    public DML.MergeResult mergeRecords(SObject primary, List<Id> duplicates);
    public DML.LeadConvertResult convertLead(Database.LeadConvert convert);
    public List<DML.LeadConvertResult> convertLeads(List<Database.LeadConvert> converts);

    @TestVisible DatabaseService mockQuery(List<SObject> records);
    @TestVisible DatabaseService mockQuery(SObjectType sObjectType, Object result);
    @TestVisible DatabaseService mockQuery(String mockId, Object result);

    @TestVisible DatabaseService mockDmls();
    @TestVisible DatabaseService mockDmlError(SObject matcherRecord);
    @TestVisible DatabaseService mockDmlError(DML.Type dmlType);
    @TestVisible DatabaseService mockDmlError(DML.Type dmlType, SObject matcherRecord);
    @TestVisible DatabaseService mockDmlResultById(DML.Type dmlType, Id mockedRecordId, Boolean success);
    @TestVisible DatabaseService mockDmlResult(DML.Type dmlType, SObject matcherRecord, Boolean success);
    @TestVisible DatabaseService mockDmlResult(DML.Type dmlType, SObject matcherRecord, DML.Result result);
    @TestVisible DatabaseService mockDmlResult(DML.DmlResultMock mock);
}
```

```apex | DatabaseUnitOfWork
public class DatabaseUnitOfWork extends DatabaseService {
    public DatabaseUnitOfWork() {}
    public DatabaseUnitOfWork(List<SObjectType> sObjectTypes) {}
    public DatabaseUnitOfWork(List<DML.Order> order) {}

    public DatabaseUnitOfWork relate(SObject record, SObjectField lookupField, SObject parent);
    public void insertRecord(SObject record, SObjectField lookupField, SObject parent);
    public void updateRecord(SObject record, SObjectField lookupField, SObject parent);
    public void upsertRecord(SObject record, SObjectField extId, SObjectField lookupField, SObject parent);
    public List<DML.DMLOperation> commitWork();
}
```

---
# Change Log
### v2.3
- Added Invocable Unit of Work action to register DMLs in Flows

### v2.2
- Added delete and undelete by record Id operations.
- Added mocking by record Id.

### v2.1
- Added inserted/updated/deleted etc. record lists to register

### v2.0
- Entire framework has been redesigned.
- Added Unit of Work class, extending DatabaseService.
- Issued DML Operations can be tracked in unit tests at all times
- DML Mocks and Query mocks can be mixed in with real DMLs

##### DatabaseService:
- Added asX methods:
    - `asUser`
    - `asSystem`
    - `asSystemWithSharing`
    - `asSystemWithoutSharing`

### v1.1.0
- Simplified DML Issuers code
- Added Database.Cursor
