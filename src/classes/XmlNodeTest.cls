@IsTest
public class XmlNodeTest {
    private final static String
            NAMESPACE_XSI = 'http://www.w3.org/2001/XMLSchema-instance',
            NAMESPACE_XSD = 'http://www.w3.org/2001/XMLSchema',
            NAMESPACE_SOAP = 'http://schemas.xmlsoap.org/soap/envelope/',
            NAMESPACE_SAMPLE = 'http://sample.test/webservices/';


    private class Envelope extends XmlNode.XmlRootNode {
        public Body body = new Body();
        public Header header = new Header();

        public Envelope() {
        }
        public Envelope(Header header, BodyContent content) {
            this.header = header;
            this.body = new Body(content);
        }

        protected override void serializeToXML() {
            createThisNode('Envelope', NAMESPACE_SOAP, 'soap');
            setNamespace('xsi', NAMESPACE_XSI);
            setNamespace('xsd', NAMESPACE_XSD);
            setNamespace('soap', NAMESPACE_SOAP);

            addChildElement(header);
            addChildElement(body);
        }

        protected override void deserializeXML() {
            deserializeChild(header);
            deserializeChild(body);
        }
    }

    private class Header extends XmlNode {
        public String username;
        public String password;

        public Header() {
        }
        public Header(String username, String password) {
            this.username = username;
            this.password = password;
        }

        protected override void serializeToXML() {
            createThisNode('Header', NAMESPACE_SOAP, 'soap');
            addChildTextElement('username', username);
            addChildTextElement('password', password);
        }

        protected override void deserializeXML() {
            this.username = getStringValue('username', null);
            this.password = getStringValue('password', null);
        }

        protected override Dom.XmlNode locateInParent(Dom.XmlNode parentNode) {
            return parentNode.getChildElement('Header', NAMESPACE_SOAP);
        }
    }

    private class Body extends XmlNode {
        public BodyContent content;

        public Body() {
        }
        public Body(BodyContent content) {
            this.content = content;
        }

        protected override void serializeToXML() {
            createThisNode('Body', NAMESPACE_SOAP, 'soap');
            addChildElement(content);
        }

        protected override void deserializeXML() {
            deserializeChild(content);
        }

        protected override Dom.XmlNode locateInParent(Dom.XmlNode parentNode) {
            return parentNode.getChildElement('Body', NAMESPACE_SOAP);
        }
    }


    /**
    * Abstract type which will be super type for all request and response elements that
    * reside in Body element
    * */
    private abstract class BodyContent extends XmlNode {
    }

    private abstract class RequestSchema extends BodyContent {
        /*
        * Deserialization methods are obsolete in request.
        * */
        protected override Dom.XmlNode locateInParent(Dom.XmlNode parentNode) {
            return null;
        }
        protected override void deserializeXML() {
        }
    }
    private abstract class ResponseSchema extends BodyContent {
        /**
        * Serialization methods are obsolete in response.
        * */
        protected override void serializeToXML() {
        }
    }


    /**
    * Sample SOAP Request which will contain 1 Criteria element and
    * a text element with predefined values (values are made up)
    * */
    private class SampleRequest extends RequestSchema {
        public ExclusionMode exclusionType = ExclusionMode.DuplicateEmail;
        public Criteria criteria = new Criteria();

        public SampleRequest() {
        }
        public SampleRequest(ExclusionMode exclusionType, Criteria criteria) {
            this.exclusionType = exclusionType;
            this.criteria = criteria;
        }

        protected override void serializeToXML() {
            createThisNode('SampleRequest', NAMESPACE_SAMPLE, '');
            addChildTextElement('exclusion', exclusionType.name());
            addChildElement(criteria);
        }
    }
    public enum ExclusionMode {
        None,
        DuplicateEmail,
        DuplicateName,
        All
    }
    private class Criteria extends XmlNodeTest.RequestSchema {
        public String firstName;
        public String lastName;
        public String email;
        public String username;
        public Datetime dob;
        public List<Address> addresses = new List<Address>();

        public Criteria() {
        }
        public Criteria(String firstName, String lastName, String email, Datetime dob, List<Address> addresses) {
            this.firstName = firstName;
            this.lastName = lastName;
            this.email = email;
            this.username = email;
            this.dob = dob;
            this.addresses = addresses;
        }

        protected override void serializeToXML() {
            createThisNode('criteria');
            addChildTextElement('FirstName', firstName);
            addChildTextElement('LastName', lastName);
            addChildTextElement('Email', email);
            addChildTextElement('Username', username);
            addChildTextElement('DateOfBirth', dob.format('dd/MM/YYYY'));
            addChildrenElements(addresses);
        }
    }
    private class Address extends XmlNodeTest.RequestSchema {
        public String country;
        public String addressLine1;
        public String addressLine2;
        public String addressLine3;
        public String addressLine4;

        public Address(String country, String addressLine1, String addressLine2) {
            this.country = country;
            this.addressLine1 = addressLine1;
            this.addressLine2 = addressLine2;
        }

        protected override void serializeToXML() {
            createThisNode('Address');
            addChildTextElement('Country', country);
            addChildTextElement('AddressLine1', addressLine1);
            addChildTextElement('AddressLine2', addressLine2);
            addChildTextElement('AddressLine3', addressLine3);
            addChildTextElement('AddressLine4', addressLine4);
        }
    }


    @IsTest
    static void testRequestSerialization() {
        Envelope envelope = new Envelope(
                new Header('api.user', 'secret'),
                new SampleRequest(ExclusionMode.DuplicateEmail,
                        new Criteria(
                                'John', 'Doe', 'John.Doe@sample.com', Datetime.newInstance(1980, 01, 01),
                                new List<Address>{
                                        new Address('UK', 'London', 'Test Street 2'),
                                        new Address('UK', 'Bridgetown', 'Other Street 2')
                                }
                        )
                )
        );


        Dom.Document document = envelope.toDOMDocument();
        System.debug(document.toXmlString());

        String expectedXML = ('<?xml version="1.0" encoding="UTF-8"?>'
                + '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"'
                + ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">'
                + '    <soap:Header>'
                + '        <username>api.user</username>'
                + '        <password>secret</password>'
                + '    </soap:Header>'
                + '    <soap:Body>'
                + '        <SampleRequest xmlns="http://sample.test/webservices/">'
                + '            <exclusion>DuplicateEmail</exclusion>'
                + '            <criteria>'
                + '                <FirstName>John</FirstName>'
                + '                <LastName>Doe</LastName>'
                + '                <Email>John.Doe@sample.com</Email>'
                + '                <Username>John.Doe@sample.com</Username>'
                + '                <DateOfBirth>01/01/1980</DateOfBirth>'
                + '                <Address>'
                + '                    <Country>UK</Country>'
                + '                    <AddressLine1>London</AddressLine1>'
                + '                    <AddressLine2>Test Street 2</AddressLine2>'
                + '                </Address>'
                + '                <Address>'
                + '                    <Country>UK</Country>'
                + '                    <AddressLine1>Bridgetown</AddressLine1>'
                + '                    <AddressLine2>Other Street 2</AddressLine2>'
                + '                </Address>'
                + '            </criteria>'
                + '        </SampleRequest>'
                + '    </soap:Body>'
                + '</soap:Envelope>').replaceAll('\\>\\s+<', '><');
        System.assertEquals(expectedXML, document.toXmlString());
    }


    /**
    * Sample SOAP response
    * */
    private class SampleResponse extends XmlNodeTest.ResponseSchema {
        public List<Match> matches = new List<Match>();

        protected override Dom.XmlNode locateInParent(Dom.XmlNode parentNode) {
            return parentNode.getChildElement('SampleResponse', NAMESPACE_SAMPLE);
        }
        protected override void deserializeXML() {
            deserializeList('matches', NAMESPACE_SAMPLE, matches, 'match', Match.class);
        }
    }

    private class Match extends XmlNodeTest.ResponseSchema {
        public String firstName;
        public String lastName;
        public Decimal score;
        public Double weight;
        public Integer height;
        public Long distance;
        public Boolean isMarried;

        protected override Dom.XmlNode locateInParent(Dom.XmlNode parentNode) {
            /*In this case, it's not needed since parent does the search*/
            return null;
        }
        protected override void deserializeXML() {
            this.firstName = getStringValue('FirstName', NAMESPACE_SAMPLE);
            this.lastName = getStringValue('LastName', NAMESPACE_SAMPLE);
            this.score = getDecimalValue('Score', NAMESPACE_SAMPLE);
            this.height = getIntegerValue('Height', NAMESPACE_SAMPLE);
            this.weight = getDoubleValue('Weight', NAMESPACE_SAMPLE);
            this.distance = getLongValue('Distance', NAMESPACE_SAMPLE);
            this.isMarried = getBooleanValue('Married', NAMESPACE_SAMPLE);
        }
    }

    @IsTest
    static void testResponseDeserialization() {
        String responseXML =
                '<?xml version="1.0" encoding="UTF-8"?>'
                        + '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"'
                        + '               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">'
                        + '    <soap:Header>'
                        + '        <username>api.user</username>'
                        + '        <password>secret</password>'
                        + '    </soap:Header>'
                        + '    <soap:Body>'
                        + '        <SampleResponse xmlns="http://sample.test/webservices/">'
                        + '            <matches>'
                        + '                <match>'
                        + '                    <FirstName>John</FirstName>'
                        + '                    <LastName>Doe</LastName>'
                        + '                    <Score>1</Score>'
                        + '                    <Height>182</Height>'
                        + '                    <Weight>69.5</Weight>'
                        + '                    <Distance>4000000</Distance>'
                        + '                    <Married>true</Married>'
                        + '                </match>'
                        + '                <match>'
                        + '                    <FirstName>Johan</FirstName>'
                        + '                    <LastName>Liebert</LastName>'
                        + '                    <Score>0.5</Score>'
                        + '                    <Height>190</Height>'
                        + '                    <Weight>80.1</Weight>'
                        + '                    <Distance>5000000</Distance>'
                        + '                    <Married>false</Married>'
                        + '                </match>'
                        + '            </matches>'
                        + '        </SampleResponse>'
                        + '    </soap:Body>'
                        + '</soap:Envelope>';

        Envelope envelope = new Envelope(
                new Header(),
                new SampleResponse()
        );
        envelope.load(responseXML);

        Map<String, Object> expected = new Map<String, Object>{
                'body' => new Map<String, Object>{
                        'content' => new Map<String, Object>{
                                'matches' => new List<Object>{
                                        new Map<String, Object>{
                                                'weight' => 69.5,
                                                'score' => 1,
                                                'lastName' => 'Doe',
                                                'isMarried' => true,
                                                'height' => 182,
                                                'firstName' => 'John',
                                                'distance' => 4000000
                                        },
                                        new Map<String, Object>{
                                                'weight' => 80.1,
                                                'score' => 0.5,
                                                'lastName' => 'Liebert',
                                                'isMarried' => false,
                                                'height' => 190,
                                                'firstName' => 'Johan',
                                                'distance' => 5000000
                                        }
                                }
                        }
                },

                'header' => new Map<String, Object>{
                        'password' => 'secret',
                        'username' => 'api.user'
                }
        };
        Map<String, Object> actual = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(envelope));
        System.assertEquals(expected, actual);
    }
}