# Query - Extensible Selector Layer

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
Query Object assumes that each query can be modified in 3 ways:

#### Extended with additional fields, relationships, limits etc

Consider this example, where we can add additional fields to the selector's base field set.
```apex
List<Contact> contact = Query.Contacts
    .byAccountId(/*...ids*/)
    .withParentAccount()
    .withFields('FirstName, LastName, CreatedBy.Name')
    .getList();
```

#### Filtered

Where clause can be combined from methods implemented in ContactQuery:
```apex
List<Contact> contact = Query.Contacts
    .byAccountId(/*...ids*/)
    .byRecordTypeId(/*Record Type Id*/)
    .byIsActive(true)
    .getList();
```

For very specialized and complex queries, there are 3 ways:
```apex
// 1) Introduce case-specific filtering method in SObject's query class:
class ContactQuery{
    /*...code*/

    public ContactQuery byMySuperSpecificCondition(Set<Id> accountIds) {
        appendMockName('byAccountId');
        return (ContactQuery) wheres('AccountId IN :accountIds AND ...', new Map<String,Object>{
            'accountIds' => accountIds,
            // other query parameters
        });
    }
}


// 2) Using QueryConditions to build query:
QueryConditions c = new QueryConditions();
Query.Accounts
    .groupBy('COUNT(ID) cnt, Profile.Name', 'Profile.Name')
    .havingCondition(
        c.ORs(
            c.ANDs(
                c.field('COUNT(ID)').greaterThan(0),
                c.field('COUNT(ID)').lessThan(10)
            ),
            c.ANDs(
                c.field('COUNT(ID)').greaterThan(20),
                c.field('COUNT(ID)').lessThan(30)
            )
        )
    )
    .getList();


// 3) Writing WHERE clause directly
List<String> names = new List<String>();
List<String> externalIds = new List<String>();
Id recordTypeId;

Query.Accounts
    .wheres('Name IN :names OR (RecordTypeId =:rtId AND ExternalID IN :externalIds)', new Map<String, Object>{
        'names' => names,
        'rtId' => recordTypeId,
        'externalIds' => externalIds
    });
```

#### Reduced
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

## Caching
The framework provides a mechanism to register cache mechanism for specific sObjects.  
Once queried records will be saved to cache - either static (lives in static map through the apex transaction), Org or Session Platform Cache.  
This has to be explicitly enabled for specific sobject types and work only on queries with 1 WHERE condition by cached field.

Consider following code in ProfileQuery:
```apex

static {
    QueryCache.registerOrgCache(
        Profile.SObjectType,
        'SELECT Id, Name FROM Profile',
        new Set <String>{'Id', 'Name'}
    );
}
```

This means that Profile records will be cached in Org platform cache using `Id` and `Name` fields for caching -
queries by ID or Name will be able to use cache.

Since org cache is reused by many users, the query string (second parameter) will be only called if cache is empty -
this is cache initialization query. It can be left empty if you don't need to initialize cache with any records, but want to cache once queried records. 

Now when user calls action that requires Profile data, the framework will first check if we have profile in cache.

#### Progressive Caching
Let's assume that we're querying 50 queue records - we have 25 in cache and 25 are not.  
Framework will take 25 records from cache and query only the remaining 25 from the database and put them in cache.   
Consecutive call with the same query will get all 50 records from the cache and thus will not use any DML.

## Mocking
It's possible to mock query response in the unit test as follows:

```apex
@IsTest
static void myTestMethod() {
    Query.Accounts.mock('.byExternalId', new List<Account>{
        // my mocked query result
    });

    Test.startTest();
    List<Account> accounts = Query.Accounts
        .byExternalId(/*...*/)
        .getList(); //returns mocked result
    Test.stopTest();
}
```

Mock name is generated from the used methods:
```apex
// For Query in class:
List<Account> accounts = Query.Accounts
    .byExternalId(/*...*/)
    .byRecordTypeId()
    .getList(); //returns mock

//Mock as follows:
Query.Accounts.mock('.byExternalId.byRecordTypeId', new List<Account>{
    // my mocked query result
});

//When in doubt add .debugLogMockName(); to the query chain.
```

Alternatively you can define your mock name to mock exactly that one query that you want.
```apex
// In your class:
List<Account> accounts = Query.Accounts
    .byExternalId(/*...*/)
    .byRecordTypeId()
    .withMockName('myAccountQuery')
    .getList(); //returns mocked result


// In your test:
Query.Accounts.mock('myAccountQuery', new List<Account>{
    // my mocked query result
});

```
