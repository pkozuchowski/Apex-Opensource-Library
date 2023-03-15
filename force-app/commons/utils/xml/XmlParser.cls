/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2023 Piotr Kożuchowski
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */


/**
 * Parses XML to untyped map (Map<String,Object>).
*/
public with sharing class XmlParser {
    private static final String KEY_TEXT = '__text';
    private String attrPrefix = '@';
    private XmlStreamReader reader;
    private List<Object> elementStack;

    public XmlParser(String xmlString) {
        this.reader = new XmlStreamReader(xmlString);
    }

    /**
     * @param prefix Prefix in JSON key that will indicate attribute. Defaults to '@'
     * Example:
     * <pre>
     * <person gender="female">
     *     <firstname>Anna</firstname>
     *     <lastname>Smith</lastname>
     * </person>
     * </pre>
     *
     * Output:
     * <pre>
     * {
     *   person: {
     *      "@gender":"female",
     *      "firstname":"Anna",
     *      "lastname":"Smith",
     *   }
     * }
     *
     * </pre>
     */
    public void setAttributePrefix(String prefix) {
        this.attrPrefix = prefix;
    }

    /**
     * @return Raw JSON generated from the XML.
     */
    public Map<String, Object> getUntyped() {
        return parseXml();
    }

    /**
     * Serializes & Deserializes untyped map into concrete apex type
     * @param apexType Type to deserialize to
     * @param withoutEnvelope If true, only xml's root element is deserialized into type instead of envelope
     * <pre>
     *     { // <----- This is with envelope
     *          "Profile":{ // <--- This is without envelope
     *              "classAccesses":[...]
     *          }
     *     }
     * </pre>
     *
     *
     * @return Parses XML into concrete apex type
     */
    public Object getAs(Type apexType, Boolean withEnvelope) {
        Map<String, Object> elementToReturn = parseXml();

        if (withEnvelope == false) {
            elementToReturn = (Map<String, Object>) elementToReturn.values()[0];
        }

        return JSON.deserialize(JSON.serialize(elementToReturn), apexType);
    }

    private Map<String, Object> parseXml() {
        Map<String, Object> root = new Map<String, Object>{
            '__root' => true
        };
        this.elementStack = new List<Object>{root};

        parseNode();
        root.remove('__root');
        this.elementStack.clear();

        return root;
    }


    private void parseNode() {
        while (reader.hasNext()) {

            switch on reader.getEventType() {
                when START_ELEMENT {
                    parseStartElement();
                }
                when END_ELEMENT {
                    parseEndElement();
                }
                when CHARACTERS, CDATA {
                    parseText();
                }
                when ATTRIBUTE {
                    System.debug(reader.getLocalName());
                }
                when else {

                }
            }

            reader.next();
        }
    }

    private void parseStartElement() {
        Map<String, Object> thisElement = new Map<String, Object>();
        String name = reader.getLocalName();

        Map<String, Object> parent = (Map<String, Object>) elementStack.get(elementStack.size() - 1);
        Object nodeWithThisNameInParent = parent.get(name);

        if (nodeWithThisNameInParent == null) {
            Object value = parent.containsKey('__root') ?
                ((Object) thisElement) :
                ((Object) new List<Object>{thisElement});
            parent.put(name, value);

        } else {
            List<Object> lst = (List<Object>) nodeWithThisNameInParent;
            lst.add(thisElement);
        }


        if (reader.getAttributeCount() > 0) {
            for (Integer i = 0; i < reader.getAttributeCount(); i++) {
                String attrName = reader.getAttributeLocalName(i);
                String attrNs = reader.getAttributeNamespace(i);
                String attrValue = reader.getAttributeValue(attrNs, attrName);
                thisElement.put(attrPrefix + attrName, attrValue);
            }
        }

        elementStack.add(thisElement);
    }

    private void parseEndElement() {
        Map<String, Object> last = (Map<String, Object>) elementStack.remove(elementStack.size() - 1);

        if (last.containsKey(KEY_TEXT)) {
            Map<String, Object> parentOfLast = (Map<String, Object>) elementStack.get(elementStack.size() - 1);
            parentOfLast.put(reader.getLocalName(), last.get(KEY_TEXT));
        }
    }

    private void parseText() {
        String text = reader.getText();

        if (String.isNotBlank(text)) {
            Map<String, Object> lastElem = (Map<String, Object>) elementStack.get(elementStack.size() - 1);

            String key = KEY_TEXT;
            if (text.isNumeric()) {
                lastElem.put(key, Decimal.valueOf(text));

            } else if (text == 'true' || text == 'false') {
                lastElem.put(key, Boolean.valueOf(text));

            } else {
                lastElem.put(key, text);
            }
        }
    }
}