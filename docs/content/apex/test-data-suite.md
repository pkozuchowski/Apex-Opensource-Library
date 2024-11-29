# Test Data Suite
*Access records created in @TestSetup*

[Source](https://github.com/pkozuchowski/Apex-Opensource-Library/tree/master/force-app/commons/testDataSuite)
[Install In Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04t08000000ga9iAAA)
[Install In Production](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t08000000ga9iAAA)

```bash
sf project deploy start -d "force-app/commons/testDataSuite" -o sfdxOrg
```

---
# Documentation
Suite of test data which reassembles static map, but is persisted between test setup and test methods.

Developers can use this class to create several different test record sets in `@TestSetup` and retrieve them later in unit test methods without any queries.  


## Example
In our test class, we want to create test data upfront in `@TestSetup` method to test different scenarios.  
Our test data will be grouped into two `TestDataSuites`:
1. Account with related cases and contacts
2. Account without any related records

```apex
private class MyClassTest {

	@TestSetup
	static void testSetup() {
		TestDataBuilder dataBuilder = new TestDataBuilder();

		List<Account> accounts = dataBuilder
			.create(new Account(Name = '1'))
			.create(new Account(Name = '2'))
			.insertRecords();

		Case[] cases = (Case[]) dataBuilder
			.create(new Case(Subject = 'Case 1', AccountId = accounts[0].Id))
			.similarly(new Case(Subject = 'Case 2'))
			.similarly(new Case(Subject = 'Case 3'))
			.insertRecords();

		Contact[] contacts = (Contact[]) dataBuilder
			.create(new Contact(FirstName = 'Joe', LastName = 'Doe1', AccountId = accounts[0].Id))
			.similarly(new Contact(LastName = 'Doe2'))
			.similarly(new Contact(LastName = 'Doe3'))
			.similarly(new Contact(LastName = 'Doe4'))
			.insertRecords();


		TestDataSuite suite1 = TestDataSuiteManager.registerSuite('Account with related');
		suite1.registerRecord('Account', accounts[0]);
		suite1.registerRecords(Case.Subject, cases);
		suite1.registerRecordsUnderGroup('Contacts to process', new List<Contact>{contacts[0], contacts[1]});
		suite1.registerRecordsUnderGroup('Contacts to remove', new List<Contact>{contacts[2], contacts[3]});

		TestDataSuite suite2 = TestDataSuiteManager.registerSuite('Account without related');
		suite2.registerRecord('Account', accounts[1]);

		TestDataSuiteManager.saveSuites();
	}
}
```

This code internally produces a map of sObjects which looks like this:
```js
{
	/*Test Data Suite 1*/
	"Account with related": {
		"sobjectByUniqueName": {
			//from registerRecord('Account', accounts[0])
			"Account": account1,
			//from registerRecords(Case.Subject, cases)
			"Case 1": case1,
			"Case 2": case2,
			"Case 3": case3
		},
		"sobjectBySObjectType": {
			"Account": [account1],
			"Case": [case1, case2, case3],
			"Contact": [contact1, contact2, contact3, contac4]
		},
		"sobjectByGroup": {
			//from registerRecordsUnderGroup('Contacts to process', ...);
			"Contacts to process": [contact1, contact2],
			"Contacts to remove": [contact3, contact4]
		}
	},
	/*Test Data Suite 2*/
	"Account without related": {
		"sobjectByUniqueName": {
			"Account": account2
		},
		"sobjectBySObjectType": {
			"Account": [account2]
		}
	}
}
```

Then in our test data, we can retrieve records from the test data suite without doing any additional queries.  
Framework uses one query to retrieve all the suites.
```apex
@IsTest
static void myTestMethod() {
	TestDataSuite suite = TestDataSuiteManager.getSuite('Account with related');

	//Get record by unique name
	Account acc = (Account) suite.get('Account');
	Case case1 = (Case) suite.get('Case 1');

	//Get All Cases in Suite
	List<Case> cases = suite.get(Case.SObjectType);

	//Get one group of records 
	List<Contact> contacts = suite.getGroup('Contacts to remove');
}
```

---
# Specification

Normally, the static variables are not persisted between @TestSetup and @IsTest methods — we can't set records in static field and reference them later in the
test.  
TestDataSuite framework workarounds that by persisting data in ContentFile - it uses 1 DML for saving and 1 SOQL query for retrieving the data,
but let's us reference any number of records in unit tests without any additional queries.


## TestDataSuiteManager
Creates, retrieves and persists TestDataSuites.

<details>
	<summary>registerSuite(String uniqueName)</summary>

```apex
public static TestDataSuite registerSuite(String uniqueName);
```
Factory Method that creates TestDataSuite and registers it internally.
This method should be called in @TestSetup to create suite of data.

##### Parameters
- `String uniqueName` - Unique name of the TestDataSuite. Used later in test to retrieve a particular suite.

##### Return Value
- `TestDataSuite` - Test Data Suite created by manager.

##### Usage
```apex
@TestSetup
static void testSetup() {
	TestDataSuite suite1 = TestDataSuiteManager.registerSuite('Account with related');
}
```
</details>

<details>
	<summary>getSuite(String uniqueName)</summary>

```apex
public static TestDataSuite getSuite(String uniqueName);
```
Retrieves previously created Data Suite by its unique name. This method should be called in test methods.


##### Parameters
- `String uniqueName` - Unique name of the TestDataSuite.

##### Return Value
- `TestDataSuite` - Test Data Suite that was previously created in @TestSetup

##### Usage
```apex
@IsTest
static void testMethodName() {
	TestDataSuite suite = TestDataSuiteManager.getSuite('Account with related');
}
```
</details>

<details>
	<summary>saveSuites()</summary>

```apex
public static void saveSuites();
```
Persists TestDataSuites created in @TestSetup.
It should be called at the end of @TestSetup when all test data is already inserted.

##### Usage
```apex
@TestSetup
static void testSetup() {
	TestDataSuite suite = TestDataSuiteManager.registerSuite('Account with related');
	//...
	TestDataSuiteManager.saveSuites();
}
```
</details>


## TestDataSuite

<details>
	<summary>registerRecords(SObjectField field, SObject[] records)</summary>

```apex
public void registerRecords(SObjectField field, SObject[] records);
```
Registers records in the test data suite by unique value stored in sobject field.
Record can be later retrieved in unit test using get() method.


##### Parameters
- `SObjectField field` - Field with unique values by which each record will be registered.
- `SObject[] records` - List of records to add to the suite.

##### Usage
```apex
@TestSetup
static void testSetup() {
	//...
	suite.registerRecords(User.Username, users);
}
```
</details>

<details>
	<summary>registerRecord(String uniqueName, SObject record)</summary>

```apex
public void registerRecord(String uniqueName, SObject record);
```
Registers record in test data suite by unique name.
Record can be later retrieved in unit test using get() method.


##### Parameters
- `String uniqueName` - Unique identifier for the record.
- `SObject record` - SObject record to save in the suite.

##### Usage
```apex
@TestSetup
static void testSetup() {
	//...
	suite.registerRecord('My User', user);
}
```
</details>


<details>
	<summary>registerRecordsUnderGroup(String groupName, SObject[] records)</summary>

```apex
public void registerRecordsUnderGroup(String groupName, SObject[] records);
```
Registers record in test data suite by group.
Record can be later retrieved in unit test using getRecords() method.

##### Parameters
- `String groupName` - Unique identifier for the group of records.
- `SObject[] records` - SObject record to save in the group.

##### Usage
```apex
@TestSetup
static void testSetup() {
	//...
	suite.registerRecordsUnderGroup('Contacts to process', contacts);
}
```
</details>

<details>
	<summary>get(String uniqueName)</summary>

```apex
public SObject get(String uniqueName);
```
Returns Record registered in the test data suite under give unique name.

##### Parameters
- `String uniqueName` - Unique identifier for the record.

##### Usage
```apex
@IsTest
static void myTestMethod() {
	TestDataSuite suite = TestDataSuiteManager.getSuite('Account with related');
	User user = (User) suite.get('My User');
}
```
</details>


<details>
	<summary>get(SObjectType type)</summary>

```apex
public List<SObject> get(SObjectType type);
```
Returns all records of given SObjectType in suite.

##### Parameters
- `SObjectType type` - SObjectType to return.

##### Usage
```apex
@IsTest
static void myTestMethod() {
	TestDataSuite suite = TestDataSuiteManager.getSuite('Account with related');
	List<Case> cases = suite.get(Case.SObjectType);
}
```
</details>


<details>
	<summary>getGroup(String groupName)</summary>

```apex
public List<SObject> getGroup(String groupName);
```
Return all records registered in given group.
Respects order in which records were added to the group.

##### Parameters
- `String groupName` - Unique name of the records group to return.

##### Usage
```apex
@IsTest
static void myTestMethod() {
	TestDataSuite suite = TestDataSuiteManager.getSuite('Account with related');
	List<Contact> contacts = suite.getGroup('Contacts to remove');
}
```
</details>