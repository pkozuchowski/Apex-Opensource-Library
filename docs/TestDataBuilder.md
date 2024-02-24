# Test Data Builder
*Setup test records for unit tests.*

[Source](https://github.com/pkozuchowski/Apex-Opensource-Library/tree/master/force-app/commons/testDataBuilder)
[Dependency](/apex/database-service)
[Install In Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04t08000000ga9dAAA)
[Install In Production](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t08000000ga9dAAA)

```bash
sf project deploy start -d "force-app/commons/testDataBuilder" \
-d "force-app/commons/database" \
-o sfdxOrg
```

---
# Test Data Builder
Test Data Builder is a utility class for creating test records with default fields in unit tests.  
It takes an example record, applies default values (and we can have different sets of default fields for each sObject type), multiplies record if needed and
inserts. It can also create sets of similar records, where the following records have only minor changes compared to previously created record.

```apex
@TestSetup
static void testSetup() {
	TestDataBuilder builder = new TestDataBuilder();

	Account[] accounts = builder
		// Creates Account with default fields + all fields defined here
		.create(new Account(Name = 'Test', BillingCountry = 'US'))

		// Creates an Account with ALL fields of previous record, but with different BillingCity
		.similarly(new Account(BillingCity = 'Austin'))

		// Creates 5 more accounts with default values
		.create(5, new Account(Name = 'Other Accounts'))

		// Create account with different variant - different set of default fields
		.create('SMB', new Account(Name = 'Business Account'))
		.insertRecords();
}
```

The fields in record passed to `create()` or `similarly()` method are overriding fields - they will be put on top of SObject default values defined
in `TestDataDefaults` class.  
Records can be returned without inserting or inserted with shorthand method:

```apex
Account[] accounts = builder.create(new Account(Name = 'Test Account')).getRecords();

// Insert right away
Account[] accounts = builder.insertRecords(new Account(Name = 'Test Account'));
```

## Creating many records at once:

It's possible to create a list of records with one call by using `count` parameter of the builder methods:

```apex
Account[] accounts = builder.insertRecords(new Account(Name = 'Test Account'));
Contact[] contacts = builder.insertRecords(10, new Contact(AccountId = accounts[0].Id, LastName = 'Doe'));
```

In this example, we will have 1 Account and 10 related Contacts - all with default fields and field overrides.

## Similar Records

Sometimes we need to create a bunch of similar records, but with minor differences between them. TestDataBuilder has special method which allows just that.  
Consider the following example:

```apex
User[] users = new TestDataBuilder()
	.create(new User(Username = 'johnson@test.com', ProfileId = salesManager.Id, UserRoleId = salesManager.Id))
	.similarly(new User(Username = 'xian@test.com'))
	.similarly(new User(Username = 'dong@test.com', UserRoleId = ceo.Id))
	.insertRecords()();
```

When `similarly` is called, it takes previous record as a base and applies new fields on top of it. So here we have:

1. Sales Manager User with Username 'johnson@test.com' and all default fields (username, alias etc.)
2. Sales Manager User with the same profile, same user role and email as above, but 'xian@test.com' username
3. Sales Manager User with the same fields as #2, but different username and different UserRoleId

## SObject Flavours

Flavors (or in other words variants) allow us to create different base records for the same SObject type.  
For example, let's assume that we have 3 Account Record Types — Person Account, Small Medium Business and Enterprise Business.
Each has a completely different layout and set of required fields.

This is when we can use flavors in TestDataDefaults:

```apex
	private final static Map<SObjectType, Map<String, SObjectFactory>> sObjectFactoriesMap = new Map<SObjectType, Map<String, SObjectFactory>>{

	Account.SObjectType => new Map<String, SObjectFactory>{
		defaults => new SimpleDefaultsFactory(new Account(
			Name = 'Test Account'
		)),

		'PersonAccount' => new SimpleDefaultsFactory(new Account(
			FirstName = 'John',
			LastName = 'Doe',
			RecordTypeId = RecordTypes.ACCOUNT_PERSON.id
			/*other Person Account fields*/
		)),

		//Small Medium Business
		'SMB' => new SimpleDefaultsFactory(new Account(
			Name = 'Test Account',
			RecordTypeId = RecordTypes.ACCOUNT_SMB.id
			/*other SMB fields*/
		)),

		'Enterprise' => new SimpleDefaultsFactory(new Account(
			Name = 'Test Account',
			RecordTypeId = RecordTypes.ACCOUNT_ENTERPRISE.id
			/*other enterprise fields*/
		))
	}


};
```

We can create different sets of base fields and then specify that flavor in test class:

```apex
Account[] accounts = new TestDataBuilder()
	.create('Person Account', new Account(/*...*/))
	.create(2, 'SMB', new Account(/*...*/))
	.create(2, 'Enterprise', new Account(/*...*/))
	.insertRecords();
```

Each Account will come with default fields specific for its flavor. If flavor is not specified, `defaults` flavor is used.

## DML mocking

It's possible to use DML mocks from DatabaseService instead of actual record insert:

```apex
TestDataBuilder builder = new TestDataBuilder()
	.mockDMLs();

Account[] accounts = builder.insertRecords(2, new Account());
```

Account will have fake id `001000000000000`.

## Trivia

* If there is no prototype set up in `TestDataDefaults`, builder will return records with only overriding fields. Nothing bad will happen. You should
  create all records through the builder, even if there's no prototype - when new required field is created, you can just add prototype
  in `TestDataDefaults` and all unit tests will have this new field populated.
* `similarly()` method needs to be preceded with `create` method.
* When calling `create()` subsequently for different sobjects, builder will return/insert a single list with many different sObjects. It's better to create
  getRecords/insertRecords for each sobject type separately.

```apex
SObject[] records = new TestDataBuilder()
	.create(new Account(/*...*/))
	.create(new Contact(/*...*/))
	.create(new Case(/*...*/))
	.getRecords();

// => records has 3 different sobjects
```

## Interface
```apex
TestDataBuilder mockDMLs();

TestDataBuilder create(SObject prototype);
TestDataBuilder create(String flavor, SObject prototype);
TestDataBuilder create(Integer count, SObject prototype);
TestDataBuilder create(Integer count, String flavor, SObject prototype);
TestDataBuilder similarly(SObject prototype);
TestDataBuilder similarly(Integer count, SObject prototype);
SObject insertRecord(SObject prototype);
SObject[] insertRecords(Integer count, SObject prototype);
SObject[] insertRecords(Integer count, String flavor, SObject prototype);
List<SObject> insertRecords();
SObject getOne();
List<SObject> getRecords();
TestDataBuilder clear();
```

---
# Test Data Defaults
Test Data Defaults is a repository that defines what default field values will be applied for each sObject Type and what variants of fields are available.

Each `default` is created through the factory class, which gives us possibility to randomize fields for each record if needed.
For simple defaults, we can use inbuilt `SimpleDefaultsFactory` which only applies default fields.
`DefaultUserFactory` is an example of custom factory class that creates unique username and alias for each new test user.

```apex
public with sharing class TestDataDefaults {
	public final static String defaults = '';

	private final static Map<SObjectType, Map<String, SObjectFactory>> sObjectFactoriesMap = new Map<SObjectType, Map<String, SObjectFactory>>{
		Account.SObjectType => new Map<String, SObjectFactory>{
			defaults => new SimpleDefaultsFactory(new Account(
				Name = 'Test Account'
			)),

			'PersonAccount' => new SimpleDefaultsFactory(new Account(
					FirstName = 'John',
					LastName = 'Doe'
			))
		},

		Contact.SObjectType => new Map<String, SObjectFactory>{
			defaults => new SimpleDefaultsFactory(new Contact(
				FirstName = 'Testy',
				LastName = 'Jones'
			))
		},

		Opportunity.SObjectType => new Map<String, SObjectFactory>{
			defaults => new SimpleDefaultsFactory(new Opportunity(
				Name = 'Test Opportunity'
			))
		},

		User.SObjectType => new Map<String, SObjectFactory>{
			defaults => new DefaultUserFactory()
		}
	};

	private class DefaultUserFactory implements SObjectFactory {
		private Integer counter = 0;
		private Id orgId = UserInfo.getOrganizationId();

		public SObject create() {
			counter++;
			String uid = '' + counter + Crypto.getRandomInteger();

			return new User(
				FirstName = 'Test',
				LastName = 'User',
				Email = 'test@example.com',
				Username = uid + '@' + orgId + '.test.com',
				ProfileId = UserInfo.getProfileId(),
				Alias = uid.left(8),
				CommunityNickname = uid.left(40),
				TimeZoneSidKey = 'GMT',
				LocaleSidKey = 'en_US',
				EmailEncodingKey = 'UTF-8',
				LanguageLocaleKey = 'en_US'
			);
		}
	}
}
```

---
# Test Data Factory
Using builder will often be overkill, and some sObjects will always be initialized with the same fields that could be conveniently defined as method
parameters.  
Test Data Factory class is a place where you can do that:

```apex
@IsTest
private class SomeTest {

	@TestSetup
	static void testSetup() {
		User testUser = TestDataFactory.createUser(Profiles.SYSTEM_ADMINISTRATOR.Id, 'test@company.com');

		Account account = TestDataFactory.createAccount('Test');
	}
}
```