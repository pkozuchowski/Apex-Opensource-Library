# Runtime
*Reflective Apex Utility*

---
## Documentation
Utility class that helps with Reflective/Dynamic aspects of Apex:

#### Sleep for a given period:
- `void sleep(Long milliSeconds)` -> waits for given amount of time. Counts against CPU time limit.
```apex
Runtime.sleep(2000); // Waits 2 seconds until executing next line.
```

#### Type Utils:
- `Type getType(Object o)` -> returns runtime Type of object.
- `String getTypeName(Object o)` -> returns runtime type name of object.
- `Type getSObjectFieldType(SObjectField field)` -> returns primitive type of the field.
```apex
Object o = new Account();

Runtime.getType(o);                        // -> returns Account.class
Runtime.getTypeName(o);                    // -> returns 'Account'
Runtime.getSObjectFieldType(Account.Name); // -> returns String.class 
```

#### List utils:
- `Type getListItemType(List<Object> o)`  
    Returns Type of given list single element.
- `Type getIterableItemType(Iterable<Object> o)`  
    Returns Type of given iterable (list or set) single element.
- `List<Object> newListOfTheSameType(List<Object> original)`  
    Returns a new empty list of the same SObject type as original.
- `List<Object> newListOfItemType(Type itemType)`  
    Returns a new list of a given item type.
- `List<SObject> newListOfItemType(SObjectType itemType)`  
    Returns a new list of a given item type (List<SObject>)
- `List<Object> newListOfFieldType(SObjectField field)`  
    Returns new list with the same item type like given SObject field.
- `List<Object> newListOfItemType(Type itemType, List<Object> fallback)`   
    Returns list of a given item type or fallback in case of exception  
    - `fallback` 
        Rallback type, in case a primary type is not constructible (ex. because the type is private).

```apex
List<Object> lst = new List<Account>();

Runtime.getListItemType(lst);                   // -> returns Account.class
Runtime.getIterableItemType(lst);               // -> returns Account.class
Runtime.newListOfTheSameType(list);             // -> returns empty List<Account>;
Runtime.newListOfItemType(Account.class);       // -> returns empty List<Account>
Runtime.newListOfItemType(Account.SObjectType); // -> returns empty List<Account>
Runtime.newListOfFieldType(Account.Name);       // -> returns new List<String> 
```

#### Stack utils:
- `String getRunningClass()` -> returns Name of running callee class.
- `String getRunningMethod()` -> returns Name of running callee class and method where this was called in stack trace format `CalleeClass.method`.
- `StackTraceLine getStackLocation()` -> returns Stack Trace Line of code where this method was called.
- `StackTraceLine[] getStackTrace()` -> returns Stack Trace Lines without Apex class entry
- `StackTraceLine getCaller()` -> returns Stack trace line of apex class which called method where Runtime.getCaller() is executed.

```apex | Runtime Stack | Example when transaction is started from Aura method
class MyController {

    @AuraEnabled
    public static void doSomething() {
        try {
            // ...
        } catch (Exception e) {
            Logger.error(e);
        }
    }
}

class Logger {
    public static void error(Exception ex) {
        Runtime.getRunningClass();  // returns 'Logger'
        Runtime.getRunningMethod(); // returns 'Logger.error'
        Runtime.getStackLocation(); // returns current stack place
        // apexClassMethod - Logger.error
        // apexClass - Logger
        // method: error

        Runtime.getCaller();        // returns stack trace line with class and method that invoked MyController.doSomething();
        // - apexClassMethod: MyController.doSomething
        // - apexClass: MyController
        // - method: doSomething

        Runtime.getStackTrace();    // returns full stack trace array
        //  [
        //      {"method":"error","line":38,"column":1,"apexClassMethod":"Logger.error","apexClass":"Logger"},
        //      {"method":"doSomething","line":39,"column":1,"apexClassMethod":"MyController.doSomething","apexClass":"MyController"}
        //  ]
    }
}
```

```apex | Stack Trace Line
public class StackTraceLine {
    public String apexClassMethod;
    public String apexClass;
    public String method;
    public Integer line;
    public Integer column;
}
```