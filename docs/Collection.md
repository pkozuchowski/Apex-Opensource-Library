# Collection
*Collection class operates on Apex Lists and simplifies most common operations.*

[Source](https://github.com/pkozuchowski/Apex-Opensource-Library/tree/master/force-app/commons/collections)
[Dependency](/apex/runtime)
[Install in Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04t08000000UK6uAAG)
[Install in Production](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t08000000UK6uAAG)

```bash
sf project deploy start \
-d force-app/commons/collections \
-d force-app/commons/shared \
-o sfdxOrg
```

---
# Documentation

Collection class provides methods simplifying the most common data operations in Apex:
- Mapping records by given field
- Grouping records with the same value in given field
- Gathering values from given field in Set or List
- Filtering records
- Reducing a collection to single variable
- Sorting records by given field or comparator

Additionally, it provides utility methods operating on lists.
## Examples
```apex
// Get first 10 won opportunities ordered by expected revenue
List<Opportunity> wonOpportunities = (List<Opportunity>)
	Collection.of(opportunities)
		.filter(Opportunity.StageName).equals('Won')
		.orderByDesc(Opportunity.ExpectedRevenue)
		.slice(0, 10)
		.getList();


// Map opportunities by Account Id
Map<Id, Opportunity> opportunityByAccountId = (Map<Id, Opportunity>)
	Collection.of(opportunities).mapBy(Opportunity.AccountId);
```

## Mapping SObjects
Collection class can be used to map sObjects by field value.

Collection class can reduce a list of items to map — depending on used method, this can be:
- Mapping sobjects by field
- Mapping 2 fields of sobject as a key and value pair
- Mappings sobject by concatenation of 2 fields
- Mapping by Mapper class implementations for key or key and value.
  Mapper interface derives value from Collection item that will be put in the map.  
  Example use case for this is when you have custom mapping that is occurring often through the code.

Mapping expects the key to be unique, if it's not - the last item in the list wins.

#### Mapping by field 
Map collection of sObjects by any field. Framework will check field's type and dynamically construct map with correct key and value type.
```apex
Map<Id, Opportunity> opportunityByAccountId = (Map<Id, Opportunity>)
	Collection.of(opportunities).mapBy(Opportunity.AccountId);

Map<String, Opportunity> opportunityByName = (Map<String, Opportunity>)
	Collection.of(opportunities).mapBy(Opportunity.Name);
```

#### Mapping between two fields
Selected fields will be mapped as a key to value map.
```apex
Map<Id, Id> ownerByAccountId = (Map<Id, Id>)
	Collection.of(opportunities).mapBy(Opportunity.AccountId, Opportunity.OwnerId);
```

#### Mapping by concatenation
Map's key will be a concatenation of two fields. There's no separator between fields.
```apex
Map<String, JunctionObject__c> mapByParents = (Map<String, JunctionObject__c>)
	Collection.of(junctions).mapByConcatenation(JunctionObject__c.Parent1__c, JunctionObject__c.Parent2__c);
```

#### Mapping by custom mapper class
Sometimes organizations will have very specific data translations that are often executed through the code.
In that case, it's possible to implement Mapper interface and reuse it in many places.
```apex
Map<Integer, Account> accountsByDay = (Map<Integer, Account>)
	Collection.of(accounts).mapBy(new MapperByCreatedDay());


public class MapperByCreatedDay implements Collection.Mapper {

	// Should return value derived from Collections item
	public Object value(Object item) {
		SObject so = (SObject) item;
		Datetime createdDate = (Datetime) so.get('CreatedDate');
		return createdDate.day();
	}

	// Should return type of value - this will also become Map's key or value type, depending where mapper is used.
	public Type valueType() { return Integer.class; }
}
```


## Grouping SObjects

Grouping is similar to mapping, except the key is non-unique among Collection items.
The result map's value will be a list of items mapped by the same key.  
Grouping provides the same methods as mapping.

#### Grouping by field
Group collection of sObjects by any field.
```apex
Map<Id, Opportunity[]> opportunitiesByAccountId = (Map<Id, Opportunity[]>)
	Collection.of(opportunities).groupBy(Opportunity.AccountId);

Map<Id, Opportunity[]> opportunitiesByOwner = (Map<Id, Opportunity[]>)
	Collection.of(opportunities).mapBy(Opportunity.OwnerId);

Map<String, Opportunity[]> opportunitiesByStage = (Map<String, Opportunity[]>)
	Collection.of(opportunities).mapBy(Opportunity.StageName);
```
#### Grouping between two fields
Selected fields will be mapped as key to list of values map.
```apex
Map<Id, Id[]> accountIdsByOwner = (Map<Id, Id[]>)
	Collection.of(opportunities).groupBy(Opportunity.OwnerId, Opportunity.AccountId);
```
#### Group by concatenation of 2 fields
Map's key will be the concatenation of 2 fields. There's no separator between fields
```apex
Map<String, JunctionObject__c[]> mapByParents = (Map<String, JunctionObject__c[]>)
	Collection.of(junctions).groupByConcatenation(JunctionObject__c.Parent1__c, JunctionObject__c.Parent2__c);
```



## Reducing collection to List or Set

Calling getSet() or getList() with sobject field, we will get List or Set of field values.  
Mapper interface can also be used to derive values from sObjects or any other item type.
#### Getting Set of values
```apex
Set<String> strings = Collection.of(opportunities).collect(Opportunity.Name).getSetString();
Set<Id> ids = Collection.of(opportunities).collect(Opportunity.Id).getSetId();
Set<Integer> integers = Collection.of(opportunities).collect(Opportunity.FiscalYear).getSetInteger();

//Any Type
Set<Datetime> createdDates = (Set<Datetime>) Collection.of(opportunities)
        .collect(Opportunity.CreatedDate)
        .getSet();
```

#### Getting List of values
```apex
List<String> strings = Collection.of(opportunities).collect(Opportunity.Name).getListString();
List<Id> ids = Collection.of(opportunities).collect(Opportunity.Id).getListId();
List<Integer> integers = Collection.of(opportunities).collect(Opportunity.FiscalYear).getListInteger();

//Any Type
List<Datetime> createdDates = (List<Datetime>) Collection.of(opportunities).collect(Opportunity.CreatedDate).getList();
```

#### All Methods
```apex
Set<Id> getSetId();
Set<String> getSetString();
Set<Integer> getSetInteger();
Object getSet();

List<Id> getListId();
List<String> getListString();
List<Integer> getListInteger();
List<Object> getList();
```




## Filtering Items

Collection can filter out records based on given conditions.  
Filtering can be combined with any other reduction method - mapping, grouping, getting set and so on.
#### Methods
```apex
FieldFilter filter(SObjectField field);
Collection filter(Condition filter);
Collection filterAlike(SObject prototype);
```
#### Filtering sObjects by value of the field.
```apex
Opportunity opp = (Opportunity) Collection.of(opportunities)
	.filter(Opportunity.Stage).equals('Won')
	.getFirst();
```
#### Filtering with complex logic
```apex
CollectionConditions c = new CollectionConditions();
List<Opportunity> filtered = (List<Opportunity>) Collection.of(opportunities)
	.filter(
		c.ORs(
			c.ANDs(
				c.field(Opportunity.NextStep).contains('Analysis'),
				c.field(Opportunity.HasOpenActivity).equals(true),
				c.field(Opportunity.LastActivityDate).lessEqualsThan(Date.today()),
				c.field(Opportunity.LastActivityDate).greaterThan(Date.today().addDays(-2))
			),
			c.field(Opportunity.NextStep).notEquals('Analysis')
		)
	)
	.getList();
```
#### Filtering similar records
Will filter records that have the same value set as given example
```apex
List<Opportunity> filtered = (List<Opportunity>) Collection.of(opportunities)
	.filterAlike(new Opportunity(
		StageName = 'Prospect',
		AccountId = myAccount.Id
	))
	.getList();
```



## Ordering collection

Order methods can sort a list by sobject field or custom comparator.
#### Order by SObject field.
```apex
List<Opportunity> sortedOpportunities = (List<Opportunity>)
	Collection.of(opportunities)
		.orderAsc(Opportunity.CreatedDate)
		.getList();
```
#### Order using comparator class
Implement standard System.Comparator<T> class to use it for ordering items: 

```apex
List<Opportunity> opportunities = (List<Opportunity>)
    Collection.of(opportunities)
        .orderBy((Comparator<Object>) new ReverseProbabilityComparator())
        .getList();

private class ReverseProbabilityComparator implements Comparator<Opportunity> {
  public Integer compare(Opportunity thisOpp, Opportunity otherOpp) {
    if (thisOpp.Probability < otherOpp.Probability) {
      return 1;

    } else if (thisOpp.Probability > otherOpp.Probability) {
      return -1;

    } else {
      return 0;
    }
  }
}

```


## Reduce

Reduce a collection to single aggregated value or completely different data structure.  
Framework provides a few out of the box arithmetic reductions, but any kind of transformation is possible by implementing custom Reducer class.
```apex
Collection collect(SObjectField field);
Collection collect(Mapper mapper);

Decimal getSum();
Decimal getAverage();
Decimal getMin();
Decimal getMax();
Object reduce(Reducer reducer, Object initialValue);

Decimal sum = Collection.of(opportunities).collect(Opportunity.Amount).getSum();
```




## List Utilities

#### Slicing list
```apex
Collection.of(contacts).slice(0, 10).getList(); //=> returns first 10 contacts  
Collection.of(contacts).slice(new List<Integer>{0, 2, 4, 9}).getList(); //=> returns contacts from given indexes  
```
#### First / Last and other
These methods are NPE safe and will return null if list is empty.
```apex
Collection.of(contacts).getFirst(); //=> returns first element or null
Collection.of(contacts).getLast();  //=> returns last element or null  
Collection.of(contacts).removeLast();  //=> removes last element   
```



---
# Interfaces

### Collection
<details>
  <summary>Methods</summary>

```java
interface Collection {
	public static Collection of (List<Object> items);

	List<Object> get();
	Object getFirst();
	Object getLast();
	Object get(Integer i);
	Object getRandom();
	Collection add(Integer index, Object element);
	Collection add(Object element);
	Collection addAll(List<Object> elements);
	Collection addAll(Set<Object> elements);
	Collection remove(Integer index);
	Collection removeLast();
	Collection clear();
	Collection slice(Integer start, Integer stop);
	Collection slice(List<Integer> indexes);
	
	Boolean isNotEmpty();
	Boolean isEmpty();
	Integer size();
	FieldFilter filter(SObjectField field);
	Collection filter(Condition filter);
	Collection filterAlike(SObject prototype);
	
	
	Object reduce(Reducer reducer, Object initialValue);
	
	Decimal getSum();
	Decimal getAverage();
	Decimal getMin();
	Decimal getMax();
	
	
	List<Id> getListId();
	List<String> getListString();
	List<Integer> getListInteger();
	List<Object> getList();
	
	Set<Id> getSetId();
	Set<String> getSetString();
	Set<Integer> getSetInteger();
	Object getSet();
	
	Object mapBy(SObjectField field);
	Object mapBy(SObjectField keyField, SObjectField valueField);
	Object mapBy(Mapper keyMapper);
	Object mapBy(Mapper keyMapper, Mapper valueMapper);
	Object mapByConcatenation(SObjectField field1, SObjectField field2);
	
	
	Object groupBy(SObjectField field);
	Object groupBy(SObjectField keyField, SObjectField valueField);
	Object groupBy(Mapper keyMapper);
	Object groupBy(Mapper keyMapper, Mapper valueMapper);
	Object groupByConcatenation(SObjectField field1, SObjectField field2);
	
	
	Collection orderAsc(SObjectField field);
	Collection orderDesc(SObjectField field);
	Collection orderBy(Comparator<Object> comparator);
}
```
</details>

### Field Filter
These methods are available when filtering sobject list by field:
```apex
public interface FieldFilter {
	Collection equals(Object value);
	Collection notEquals(Object value);
	Collection greaterThan(Object value);
	Collection greaterEqualsThan(Object value);
	Collection lessThan(Object value);
	Collection lessEqualsThan(Object value);
	Collection isIn(Set<Object> values);
	Collection isIn(List<Object> values);
	Collection isIn(List<SObject> parents);
	Collection isNotIn(Set<Object> values);
	Collection isNotIn(List<Object> values);
	Collection contains(String value);
}
```

### Mapper
Mapper is a class that takes single collection item and converts it to value. This value can be used as maps/groups/set/list key or value.
```apex
interface Mapper {
	Type valueType();
	Object value(Object item);
}
```

### Reducer
Reducer takes entire collection and converts it to another value. This could be for example sum, min/max of the items fields, but also any different custom reduction.
```apex
interface Reducer {
	Object reduce(Object accumulator, Object item, Integer index);
}
```

---
# Change Log

### 2.0.0
- Changed custom Comparator interface to a standard that was introduced in Winter '24
- getList/getSet reducers are more robust, but now require collect calls
- Arithmetic reducers are more robust and work on collections of numeric values
```apex
Collection.of(accounts).collect(Account.AnnualRevenue).getList();
Collection.of(accounts).collect(Account.AnnualRevenue).getSet();
Collection.of(accounts).collect(Account.AnnualRevenue).getSum();
```
- Fixed wrong type returned in getList method
- API Version bumped to 61.0
