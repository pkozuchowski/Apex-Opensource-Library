# Runtime

Utility that helps with Reflective/Dynamic aspects of Apex:

##### Sleep for given period:
```apex
Runtime.sleep(2000); // Waits 2 seconds until executing next line.
```

#### Get runtime type of object:
```apex
Object o = new Account();

Runtime.getType(o); // -> returns Account.class
Runtime.getTypeName(o); // -> returns 'Account'


List<Object> lst = new List<Account>();
Runtime.getListItemType(lst); // -> returns Account.class
```


#### Stack utils:
```apex
class MyController{
    public void doSomething(){
        Runtime.getRunningClass(); // returns 'MyController'
        Runtime.getRunningMethod(); // returns 'MyController.doSomething'
        Runtime.getCaller(); //returns stack entry with class and method that invoked MyController.doSomething(); 
    }
}
```