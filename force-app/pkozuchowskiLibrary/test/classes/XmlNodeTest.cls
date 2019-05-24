/**
* MIT License
*
* Copyright (c) 2018 Piotr Kożuchowski
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
@IsTest
private class XmlNodeTest {
    private final static String
            NAMESPACE_XSI = 'http://www.w3.org/2001/XMLSchema-instance',
            NAMESPACE_XSD = 'http://www.w3.org/2001/XMLSchema',
            NAMESPACE_SOAP = 'http://schemas.xmlsoap.org/soap/envelope/',
            NAMESPACE_SAMPLE = 'http://sample.test/webservices/';


    /*Root Element must extend XmlRootNode*/
    private class Envelope extends XmlNode.XmlRootNode {
        /*It's important to have all nodes initialized. Otherwise they will be omitted.*/
        public Body body = new Body();
        public Header header = new Header();

        public Envelope() {
        }
        public Envelope(Header header, BodyContent content) {
            this.header = header;
            this.body = new Body(content);
        }

        protected override void registerXML(XmlNode.Context ctx) {
            /*Root node has to call registerRootNode() as first entry in registerXML()*/
            registerRootNode('Envelope', NAMESPACE_SOAP, 'soap');

            /*Namespaces of the root element*/
            registerNamespace('xsi', NAMESPACE_XSI);
            registerNamespace('xsd', NAMESPACE_XSD);
            registerNamespace('soap', NAMESPACE_SOAP);

            /*registerChild() will create a Dom.XMLNode with given specs for the child element and pass it
            * for futher processing to header element*/
            registerChild(header, 'Header', NAMESPACE_SOAP, 'soap');
            registerChild(body, 'Body', NAMESPACE_SOAP, 'soap');
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

        protected override void registerXML(XmlNode.Context ctx) {
            /*Passed value is important in serialization, returned in deserialization*/
            this.username = (String) registerTextNode(String.class, 'username', null, null, username);
            this.password = (String) registerTextNode(String.class, 'password', null, null, password);
        }
    }

    private class Body extends XmlNode {
        public BodyContent content;

        public Body() {
        }
        public Body(BodyContent content) {
            this.content = content;
        }

        protected override void registerXML(XmlNode.Context ctx) {
            registerChild(content, content.getNodeName(), NAMESPACE_SAMPLE, '');
        }
    }


    /**
    * Abstract type which will be super type for all request and response elements that
    * reside in Body element.
    * */
    private abstract class BodyContent extends XmlNode {
        public abstract String getNodeName();
    }

    /**
    * Sample SOAP Request which will contain 1 Criteria element and
    * a text element with predefined values (values are made up)
    * */
    private class SampleRequest extends BodyContent {
        public ExclusionMode exclusionType = ExclusionMode.None;
        public Criteria criteria = new Criteria();

        public SampleRequest() {
        }
        public SampleRequest(ExclusionMode exclusionType, Criteria criteria) {
            this.exclusionType = exclusionType;
            this.criteria = criteria;
        }

        protected override void registerXML(XmlNode.Context ctx) {
            /*Enums are automatically deserialized from the XML string as well*/
            this.exclusionType = (ExclusionMode) registerTextNode(ExclusionMode.class, 'exclusion', NAMESPACE_SAMPLE, '', exclusionType);
            registerChild(criteria, 'criteria', NAMESPACE_SAMPLE, '');
        }

        public override String getNodeName() {
            return 'SampleRequest';
        }
    }
    public enum ExclusionMode {
        None,
        DuplicateEmail,
        DuplicateName,
        All
    }

    private class Criteria extends XmlNode {
        public String criteriaType;
        public String firstName;
        public String lastName;
        public String email;
        public String username;
        public Datetime dob = Datetime.now();
        public List<Address> addresses = new List<Address>();

        public Criteria() {
        }
        public Criteria(String criteriaType, String firstName, String lastName, String email, Datetime dob, List<Address> addresses) {
            this.criteriaType = criteriaType;
            this.firstName = firstName;
            this.lastName = lastName;
            this.email = email;
            this.username = email;
            this.dob = dob = dob;
            this.addresses = addresses;
        }

        protected override void registerXML(XmlNode.Context ctx) {
            this.criteriaType = (String) registerAttribute(String.class, 'type', criteriaType);
            this.firstName = (String) registerTextNode(String.class, 'FirstName', NAMESPACE_SAMPLE, '', firstName);
            this.lastName = (String) registerTextNode(String.class, 'LastName', NAMESPACE_SAMPLE, '', lastName);
            this.email = (String) registerTextNode(String.class, 'Email', NAMESPACE_SAMPLE, '', email);
            this.username = (String) registerTextNode(String.class, 'Username', NAMESPACE_SAMPLE, '', username);

            /*You can decouple deserialization and serialization using context.
            * In this case, variable is a Datetime, but we pass in String value - formatted Date.
            * registerTextNode() will always return passed value, so a String in this case.
            * I don't want to change the value during serialization, so I only handled returned date string in
            * deserialization context.
            * */
            String dobStr = (String) registerTextNode(String.class, 'DateOfBirth', NAMESPACE_SAMPLE, '', dob.format('dd/MM/YYYY'));
            if (ctx == XmlNode.Context.DESERIALIZATION) {
                this.dob = Date.parse(dobStr);
            }


            registerChildren(addresses, 'Address', NAMESPACE_SAMPLE, '', Address.class);
        }
    }
    private class Address extends XmlNode {
        public String country;
        public String addressLine1;
        public String addressLine2;
        public String addressLine3;
        public String addressLine4;

        public Address() {
        }
        public Address(String country, String addressLine1, String addressLine2) {
            this.country = country;
            this.addressLine1 = addressLine1;
            this.addressLine2 = addressLine2;
        }

        protected override void registerXML(XmlNode.Context ctx) {
            this.country = (String) registerTextNode(String.class, 'Country', NAMESPACE_SAMPLE, null, country);
            this.addressLine1 = (String) registerTextNode(String.class, 'AddressLine1', NAMESPACE_SAMPLE, '', addressLine1);
            this.addressLine2 = (String) registerTextNode(String.class, 'AddressLine2', NAMESPACE_SAMPLE, '', addressLine2);
            this.addressLine3 = (String) registerTextNode(String.class, 'AddressLine3', NAMESPACE_SAMPLE, '', addressLine3);
            this.addressLine4 = (String) registerTextNode(String.class, 'AddressLine4', NAMESPACE_SAMPLE, '', addressLine4);
        }
    }


    /**
    * Sample SOAP response
    * */
    private class SampleResponse extends BodyContent {
        public List<Match> matches = new List<Match>();

        protected override void registerXML(XmlNode.Context ctx) {
            /*registerList() creates single List node - 'matches' using listNodeName, ListNamespace and listPrefix
            * then creates 'match' nodes inside it.
            *
            * Adequately, during deserialization single matches child is retrieved and all it's match nodes are deserialized
            * to the List<Match>
            * */
            registerList('matches', NAMESPACE_SAMPLE, '', matches, 'match', NAMESPACE_SAMPLE, '', Match.class);
        }

        public override String getNodeName() {
            return 'SampleResponse';
        }
    }

    private class Match extends XmlNode {
        public String firstName;
        public String lastName;
        public Decimal score;
        public Double weight;
        public Integer height;
        public Long distance;
        public Boolean isMarried;

        protected override void registerXML(XmlNode.Context ctx) {
            this.firstName = (String) registerTextNode(String.class, 'FirstName', NAMESPACE_SAMPLE, '', firstName);
            this.lastName = (String) registerTextNode(String.class, 'LastName', NAMESPACE_SAMPLE, '', lastName);
            /*During deserialization, text value of Score text node will be deserialized to Decimal*/
            this.score = (Decimal) registerTextNode(Decimal.class, 'Score', NAMESPACE_SAMPLE, '', score);
            this.weight = (Double) registerTextNode(Double.class, 'Weight', NAMESPACE_SAMPLE, '', weight);
            this.height = (Integer) registerTextNode(Integer.class, 'Height', NAMESPACE_SAMPLE, '', height);
            this.distance = (Long) registerTextNode(Long.class, 'Distance', NAMESPACE_SAMPLE, '', distance);
            this.isMarried = (Boolean) registerTextNode(Boolean.class, 'Married', NAMESPACE_SAMPLE, '', isMarried);
        }
    }


    /**
     * @description
     * Envelope class structure and all it's data are transformed into proper XML request,
     * maintaining proper namespaces, node names and attributes according to registerXML() implementations.
     * Resulting XML is then loaded by another instance and serialized again to make sure, that consecutive serialization
     * and deserialization yields the same result.
     */
    @IsTest
    static void testRequestEnvelopeStructureIsSerializedToTheXMLProperly() {
        User usr = new User(
                Id = UserInfo.getUserId(),
                TimeZoneSidKey = 'GMT',
                LocaleSidKey = 'en_US'
        );
        update usr;

        System.runAs(usr) {
            Envelope envelope = new Envelope(
                    new Header('api.user', 'secret'),
                    new SampleRequest(ExclusionMode.DuplicateEmail,
                            new Criteria(
                                    'Personal Data', 'John', 'Doe', 'John.Doe@sample.com', Datetime.newInstance(1980, 01, 01),
                                    new List<Address>{
                                            new Address('UK', 'London', 'Test Street 2'),
                                            new Address('UK', 'Bridgetown', 'Other Street 2')
                                    }
                            )
                    )
            );

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
                    + '            <criteria type="Personal Data">'
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

            String actual = envelope.toXmlString();
            System.assertEquals(expectedXML, actual);


            Envelope envelope2 = new Envelope(
                    new Header('api.user', 'secret'),
                    new SampleRequest()
            );

            envelope2.load(actual);
            String actual2 = envelope2.toXmlString();
            System.assertEquals(actual, actual2);
        }
    }


    /**
     * @description
     * XML string is deserialized by given Envelope class structure.
     * XML text node values are parsed to the correct types and are available on the Envelope instance after loading xml.
     * After loading XML, Envelope is serialized again and the result should be the same as initial response xml.
     */
    @IsTest
    static void testResponseIsDeserializedToEnvelopeStructure() {
        User usr = new User(
                Id = UserInfo.getUserId(),
                TimeZoneSidKey = 'GMT',
                LocaleSidKey = 'en_US'
        );
        update usr;

        System.runAs(usr) {

            String responseXML =
                    ('<?xml version="1.0" encoding="UTF-8"?>'
                            + '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"'
                            + ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">'
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
                            + '                    <Weight>69.5</Weight>'
                            + '                    <Height>182</Height>'
                            + '                    <Distance>4000000</Distance>'
                            + '                    <Married>true</Married>'
                            + '                </match>'
                            + '                <match>'
                            + '                    <FirstName>Johan</FirstName>'
                            + '                    <LastName>Liebert</LastName>'
                            + '                    <Score>0.5</Score>'
                            + '                    <Weight>80.1</Weight>'
                            + '                    <Height>190</Height>'
                            + '                    <Distance>5000000</Distance>'
                            + '                    <Married>false</Married>'
                            + '                </match>'
                            + '            </matches>'
                            + '        </SampleResponse>'
                            + '    </soap:Body>'
                            + '</soap:Envelope>').replaceAll('\\>\\s+<', '><');

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
            System.assertEquals(responseXML, envelope.toXmlString());
        }
    }
}