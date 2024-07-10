# HTTP Callout Mock Router
*Configuration-driven, endpoint pattern-based router for Http Mocks.*

[Source](https://github.com/pkozuchowski/Apex-Opensource-Library/tree/master/force-app/commons/httpMocks)
[Install In Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04t08000000UK7EAAW)
[Install In Production](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t08000000UK7EAAW)

```bash
sf project deploy start -d force-app/commons/httpMocks -o sfdxOrg
```

---
# Documentation
HTTP Callout Router is a configuration-driven framework for mocking Http Callouts that matches mocks by endpoint pattern and HTTP method.  
Let's consider the following configuration for Salesforce REST API:

#### Variables

| DeveloperName | Pattern              |
|---------------|----------------------|
| sfId          | ([0-9a-zA-Z]{15,18}) |
| sObjectType   | \w+                  |

#### Mocks
| Developer Name                    | Default | Methods    | Endpoint                                             | Status Code | Status       | Response                                                               | Static Resource  | Apex Class                          |
|-----------------------------------|---------|------------|------------------------------------------------------|-------------|--------------|------------------------------------------------------------------------|------------------|-------------------------------------|
| SampleAPI_Get_Beers_Ale_OK        | ☑       | GET        | callout:SampleAPI/beers/ale                          | 200         | OK           | [{"price":"$16.99","name":"Founders All Day IPA","rating":4,"id":1}]   |                  |                                     |
| SampleAPI_Update_Beers_Ale_OK     | ☑       | POST,Patch | callout:SampleAPI/beers/ale                          | 200         | OK           |                                                                        |                  |                                     |
| SampleAPI_Common_401_Unauthorized | ☐       | GET        | callout:SampleAPI/.*                                 | 401         | Unauthorized | [{"message":"Invalid access token. Please pass a valid access token"}] |                  |                                     |
| SF_REST_Query                     | ☑       | GET        | callout:SfRestAPI/query/.*                           | 200         | OK           | {"records":[{"Name":"Test Account"}]}                                  |                  |                                     |
| SF_REST_Query_Empty               | ☐       | GET        | callout:SfRestAPI/query/.*                           | 200         | OK           | {"records":[]}                                                         |                  |                                     |
| SF_REST_SObject_Describe          | ☑       | GET        | callout:SfRestAPI/sobjects/{{sObjectType}}/describe/ | 200         | OK           |                                                                        |                  | SalesforceMocks.SObjectDescribeMock |
| SF_REST_SObject_Row_Get_Account   | ☑       | GET        | callout:SfRestAPI/sobjects/Account/{{sfId}}          | 200         | OK           |                                                                        | Mocks_SF_Account |                                     |

Router loads default (*Default__c=true*) configuration and substitutes all endpoint variables (*{{variable}}*) with their values defined in
HttpCalloutMockVariable__mdt custom metadata.  
Then for each callout request, router will check configured mocks until it matches first that can handle the request based on HTTP Method and Endpoint pattern.

```apex
@IsTest
private class MyTest {

    @IsTest
    static void myCalloutTest() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, HttpMocks.config());
        // Do callout
        Test.stopTest();
    }
}
```

## How does it work?

Let's assume we are making `GET` callout to endpoint `https://acme.api.com/commerce/customers/135479512398189` to get external customer data by Id and our unit
tests uses OrgMocks class.

1. HttpCalloutMockRouter fetches configuration records from custom metadata and registers variables and mocks
1. Merge fields in endpoints are replaced with their pattern values
1. Router respond method checks mocks from custom metadata and any other mocks defined in code.
1. Each mock is checked for handled HTTP Methods, and if the endpoint matches with the request.
1. The first mock that matches response will have its response returned according to the settings.
    - If StaticResource__c field is provided, mock will respond with it's content
    - If ApexClass__c is provided, mock creates instance of this class and returns it. The class should implement HttpCalloutMock interface.
    - If Response__c field is provided, it's returned as callout response body.
    - If Headers__c field is provided - it's split by new lines and colons and added to response body headers.
1. The response is handled.

### Negative Scenario
If none of the registered mocks matches the request, Unhandled Callout exception is thrown.  
Something is clearly missing in the configuration.

## Endpoint Variables

Endpoint is matched by regexp, and if we are handling many different requests against webservice, we will notice some repeating patterns.  
In that case, we can register endpoint variable, which will be replaced in the endpoint pattern string before regexp is compiled and matched.

**Is it required to use variables?**  
No, but it makes writing endpoint much more convenient. Alternatively each configuration would have a full endpoint
ex: `https://test.salesforce.com/services/data/v50.0/query/.* `.  
Variables make it easier to handle endpoints that are different on each sandbox.

## Overrides
Each mock is registered under a unique developer name. We can utilize this name to replace mock with a different one in our tests.

Consider this example:

```apex
Test.setMock(HttpCalloutMock.class, new OrgMocks()
    .overrideMock('SF_REST_Query', HttpMocks.config('SF_REST_Query_Empty')));
```
`SF_REST_Query` mock was replaced, and now it will respond with mock registered under name `SF_REST_Query_Empty`.


---
# Custom Metadata

## HttpCalloutMock__mdt
- **DeveloperName** - This is a unique mock name that can be referenced in tests and used to override default mocks.
- **Default__c** - Default mocks are loaded in the router, while all non-defaults can be used to override default mock in unit tests.
- **Methods** - Which Http Methods should be considered. Accepted values are single methods ("GET"), comma separated methods ("POST,PATCH") or asterisk for
  matching
  all methods (*).
- **Endpoint__c** - Regexp pattern for endpoint. It can contain variables denoted by double curly braces.
- **Status__c** - Http Status of response
- **StatusCode__c** - Http Status Code of response
- **Response__c** - Body of the Http Response
- **StaticResource__c** - Alternative ot Response__c. If this is provided with Static Resource name, it's body will be used as response.
- **ApexClass__c** - Name of Apex Class implementing HttpCalloutMock interface that produces response. Alternative to Response__c & StaticResource__c. Class
  must be public and have public no-args constructor.
- **Headers__c** - Http Headers of the response. Each header should be on separate line and in key:value format.

---
# Programmatic Mocks

Alternatively or additively to configuration-based mocks, developer can choose to implement mocks directly in their code,
as seen on example bellow.

```apex
public class AzureBlobStorageMocks extends HttpCalloutMockRouter {

    public AzureBlobStorageMocks() {
        variables(new Map<String, String>{
            'endpoint' => 'https://azure.com/api', // Pattern for Microhard Endpoint shared by all requests
            'mdId' => '[\\d]{10}', // ID pattern of Microhard database entities,
            'container' => '[a-zA-Z\\s]+', //Matches blob container name
            'blob' => '[a-zA-Z\\s]+' //Matches blob name
        });

        mock('Auth', 'POST', '{{endpoint}}/auth', HttpMocks.text(200, 'OK', '{"sessionToken":"000001"}'));
        mock('Get Blob', 'GET', '{{endpoint}}/blobs/{container}/{blob}', HttpMocks.staticResource(200, 'OK', 'AzureMocks_GetBlob_200'));
        mock('Put Blob', 'PUT', '{{endpoint}}/blobs/{container}/{blob}', HttpMocks.json(200, 'OK', new CreateBlobResult()));
        mock('Delete Blob', 'Delete', '{{endpoint}}/blobs/{container}/{blob}', HttpMocks.json(200, 'OK', new DeleteBlobResult()));
        //... so on
    }
}
```

## HttpCalloutChainMock Interface
```apex
interface HttpCalloutChainMock extends HttpCalloutMock {
    Boolean handles(HttpRequest request);
}
```

Router uses this interface to implement nestable structures of mocks using a chain of responsibility design pattern.  
Additional `handles()` method is used by mock to decide whether it can handle the request or not - the first mock that returns true
will be the one to return response.

## Nesting Routers
It's possible to create a separate programmatic router for each webservice and bundle them together in Org-wide router as seen bellow.  
This approach only makes sense if you are not using custom metadata.

```apex
public class OrgMocks extends HttpCalloutMockRouter {

    public OrgMocks() {
        mock('AWS Mocks', new AWSMocks());
        mock('Salesforce Mocks', new SalesforceMocks());
        mock('Microdwarf Mocks', new MicrodwarfMocks());
        mock('Noodle Mocks', new NoodleMocks());
    }
}

public with sharing class AWSMocks extends HttpCalloutMockRouter {

    public AWSMocks() {
        variable('endpoint', 'https://aws.com/amazing/services/v/\\d');

        mock('Auth', 'POST', '{{endpoint}}/auth', HttpMocks.text(200, 'OK', '{"sessionToken":"000001"}'));
        mock('Save Quote', 'POST', '{{endpoint}}/quotes', HttpMocks.json(200, 'OK', new SaveQuoteResult()));
        //...
    }
}

public class SalesforceRestAPIMocks extends HttpCalloutMockRouter {

    public SalesforceRestAPIMocks() {
        variables(new Map<String, String>{
            'endpoint' => Url.getOrgDomainUrl().toExternalForm() + '/services/data/v\\d.0',
            'id' => '([0-9a-zA-Z]{15,18})'
        });

        mock('Query', 'GET', '{{endpoint}}/query/?q=.*', HttpMocks.text(200, 'OK', 'StaticResourceWithResponse'));
        mock('Create Account', 'POST', '{{endpoint}}/sobjects/Account/', HttpMocks.json(201, 'Created', new CreateRecordResult(true)));
        //...
    }
}
```

---
# Trivia

* Method__c field accepts '*' wild-card, which matches all methods.
* Method__c field accepts comma separated values: 'POST,PUT'
* Variables should be defined as the first thing
* `HttpMocks` class contains methods for creating mocks from different sources
    * `HttpMocks.staticResource(Integer statusCode, String status, String resource)` - Responds with static resource body
    * `HttpMocks.json(Integer statusCode, String status, Object o)` - Responds with a serialized object
    * `HttpMocks.text(Integer statusCode, String status, String response)` - Responds with plain text response body
    * `HttpMocks.config(String developerName)` - Responds with mock from Custom Metadata
* Mocks can be easily extended with custom properties if needed:
```apex
public class MyCustomMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest request) {
        HttpResponse response = HttpMocks.config('MyMetadata').respond(request);

        //modify response
        response.setStatus(400);

        return response;
    }
}
```

---
# Change Log
### 1.0.2
- Fixed bug in HTTP Headers specified in metadata, where header value would not be parsed correctly if it contained colon, which would cause issues for Location headers.
- Added help text to custom metadata fields.