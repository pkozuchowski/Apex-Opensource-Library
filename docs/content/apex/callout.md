# Callout Framework
*Define common behavior for outgoing callouts.*

[Source](https://github.com/pkozuchowski/Apex-Opensource-Library/tree/master/force-app/commons/callout)
[Dependency](/apex/runtime)
[Install In Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04tJ6000000LYsyIAG)
[Install In Production](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tJ6000000LYsyIAG)

```bash
sf project deploy start \
-d force-app/commons/callout \
-d force-app/commons/shared \
-o sfdxOrg
```

---
# Documentation
## Overview of Callout Framework

Callout framework standardizes **how your org performs HTTP integrations** by wrapping `HttpRequest/HttpResponse` in a small orchestration layer that is:

- **Composable** (plug in behavior via handlers),
- **Predictable** (consistent success/error handling),
- **Extensible** (API-specific subclasses),
- **Test-friendly** (works cleanly with `HttpCalloutMock`),
- **Operational** (supports retries, logging hooks, rich exceptions, and metadata like duration / related record).

At a high level, you build a `Callout`, configure the request (method/endpoint/headers/body/params), optionally declare what type you expect back, and then
execute it.

The framework runs:
1. **Before-callout handlers** (e.g., auth header injection)
2. The actual HTTP callout
3. **After-callout handlers** (e.g., retry, translate errors to typed exceptions, return JSON, logging)

### Example
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

    private class AcmeAPIAuthHandler implements Callout.Handler {
        public Object handle(Callout c) {
            c.setHeader('Authorization', 'Bearer XXX');
            return null;
        }
    }
}
```

#### Explanation
Let's break this down:
- **Before Callout:**
    1. Runs custom authorization handler once. This is example class that would generate Oauth token for us if Named Credential can't be used. It's just an
       example of a custom handler, it's not necessary to write any in most cases.


- **After Callout:**
    1. If response returned 401 Unauthorized, run authorization handler again
    2. Retry callout once again with new authorization token
    3. On timeout, retry once again
    4. Slot named "beforeValidation" - this does nothing, but can be used for injecting handlers later in this place
    5. If any CalloutException was thrown, creates log record with ERROR severity
    6. If any CalloutException was thrown, throws CalloutResponseException
    7. If webservice responded with error codes (400-599), creates log record with ERROR severity
    8. If webservice responded error code, throws CalloutResponseException
    9. If webservice responded with success code, log callout with INFO severity
    10. If webservice responded with success code, deserialize response body to given apex type.

## Key Concepts

### Callout (the orchestrator)
A `Callout` instance owns:

- A `HttpRequest` being built
- The last `HttpResponse` (if any)
- The last `CalloutException` (if the platform threw one)
- `metadata` such as:
    - `duration` (ms)
    - `relatedId` (record correlation)
    - `logName` (human-friendly identifier)
- Two handler pipelines:
    - `onBeforeCallout()`
    - `onAfterCallout()`

It also exposes two convenience objects:

- `match` — a catalog of conditions (`CalloutConditions`)
- `action` — a catalog of handler factories (`CalloutHandlers`)

### Conditions (CalloutConditions)
Conditions decide *when* a handler should run, based on the callout state (response, status code, exception, body content, etc.).

Typical conditions include:

- HTTP status checks:
    - `onSuccess()` → 2xx
    - `onUnauthorized()` → 401
    - `onRateLimit()` → 429
    - `onNotFound()` → 404
    - `onAnyErrorCode()` → 4xx–5xx
    - `onTimeout()` → matches timeout exception and/or 408/504
- Exception checks:
    - `onException()` / `onException('...exact message...')`
- Body checks:
    - `onRegexMatch('...')`
    - `onContains('...')`
    - `onDeserializableTo(SomeType.class)` → “is the body shaped like X?”

### Handlers (CalloutHandlers and Callout.Handler)
Handlers define *what to do* when a condition matches. A handler is simply:

- Input: the current `Callout`
- Output: `Object` (usually `null`, but can short-circuit execution by returning a value)

Common actions provided:

- `retry(n)` → re-executes the callout up to *n* times when matched
- `sleep(ms)` → pauses execution (useful for 429 backoff)
- `throwEx([message])` → throws a `CalloutResponseException` with the response attached
- `throwResponseEx(SomeExceptionType.class)` → deserialize error JSON into a typed exception and throw it
- `returnJSON(SomeType.class)` → deserialize success body and return it
- `returns(anyValue)` → return a fixed value (e.g., “return empty list on 404”)
- `replaceAll(regex, substitution)` → mutate response body before subsequent steps (handy for odd JSON keys)

> Logging is intentionally a hook: there’s a `logCallout(level)` handler stub meant to be wired to *your* logger implementation.

### Handler list orchestration (CalloutHandlersList)
Handlers are stored in an ordered list and executed in sequence. Features:

- **Named handlers**: `add('name', condition, handler)` so you can `remove()` or `replace()`
- **Slots**: `slot('beforeValidation')` creates an insertion point
- **Inject into slots**: `addToSlot('beforeValidation', ...)` to push a handler *into the middle* of a pre-built pipeline
- **Locking**: the list is “locked” at first execution to avoid surprises if modified while iterating

This makes it easy to define a “default integration policy” and then tweak behavior per endpoint call.


## Why use this framework? (Problems it solves)

### Consistency across integrations
Instead of each team writing bespoke patterns for:
- status handling,
- retries,
- error parsing,
- logging/correlation,
- response deserialization,

…you standardize it with a shared callout pipeline.

### Separation of concerns
- “How to call Acme API” lives in a subclass and its handlers.
- “What this method returns to business logic” lives in a small, readable API method.
- Error handling is declarative (“on 400 → throw typed exception”).

### Safer operations
- Centralizes retry logic and allows targeted retry rules (401/timeout/rate-limit).
- Captures duration and correlation IDs for observability.

### Easier testing
You can test behavior by returning different HTTP status codes/bodies and verifying:
- correct retries,
- correct return values,
- correct exceptions,
- correct headers (auth handler ran).

## Recommended Use-Cases

### Use-case A: Build an “API client” class (clean boundary)
Create a class like `PaymentsApi`, `ErpApi`, `KycApi` where each method constructs a callout and returns typed data. Consumers never touch raw `Http`.

### Use-case B: Centralized retry + backoff policies
- Retry on 401 (token expired, refresh flow may be in a before-handler)
- Retry on timeouts (408/504 or “Read timed out”)
- Sleep on 429 and reattempt

### Use-case C: Typed error handling for downstream callers
Map error payloads into a typed `CalloutResponseException` subclass so callers can catch specific exceptions and react (e.g., show user-friendly message vs.
fail silently).

### Use-case D: Normalize “weird JSON”
Some APIs return invalid Apex field names (e.g., keys with dots). Use `replaceAll()` before deserialization.

### Use-case E: Correlate callouts to records / business transactions
Set `relatedId` (or other metadata) so logs can link back to a specific record or process run.

---
# Usage Patterns & Examples
## Usage Patterns & Examples

### Example 1: The simplest “GET + return JSON”
```apex
public with sharing class WeatherApi {
    public class ForecastDto {
        public String city;
        public Decimal temperatureC;
    }

    public static ForecastDto getForecast(String city) {
        Callout c = new Callout();
        c.setMethod('GET');
        c.setEndpoint('callout:Weather_NC/forecast');
        c.setParam('city', city, true);
        c.setResponseType(ForecastDto.class);

        return (ForecastDto) c.execute();
    }
}
```

### Example 2: API-specific subclass (default policy once, reused everywhere)
Create one subclass per remote system to define the “house rules”:
- auth before-callout
- retries on transient failures
- throw exceptions on non-2xx
- return JSON on 2xx

```apex
public with sharing class AcmeCallout extends Callout {
    private class AuthHandler implements Callout.Handler {
        public Object handle(Callout c) {
            c.setHeader('Authorization', 'Bearer ' + '<token-placeholder>');
            return null;
        }
    }

    protected override void setupHandlers() {
        onBeforeCallout()
            .add(match.once(), new AuthHandler());

        onAfterCallout()
            .add(match.onUnauthorized(), action.retry(1))
            .add(match.onTimeout(), action.retry(1))
            .add(match.onAnyErrorCode(), action.throwEx())
            .add(match.onSuccess(), action.returnJSON(responseType));
    }
}
```

### Example 3: “Return empty list on 404” without changing global policy
Slots let you inject special-case behavior between the shared rules.

```apex
public with sharing class AcmeAccountsApi {
    public static List<Account> findAccounts(List<String> ids) {
        Callout c = new AcmeCallout();
        c.setMethod('GET');
        c.setEndpoint('callout:Acme_NC/api/accounts');
        c.setParams(new Map<String, Object>{'id' => ids}, true);
        c.setResponseType(List<Account>.class);

        c.onAfterCallout()
            .addToSlot('beforeValidation', c.match.onNotFound(), c.action.returns(new List<Account>()));

        return (List<Account>) c.execute();
    }
}
```

### Example 4: Typed error exception (deserialize error JSON, throw it)
Use when you want to catch specific error fields.

```apex
public with sharing class AcmeError extends CalloutResponseException {
    public String errorCode;
    public String errorMessage;

    public override String getMessage(HttpResponse response) {
        AcmeError parsed = (AcmeError) JSON.deserialize(response.getBody(), AcmeError.class);
        this.errorCode = parsed.errorCode;
        this.errorMessage = parsed.errorMessage;
        return errorMessage;
    }
}

public with sharing class AcmeUpdateApi {
    public static Account update(Account a) {
        Callout c = new AcmeCallout();
        c.setMethod('POST');
        c.setEndpoint('callout:Acme_NC/api/accounts/' + a.Id);
        c.setBodyJSON(a, true);
        c.setResponseType(Account.class);

        c.onAfterCallout()
            .add(c.match.onBadRequest(), c.action.throwResponseEx(AcmeError.class));

        return (Account) c.execute();
    }
}
```

### Example 5: Normalize response JSON before parsing
Useful for keys like `"odata.error"` that don’t map to Apex fields cleanly.

```apex
public with sharing class OdataErrorResponse extends CalloutResponseException {
    public OdataError odata_error;
    public class OdataError {
        public String code;
        public Map<String, String> message;
    }
}

public with sharing class OdataClient {
    public static void run() {
        Callout c = new Callout();
        c.setMethod('GET');
        c.setEndpoint('callout:OData_NC/some/resource');

        c.onAfterCallout()
            .clear()
            .add(c.match.onContains('"odata.error"'), c.action.replaceAll('"odata\\.error"', '"odata_error"'))
            .add(c.match.onDeserializableTo(OdataErrorResponse.class), c.action.throwResponseEx(OdataErrorResponse.class));

        c.execute(); // will throw typed exception when error payload matches
    }
}
```

---
# Operational Guidance
## Operational Guidance

### Handler ordering matters
A common best-practice sequence for `onAfterCallout()`:

1. **Retry rules** (401, timeout, maybe 429 with sleep)
2. **Normalization / response massaging** (replaceAll)
3. **Business exceptions** (throw typed exceptions on known client errors)
4. **Generic exception on any 4xx/5xx**
5. **Logging**
6. **Return JSON** (only on success)

### Avoid infinite retry loops
Retries are explicit (`retry(1)`, `retry(2)`, etc.). Keep them small and targeted.

### Prefer Named Credentials
Endpoints like `callout:YourNamedCredential/...` keep auth and host configuration out of code and simplify deployments.

### Use metadata for correlation
Set:
- `setRelatedId(recordId)` to tie callouts to a record
- `setLogName('MeaningfulName')` to make logs searchable/consistent
- `setMetadata(String key, Object value)` for any other metadata

## Quick “How do I adopt this in my repo/org?”

1. Create one subclass per external system (e.g., `SapCallout`, `StripeCallout`).
2. Standardize before and after-callout policy (retry/transforms/error/return/log).
3. Expose small “client” classes (e.g., `SapOrdersApi`) that return typed DTOs.
4. Add tests per endpoint behavior using `HttpCalloutMock`.

---
# Change Log
## Change Log

### Ver. 1.1.1
* Added sleep(Integer ms) handler
* Added onRateLimit() matcher
* Bumped API Version to 62.0

### Ver. 1.0.1
* Fixed bug where CalloutException was not handled properly and resulted in framework returning null.
