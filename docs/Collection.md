# Collection

Utility class for one of the most occurring logic in Apex - Mapping records by fields
and retrieving set of fields.

#### General Utility Methods

* `getFirst();` => returns first element or null
* `getLast();` =>  returns last element or null
* `get(Integer i);` => return n-th element
* `getRandom();` => returns random element
* `add(Integer index, Object element);`
* `add(Object element);`
* `addAll(List<Object> elements);`
* `addAll(Set<Object> elements);`
* `remove(Integer index);`
* `removeLast();`
* `clear();`
* `Boolean isNotEmpty();`
* `Boolean isEmpty();`
* `Integer size();`

<br/>

#### Mapping By Field

Call `.mapBy()` to map list of records by field.  
Method automatically determines map's key and value type by checking field type, so you only need to cast it to expected type.

```apex
Map<Id, Contact> contactMap = (Map<Id, Contact>) Collection.of(contacts)
    .mapBy(Contact.AccountId);
```

##### Map between 2 fields

When we need to map one sobject field to another:

```apex
Map<Id, String> usernameByProfileId = (Map<Id, String>) Collection.of(users)
    .mapBy(User.ProfileId, User.Username);
```

Output:

```json
{
    "00e5r000000bf2XAAQ": "chatty.00d5r000000h4gwea0.1nqphqruojkv@chatter.salesforce.com",
    "00e5r000000bf2YAAQ": "cloud@00d5r000000h4gwea0",
    "00e5r000000bf2SAAQ": "test-hczutyqdcjti@example.com",
    "00e5r000000bf2WAAQ": "insightssecurity@00d5r000000h4gwea0.com",
    "00e5r000000bf2TAAQ": "integration@00d5r000000h4gwea0.com",
    "00e5r000000bf2UAAQ": "automatedclean@00d5r000000h4gwea0"
}
```

##### Map by concatenation of 2 fields:

Map key is concatenation of 2 fields without any separator:

```apex
Map<String, JunctionObject__c> mapByParents = (Map<String, JunctionObject__c>) Collection.of(junctionObjects)
    .mapByConcatenation(JunctionObject__c.Parent1__c, JunctionObject__c.Parent2__c);
```

<br/>

#### Grouping By Field

Grouping is similar to mapping, except it expects values to be non-unique - it will produce List as map's value:

```apex
Map<Id, Contact[]> contactMap = (Map<Id, Contact[]>) Collection.of(contacts)
    .groupBy(Contact.AccountId);
```

<br/>

##### Group field by field:

Similar to mapBy() equivalent, but in the list we will find field value instead of sobject.

```apex
Map<Id, String[]> usernamesByProfile = (Map<Id, String[]>) Collection.of(users)
    .groupBy(User.ProfileId, User.Username);
```

Output:

```json
{
    "00e5r000000bf2XAAQ": [
        "chatty.00d5r000000h4gwea0.1nqphqruojkv@chatter.salesforce.com"
    ],
    "00e5r000000bf2YAAQ": [
        "cloud@00d5r000000h4gwea0"
    ],
    "00e5r000000bf2SAAQ": [
        "test-hczutyqdcjti@example.com"
    ],
    "00e5r000000bf2WAAQ": [
        "insightssecurity@00d5r000000h4gwea0.com"
    ],
    "00e5r000000bf2TAAQ": [
        "integration@00d5r000000h4gwea0.com"
    ],
    "00e5r000000bf2UAAQ": [
        "autoproc@00d5r000000h4gwea0",
        "automatedclean@00d5r000000h4gwea0"
    ]
}
```

#### Getting List or Set of field values:

Calling getSet() or getList() with sobject field, we will get List or Set of field values:

```apex
Set<Id> accountIds = Collection.of(contacts).getSetId(Contact.AccountId); // Preferred
Set<Id> accountIds = (Set<Id>) Collection.of(contacts).getSet(Contact.AccountId); // Code figures out set type automatically

//For Integer fields:
Set<Integer> externalIds = Collection.of(contacts).getSetInteger(Contact.ExternalId__c); // Preferred
Set<Integer> externalIds = (Set<Integer>) Collection.of(contacts).getSet(Contact.ExternalId__c);

// Similarly we can get List of values
List<String> contactNames = (List<String>) Collection.of(contacts).getList(Contact.Name);

```

<br/>

#### Filtering Collection

We can use .filter() methods to remove records that do not meet the filter:

```apex
List<Contact> contacts = (List<Contact>) Collection.of(contacts)
    .filter(Contact.AccountId).isIn(accountIds)
    .get();
```

Available field filter methods:

```apex
.equals(Object value);
.notEquals(Object value);
.greaterThan(Object value);
.greaterEqualsThan(Object value);
.lessThan(Object value);
.lessEqualsThan(Object value);
.isIn(Set<Object> values);
.isIn(List<Object> values);
.isIn(List<SObject> parents);
.isNotIn(Set<Object> values);
.isNotIn(List<Object> values);
.contains(String value);
```

Most are self-explanatory.  
`.isIn(List<SObject> parents)` is a short-hand method which doesn't require ids:

```apex
List<Account> accounts;

//get accountIds first
Collection.of(contacts)
    .filter(Contact.AccountId).isIn(accounts);
```

###### Filter Alike

This is separate method, which filters records with the same field-values as provided sample record:

```apex
Collection.of(contacts)
    .filterALike(new Contact(
        RecordTypeId = RecordTypes.CONTACT_PRIMARY.id,
        MailingCountry = 'US'
    ));
// ==> This filters contacts that have Primary record type and US country.
```

###### Complex Conditions

More complex conditions can be created with conditions factory as follows:

```apex
Conditions c = new Conditions();
Collection.of(contacts)
    .filter(
        c.ANDs(
            c.ORs(
                c.field(Contact.Name).equals('1'),
                c.field(Contact.Name).equals('2')
            ),
            C.ORs(
                c.field(Contact.Name).equals('3'),
                c.field(Contact.Name).equals('4')
            )
        )
    );
```

Though, at this point I'd consider rewriting it as standard for-loop, since it will be more compact and efficient.

#### Slicing

Returns slice of collection:

```apex
Collection.of(contacts).slice(0, 10); //=> returns first 10 contacts  
Collection.of(contacts).slice(new List<Integer>{0, 2, 4, 9}); //=> returns contacts from given indexes  
```

<br/>

#### Ordering

Order SObjects by field:

```apex
Collection.of(contacts).orderAsc(Contact.Name);
Collection.of(contacts).orderDesc(Contact.Name);
```

<br/>

#### Reduce

Inspired by Javascript reduce method, this provides Reducer interface and a few out of the box methods:

```apex
Decimal getSum(SObjectField field);
Decimal getMin(SObjectField field);
Decimal getMax(SObjectField field);
Decimal getAverage(SObjectField field);

Decimal sum = Collection.of(opportunities).getSum(Opportunity.Amount);
```
