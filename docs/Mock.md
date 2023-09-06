# Mock Utility
*Mock response of the called method.*

[Source](https://github.com/pkozuchowski/Apex-Opensource-Library/blob/master/force-app/commons/mocks/Mock.cls)


```bash
sf project deploy start -m "ApexClass:Mock" -o sfdxOrg
```

---
## Documentation
A very light-weight Mocking utility (less than 100 lines of code) that simplifies mocking.

It features the following methods:
- Mocking return values
- Mocking return value for given method
- Mocking return value for n-th invocation of given method
- Mocking exception thrown by the mocked method

## Usage

Consider, we have the following controller class for My Account page and associated selector.  
In unit tests, we want to mock the response of the selector class.

```apex
public class MyAccountCtrl {
    @TestVisible AccountSelector accountSelector = new AccountSelector();

    public static Account getMyAccount() {
        try {
            Id myId = UserInfo.getUserId();
            return accountSelector.getByOwnerId(myId);

        } catch (Exception e) {
            throw new AuraHandledException('Account unavailable');
        }
    }
} 
```

#### Mock response of any method
If the code only calls one method from mocked class, we can skip the method name. In that case, all calls will return mocked response.
```apex
public class MyAccountCtrlTest {

    @IsTest
    static void testGetMyAccount() {
        MyAccountCtrl.accountSelector = (AccountSelector) Mock.response(AccountSelector.class,
            new Account(Name = 'My Account')
        );
    }
} 
```

If response value is an exception, that exception will be thrown when mocked method is called.
```apex
MyAccountCtrl.accountSelector = (AccountSelector) Mock.response(AccountSelector.class,
    new QueryException('List has no rows for assignment to SObject')
);
```

#### Mock specific method

Mock response just for given method. Other methods will return null.
```apex
public class MyAccountCtrlTest {

    @IsTest
    static void testGetMyAccount() {
        MyAccountCtrl.accountSelector = (AccountSelector) Mock.response(AccountSelector.class,
            'getByOwnerId', new Account(Name = 'My Account')
        );
    }
} 
```

#### Mock different responses for different methods
You can specify a map of responses for different methods or add '#n' suffix to change response for n-th invocation of the method.  
In example bellow, calling `accountSelector.getById()` will yield a different result each time.
```apex
public class MyAccountCtrlTest {

    @IsTest
    static void testGetMyAccount() {
        MyAccountCtrl.accountSelector = (AccountSelector) Mock.response(AccountSelector.class,
            new Map<String, Object>{
                'getByOwnerId' => new Account(Name = 'My Account'),
                'getById#1' => new Account(Name = 'Test Account'),
                'getById#2' => new Account(Name = 'Another Account'),
                'getById#3' => new QueryException('List has no rows for assignment to SObject')
            }
        );
    }
} 
```