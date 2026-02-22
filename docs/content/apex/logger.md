# Apex Logging Framework
*Easy to use, easy to expand Logging Framework with all inbuilt settings, reports, permission set and batch for clearing old logs.*

[Source](https://github.com/pkozuchowski/Apex-Opensource-Library/tree/master/force-app/commons/logger)
[Dependency](/apex/runtime)
[Install In Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04tJ6000000LuhEIAS)
[Install In Production](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tJ6000000LuhEIAS)

```bash
sf project deploy start \
-d force-app/commons/logger \
-d force-app/commons/shared \
-o sfdxOrg
```

---
# Documentation

## Overview of Logger Framework
This logger is a **lightweight, persistent, cross‑channel logging framework** for Salesforce that works consistently across:
- Apex (synchronous + async, REST, callouts, exception handling)
- Flows (invocable action)
- LWCs (AuraEnabled Apex endpoint)

It is designed for operational visibility (what happened, where, for whom, and how long it took) while keeping logs survivable even in failure scenarios.

## What the framework provides
### Custom Configuration
Logs are stored as records in a custom object (e.g., Log__c), so you can:
- build reports/dashboards
- filter by severity, source, reference id, user
- review request/response payloads (within platform limits)

### A simple developer API
Developers create a log entry using a Log builder object (message, exception, HTTP, REST),
then send it via Logger at given severity - INFO, WARN, ERROR

### Runtime context automatically captured
The framework enriches logs with operational context such as:
- Source (defaults to caller method if not provided)
- User (who initiated the transaction)
- Execution time (optional performance metrics you can attach)
- Request Id (correlation across Salesforce infrastructure)
- Quiddity (execution context type, e.g., synchronous, REST, queueable, etc.)

### Configurable verbosity + retention
- Configuration is done using Custom Metadata:
- Per‑severity “Create?” toggle (turn off INFO in prod, keep ERROR, etc.)
- Retention days per severity, with a scheduled batch that deletes old log records

### Data masking (PII/PCI safety net)
Before logs are persisted, log text is sanitized using configurable regex patterns (Custom Metadata).
This helps prevent sensitive values from being stored in Request__c / Response__c.

## Typical use‑cases
### Operational troubleshooting
- “Why did this integration fail for record X?”
- “What response did the external service return?”
- “Which Apex method triggered the error?”

### Business process observability (Flows + UI)
- Flows that fail intermittently (e.g., validation rules, locking)
- UI users reporting “something went wrong” — capture a reference id to locate the exact log

### Integration monitoring
- Log outbound callout request/response (sanitized)
- Capture HTTP status and payload for fast triage

### Performance diagnostics
- Capture execution time around known hotspots (selectors, callouts, complex orchestration)

### Security & compliance hygiene
- Mask patterns reduce accidental storage of sensitive data
- Centralized retention policy controls how long logs remain

## How Platform Events are used (core design)
### Why Platform Events?
Platform Events act as a durable handoff between the code that detects an issue and the code that persists the log record.

This is especially useful when:
- the transaction may throw an unhandled exception
- you’re in UI/Aura/LWC contexts where exceptions can cause the transaction to roll back
- you want logs to be processed in a controlled, consistent way

### The flow of data
1. Producer (Apex/Flow/LWC) creates a log payload.
2. The framework publishes a Platform Event (e.g., LoggingEvent__e) using EventBus.publish(...).
3. A trigger on the Platform Event runs after insert.
4. The trigger handler maps event fields to a persistent Log__c record and sanitizes request/response fields using the masking rules.
5. Log__c is inserted (“as system”), so logging is resilient to user permissions, while access to view logs is still governed by View Logs permission set.

---
# Examples
## Logging examples

### Logging Exception

```apex
public with sharing class SomeCtrl {

    @AuraEnabled
    public static void doSomething() {
        try {
            SomeService.doBusinessLogic();

        } catch (Exception ex) {
            Logger.error(ex);
            throw new AuraHandledException(ex.getMessage());
        }
    }
}
```

### Logging Exception with inputs

```apex
public with sharing class SomeCtrl {

    @AuraEnabled
    public static void doSomething(Id recordId) {
        try {
            SomeService.doBusinessLogic(recordId);

        } catch (Exception ex) {
            Logger.error(new Log(ex)
                .withInput('recordId', recordId));
            throw new AuraHandledException(ex.getMessage());
        }
    }
}
```

### Logging Callouts

```apex
HttpRequest request; //...
HttpResponse response = new Http().send(request);

Logger.error(new Log(request, response)
    .withSource('Google Drive - File Upload'));
```

### Logging Webservices

```apex
Logger.error(new Log(RestContext.request, RestContext.response));
```

### Logging Additional Information

* `withReferenceId(String referenceId)` - Saves reference identifier, which may be SF record Id, UUID, http request ID etc.
* `withParameter(String method, Object value)` - Saves logged method's parameter - useful for debugging
* `withParameters(Map<String, Object> parameters)` - Same as above
* `withTimeMetric(Long timeMs)` - Saves execution time of Http Request / Apex method etc.
* `withTimeMetric(Datetime startTime)` - Saves execution time since given Datetime.
* For new Log__c fields, you can add additional Log building methods.

```apex
public with sharing class SomeCtrl {
    private static Datetime startTime = Datetime.now();

    @AuraEnabled
    public static void updateAccount(Id accountId) {
        try {
            SomeService.doBusinessLogic(accountId);

        } catch (Exception ex) {
            Logger.error(new Log(ex)
                .withInput('accountId', accountId)
                .withReferenceId(accountId)
                .withTimeMetric(startTime));
            throw new AuraHandledException(ex.getMessage());
        }
    }
}
```

### Flow example (Invocable Action)
The framework exposes an **Invocable Method** you can use as a Flow Action to create logs without writing Apex.

#### How to use in Flow
1. In Flow Builder, add an Action.
2. Select the Apex action named something like “Log”.
3. Provide:
    - Flow Name: e.g., Order Orchestration Flow
    - Message: e.g., Unable to reserve inventory
    - Severity: INFO, WARN, or ERROR
    - Reference Id: typically the record Id the flow is processing
    - Optional input name/value pairs (up to the action’s supported count)

#### Example configuration (recommended)
- Severity: ERROR for fault paths
- Reference Id: {!$Record.Id} (or the primary record variable)
- Inputs:
    - stage = reserve_inventory
    - reason = {!FaultMessage} (or a sanitized summary)
    - flowInterviewGuid = {!$Flow.InterviewGuid} (useful for correlation)
- This produces a persistent Log__c record with Source = Flow Name, plus your message and inputs.

### LWC example
For UI logging, the framework provides an AuraEnabled Apex method you can call from LWC. That Apex method publishes the event the same way Apex code does.

```js
import log from '@salesforce/apex/LogActions.log';

export async function logClientError({componentName, message, referenceId}) {
    try {
        await log({
            severity: 'ERROR',
            source  : componentName ?? 'LWC',
            message,
            referenceId,
            inputs  : {
                uiRoute      : 'orderCheckout',
                clientContext: 'buttonClick'
            }
        });
    } catch (e) {
        // Avoid infinite loops: don't attempt to log the logging failure
        // Optionally: console.error(e);
    }
}
```

#### When to use LWC logging
- Capture UI-only failures (unexpected states, caught exceptions)
- Record user actions that lead to server errors (with a referenceId)
- Provide support teams with correlation: “Give me the Log Reference Id from the error toast”

---
# Guidance
## Operational guidance
### Severity recommendations
- **INFO**: milestones and diagnostics (enable selectively in prod)
- **WARN**: recoverable issues, retries, degraded behavior
- **ERROR**: failed transactions, exceptions, non-recoverable integration issues

## Source + ReferenceId conventions
- Source: <Class>.<method> (Apex) (auto populated), Flow API name, or LWC component name, API endpoint name
- ReferenceId: the primary business record Id (Order, Case, Opportunity, etc.)

## Access & permissions
- Use **Create Logs** permission set for who can create logs from UI (LWC).
- Use **View Logs** permission set for who can view logs (admins/support).

## Retention
- Keep ERROR longer than INFO.
- Use the scheduled cleanup job (LogCleanerBatch) so the log object doesn’t grow forever.

## Data protection
- Treat `Request__c` / `Response__c` as sensitive.
- Keep masking patterns updated (PII, payment tokens, authorization headers, etc.).
- Prefer logging summaries over full payloads when possible.

---
# API

## Logger

```apex
public class Logger {
    public static void info(Log log) {}
    public static void warn(Log log) {}
    public static void error(Log log) {}
    public static void error(Exception ex) {}
    public static void log(LoggingLevel loggingLevel, Log log) {}
}
```

## Log
```apex
public class Log {
    public Log(String message) {}
    public Log(Exception ex) {}
    public Log(HttpRequest request, HttpResponse response) {}
    public Log(RestRequest request, RestResponse response) {}
    public Log(LoggingEvent__e log) {}

    public Log withReferenceId(String referenceId) {}
    public Log withParameter(String param, Object value) {}
    public Log withParameters(Map<String, Object> parameters) {}
    public Log withTimeMetric(Long timeMs) {}
    public Log withTimeMetric(Datetime startTime) {}
}
```