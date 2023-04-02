# Callout Framework
Callout class is a building block for constructing outbound integrations, where each callout should go through similar flow.

Consider following example - we are creating integration with Acme APIs, which consist of X different endpoints:
- searching orders
- fetching order details
- creating new order
- fetching customer details
- etc

All calls to Acme APIs should have streamlined workflow - callouts should be authorized, logged with appropriate logging level, retried in specific cases.  
To build this configuration, we could derive new class from Callout class and configure it as follows:
```apex
public class AcmeApiCallout extends Callout {
    private AcmeAPIAuthHandler authorizationHandler = new AcmeAPIAuthHandler();

    protected override CalloutHandlersList onBeforeCalloutInit() {
        return new CalloutHandlersList()
            .add(match.once(), authorizationHandler);
    }

    protected override CalloutHandlersList onAfterCalloutInit() {
        return new CalloutHandlersList()
            .add(match.onUnauthorized(), authorizationHandler)
            .add(match.onUnauthorized(), action.retry(1))
            .add(match.onTimeout(), action.retry(1))
            .slot('beforeValidation')
            .add(match.onAnyErrorCode(), action.logCallout(LoggingLevel.ERROR))
            .add(match.onAnyErrorCode(), action.throwEx())
            .add(match.onSuccess(), action.logCallout(LoggingLevel.INFO))
            .add(match.onSuccess(), action.returnJSON(responseType));
    }
}
```

Let's break this down:  
Before Callout:
1) Runs custom authorization handler once. This is example class that would generate Oauth token for us if Named Credential can't be used.  
   It's just an example of custom handler, it's not necessary to write any in most cases.

After Callout:
1) If response returned 401 Unauthorized, run authorization handler again
2) Retry callout once again with new authorization token
3) On timeout, retry once again
4) Slot named "beforeValidation" - this does nothing, but can be used for injecting handlers later in this place
5) If webservice responded with error codes (400-599), creates log record with ERROR severity
6) If webservice responded error code, throw CalloutResponseException
7) If webservice responded with success code, log callout with INFO severity
8) If webservice responded with success code, deserialize response body to given apex type.

### Usage in API class
The callout class can then be used in methods which expose particular endpoints.
```apex
 public class AcmeAccountAPI {

    public List<Account> getAccounts(List<String> accountIds) {
        Callout c = new AcmeApiCallout();
        c.setMethod('GET');
        c.setEndpoint('callout:MyCredential/api/Account');
        c.setParam('id', accountIds, true);
        c.setResponseType(List<Account>.class);
        c.onAfterCallout()
            .addToSlot('beforeValidation',
                c.match.onNotFound(),
                c.action.returns(new List<Account>()));

        return (List<Account>) c.execute();
    }

    public Account updateAccount(Account account) {
        Callout c = new AcmeApiCallout();
        c.setMethod('POST');
        c.setEndpoint('callout:MyCredential/api/Account');
        c.setBodyJSON(account);
        c.setResponseType(Account.class);
        return (Account) c.execute();
    }
}
```
In above example slot functionality was utilized to return empty list when webservice responds with 404 Not Found.  
There's no limit on how many handlers can be added to the slot.

### Integration Design Guidelines
1) Each integration should have separate module - a set of similarly named/prefixed classes not related to any business requirement.  
   Module should be only responsible for exposing webservice endpoints in convenient way, without exposing API details.
2) Integration module should have the following classes:
    - Callout class specifying common workflow
    - DTO / Wrapper container class where each request and response is implemented as inner class.  
      This is used for serialization/deserialization.
    - Webservice endpoint methods grouped by domain ex. AcmeCustomerAPI, AcmeOrderAPI, Acme
3) Client code should not know about any API details
4) Avoid using DTO inner classes on front-end. If new API version appears, it's easier to switch if you have intermediary layer between API and front-end and
   remap your responses.  
   It also makes it possible to support many different API versions simultaneously - for example if you want to roll out new version only for selected pilot
   users.

### Trivia
- It's not required to extend Callout class, it can be used as is or configured without inheritance:
```apex
Callout c = new Callout();
c.onAfterCallout()
    .add(c.match.onNotFound(), c.action.returns(new List<Account>()));
```

- Callout by default has some handlers implemented by default:
```apex
 protected virtual CalloutHandlersList onAfterCalloutInit() {
     return new CalloutHandlersList()
         .add(match.onUnauthorized(), action.retry(1))
         .add(match.onTimeout(), action.retry(1))
         .slot('beforeValidation')
         .add(match.onAnyErrorCode(), action.logCallout(LoggingLevel.ERROR))
         .add(match.onAnyErrorCode(), action.throwEx())
         .add(match.onSuccess(), action.logCallout(LoggingLevel.INFO))
         .add(match.onSuccess(), action.returnJSON(responseType));
 }
```
- Client can remove/replace particular handlers. Name can be added to the handler, which then can be used to remove/replace.
- Shorthand method can be used to configure callout with a map:
```apex
Callout c = new AcmeApiCallout()
    .config(new Map<String, Object>{
        'method' => 'GET',
        'endpoint' => 'callout:MyCredential/api/Account',
        'params' => new Map<String, Object>{
            'id' => accountIds
        },
        'responseType' => List<Account>.class
    });
```