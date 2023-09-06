# Apex Logging Framework
*Easy to use, easy to expand Logging Framework with all inbuilt settings, reports, permission set and batch for clearing old logs.*

[Source](https://github.com/pkozuchowski/Apex-Opensource-Library/tree/master/force-app/commons/logger)

```bash
sf project deploy start -d force-app/commons/logger -d force-app/commons/shared -o sfdxOrg
```

---
# Documentation

Call `Logger.info()`, `Logger.warn()`, or `Logger.error()` static method depending
on severity of the event.

This method takes instance of Log, which is used to build a variety of logs, tailored to specific needs.  
Log can be constructed from plain string message, exception, HTTP callout or Rest Webservice inbound call
and further expanded with methods to save additional data - referenceId, parameter or execution time metric.

Logs are created through Platform Event, which allows easy logging in-between HTTP callouts
or when a transaction fails.

### Examples:

###### Logging Exception:

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

###### Logging Callouts:

```apex
HttpRequest request; //...
HttpResponse response = new Http().send(request);

Logger.error(new Log(request, response));
```

###### Logging Webservices:

```apex
Logger.error(new Log(RestContext.request, RestContext.response));
```

###### Logging Additional Information

* `withReferenceId(String referenceId)` - Saves reference identifier, which may be SF record Id, UUID, http request ID etc.
* `withParameter(String method, Object value)` - Saves logged method's parameter - useful for debugging
* `withParameters(Map<String, Object> parameters)` - Same as above
* `withTimeMetric(Long timeMs)` - Saves execution time of Http Request / Aura method etc.
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
                .withReferenceId(accountId)
                .withTimeMetric(startTime));
            throw new AuraHandledException(ex.getMessage());
        }
    }
}
```


---
# API

```apex
public class Logger {
    public static void info(Log log) {}
    public static void warn(Log log) {}
    public static void error(Log log) {}
    public static void log(LoggingLevel loggingLevel, Log log) {}
}

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