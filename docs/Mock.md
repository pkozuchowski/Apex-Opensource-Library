# Mock Utility

A very light-weight Mocking utility (less than 100 lines of code) that simplifies mocking.

It features the following methods:
- Mocking return values
- Mocking return value for given method
- Mocking return value for n-th invocation of given method
- Mocking exception thrown by the mocked method

## Examples:

Consider, we have the following controller class for My Account page and associated selector.  
In unit tests, we want to mock the response 55of the selector class.

```apex
public class MyAccountCtrl {
    @TestVisible AccountSelector accountSelector = new AccountSelector();

    public static Account getMyAccount() {
        try {
            Id myId = UserInfo.getUserId();
            return accountSelector.getByOwnerId(myId).get(0);
            
        } catch (Exception e) {
            throw new AuraHandledException('Account unavailable');
        }
    }
} 
```

Mock response without specifying method:
```apex
public class MyAccountCtrlT {

    @IsTest
    static void testGetMyAccount() {
        MyAccountCtrl.accountSelector = (AccountSelector) Mock.response(AccountSelector.class, new List<Account>{
            new Account(Name = 'My Account')
        });

        //or to simulate exception
        MyAccountCtrl.accountSelector = (AccountSelector) Mock.response(AccountSelector.class,
            new QueryException('List has no rows for assignment to SObject')
        );
    }
} 
```

Mock response just for given method. Other methods return null.
```apex
public class MyAccountCtrlT {

    @IsTest
    static void testGetMyAccount() {
        MyAccountCtrl.accountSelector = (AccountSelector) Mock.response(AccountSelector.class,
            'getByOwnerId', new List<Account>{
                new Account(Name = 'My Account')
            });
    }
} 
```


**Mock different responses for different methods**  
You can specify '#n' suffix to change response for n-th invocation of the method. Or you can specify exception
```apex
public class MyAccountCtrlT {

    @IsTest
    static void testGetMyAccount() {
        MyAccountCtrl.accountSelector = (AccountSelector) Mock.response(AccountSelector.class,
            new Map<String, Object>{
                'getByOwnerId' => new List<Account>{
                    new Account(Name = 'My Account')
                },
                'getById#1' => new List<Account>{
                    new Account(Name = 'Test Account')
                },
                'getById#2' => new List<Account>{
                    new Account(Name = 'Another Account')
                },
                'getById#3' => new QueryException('List has no rows for assignment to SObject')
            }
        );
    }
} 
```