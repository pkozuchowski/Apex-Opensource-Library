# HTTP Callout Mock Router
*Configuration-driven, endpoint pattern-based router for Http Mocks.*

[Source](https://github.com/pkozuchowski/Apex-Opensource-Library/tree/master/force-app/commons/httpMocks)
[Install In Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04td2000000L9jRAAS)
[Install In Production](https://login.salesforce.com/packaging/installPackage.apexp?p0=04td2000000L9jRAAS)

```bash
sf project deploy start -d force-app/commons/httpMocks -o sfdxOrg
```

---
# Documentation
The **HTTP Callout Mock Router** is a configuration-driven test framework that makes HTTP callout mocking
predictable, scalable, and maintainable by routing HTTP requests to the correct mock based on:
- **HTTP Method** – (`GET/POST/PUT/PATCH/DELETE or *`)
- **Endpoint pattern** – (regex)

Mocks can be defined in custom metadata or programmatically in Apex and can be overridden and mutated as needed.

#### Metadata Router
![http-router-example.png](/img/http-router-example.png)
```apex
Test.setMock(HttpCalloutMock.class, HttpMocks.config());
```

#### Apex Router
```apex
public class SalesforceRestAPIMocks extends HttpCalloutMockRouter {

    public SalesforceRestAPIMocks() {
        mock('Query', 'GET', 'callout:SF_API/query\\?q=.*',
            HttpMocks.staticResource(200, 'OK', 'StaticResourceWithResponse')
        );

        mock('Create Account', 'POST', 'callout:SF_API/sobjects/Account/',
            HttpMocks.json(201, 'Created', new CreateRecordResult(true))
        );

        mock('Get Account', 'GET', 'callout:SF_API/sobjects/Account/.*',
            HttpMocks.response(200, 'OK')
                .header('X-API-Version', 'v1')
                .body('{"success":true}')
        );
    }
}

```

```apex
Test.setMock(HttpCalloutMock.class, new SalesforceRestAPIMocks());
```

## Core Concept
Framework introduces a new **HttpCalloutChainMock** interface, which checks whether the mock should handle the request:
```apex
public interface HttpCalloutChainMock extends HttpCalloutMock {
    Boolean handles(HttpRequest request);
}
```

The router implements the `HttpCalloutChainMock` interface and during the test,
it is set as mock using Test class - `Test.setMock(HttpCalloutMock.class, HttpMocks.config());`.

All mocks registered in the router are wrapped into `HttpCalloutChainMock` instance that checks whether the request should be handled by the mock,
based on the Http Endpoint and Method.

When Http Request is made, the router:
1. Loads **Default** metadata mocks
2. Iterates through registered mocks
3. Finds the first handler whose `handles(request)` returns `true`
4. Uses either:
    - the default handler, or
    - override (by mock's name)
5. Returns the resulting `HttpResponse`
6. Stores the request/response for later assertions

If nothing matches, it throws an “Unhandled request” exception — it tells you forgot to mock something.


## What problems it solves

### One mock, many endpoints
Instead of selecting the right mock for each test, you define a **router** which will decide which mock to use.
If multiple callouts are made in the test, all will be properly routed to the correct mock.

### Stable mocks even when URLs vary
Endpoints are matched via **regex patterns**, which lets you tolerate variations like:
- record IDs
- query parameters
- API versions in the URL
- different Named Credential base URLs between environments

### Configuration-driven mocking
Mocks can be defined in **Custom Metadata (`HttpCalloutMock__mdt`)**, making them:
- deployable
- reviewable
- reusable across many tests
- easy to override per test without cloning or customizing Apex classes

### Easy negative and mutation testing
A default “happy path” mock can be overridden or mutated in a specific test to simulate:
- `401 Unauthorized`
- `404 Not Found`
- `429 Too Many Requests`
- `500 Internal Server Error`
- redirects (e.g., `Location` header)
- vendor-specific error payloads

The framework includes a fluent response builder you can use to:
- change status
- add headers
- set body (text, JSON, static resource)
- perform string replacements in the body
- apply targeted JSON path replacements (great for tweaking a single field)

Overriding named mock with configuration-based mock:
```apex
Test.setMock(HttpCalloutMock.class, HttpMocks.config()
    .overrideMock('SF_REST_Query', 'SF_REST_Query_Empty')
);
```

Overriding named mock with fluent response builder:
```apex
Test.setMock(HttpCalloutMock.class, HttpMocks.config()
    .overrideMock('SF_REST_Query', HttpMocks.response(404, 'Not Found'))
);
```

Mutating returned response:
```apex
Test.setMock(HttpCalloutMock.class, HttpMocks.config()
    .mutateResponse()
    .status(404, 'Not Found')
    .replaceInBody('success', 'error')
);
```

Replacing the response JSON property with a new value:
```apex
Test.setMock(HttpCalloutMock.class, HttpMocks.config()
    .mutateResponse()
    .replaceInJson('.records.[0].Name', 'New Account Name')
);
```

### Assert what was actually called
The router can keep a history of handled `HttpRequest` and returned `HttpResponse`, which is useful when your production code hides the request
details behind service layers.

```apex
List<HttpRequest> requests = HttpMocks.getRequests();
List<HttpResponse> responses = HttpMocks.getResponses();
```

This is especially useful for:
- verifying request/response payloads
- verifying callout ordering
- verifying retry behavior (multiple requests)
- ensuring the correct endpoint was called

## Custom Metadata model (HttpCalloutMock__mdt)

Each record represents one “route” with a response.

Key fields (what you typically fill in):

- **DeveloperName**: unique identifier (used for overrides)
- **Default__c**: whether it loads automatically as a default route
- **Methods__c**: e.g. `"GET"` or `"GET,POST"` or `"*"`
- **Endpoint__c**: regex pattern to match against `HttpRequest.getEndpoint()`
- **StatusCode__c** / **Status__c**
- **Type__c**: one of:
    - `Plain Body`
    - `Static Resource`
    - `Apex Class`
- **Response__c**:
    - for `Plain Body`: literal response body
    - for `Static Resource`: static resource name
    - for `Apex Class`: Apex class name that implements `HttpCalloutMock`
- **Headers__c**: newline-separated `Header: Value` pairs

This supports both “simple declarative response bodies,” big responses in static resources, and “smart mocks” via Apex classes.


---
# Programmatic routing

If you prefer mocks defined in Apex (or need logic-based matching), you can create a router class and register and nest routers.

Router class considers a request to be handled by a mock if it matches at least one of its registered handlers.

```apex
Test.setMock(HttpCalloutMock.class, new PaymentsMocks());
```

```apex
public class OrgMocks extends HttpCalloutMockRouter {
    public OrgMocks() {
        mock('Salesforce APIs', new SalesforceRestAPIMocks());
        mock('Azure APIs', new AzureMocks());
    }
}

public class SalesforceRestAPIMocks extends HttpCalloutMockRouter {

    public SalesforceRestAPIMocks() {
        mock('Query', 'GET', 'callout:SF_API/query\\?q=.*',
            HttpMocks.staticResource(200, 'OK', 'StaticResourceWithResponse')
        );

        mock('Create Account', 'POST', 'callout:SF_API/sobjects/Account/',
            HttpMocks.json(201, 'Created', new CreateRecordResult(true))
        );

        mock('Get Account', 'GET', 'callout:SF_API/sobjects/Account/.*',
            HttpMocks.json(200, 'OK',
                new Account(Id = ACCOUNT_ID, Name = ACCOUNT_NAME))
        );

        mock('Delete Account', 'DELETE', 'callout:SF_API/sobjects/Account/.*',
            HttpMocks.response(204, 'No Content')
        );
    }
}

public class AzureMocks extends HttpCalloutMockRouter {
    public AzureMocks() {
        mock('Get Account', 'GET', 'callout:AWS/Account',
            HttpMocks.response(200, 'OK')
                .body('{"name":"Test"}')
        );
    }
}
```

---
# Recommendations
## Recommended patterns for real projects

### Pattern 1: “Defaults in metadata, overrides in tests”
- Put stable “happy path” mocks in `HttpCalloutMock__mdt` with `Default__c = true`
- Create additional non-default mocks (e.g., error variants)
- Override in tests as needed
- Create generic error mocks (ex. 404 Not Found, 500 Internal Server Error)

Result: tests become **short**, **consistent**, and **easy to review**.

### Pattern 2: “Per integration module router” for programmatic routing
- One router per vendor/service
- A top-level `OrgMocks` router aggregates them
- Keeps responsibility boundaries clean and avoids a 1,000-line mock class

## Common gotchas
- **Regex matters**: `Endpoint__c` is a regex pattern. If you mean “any characters,” you likely need `.*`.
- **Match the actual `request.getEndpoint()`**: in callout tests this often includes `callout:NamedCredential/...`.
- **Order and specificity**: if two patterns can match, ensure only one is Default.
    - If regexp is too broad and matches many endpoints, consider using a more specific endpoint pattern.
- **Unhandled request exception is good**: it flags missing mock coverage early.
- **Method__c** field accepts '*' wild-card, which matches all methods, and comma-separated values (`"POST,PUT"`).

---
# Specification

### HttpCalloutChainMock (interface)

| Signature                              | Description                                                                                                                                                                                              |
|----------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `Boolean handles(HttpRequest request)` | Determines whether the mock should handle the incoming HTTP request. Extends the standard `HttpCalloutMock` contract, so implementations also provide `respond(HttpRequest)` via the platform interface. |

### HttpMocks
Convenience factory for creating HTTP mocks and accessing recorded requests/responses.

| Signature                                                                                         | Description                                                                               |
|---------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------|
| `static List<HttpRequest> getRequests()`                                                          | Returns all handled requests recorded by the router.                                      |
| `static List<HttpResponse> getResponses()`                                                        | Returns all responses recorded by the router.                                             |
| `static HttpCalloutMockRouter config()`                                                           | Creates a router populated from default custom metadata mocks.                            |
| `static HttpMockBuilder config(String customMetadataName)`                                        | Creates a builder backed by a specific metadata-defined mock, selected by developer name. |
| `static HttpMockBuilder config(HttpCalloutMock__mdt customMetadata)`                              | Creates a builder backed by a provided metadata mock record.                              |
| `static HttpMockBuilder response(Integer statusCode, String status)`                              | Creates a builder with the specified status only.                                         |
| `static HttpMockBuilder response(Integer statusCode, String status, String body)`                 | Creates a builder with the specified status and raw body.                                 |
| `static HttpMockBuilder json(Integer statusCode, String status, Object toSerialize)`              | Creates a builder with the specified status and JSON-serialized body.                     |
| `static HttpMockBuilder staticResource(Integer statusCode, String status, String staticResource)` | Creates a builder backed by a `StaticResourceCalloutMock`.                                |

### HttpCalloutMockRouter

| Signature                                                                                               | Description                                                                                                                                            |
|---------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------|
| `HttpCalloutMockRouter mock(String name, String methods, String endpointPattern, HttpCalloutMock mock)` | Registers a mock for a given HTTP method list and endpoint regex. Internally wraps it in an endpoint matcher.                                          |
| `HttpCalloutMockRouter mock(String name, HttpCalloutChainMock handler)`                                 | Registers a chain-aware mock handler under a unique name.                                                                                              |
| `HttpCalloutMockRouter overrideMock(String name, String overrideMetadataName)`                          | Replaces a named registered mock with one loaded from custom metadata.                                                                                 |
| `HttpCalloutMockRouter overrideMock(String name, HttpCalloutMock mock)`                                 | Replaces a named registered mock with another `HttpCalloutMock`. Throws if the named mock is not registered.                                           |
| `HttpMockBuilder mutateResponse()`                                                                      | Creates a response builder layered on top of this router, allowing post-processing of routed responses.                                                |
| `HttpResponse respond(HttpRequest request)`                                                             | Finds the first registered mock that can handle the request, invokes it, stores request/response, and returns the response. Throws if no mock matches. |

### HttpMockBuilder
Fluent builder for constructing or mutating HTTP mock responses. Can operate standalone or wrap another `HttpCalloutMock`.

| Signature                                                            | Description                                                           |
|----------------------------------------------------------------------|-----------------------------------------------------------------------|
| `HttpMockBuilder()`                                                  | Creates an empty builder.                                             |
| `HttpMockBuilder(HttpCalloutMock mock)`                              | Creates a builder that decorates an existing mock.                    |
| `HttpMockBuilder status(Integer statusCode, String status)`          | Sets the HTTP status code and status text.                            |
| `HttpMockBuilder header(String key, String value)`                   | Adds or replaces a response header.                                   |
| `HttpMockBuilder body(String body)`                                  | Sets the raw response body.                                           |
| `HttpMockBuilder json(Object toSerialize)`                           | Serializes an object to JSON and uses it as the response body.        |
| `HttpMockBuilder replaceInBody(String target, String replacement)`   | Registers a plain string replacement to apply to the response body.   |
| `HttpMockBuilder replaceInJSON(String jsonPath, Object replacement)` | Replaces a JSON node at a path after deserializing the response body. |

---
# Change Log
### v2.0
- Refactored and cleaned up code base
- Removed Http Callout Mock Variable metadata from the package
- Added fluent response builder
- Added Mutation API
- Added Body and JSON replacements mutations.

### v1.2
- Added apex class namespace to custom metadata class and updated API versions

### v1.1.2
- Bugfix: Fixed endpoint variables not loading from metadata

### v1.1.1
- Bugfix: Added missing query fields

### v1.1.0
- Added shorthand override method Http
    ```apex
    public HttpCalloutMockRouter overrideMock(String name, String overrideMetadataName)
    ```
- Added HttpMocks methods to return issued requests and responses.

### v1.0.2
- Fixed bug in HTTP Headers specified in metadata, where header value would not be parsed correctly if it contained colon, which would cause issues for Location
  headers.
- Added help text to custom metadata fields.