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

        protected override void serializeToXML() {
            createThisNode('Envelope', NAMESPACE_SOAP, 'soap');
            setNamespace('xsi', NAMESPACE_XSI);
            setNamespace('xsd', NAMESPACE_XSD);
            setNamespace('soap', NAMESPACE_SOAP);

            addChildElement(header);
            addChildElement(body);
        }

        protected override void deserializeXML() {
            deserializeChild(body);
        }
    }

    private class Header extends XmlNode {
        public String username;
        public String password;

        protected override void serializeToXML() {
            createThisNode('Header', NAMESPACE_SOAP, 'soap');
            addChildTextElement('username', username);
            addChildTextElement('password', password);
        }

        protected override void deserializeXML() {
        }

        protected override Dom.XmlNode locateInParent(Dom.XmlNode parentNode) {
            return parentNode.getChildElement('Header', NAMESPACE_SOAP);
        }
    }

    private class Body extends XmlNode {
        public BodyContent content;

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
        SampleRequest request = new SampleRequest();

        Envelope envelope = new Envelope();
        envelope.body.content = request;

        envelope.header.username = 'api.user';
        envelope.header.password = 'secret';

        request.exclusionType = ExclusionMode.DuplicateEmail;
        request.criteria.firstName = 'John';
        request.criteria.lastName = 'Doe';
        request.criteria.username = request.criteria.email = 'John.Doe@sample.com';
        request.criteria.dob = Datetime.newInstance(1980, 01, 01);

        Address mailingAddress = new Address();
        mailingAddress.country = 'UK';
        mailingAddress.addressLine1 = 'London';
        mailingAddress.addressLine2 = 'Test Street 2';
        request.criteria.addresses.add(mailingAddress);

        Address billingStreet = new Address();
        billingStreet.country = 'UK';
        billingStreet.addressLine1 = 'Bridgetown';
        billingStreet.addressLine2 = 'Other Street 2';
        request.criteria.addresses.add(billingStreet);

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
        public Matches matches = new Matches();

        protected override Dom.XmlNode locateInParent(Dom.XmlNode parentNode) {
            return parentNode.getChildElement('SampleResponse', NAMESPACE_SAMPLE);
        }
        protected override void deserializeXML() {
            deserializeChild(matches);
        }
    }

    private class Matches extends XmlNodeTest.ResponseSchema {
        public List<Match> matches = new List<Match>();

        protected override Dom.XmlNode locateInParent(Dom.XmlNode parentNode) {
            return parentNode.getChildElement('matches', NAMESPACE_SAMPLE);
        }
        protected override void deserializeXML() {
            /*
            * Iterates through children and looks for element with name 'match' (2nd argument),
            * new XmlNode node is constructed from given prototype (3rd argument)
            * and added to the list (1st argument)
            * */
            deserializeChildren(matches, 'match', Match.class);
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
        Dom.Document document = new Dom.Document();
        document.load(responseXML);

        SampleResponse response = new SampleResponse();

        Envelope envelope = new Envelope();
        envelope.body.content = response;

        envelope.deserializeXML(document);

        List<Match> matches = response.matches.matches;
        System.assertEquals(2, matches.size());

        System.assertEquals('John', matches.get(0).firstName);
        System.assertEquals('Doe', matches.get(0).lastName);
        System.assertEquals(1.0, matches.get(0).score);
        System.assertEquals(182, matches.get(0).height);
        System.assertEquals(69.5, matches.get(0).weight);
        System.assertEquals(4000000, matches.get(0).distance);
        System.assertEquals(true, matches.get(0).isMarried);

        System.assertEquals('Johan', matches.get(1).firstName);
        System.assertEquals('Liebert', matches.get(1).lastName);
        System.assertEquals(0.5, matches.get(1).score);
        System.assertEquals(190, matches.get(1).height);
        System.assertEquals(80.1, matches.get(1).weight);
        System.assertEquals(5000000, matches.get(1).distance);
        System.assertEquals(false, matches.get(1).isMarried);
    }
}