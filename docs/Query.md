# Query Framework
*Flexible Selector Layer with Record Caching mechanism.*

[Source](https://github.com/pkozuchowski/Apex-Opensource-Library/tree/master/force-app/commons/queries)
[Dependency 1](/apex/database-service)
[Dependency 2](/apex/runtime)
[Install In Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04t08000000ga9TAAQ)
[Install In Production](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t08000000ga9TAAQ)

```bash
sf project deploy start \
-d force-app/commons/queries \
-d force-app/commons/shared \
-d force-app/commons/database \
-o sfdxOrg
```

---
# Documentation
Query is an extensible approach for a Selector layer in which every SOQL query is encapsulated in an object.  
This stands in opposition to more traditional approaches where Selector is a service class with a method for each query.
The common problem with service-type selectors is the code bloat that shows up for any deviations from the base query.  
Selector's method is not able to make up for small differences in the queries.

With Query Object approach, it's very easy to tailor the queries for each client code.  
Notice how simple and verbose this is:
```apex
//Given:
Set<String> externalIDs;

List<Account> accounts = Query.Accounts.byExternalId(externalIDs).getList();
```

## Extend, Filter, Reduce
Query Framework assumes that each query may need to be tailored to the specific requirement:
* Extend with additional fields, relationships
* Filtered with additional WHERE clauses
* Grouped or Limited
* Reduced to a list, map, field or other type
* etc.

### Extend with additional fields, relationships, limits...

Consider this example, where we can add additional fields to the selector's base field set.
```apex
List<Contact> contact = Query.Contacts
	.byAccountId(/*...ids*/)
	.withParentAccount()
	.withFields('FirstName, LastName, CreatedBy.Name')
	.getList();
```

### Define WHERE Clause

Where clause can be combined from methods implemented in ContactQuery and generic methods implemented in QueryObject class.
```apex
List<Contact> contact = Query.Contacts
	.byAccountId(/*...ids*/)
	.byRecordTypeId(/*Record Type Id*/)
	.getList();
```

For very specialized and complex queries, there are multiple ways to define the conditions:
- Combining field filters and declaring filter logic.
  Each identifier in the logic string (`{0}`) corresponds to the `byCondition()` method above in the order they were declared.
	```apex
	Query.Accounts
		.byName('TestName')
		.byRecordTypeDeveloperName('SMB')
		.byOwnerId(UserInfo.getUserId())
		.withFilterLogic('{0} OR ({1} AND {2})')
		.getList();
	```
- Introduce case-specific filtering method in SObject's query class:
	```apex
	class ContactQuery {

		public ContactQuery byMySuperSpecificCondition(String name, String recordTypeName, Id ownerId) {
			appendMockName('byMySuperSpecificCondition');
			return (ContactQuery) wheres('Name =:name OR (RecordType.DeveloperName = :recordTypeName AND OwnerId = :ownerId)', 
				new Map<String, Object>{
				'name' => name,
				'recordTypeName' => recordTypeName,
				'ownerId' => ownerId
			});
		}
	}
	```
	```apex
  Query.Accounts.byMySuperSpecificCondition(
	   'TestName', 'SMB', UserInfo.getUserId()
  ).getList();
	```
  You can even mix that with other methods:
	```apex
  Query.Accounts
  .byMySuperSpecificCondition( 'TestName', 'SMB', UserInfo.getUserId() )
  .byIsActive(true)
  .getList();
	```

- Using QueryConditions to build the query:
	```apex
	QueryConditions c = new QueryConditions();
	Query.Accounts
		.wheres(
			c.ORs(
				c.field(Account.Name).equals('TestName'),
				c.ANDs(
					c.field('RecordType.DeveloperName').equals('SMB'),
					c.field(Account.OwnerId).equals(UserInfo.getUserId())
				)
			)
		)
		.getList();
	```

- Writing WHERE clause directly in client code:
	```apex
	List<String> names = new List<String>();
	List<String> externalIds = new List<String>();
	Id recordTypeId;
	
	Query.Accounts
		.wheres('Name IN :names OR (RecordTypeId =:rtId AND ExternalID IN :externalIds)', new Map<String, Object>{
			'names' => names,
			'rtId' => recordTypeId,
			'externalIds' => externalIds
		})
		.getList();
	```

### Reduce to result
Query result can be reduced to different things:
```apex
//given
ContactQuery contactQuery = Query.Contacts.byEmail();

List<Contact> contacts = contactQuery.getList();
Contact c = ContactQuery.getFirst();
Contact c = ContactQuery.getFirstOrNull(); // Does not throw exception on empty results

// Return Set of Ids
Set<Id> contactIds = contactQuery.getIds();

// Return Map by Contact Id
Map<Id, Contact> contactById = contactQuery.getMapById();

// Map by given field
Map<String, Contact> contactByEmail = ContactQuery.getMapByString(Contact.Email);

Id contactId = contactQuery.getFirstIdOrNull();
String contactEmail = contactQuery.
```

---
# Caching
The framework provides a mechanism to register cache mechanism for specific sObjects.  
Once queried, records will be saved to the cache—either static (lives in a static map through the apex transaction), Org or Session Platform Cache.  
This has to be explicitly enabled for specific sobject types and work only on queries with one WHERE condition by cached field.

The cache is configured in Custom Metadata (QueryCache__mdt):
![image](https://github.com/pkozuchowski/Apex-Opensource-Library/assets/4470967/8da502f2-dd5f-4ffe-8494-d859436fa5d9)

Let's consider Profile Cache settings:

| Field          | Value                                   | Description                                                                                          |
|----------------|-----------------------------------------|------------------------------------------------------------------------------------------------------|
| SObject__c     | Profile                                 | Qualified API Name (with namespace) for the SOObject.                                                |
| Active__c      | true                                    | Is Cache Active. Can be turned off quickly if needed.                                                |
| Storage__c     | Organization                            | Storage — where records should be stored.                                                            |
| SOQL__c        | SELECT Id, Name FROM Profile            | If provided, empty cache will be first initialized with the results of this SOQL.                    |
| CacheFields__c | SELECT Id, Name FROM Profile            | Profile records will be cached using Id and Name fields. <br/> Queries by Id or Name will use Cache. |
| TimeToLive__c  | 86400                                   | How many seconds records will be stored in Organization or Session cache.                            |
| Description__c | Caches all Profile records in Org cache | Description of the cache purpose for other admins.                                                   |

<br/>

## Cache Storage
There are three options for Cache storage:
- Organization — Records are cached in an Org Platform Cache and all users can benefit from a single query
- Session — Cached records are only visible for the user that performed the query. Same queries done by different users will not use each other's cache, but
  they will use their own cache on a subsequent query.
- Transaction—Records are cached only for the duration of single apex request (ex. through execution of the trigger)

## Explanation
This configuration means that Profile records will be cached in Org platform cache using `Id` and `Name` fields for caching -
queries by ID or Name will be able to use cache and results will be saved for 24 hours.
During that time, all users will be saving trip to the database whenever a query for Profile is issued.

When the cache is empty and first user issues a Profile query, it will initialize the cache with the SOQL__c query.
It can be left empty if you don't want to repopulate cache with any records, but want to cache once queried records.
This is described further in the Progressive Caching section.

Now when a user calls an action that requires Profile data, the framework will first check if we have profile in cache.

## Progressive Caching
Let's assume that we're querying 50 queue records—we have 25 in cache, and 25 are not.  
The Framework will take 25 records from the cache and query only the remaining 25 from the database and put them in the cache.   
Consecutive call with the same query will get all 50 records from the cache and thus will not use any query.

## When Cache is not used:
- Any deployments clear Platform Cache out of the box. You don't need to worry that you will have invalid setup objects cached.
- When the query is modified, additional fields are added—in that case, the Framework assumes that cache may not have the additional fields.
- When there's more than one WHERE clause. The Framework can only retrieve records by one key, in Profile example it would be query by Id or DeveloperName
  ```apex
  Query.Profiles.byName('System Administrator');
  Query.Profiles.byId(UserInfo.getProfileId());
  ```

---
# Mocking
You can easily mock the query using class and method name where the query was invoked, or by associating query with a mock Id:

If our client code looks like this:
```apex
public with sharing class AccountQuotingService {

    public void generateQuotes(Set<Id> accountIds) {
        List<Accounts> accounts = Query.Accounts.byId(accountIds).getList();
        
        // ... 
    }

}
```

Then, the easiest way to mock it is as follows:
```apex
@IsTest
static void myTestMethod() {
    Query.Accounts.mock('AccountQuotingService.generateQuotes', new List<Account>{
        // my mocked query result
    });
    
    // or
    
    Query.mock(Account.SObjectType, 'AccountQuotingService.generateQuotes', new List<Account>{
        // my mocked query result
    });
}

```

Alternatively, you can still use mock name:
```apex
@IsTest
static void myTestMethod() {
    Query.Accounts.mock('myAccountQuery', new List<Account>{
        // my mocked query result
    });
    
    // or
    
    Query.mock(Account.SObjectType, 'myAccountQuery', new List<Account>{
        // my mocked query result
    });
}

```

### Special cases:
Static initialization and static block is mocked just by class name: 


```apex
public with sharing class AccountQuotingService {
    private static List<Profile> profiles = Query.Profiles.getList();
}
```

```apex
Query.Accounts.mock('AccountQuotingService', new List<Account>{
    // my mocked query result
});
```

All constructors are mocked as follows:
```apex
Query.Accounts.mock('AccountQuotingService.<init>', new List<Account>{
// my mocked query result
});
```

---
# Specification

## Constructing Query
Query can be constructed in two ways:
- by extending QueryObject class
- by using a generic query

### Extending Query class
The default way is to introduce a new class for our SObject—this allows us to introduce SObject specific methods.
If we want to have selector for Account, then we should create `AccountQuery` class that
extends `QueryObject`.
In the constructor, we should define default fields (optional) and sObject type (required):
```apex
public with sharing class AccountQuery extends QueryObject {
	public AccountQuery() {
		super(new List<String>{
			'Id',
			'Name'
		}, Account.SObjectType);
	}
}
```

Then we can add Account-specific methods — that could be methods that add more fields to the query or methods that add WHERE condition.  
Condition methods should append mock name - this way, we can use this string for mocking in unit tests, without specifying mock name explicitly.
```apex
public AccountQuery withContacts() {
	withChildren(new List<String>{
		'Id'
	}, 'Contacts');
	return this;
}

public AccountQuery byName(Set<String> names) {
	appendMockName('byName');
	return (AccountQuery) byField(Account.Name, 'IN', names);
}
```

AccountQuery can be added to Query container for verbosity or to domain class, or it can be used as is:
```apex
Query.Account.byName('Test').getList();

Accounts.query.byName('Test').getList();

new AccountQuery().byName('Test').getList();


```

### Generic Query
It's possible to construct a query without an inheritance, but it will be only possible to use default fields.

```apex
Query.fromSObject(Account.SObjectType)
	.byField(Account.Name, '=', 'Test Account')
	.getList();
```

## QueryObject
Parent class for all selectors.

### Constructors
protected QueryObject(SObjectType sObjectType)
protected QueryObject(List<String> fields, SObjectType sObjectType)

### Selecting Fields
<details>
	<summary>withFields(Query.Fields field)</summary>

```apex
public QueryObject withFields(Query.Fields field);
```

Selects All, Custom or Standard fields.  
Query is restricted to 200 records in case of ALL and CUSTOM fields.

#### Parameters
- `fields` - `Query.Fields.ALL` | `Query.Fields.CUSTOM` | `Query.Fields.STANDARD`  
  Corresponds to FIELDS(ALL) in SOQL.

#### Usage
```apex
Query.Accounts
	.withFields(Query.Fields.ALL)
	.getList();
```
</details>


<details>
	<summary>withFields(fields)</summary>

```apex
public QueryObject withFields(String fields);
```
Adds given fields to the query.


#### Parameters
- `String fields` - Comma separated fields ex. selectFields('Id, Name, Username')
- `List<String> fields` - List of fields to query

#### Usage
```apex
Query.Accounts
	.withFields('Id, Name, Parent.Name')
	//or
	.withFields(new List<String>{'Id', 'Name', 'Parent.Name'})
	.getList();
```
</details>


<details>
	<summary>withAllFields()</summary>

```apex
public QueryObject withAllFields();
```
Select all fields. Fields are retrieved from sObjectType describe and is different from selecting `FIELDS(ALL)` as the `FIELDS(ALL/STANDARD/CUSTOM)` is
restricted
to 200 records

#### Usage
```apex
Query.Accounts
	.withAllFields()
	.getList();
```
</details>


<details>
	<summary>withChildren(fields, relationshipName)</summary>

```apex
public QueryObject withChildren(String fieldsCSV, String relationshipName);
public QueryObject withChildren(List<String> fields, String relationshipName);
```
Adds subquery with given fields and relationship name. Disables caching.

#### Parameters
- `String fieldsCSV` - Children fields to query in CSV format
- `List<String> fields` - List of children fields to query
- `relationshipName` - Subquery FROM

#### Usage
```apex
Query.Accounts
	.withChildren('FirstName, LastName', 'Contacts')
	//or 
	.withChildren(new List<String>{'FirstName', 'LastName', 'Contacts'})
	.getList();
```
</details>


<details>
<summary>withChildren(subquery, relationshipName)</summary>

```apex
public QueryObject withChildren(QueryObject subquery, String relationshipName);
```
Adds subquery using another Query instance.

#### Parameters
- `subquery` - Subquery instance
- `relationshipName` - Name of the relationship

#### Usage
```apex
Query.Accounts
	.withChildren(Query.Contacts.byLastName('Doe'), 'Contacts')
	.getList();
```
</details>


### Conditions
<details>
	<summary>withFilterLogic(filterLogic)</summary>

```apex
public QueryObject withFilterLogic(String filterLogic);
```
Provide filter logic for previously specified conditions

#### Parameters
- `filterLogic` - String that defines boolean logic for conditions.   
  Each condition is marked as `{0}` - where 0 is index of the condition in order they were defined.

#### Usage
```apex
Query.Accounts
	.byName('TestName')
	.byRecordTypeDeveloperName('SMB')
	.byOwnerId(UserInfo.getUserId())
	.withFilterLogic('{0} OR ({1} AND {2})')
	.toString();
```
Evaluates to:
```sql
WHERE
  Name IN ('TestName')
  OR (RecordType.DeveloperName IN ('SMB') AND OwnerId IN ('0051l000008ZcWDAA0')
```
</details>


<details>
	<summary>byId()</summary>

```apex
public virtual QueryObject byId(Id recordId);
public virtual QueryObject byId(List<SObject> records);
public virtual QueryObject byId(Set<Id> recordIds);
```
Filters records by Ids;

#### Parameters
- `recordId` - Single record id
- `recordIds` - Set of record ids
- `records` - List of SObjects.

#### Usage
```apex
Query.Account.byId(accountId).getFirst();
Query.Account.byId(accountIds).getList();

List<Account> accounts;
Query.Account.byId(accounts).getList();
```
</details>





<details>
	<summary>byRecordTypeId()</summary>

```apex
public virtual QueryObject byRecordTypeId(Id recordTypeId);
public virtual QueryObject byRecordTypeId(Set<Id> recordTypeId);
```
Filters records by Record Type Id

#### Parameters
- `recordTypeId` - Single Salesforce id or set of ids

#### Usage
```apex
Query.Accounts.byRecordTypeId(RecordTypes.Account.SMB.Id).getList();
```
</details>


<details>
	<summary>byRecordTypeDeveloperName()</summary>

```apex
public virtual QueryObject byRecordTypeDeveloperName(String recordTypeDeveloperName);
public virtual QueryObject byRecordTypeDeveloperName(Set<String> recordTypeDeveloperName);
```
Filters records by Record Type Developer Name

#### Parameters
- `recordTypeDeveloperName` - Developer Name of Record Type
#### Usage
```apex
Query.Accounts.byRecordTypeDeveloperName('SMB').getList();
```
</details>


<details>
	<summary>byOwnerId(ownerIds)</summary>

```apex
public virtual QueryObject byOwnerId(Id ownerId);
public virtual QueryObject byOwnerId(Set<Id> ownerIds);
```
Filters records by OwnerId.

#### Parameters
- `Id ownerId` - Salesforce Id of record owner (OwnerId).
- `Set<Id> ownerId` - Set of Salesforce Ids of record owner (OwnerId).

#### Usage
```apex
Id thisUser = UserInfo.getUserId();
Query.Accounts.byOwnerId(thisUser).getList();
```
</details>


<details>
	<summary>relatedToChildren()</summary>

```apex
public virtual QueryObject relatedToChildren(SObject[] childRecords, SObjectField relationShipField);
public virtual QueryObject relatedToChildren(SObject[] childRecords, String relationShipField);
```

#### Parameters
- `childRecords` - List of children records for which parent records are queried
- `relationShipField` -Parent field on records (ex. Contact.AccountId for Contacts children of Accounts)

#### Usage
```apex
Query.Accounts.relatedToChildren(contacts, Contact.AccountId);
```
</details>


<details>
	<summary>relatedToParent()</summary>

```apex
public virtual QueryObject relatedToParent(SObject[] parentRecords, SObjectField relationShipField);
```

#### Parameters
- `parentRecords` - List of parent records in relationship
- `relationShipField` - Parent field on records (ex. Contact.AccountId for list of Contacts)

#### Usage
```apex
Query.Contacts.relatedToParent(accounts, Contact.AccountId);
```
</details>


<details>
	<summary>byField(field, operator, value)</summary>

```apex
public virtual QueryObject byField(SObjectField field, String operator, Object value);
public virtual QueryObject byField(String fieldAPIName, String operator, Object value);
```
Adds field condition to the query.

#### Parameters
- `field` - SObject field in token or string format
- `operator` - Condition operator - '=', '!=', 'IN' etc.
- `value` - Right-hand side value of the operator. This can be a primitive, List or Set of primitives or List of SObjects

#### Usage
```apex
Query.Accounts.byField(Account.Name, '=', 'Test Account');

List<User> owners;
Query.Accounts.byField(Account.OwnerId, 'IN', owners);
```

</details>


<details>
	<summary>wheres(whereString, params)</summary>

```apex
public QueryObject wheres(String whereString, Map<String, Object> params);
```
Adds explicitly typed WHERE condition.

#### Parameters
- `whereString` - Part of the query string after WHERE clause. Can contain parameters preceded by colon.
- `params` - Map of SOQL bindings.

#### Usage
```apex | Example 1 - Usage in internal method
public AccountQuery byParentIds(Set<Id> parentIds) {
	wheres('ParentId IN :parentIds', new Map<String, Object>{'parentIds' => parentIds});
	return this;
}
```

```apex | Example 2 - Usage in client code
Query.Accounts
	.wheres('Parent.OwnerId IN :owners AND RecordType.DeveloperName = :rt', new Map<String, Object>{
		'owners' => owners,
		'rt' => 'PersonAccount'
	});
```

</details>


<details>
	<summary>wheres(wheresCondition)</summary>

```apex
public QueryObject wheres(Query.Condition wheres);
```
Adds WHERE clause constructed from QueryConditions class.

#### Parameters
- `wheres` - Condition
#### Usage
```apex
	QueryConditions c = new QueryConditions();
Query.Accounts
	.wheres(
		c.ORs(
			c.field(Account.Name).equals('TestName'),
			c.ANDs(
				c.field('RecordType.DeveloperName').equals('SMB'),
				c.field(Account.OwnerId).equals(UserInfo.getUserId())
			)
		)
	)
	.getList();
```

</details>


### Aggregations
<details>
	<summary>groupBy(groupBy)</summary>

```apex
public QueryObject groupBy(String groupBy);
```
Sets GROUP BY clause on the query.

#### Parameters
- `String groupBy` - String that follows GROUP BY in a query.

#### Usage
```apex
Query.fromSObject(User.SObjectType)
	.withFields('COUNT(Id), ProfileId')
	.groupBy('ProfileId')
	.havingCondition('COUNT(ID) > 1')
	.toSOQL();
```
</details>


<details>
	<summary>havingCondition(fields)</summary>

```apex
public QueryObject havingCondition(String fields);
public QueryObject havingCondition(String fields, Map<String, Object> params);
```
Sets HAVING condition on the query

#### Parameters
- `String fields` - String that follows HAVING in a query.
- `Map<String, Object> params` - (optional) Query bindings

#### Usage
```apex
Query.fromSObject(User.SObjectType)
	.withFields('COUNT(Id), ProfileId')
	.groupBy('ProfileId')
	.havingCondition('COUNT(ID) > :count', new Map<String, Object>{'count' => userCount})
	.toSOQL();
```
</details>


<details>
	<summary>havingCondition(condition)</summary>

```apex
public QueryObject havingCondition(Query.Condition condition);
```
Sets given condition as HAVING clause.

#### Parameters
- `Query.Condition condition` - Composite condition to add to the query's HAVING clause.

#### Usage
```apex
QueryConditions c = new QueryConditions();
Query.Users
	.selectFields('COUNT(ID), Email')
	.havingConditions(
		c.ANDs(
			c.field('COUNT(ID)').greaterThan(5),
			c.field('COUNT(ID)').lessThan(10)
		)
			.getList();
```

</details>


### Limit / Offset
<details>
	<summary>withLimit(limit)</summary>

```apex
public QueryObject withLimit(Integer l);
```
Sets LIMIT clause on the query.

#### Parameters
- `Integer l` - Value of the limit (0-2000).

#### Usage
```apex
Query.Accounts
	.byName('Test')
	.withLimit(10)
	.getList();
```
</details>


<details>
	<summary>withOffset(offset)</summary>

```apex
public QueryObject withOffset(Integer o);
```
Sets OFFSET clause on the query.

#### Parameters
- `Integer o` - Value of the offset (0-2000).

#### Usage
```apex
Query.Accounts
	.byName('Test')
	.withLimit(10)
	.withOffset(10)
	.getList();
```
</details>


### Mocking
<details>
	<summary>mock(mockName, result)</summary>

```apex
public QueryObject mock(String mockName, Object result);
```
Mocks output of the query with the given result.

#### Parameters
- `String mockName` - Unique identifier of the query used for mocking or Apex Class and Method name where query was invoked.
- `Object result` - Query result to mock - Integer or List of SObjects

#### Usage
```apex
// in class
Query.Accounts.byName('Test').getList(); // returns mock accounts

// in test
Query.Accounts.mock('byName', mockAccounts);
```
</details>


<details>
	<summary>withMockName(mockName)</summary>

```apex
public QueryObject withMockName(String mockName);
```
Give this query unique name, which can be referenced in Unit Tests to mock results for named query.

#### Parameters
- `String mockName` - unique mock identifier.

#### Usage
```apex
// in class
Query.Accounts.withMockName('myquery').getList(); // returns mock accounts

// in test
Query.Accounts.mock('myquery', mockAccounts);
```
</details>


<details>
	<summary>debugLogMockName()</summary>

```apex
public QueryObject debugLogMockName();
```
This method prints log with expected mock name.
Use this when in doubt what mocked name is expected.

#### Usage
```apex
Query.Account
	.byName('Test')
	.byRecordTypeDeveloperName('SMB')
	.debugLogMockName();
// > '.byName.byRecordTypeDeveloperName'
```
</details>



### Security
<details>
	<summary>withSharing()</summary>

```apex
public QueryObject withSharing();
```
Query will be executed in "with sharing" context,returning only those records user has access to.

#### Usage
```apex
Query.Accounts
	.withSharing()
	.getList();
```
</details>


<details>
	<summary>withoutSharing()</summary>

```apex
public QueryObject withoutSharing();
```
Query will be executed in "without sharing" context,returning only those records user has access to.

#### Usage
```apex
Query.Accounts
	.withoutSharing()
	.getList();
```
</details>


<details>
	<summary>withFieldAccess(accessType)</summary>

```apex
public QueryObject withFieldAccess(AccessType accessType);
```
Enforces Object and Field level security on records.  
Inaccessible fields are stripped from result and inaccessible objects throws exception.  
@throws System.NoAccessException No access to entity.

Calls Security.stripInaccessible on the query result.

#### Parameters
- `AccessType accessType` - System.AccessType enum - CREATABLE | READABLE | UPDATABLE | UPSERTABLE

#### Usage
```apex
Query.Accounts
	.withFieldAccess(AccessType.READABLE)
	.getList();
```
</details>


<details>
	<summary>usingCache(useCache)</summary>

```apex
public QueryObject usingCache(Boolean useCache);
```
Toggle usage of the cached records to limit SOQLs query limit.

#### Parameters
- `Boolean useCache` - True if query should use cached records. Default: True.

#### Usage
```apex | Query Profiles without resorting to cache.
Query.Profile
	.usingCache(false)
	.getList();
```
</details>


### Reductors
<details>
	<summary>getList()</summary>

```apex
public SObject[] getList();
```
Returns standard query result list.

#### Usage
```apex
List<Account> accounts = Query.Account
	.byName('Test')
	.getList();
```
</details>


<details>
	<summary>getFirst()</summary>

```apex
public SObject getFirst();
```
Returns first and only record returned by query. Throws System.ListException if query did not return results.

#### Usage
```apex
Account acc = (Account) Query.Account.byName('Test').getFirst();
```
</details>


<details>
	<summary>getFirstOrNull()</summary>

```apex
public SObject getFirstOrNull();
```
Returns first record or null if list has no results

#### Usage
```apex
Account acc = (Account) Query.Account.byName('Test').getFirstOrNull();
```
</details>



<details>
	<summary>getFirstIdOrNull()</summary>

```apex
public Id getFirstIdOrNull();
```
Executes query and returns Id of the first record. If query result list is empty, returns null.

#### Usage
```apex
Id systemAdmin = Query.Profile
	.byName('System Administrator')
	.getFirstIdOrNull();
```
</details>


<details>
	<summary>getFirstFieldOrNull(field)</summary>

```apex
public Object getFirstFieldOrNull(SObjectField field);
```
Executes query and returns field of first record or null if list has no results

#### Parameters
- `SObjectField field` - Which field should be returned from the first record.

#### Usage
```apex
Id ownerId = (Id) Query.Account
	.byName('Test Account')
	.getFirstFieldOrNull(Account.OwnerId);
```
</details>


<details>
	<summary>getFirstFieldOrFallback(field, fallbackValue)</summary>

```apex
public Object getFirstFieldOrFallback(SObjectField field, Object fallbackValue);
```
Executes query and returns field of first record or fallback value if list has no results.

#### Parameters
- `SObjectField field` - Which field should be returned from the first record.
- `Object fallbackValue` - Value that is returned if query has no result.

#### Usage
```apex
public static Id getDefaultOwner() {
	Query.User
		.byName('DEFAULT OWNER')
		.getFirstFieldOrFallback(User.Id, UserInfo.getUserId());
}
```
</details>


<details>
	<summary>getIds()</summary>

```apex
public Set<Id> getIds();
```
Returns Ids of SObjects.

#### Usage
```apex
Set<Id> accountIds = Query.Account
	.byName('Test')
	.getIds();
```
</details>


<details>
	<summary>getMapById()</summary>

```apex
public Map<Id, SObject> getMapById();
```
Executes query and returns records mapped by Ids.

#### Usage
```apex
Map<Id, Account> accountIds = (Map<Id, Account>) Query.Account
	.getMapById();
```
</details>


<details>
	<summary>getMapByString(field)</summary>

```apex
public Map<String, SObject> getMapByString(SObjectField field);
public Map<String, SObject> getMapByString(String field);
```
Executes query and maps result records by given SObject Field.

#### Parameters
- `SObjectField | String field` - Field to map records by.

#### Usage
```apex
Map<String, Account> accountIds = (Map<String, Account>) Query.Account
	.getMapByString(Account.Name);
```
</details>


<details>
	<summary>QueryLocator getQueryLocator()</summary>

```apex
public Database.QueryLocator getQueryLocator();
```
Returns QueryLocator for current query.

#### Usage
```apex
Query.Accounts.getQueryLocator();
```
</details>


<details>
	<summary>getCount()</summary>

```apex
public Integer getCount();
```
Executes query and returns Count();

#### Usage
```apex
Query.Accounts.getCount();
```
</details>


<details>
	<summary>toSOQL()</summary>

```apex
public String toSOQL();
```
Returns SOQL string for given query. Useful for unit testing query methods.

#### Usage
```apex
Query.Accounts
	.byName('Test Account')
	.byRecordTypDeveloperName('SMB')
	.toSOQL();

// > SELECT Id, Name FROM Account WHERE ((Name IN :var0) AND (RecordType.DeveloperName IN :var1))
```
</details>

<details>
	<summary>String toString()</summary>

```apex
public override String toString();
```
Returns SOQL string with bindings for given query. Useful for unit testing query methods.

#### Usage
```apex
Query.Accounts
	.byName('Test Account')
	.byRecordTypDeveloperName('SMB')
	.toSOQL();

// > SELECT Id, Name FROM Account WHERE ((Name IN :var0) AND (RecordType.DeveloperName IN :var1)), 
// {var0={Test Account}, var1={SMB}})
```
</details>



---
# Issues

Query Framework uses Builder with an inheritance pattern, which has one downside that cannot be fixed in Apex at this time:
- When we use method from super class, we can't call methods from child class anymore.

<br/>

Consider the following selector:
```apex
public with sharing class AccountQuery extends QueryObject {

	public AccountQuery() {
		super(new List<String>{
			'Id', 'Name'
		}, Account.SObjectType);
	}

	public AccountQuery byName(Set<String> names) {
		appendMockName('byName');
		return (AccountQuery) byField(Account.Name, 'IN', names);
	}
}
```

Now let's consider a situation, where I want to use one of the standard methods in the middle of the method
chain - `public QueryObject withFields(String fields)`.
As you can see, it returns `QueryObject`, not `AccountQuery`.

```apex
new AccountQuery()
	.withFields('Id, Name, BillingCity') // < this returns QueryObject, which doesn't have byName() method
	.byName('Test Account');
```

In modern languages, this is solved by generic types, but unfortunately Apex is 20 years behind the rest of the world.

## Countermeasures
This problem can be solved in 3 ways:

- Reordering methods, so the AccountQuery method is called first:
```apex
new AccountQuery()
	.byName('Test Account')
	.withFields('Id, Name, BillingCity')
	.getList();
```

- Reintroduce method you need in AccountQuery and cast type. Unfortunately, we have to use different method name:
```apex
public with sharing class AccountQuery extends QueryObject {

	public AccountQuery withFieldsx(String fields) {
		return (AccountQuery) withFields(fields);
	}
}
```

- Declare variable instead of chaining:
```apex
AccountQuery q = new AccountQuery();
q.withFields('Id, Name');
q.byName('Test Account');
return q.getList();
```

---
# Change Log
### 1.1.0
- Added new mocking method without using mock ids.
- Added ORDER BY
- Removed Query - QueryObject syntactic sugar inheritance 
```

```
- 