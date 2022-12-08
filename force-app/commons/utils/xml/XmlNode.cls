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

/**
* Dom.XmlNode wrapper for automatic serialization/deserialization of class structures to/from XML.
* To use this class, you have to recreate XML tree structure as class structure and each class should extend XmlNode.
* Each class will have to implement registerXML() class and register all children as either text node, child node or list node.
* @see XmlNodeTest for usage.
* @author Piotr Kożuchowski
* */
public abstract class XmlNode {
    private transient Dom.XmlNode node;
    private transient Context mode;

    public enum Context {
        SERIALIZATION,
        DESERIALIZATION
    }

    /**
     * Override this method to register all text nodes and child nodes under current node.
     */
    protected abstract void registerXML(Context mode);

    /**
     * This method is required to clean up node and parent after work is done.
     * It significantly reduces required heap size (by half).
     */
    private void registerXML_internal(Context mode) {
        this.mode = mode;
        registerXML(mode);
        this.node = null;
    }


    /**
     * During serialization:
     * Creates child xml node with given nodeName, namespace and prefix.
     *
     * During deserialization:
     * Finds child node element of given nodeName and namespace in current node.
     *
     * @param childNode XmlNode implementation
     * @param nodeName Name of child node.
     * @param namespace Namespace of child node.
     * @param prefix Prefix of child node. (Serialization phase only)
     */
    protected void registerChild(XmlNode childNode, String nodeName, String namespace, String prefix) {
        if (childNode != null) {
            if (mode == Context.SERIALIZATION) {
                childNode.node = this.node.addChildElement(nodeName, namespace, prefix);
            } else {
                childNode.node = this.node.getChildElement(nodeName, namespace);
            }

            childNode.registerXML_internal(mode);
        }
    }


    /**
     * Serialization Phase:
     * Registers each child node in given list as direct child of this node.
     *
     * Deserialization Phase:
     * Searches through children of deserialized node for children with given name and namespace and deserialize found nodes.
     *
     * @param childNodes List of nodes to register. (required in both phases)
     * @param name Name of the child nodes to search for. (Deserialization phase only)
     * @param namespace Namespace of the child nodes to search for. (Deserialization phase only)
     * @param prefix Prefix of the created child nodes. (Serialization phase only)
     */
    protected void registerChildren(List<XmlNode> childNodes, String name, String namespace, String prefix) {
        Type childType = Runtime.getListItemType(childNodes);

        if (childType == null) {
            throw new TypeException('Child class is not public.');
        }

        registerChildren(childNodes, name, namespace, prefix, Runtime.getListItemType(childNodes));
    }

    /**
     * Serialization Phase:
     * Registers each child node in given list as direct child of this node.
     *
     * Deserialization Phase:
     * Searches through children of deserialized node for children with given name and namespace and deserialize found nodes.
     *
     * @param childNodes List of nodes to register. (required in both phases)
     * @param name Name of the child nodes to search for. (Deserialization phase only)
     * @param namespace Namespace of the child nodes to search for. (Deserialization phase only)
     * @param prefix Prefix of the created child nodes. (Serialization phase only)
     * @param childType Type of the children. Children must extend XmlNode and have no-args constructor. (Deserialization phase only)
     */
    protected void registerChildren(List<XmlNode> childNodes, String name, String namespace, String prefix, Type childType) {
        if (childNodes != null) {
            if (mode == Context.SERIALIZATION) {
                for (XmlNode childNode : childNodes) {
                    registerChild(childNode, name, namespace, prefix);
                }

            } else {
                for (Dom.XmlNode childDomNode : getChildElements()) {
                    if (childDomNode.getName() == name && childDomNode.getNamespace() == namespace) {
                        XmlNode childNode = (XmlNode) childType.newInstance();
                        childNode.node = childDomNode;
                        childNode.registerXML_internal(mode);

                        childNodes.add(childNode);
                    }
                }
            }
        }
    }


    /**
     * @return List of Dom.XmlNode elements under current node.
     */
    protected virtual List<Dom.XmlNode> getChildElements() {
        return node.getChildElements();
    }

    /**
     * @return Text value of the current node.
     */
    protected String getStringValue() {
        return this.node.getText();
    }


    /**
    * Sets namespace for current node
    * */
    protected void registerNamespace(String prefix, String namespace) {
        this.node.setNamespace(prefix, namespace);
    }


    /**
     * During serialization:
     * Creates text node in current element with given text value.
     *
     * During deserialization:
     * Returns value of text node specified by given name and namespace.
     *
     * @param valueType Text node value will be automatically parsed to this type.
     * Possible values: String,Double,Decimal,Integer,Long,Date,Datetime,Boolean, Any enum type (for any other, returns String)
     * Required in deserialization.
     * @param name Text node name.
     * @param namespace Text node namespace.
     * @param prefix Text node prefix (only in serialization phase).
     * @param value This value will be parsed to String, escaped and placed in created text node. (Only in serialization phase).
     *
     * @return
     */
    protected Object registerTextNode(Type valueType, String name, String namespace, String prefix, Object value) {
        if (mode == Context.SERIALIZATION) {
            if (value != null) {
                Dom.XmlNode txtNode = this.node.addChildElement(name, namespace, prefix);
                String textValue = String.valueOf(value).escapeXml();
                txtNode.addTextNode(textValue);
            }
            return value;

        } else {
            Dom.XmlNode textNode = this.node.getChildElement(name, namespace);
            String nodeValue = textNode == null ? '' : textNode.getText();

            return parseStringValue(valueType, nodeValue);
        }
    }

    /**
    * Invokes registerAttribute with null key namespace and value namespace.
    * @see XmlNode.registerAttribute
     */
    protected Object registerAttribute(Type valueType, String key, Object value) {
        return registerAttribute(valueType, key, value, null, null);
    }

    /**
     * Serialization Phase:
     * Sets attribute on XML Node.
     *
     * Deserialization Phase:
     * Returns attribute from deserialized node.
     *
     * @param valueType Attribute value will be automatically parsed to this type. (Deserialization phase only)
     * @param key Attribute key
     * @param value Attribute value
     * @param keyNamespace Namespace of the attribute's key. (Serialization phase only)
     * @param valueNamespace Namespace of the attribute's value. (Serialization phase only)
     *
     * @return Serialization: returns passed value. Deserialization: returns attribute's value.
     */
    protected Object registerAttribute(Type valueType, String key, Object value, String keyNamespace, String valueNamespace) {
        if (mode == Context.SERIALIZATION) {
            this.node.setAttributeNs(key, String.valueOf(value), keyNamespace, valueNamespace);
            return value;
        } else {
            String atributeValue = this.node.getAttribute(key, keyNamespace);
            return parseStringValue(valueType, atributeValue);
        }
    }

    /**
    * @return Value of the text node child specified by name and namespace.
    * Value is parsed to given primitive or enum type, or returned as String if type is not supported.
    * */
    private Object parseStringValue(Type valueType, String value) {
        if (String.isNotBlank(value)) {
            if (valueType == String.class) return value;
            if (valueType == Double.class) return Double.valueOf(value);
            if (valueType == Decimal.class) return Decimal.valueOf(value);
            if (valueType == Integer.class) return Integer.valueOf(value);
            if (valueType == Long.class) return Long.valueOf(value);
            if (valueType == Date.class) return Date.valueOf(value);
            if (valueType == Datetime.class) return Datetime.valueOf(value);
            if (valueType == Boolean.class) return Boolean.valueOf(value);

            /*Attempt to cast string value to Enum. This is only possible through JSON deserialization to List<Enums>*/
            try {
                List<Object> enums = (List<Object>) JSON.deserialize('["' + value + '"]', Type.forName('List<' + valueType + '>'));
                return enums[0];
            } catch (Exception ex) {
            }

            return value;
        }
        return null;
    }


    /**
    * Unique kind of XML Node which is restricted only for top most node - a root node
    * This implementation can convert all class hierarchy into a Dom document and deserialize Dom Document into
    * class hierarchy.
    * */
    public abstract class XmlRootNode extends XmlNode {
        private transient Dom.Document document;

        protected void registerRootNode(String nodeName, String namespace, String prefix) {
            if (mode == Context.SERIALIZATION) {
                this.document = new Dom.Document();
                this.node = this.document.createRootElement(nodeName, namespace, prefix);
            }
        }

        public String toXmlString() {
            return toDomDocument().toXmlString();
        }

        public Dom.Document toDomDocument() {
            this.mode = Context.SERIALIZATION;
            registerXML_internal(mode);
            return document;
        }

        public virtual void load(String xmlStr) {
            Dom.Document document = new Dom.Document();
            document.load(xmlStr);
            load(document);
        }

        public virtual void load(Dom.Document document) {
            this.mode = Context.DESERIALIZATION;
            this.node = document.getRootElement();
            registerXML_internal(mode);
        }
    }
}