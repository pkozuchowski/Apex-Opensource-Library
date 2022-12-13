# Test Data Builder

Test Data Builder is a utility class for creating test records with default fields in unit tests.
This builder utilizes 3 design patterns - builder, prototype and factory. First of all, we have repository of default fields,
which will be actively extended for new sObjects as project progresses.

It will look like this:

```apex
public with sharing class TestDataBuilderFactories {
    private final static Map<SObjectType, Map<String, SObjectFactory>> sObjectFactoriesMap = new Map<SObjectType, Map<String, SObjectFactory>>{
        User.SObjectType => new Map<String, SObjectFactory>{
            defaults => new DefaultUserFactory()
        },

        Account.SObjectType => new Map<String, SObjectFactory>{
            defaults => new SimpleDefaultsFactory(new Account(
                Name = 'Test Account'
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

As you can see, these are just default fields that will be applied by builder for each record.   
For simple defaults, we can use inbuilt `SimpleDefaultsFactory` which only applies default fields, but as you can see on `DefaultUserFactory` example, it's
possible to create custom solution to customize the fields - in this case to make
unique username and alias for each new user.

Not let's see the actual builder:

```apex
TestDataBuilder builder = new TestDataBuilder();

User[] users = builder.create(new User(LastName = 'Johnson')).getRecords();
```

The builder takes prototype record from `TestDataBuilderFactories`, applies LastName = 'Johnson' on top of it and returns the User.  
Voila. That's it. You can override any fields you want easily, or create records instantly using `.insertRecords()` method:

```apex
TestDataBuilder builder = new TestDataBuilder();

User[] users = builder.create(new User(LastName = 'Johnson')).insertRecords();

//Or even shorter:
Account[] accounts = builder.insertRecords(new Account(Name = 'Test Account'));
```

We have 2 prototype records here - default fields in `TestDataBuilderFactories` and overriding fields prototype passed to builder.

<br/>

### Creating many records at once:

It's possible to create a list of records with one call by using `count` parameter of the builder methods:

```apex
Account[] accounts = builder.insertRecords(new Account(Name = 'Test Account'));
Contact[] contacts = builder.insertRecords(10, new Contact(AccountId = accounts[0].Id, LastName = 'Doe'));
```

In this example, we will have 1 Account and 10 related Contacts - all with default fields and field overrides.

<br/>

### Similar Records

Sometimes we need to create a bunch of similar records, but with minor differences between them. TestDataBuilder has special method which allows just that.  
Consider following example:

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

<br/>

### SObject Flavours

Flavours allow us to create different base records for the same SObject type.  
For example, let's assume that we have 3 Account Record Types - Person Account, Small Medium Business and Enterprise Business.
Each has completely different layout and set of required fields.

This is when we can use flavours in TestDataFactories:

```apex
    private final static Map<SObjectType, Map<String, SObjectFactory>> sObjectFactoriesMap = new Map<SObjectType, Map<String, SObjectFactory>>{

    Account.SObjectType => new Map<String, SObjectFactory>{
        defaults => new SimpleDefaultsFactory(new Account(
            Name = 'Test Account'
        )),

        'PersonAccount' => new SimpleDefaultsFactory(new Account(
            FirstName = 'John',
            LastName = 'Doe',
            RecordTypeId = RecordTypes.ACCOUNT_PERSON.id,
            /*other Person Account fields*/
            )),

        //Small Medium Business
        'SMB' => new SimpleDefaultsFactory(new Account(
            Name = 'Test Account',
            RecordTypeId = RecordTypes.ACCOUNT_SMB.id,
            /*other SMB fields*/
            )),

        'Enterprise' => new SimpleDefaultsFactory(new Account(
            Name = 'Test Account',
            RecordTypeId = RecordTypes.ACCOUNT_ENTERPRISE.id,
            /*other enterprise fields*/
            ))
    }

};
```

We can create different sets of base fields and then specify that flavour in test class:

```apex
Account[] accounts = new TestDataBuilder()
    .create('Person Account', new Account(/*...*/))
    .create(2, 'SMB', new Account(/*...*/))
    .create(2, 'Enterprise', new Account(/*...*/))
    .insertRecords();
```

Each Account will come with default fields specific for its flavour. If flavour is not specified, `defaults` flavour is used.
<br/>

<br/>

### Correlation with DML mocking

It's possible to use DML mocks from DatabaseService instead of actual record insert:

```apex
TestDataBuilder builder = new TestDataBuilder();
builder.databaseService.useMock();

Account[] accounts = builder.insertRecords(2, new Account());
```

Account will have fake id `001000000000000`.

<br/>

### Trivia

* If there is no prototype set up in `TestDataBuilderFactories`, builder will return records with only overriding fields. Nothing bad will happen. You should
  create all records through the builder, even if there's no prototype - when new required field is created, you can just add prototype
  in [TestDataBuilderFactories](..%2Fforce-app%2Fcommons%2FunitTesting%2FTestDataBuilderFactories.cls) and all unit tests will have this new field populated.
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

<br/>

### API

```apex
/**
 * Creates test record with default field values, overridden by given prototype field values.
 *
 * @param prototype Example of record to create - fields specified in the constructor will override defaults
 * @throws TestDataBuilder.TestDataBuilderException when default is not defined
 *
 * @return instance of DataBuilder for subsequent calls.
 */
public TestDataBuilder create(SObject prototype);

/**
 * Creates test record with unit test default field values, overridden by given prototype field values.
 *
 * @param flavour Name of the default fields configuration - defines which default field values will be used for SObject
 * @param prototype Example of record to create - fields specified in the constructor will override defaults
 * @throws TestDataBuilder.TestDataBuilderException when flavour is not defined
 *
 * @return instance of DataBuilder for subsequent calls.
 */
public TestDataBuilder create(String flavour, SObject prototype);

/**
 * Creates N test records with default field values, overridden by given prototype field values.
 *
 * @param count How many copies should be created.
 * @param prototype Example of record to create - fields specified in the constructor will override defaults
 * @throws TestDataBuilder.TestDataBuilderException when flavour is not defined
 *
 * @return instance of DataBuilder for subsequent calls.
 */
public TestDataBuilder create(Integer count, SObject prototype);

/**
 * Creates N test record with default field values, overridden by given prototype field values.
 *
 * @param count How many copies should be created.
 * @param flavour Name of the default fields configuration - defines which default field values will be used for SObject
 * @param prototype Example of record to create - fields specified in the constructor will override defaults
 * @throws TestDataBuilder.TestDataBuilderException when flavour is not defined
 *
 * @return instance of DataBuilder for subsequent calls.
 */
public TestDataBuilder create(Integer count, String flavour, SObject prototype);


/**
 * Creates a copy of record from previous create() or similarly() call and adjust it's values by given prototype field values.
 * This method cannot be called prior to create() or for different SObject type than prior create/similarly call.
 * Records are created with the same flavour as previous prototype.
 * <p/>
 * Usage:
 *  List<Account> accounts = TestDataBuilder.builder()
 *       .create(new Account(Name = 'Test'))
 *       .similarly(10, new Account(BillingCountry = 'Test'))
 *       .insertRecords()
 *       .getRecords();
 *  This example creates 11 accounts in total, all of them with "Test" Name and 10 with additional Billing country
 *
 * @param prototype Example of record to create - fields specified in the constructor will override defaults
 *
 * @return instance of DataBuilder for subsequent calls.
 */
public TestDataBuilder similarly(SObject prototype);

/**
 * Creates a copy of record from previous create() or similarly() call and adjust it's values by given prototype field values.
 * This method cannot be called prior to create() or for different SObject type than prior create/similarly call.
 * Records are created with the same flavour as previous prototype.
 *
 * @param count How many copies should be created.
 * @param prototype Example of record to create - fields specified in the constructor will override defaults
 *
 * @return instance of TestDataBuilder for subsequent calls.
 */
public TestDataBuilder similarly(Integer count, SObject prototype);


/**
 * Inserts and returns record with default field values, overridden by given prototype field values.
 *
 * @param prototype Example of record to create - fields specified in the constructor will override defaults
 * @return instance of TestDataBuilder for subsequent calls.
 */
public SObject insertRecord(SObject prototype);

/**
 * Inserts and returns record with default field values, overridden by given prototype field values.
 *
 * @param count How many records should be created.
 * @param prototype Example of record to create - fields specified in the constructor will override defaults
 * @return instance of TestDataBuilder for subsequent calls.
 */
public SObject[] insertRecords(Integer count, SObject prototype);

/**
 * Inserts and returns record with default field values, overridden by given prototype field values.
 *
 * @param count How many records should be created.
 * @param flavour Name of the default fields configuration - defines which default field values will be used for SObject
 * @param prototype Example of record to create - fields specified in the constructor will override defaults
 * @return instance of TestDataBuilder for subsequent calls.
 */
public SObject[] insertRecords(Integer count, String flavour, SObject prototype);


/**
 * Inserts records stored in builder's internal storage, clears buffer and returns records.
 *
 * @return inserted records
 */
public List<SObject> insertRecords();


/**
 * @return First record from Builder's internal storage and clear's storage.
 */
public SObject getOne();

/**
 * @return Records from Builder's internal storage.
 */
public List<SObject> getRecords();

/**
 * Clears the builder's internal storage.
 */
public TestDataBuilder clear();
```