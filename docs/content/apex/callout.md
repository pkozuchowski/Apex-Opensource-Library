# Callout Framework
*Define common behavior for outgoing callouts.*

[Source](https://github.com/pkozuchowski/Apex-Opensource-Library/tree/master/force-app/commons/callout)
[Dependency](/apex/runtime)
[Install In Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04t08000000UK6VAAW)
[Install In Production](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t08000000UK6VAAW)

```bash
sf project deploy start \
-d force-app/commons/callout \
-d force-app/commons/shared \
-o sfdxOrg
```

---
# Documentation
Callout class is a building block for constructing outbound integrations, where each callout should go through similar flow
of authorization, error handling and response handling.

## Example

Consider an example of integration with external webservices where a few different endpoints are used:
- searching orders
  - fetching order details
  - creating new order

All calls to the API should have streamlined workflow - callouts should be authorized, logged with appropriate logging level, retried on timeout.    
To implement this configuration, we could derive a new class from Callout class and configure it as follows:
```apex
public class AcmeApiCallout extends Callout {
    private AcmeAPIAuthHandler authorizationHandler = new AcmeAPIAuthHandler();

    protected override void setupHandlers() {
        onBeforeCallout()
            .add(match.once(), authorizationHandler);

        onAfterCallout()
            .add(match.onUnauthorized(), authorizationHandler)
            .add(match.onUnauthorized(), action.retry(1))
            .add(match.onTimeout(), action.retry(1))
            .slot('beforeValidation')

            .add(match.onException(), action.logCallout(LoggingLevel.ERROR))
            .add(match.onException(), action.throwEx())

            .add(match.onAnyErrorCode(), action.logCallout(LoggingLevel.ERROR))
            .add(match.onAnyErrorCode(), action.throwEx())

            .add(match.onSuccess(), action.logCallout(LoggingLevel.INFO))
            .add(match.onSuccess(), action.returnJSON(responseType));
    }
}
```

Let's break this down:
- Before Callout:
    1. Runs custom authorization handler once. This is example class that would generate Oauth token for us if Named Credential can't be used.  
       It's just an example of custom handler, it's not necessary to write any in most cases.


- After Callout:
    1. If response returned 401 Unauthorized, run authorization handler again
    1. Retry callout once again with new authorization token
    1. On timeout, retry once again
    1. Slot named "beforeValidation" - this does nothing, but can be used for injecting handlers later in this place
    1. If any CalloutException was thrown, creates log record with ERROR severity
    1. If any CalloutException was thrown, throws CalloutResponseException
    1. If webservice responded with error codes (400-599), creates log record with ERROR severity
    1. If webservice responded error code, throws CalloutResponseException
    1. If webservice responded with success code, log callout with INFO severity
    1. If webservice responded with success code, deserialize response body to given apex type.

## Usage in API class
The callout class can then be used in methods which expose particular endpoints.
```apex
 public class AcmeCustomerAPI {

    public List<Customer> getCustomers(List<String> accountIds) {
        Callout c = new AcmeApiCallout();
        c.setMethod('GET');
        c.setEndpoint('callout:MyCredential/api/Customer');
        c.setParam('id', accountIds, true);
        c.setResponseType(List<Customer>.class);
        c.onAfterCallout()
            .addToSlot('beforeValidation',
                c.match.onNotFound(), c.action.returns(new List<Customer>())
            );

        return (List<Customer>) c.execute();
    }

    public Customer updateCustomer(Customer customer) {
        Callout c = new AcmeApiCallout();
        c.setMethod('POST');
        c.setEndpoint('callout:MyCredential/api/Customer');
        c.setBodyJSON(account);
        c.setResponseType(Account.class);
        return (Account) c.execute();
    }
}
```
In the above example, **slot** functionality was utilized to return an empty list when webservice responds with 404 Not Found.  
There's no limit on how many handlers can be added to the slot.


## Named Handlers
In real life, there may be exceptions to the common flow - Endpoints that do not require an authorization step, Endpoint that return NOT FOUND error code when
we'd expect an empty array, and so on. We can change the flow using Named Handlers and Slots.

Each handler pair can be given developer name, which can be later used to remove or replace the handler.  
Consider the following setup:

```apex | API-specific Callout configuration
public class AcmeApiCallout extends Callout {
    private AcmeAPIAuthHandler authorizationHandler = new AcmeAPIAuthHandler();

    protected override void setupHandlers() {
        onAfterCallout()
            .add('authorize', match.onUnauthorized(), authorizationHandler)
            .add('authorizeRetry', match.onUnauthorized(), action.retry(1))
            .add('timeoutRetry', match.onTimeout(), action.retry(1))
            .add(match.onSuccess(), action.logCallout(LoggingLevel.INFO))
            .add(match.onSuccess(), action.returnJSON(responseType));
    }
}
```

In one of the calls, we will remove an `authorizeRetry` step and replace retry with logging action. We will also retry on timeout 5 times instead of once.
```apex | Client Code
 public class AcmeCustomerAPI {

    public List<Customer> getCustomers(List<String> accountIds) {
        Callout c = new AcmeApiCallout();
        c.onAfterCallout()
            .remove('authorize')
            .replace('authorizeRetry', c.action.logCallout(LoggingLevel.ERROR))
            .replace('timeoutRetry', c.action.retry(5));

        return (List<Customer>) c.execute();
    }
}
```

## Slots
List of handlers can be defined with a slot - placeholder in which we can later add any number of additional steps:

```apex | API-specific Callout configuration
public class AcmeApiCallout extends Callout {
    private AcmeAPIAuthHandler authorizationHandler = new AcmeAPIAuthHandler();

    protected override void setupHandlers() {
        onAfterCallout()
            .slot('beforeValidation')
            .add(match.onAnyErrorCode(), action.logCallout(LoggingLevel.ERROR))
            .add(match.onAnyErrorCode(), action.throwEx())
            .add(match.onSuccess(), action.returnJSON(responseType));
    }
}
```

Add handler to the slot which does following:
- IF Webservice returned `404 NOT FOUND`
  - THEN return an empty list and stop execution
```apex
 public class AcmeCustomerAPI {

    public List<Customer> getCustomers(List<String> accountIds) {
        Callout c = new AcmeApiCallout();
        c.onAfterCallout()
            .addToSlot('beforeValidation',
                c.match.onNotFound(), c.action.returns(new List<Customer>())
            );

        return (List<Customer>) c.execute();
    }
}
```

---
# Extensions

## Custom Matchers and Handlers
Callout Framework can be easily extended by implementing two interfaces for matching and handling callouts:

```apex | Condition | Generic Condition interface is used to check if Callout satisfies the condition for associated action.
public interface Condition {
    Boolean isTrue(Object item);
}
```

```apex | Callout.Handler | Represents action to perform.
public interface Handler {
    Object handle(Callout c);
}
```

The Framework works as follows - when callout is executed():
1. Iterate through pairs of Condition-Handler
   1. If the Condition returns true:
       1. Execute Handler and check return value:
           1. If `null` - continue iteration over actions.
           1. If not null - return this immediately as response from callout `execute` method.
           1. If throws exception, breaks the code execution - this exception has to be handled in client code.

Callout has two lists of handlers - one executed before and one after the callout.

## Examples

```apex | Example of Condition class
/**
 * Matches Response body that contains substring
 */
private class SubstringMatcher implements Condition {
    private String substring;

    private SubstringMatcher(String substring) {
        this.substring = substring;
    }

    public Boolean isTrue(Object item) {
        Callout c = (Callout) item;

        return c.getResponse()?.getBody()?.containsIgnoreCase(substring) == true;
    }
}
```

```apex | Example of Handler class
private class RetryHandler implements Callout.Handler {
    private Integer attempt = 0, maxAttempts;

    public RetryHandler(Integer howManyTimes) {
        maxAttempts = howManyTimes;
    }

    public Object handle(Callout c) {
        if (attempt < maxAttempts) {
            attempt++;
            return c.execute();
        }

        return null;
    }
}
```

---
# Interfaces

## Callout
<details>
	<summary>Methods</summary>

| Method                                                                | Description                                                                          |
|-----------------------------------------------------------------------|--------------------------------------------------------------------------------------|
| `void setMethod(String method)`                                       | Sets Http Request's Method                                                           |
| `void setEndpoint(String endpoint)`                                   | Sets Http Request's Endpoint                                                         |
| `void setTimeout(Integer timeout)`                                    | Sets Http Request's Timeout value                                                    |
| `void setHeader(String header, String value)`                         | Sets Http Request's Header                                                           |
| `void setHeaders(Map<String, String> headersMap)`                     | Sets Http Request's headers `(Map<Header, Value>)`                                   |
| `void setBody(String body)`                                           | Sets plain text body                                                                 |
| `void setBodyJSON(Object o, Boolean suppressNulls)`                   | Serializes object and sets as body                                                   |
| `void setLogName(String logName)`                                     | Sets Log's name - by default this is Method + Endpoint                               |
| `void setParams(Map<String, Object> params, Boolean urlEncode)`       | Set URL query parameters                                                             |
| `void setParam(String name, Object value, Boolean urlEncode)`         | Set URL query parameter                                                              |
| `void setParams(String name, List<Object> values, Boolean urlEncode)` | Set URL query list parameter                                                         |
| `void setResponseType(Type apexType)`                                 | If provided, response will be deserialized to this type and returned from execute(); |
| `HttpResponse getResponse()`                                          | returns HttpResponse                                                                 |
| `HttpRequest getRequest()`                                            | returns HttpRequest                                                                  |
| `Object getCalloutException()`                                        | returns Callout Exception from the latest execution                                  |

</details>

## CalloutHandlersList
<details>
	<summary>Methods</summary>

| Method                                                                                        | Description                                                     |
|-----------------------------------------------------------------------------------------------|-----------------------------------------------------------------|
| `CalloutHandlersList add(Condition matcher, Callout.Handler handler);`                        | Adds new handler to the list                                    |
| `CalloutHandlersList add(String name, Condition matcher, Callout.Handler handler);`           | Adds new handler with unique name                               |
| `CalloutHandlersList addToSlot(String slotName, Condition matcher, Callout.Handler handler);` | Adds handler to the slot                                        |
| `CalloutHandlersList slot(String slotName);`                                                  | Creates slot with given name                                    |
| `CalloutHandlersList remove(String name);`                                                    | Removes handler with given name                                 |
| `CalloutHandlersList replace(String name, Callout.Handler handler);`                          | Replaces handler under given name, while matcher stays the same |
| `CalloutHandlersList clear();`                                                                | Clears list of handlers                                         |
</details>


## Condition
```apex | Condition
public interface Condition {
    Boolean isTrue(Object item);
}
```

## Callout.Handler
```apex | Callout.Handler
public interface Handler {
    Object handle(Callout c);
}
```

---
# Trivia
- It's not required to extend Callout class. It can be used as is or configured without inheritance:
```apex
public Callout getAcmeCallout() {
    Callout c = new Callout();
    c.onBeforeCallout()
        .add(c.match.once(), authorizationHandler);

    c.onAfterCallout()
        .add(c.match.onUnauthorized(), authorizationHandler)
        .add(c.match.onUnauthorized(), c.action.retry(1))
        .add(c.match.onTimeout(), c.action.retry(1))
        .slot('beforeValidation')
        .add(c.match.onAnyErrorCode(), c.action.logCallout(LoggingLevel.ERROR))
        .add(c.match.onAnyErrorCode(), c.action.throwEx())
        .add(c.match.onSuccess(), c.action.logCallout(LoggingLevel.INFO))
        .add(c.match.onSuccess(), c.action.returnJSON(responseType));

    return c;
}
```

- Callout has some handlers implemented by default:
```apex | Default Handlers
onAfterCallout()
	.add(match.onUnauthorized(), action.retry(1))
	.add(match.onTimeout(), action.retry(1))
	.slot('beforeValidation')
	.add(match.onException(), action.logCallout(LoggingLevel.ERROR))
	.add(match.onException(), action.throwEx())
	.add(match.onAnyErrorCode(), action.logCallout(LoggingLevel.ERROR))
	.add(match.onAnyErrorCode(), action.throwEx())
	.add(match.onSuccess(), action.logCallout(LoggingLevel.INFO))
	.add(match.onSuccess(), action.returnJSON(responseType));
```
- Client code can remove or replace particular handlers. Name can be added to the handler, which then can be used to remove/replace.

---
# Change Log

### Ver. 1.0.1
* Fixed bug where CalloutException was not handled properly and resulted in framework returning null.