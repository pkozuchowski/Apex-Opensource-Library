# HTTP Callout Router

Utility class for routing callouts to specific response.
Router will try to match HTTP Request to registered mocks by endpoint regexp and HTTP method and will return provided response.  
Each registered mock has a developer name which can be used for overrides - we can have one default success mock, but in one particular test we can override it
and return error http response.

Example Use Case:  
Team is developing integration with Amazing Web Services (AWS for short), which involves several types of requests.  
In this situation, you can create one AWSMockRouter class which will mock responses for all AWS callouts and reuse it in all tests. Router will match registerd
responses
to the requests.

In the future, another integrations with Microdwarf and Noodle services appear in the landscape. You can create one org-wide router to serve them all, because
router has composite structure:

* OrgMocks
    * AWSMocks
    * MicrodwarfMocks
    * Salesforce Mocks
    * NoodleMocks

Each router would look at the HttpRequest's endpoint and decide whether it can handle it or not. The code would look like this:

Top level mocks register mock aggregators for each service, this class wouldn't be changed much even if it's shared between teams:

```apex
public class OrgMocks extends HttpCalloutMockRouter {

    public OrgMocks() {
        this.mock('AWS Mocks', new AWSMocks());
        this.mock('Microdwarf Mocks', new MicrodwarfMocks());
        this.mock('Salesforce Mocks', new SalesforceMocks());
        this.mock('Noodle Mocks', new NoodleMocks());
    }
}

public with sharing class AWSMocks extends HttpCalloutMockRouter {

    public AWSMocks() {
        this.variable('endpoint', 'https://aws.com/amazing/services/v/\\d');

        this.mock('Auth', 'POST', '{{endpoint}}/auth', 200, 'OK', '{"sessionToken":"000001"}');
        this.mock('Save Quote', 'POST', '{{endpoint}}/quotes', 200, 'OK', new SaveQuoteResult());
        //... Other AWS Mocks
    }
}

public class MicrodwarfMocks extends HttpCalloutMockRouter {

    public MicrodwarfMocks() {
        this.variables(new Map<String, String>{
            'endpoint' => 'https://microdwarf.com/api', // Pattern for Microdwarf Endpoint shared by all requests
            'mdId' => '[\\d]{10}', // ID pattern of Microdwarf database entities,
            'container' => '[a-zA-Z\\s]+', //Matches blob container name
            'blob' => '[a-zA-Z\\s]+' //Matches blob name
        });

        this.mock('Auth', 'POST', '{{endpoint}}/auth', 200, 'OK', '{"sessionToken":"000001"}');
        this.mock('Get Blob', 'GET', '{{endpoint}}/blobs/{container}/{blob}', 200, 'OK', new GetBlobResult());
        this.mock('Put Blob', 'PUT', '{{endpoint}}/blobs/{container}/{blob}', 200, 'OK', new CreateBlobResult());
        this.mock('Delete Blob', 'Delete', '{{endpoint}}/blobs/{container}/{blob}', 200, 'OK', new DeleteBlobResult());
        //... Other MD Mocks
    }
}

public class SalesforceRestAPIMocks extends HttpCalloutMockRouter {

    public SalesforceRestAPIMocks() {
        this.variables(new Map<String, String>{
            'endpoint' => Url.getOrgDomainUrl().toExternalForm() + '/services/data/v\\d.0',
            'id' => '([0-9a-zA-Z]{15,18})'
        });

        this.registerStaticResourceMock('Query', 'GET', '{{endpoint}}/query/?q=.*', 200, 'OK', 'StaticResourceWithResponse');
        this.mock('Create Account', 'POST', '{{endpoint}}/sobjects/Account/', 201, 'Created', new CreateRecordResult(true));
        this.mock('Get Account', 'GET', '{{endpoint}}/sobjects/Account/{{id}}', 200, 'OK', new Account(Id = ACCOUNT_ID, Name = ACCOUNT_NAME));
        this.mock('Delete Account', 'DELETE', '{{endpoint}}/sobjects/Account/{{id}}', 204, 'No Content', '');
    }
}
//...

// IN Test:
Test.startTest();
Test.setMock(HttpCalloutMock.class, new OrgMocks());
//...tests
Test.stopTest();
```

How does it work in above example?  
Let's assume we are making `PUT` callout to endpoint `https://microdwarf.com/api/blobs/my_folder/myFile` to create file in external file storage. Unit tests
uses OrgMocks as mock.

1) OrgMocks extend HttpCalloutMockRouter class, which implements standard mocking HttpCalloutMock class, so the request first goes to router's internal respond
   method.
2) OrgMocks internal respond method checks all registered mocks and asks each one if it can handle the request.
3) AWSMocks is the first registered and first asked - it's also a router, so it does the same thing - it asks all registered mocks if any can handle request
   with this method and endpoint. In this case, it cannot -> all AWS mocks respond with "false" and AWSMocks also respond with false.
4) OrgMocks ask next registerd mock, which is MicrodwarfMocks. Again, it's a nested router class so it goes over all it's mocks and asks each one if it can
   handle the request. In this case we have match, 'Put Blob' mock will respond with true.
5) AwsMocks calls mock's respond method and return HttpResponse all way up through the chain.

The response is handled.

<br/>

**Negative Scenario**  
If none of the registered mocks would be able to handle the request, exception is thrown. Something is clearly missing in the configuration.

<br/>

### Endpoint Variables

Endpoint is matched by regexp and if we are handling many different requests against webservice, we will notice some repeating patterns.  
In that case, we can register endpoint variable, which will be replaced in the string before regexp is compiled and matched.  
See example snippets.

<br/>

### Overrides

Each mock is registered under unique name. We can utilize this name to replace mock with different one in our tests.  
Consider this example:

```apex
Test.startTest();
Test.setMock(HttpCalloutMock.class, new SalesforceMocks()
    .overrideMock('Create Account', new SalesforceMocks.AccountCreateError()));
Test.stopTest();
```

'Create Account' mock was replaced and now it will respond with error response.

If our mock router composition is more complex, like with OrgMocks example, the override would look like this:

```apex
Test.startTest();
Test.setMock(HttpCalloutMock.class, new OrgMocks()
    .overrideMock('Salesforce Mocks', new SalesforceMocks()
        .overrideMock('Create Account', new SalesforceMocks.AccountCreateError())
    ));
Test.stopTest();
```

Over course, some shorthand methods can be introduced when needed.

<br/>

### Trivia

* Method parameter accepts '*' wild-card, which matches all methods.
* Method parameter accepts comma separated values: 'POST,PUT'
* registerMocks() method comes in many overloaded varieties:
    * `registerStaticResourceMock(String name, String methods, String endpointPattern, Integer statusCode, String status, String resource)` - Responds static
      resource body
    * `registerJsonMock(String name, String methods, String endpointPattern, Integer statusCode, String status, Object objectToSerialize)` - Serializes object
      to JSON
    * `registerMock(String name, String methods, String endpointPattern, Integer statusCode, String status, String body)` - Responds with plain text body
    * `registerMock(String name, String methods, String endpointPattern, HttpCalloutMock mock)` - Responds with class implementing HttpCalloutMock class.
    * `registerMock(String name, HttpCalloutChainMock handler)` - Responds with router class.