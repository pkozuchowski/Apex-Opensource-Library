/**
* XML Tree generation tool
* Used to create XML Tree from hierarchy of classes extending this abstract class
* @author Piotr Kożuchowski
* */
public abstract class XmlNode {
    private transient Dom.XmlNode node;
    private static Boolean isSerialization;


    /**
     * Override this method to register all text nodes and child nodes under current node.
     */
    protected abstract void registerXML();

    /**
     * This method is required to clean up node and parent after work is done.
     * It significantly reduces required heap size (by half).
     */
    private void registerXML_internal() {
        registerXML();
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
            if (isSerialization) {
                childNode.node = this.node.addChildElement(nodeName, namespace, prefix);
            } else {
                childNode.node = this.node.getChildElement(nodeName, namespace);
            }

            childNode.registerXML_internal();
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
     * @param childType Type of the children. Children must extend XmlNode and have no-args constructor. (Deserialization phase only)
     */
    protected void registerChildren(List<XmlNode> childNodes, String name, String namespace, String prefix, Type childType) {
        if (childNodes != null) {
            if (isSerialization) {
                for (XmlNode childNode : childNodes) {
                    registerChild(childNode, name, namespace, prefix);
                }

            } else {
                for (Dom.XmlNode childDomNode : getChildElements()) {
                    if (childDomNode.getName() == name && childDomNode.getNamespace() == namespace) {
                        XmlNode childNode = (XmlNode) childType.newInstance();
                        childNode.node = childDomNode;
                        childNode.registerXML_internal();

                        childNodes.add(childNode);
                    }
                }
            }
        }
    }


    /**
     * Serialization Phase:
     * Registers each child node in given named list.
     *
     * Deserialization Phase:
     * Searches through children of deserialized node for node with listName and listNamspace
     * and iterates through the children of that node. Grandchildren with given name and namespace are deserialized to the list
     * of children of current node.
     *
     * <pre>
     *     &lt;SampleResponse&gt;
     *         &lt;matchesPrefix:matches&gt;
     *             &lt;match&gt;
     *             &lt;/match&gt;
     *         &lt;/matchesPrefix:matches&gt;
     *     &lt;/SampleResponse&gt; <br/>

     *     class Matches extends XmlNode{
     *          private List<Match> matches = new List<Match>();
     *
     *          protected override void registerXML(){
     *              ...
     *              registerList('matches',responseNamespace,matchesPrefix,matches,'match',responseNamespace,Match.class);
     *          }
     *     } <br/>
     *
     *     class Match extends XmlNode{...}
     * </pre>
     *
     * @param listName Name of the list element. (Both phase)
     * @param listNamespace Namespace of the list element. (Both phase)
     * @param listPrefix Prefix of the list element. (Serialization phase)
     * @param childrenList List of children to serialize under current node, or list to populate from deserialized node.
     * @param childNodeName Node name of the grand children to search for.(Deserialization phase only)
     * @param childNamespace Namespace of the grand children to search for.(Deserialization phase only)
     * @param childPrefix Prefix of the created grand children.(Serialization phase only)
     * @param prototype Type of the children. Children must extend XmlNode and have no-args constructor. (Deserialization phase only)
     */
    protected virtual void registerList(String listName, String listNamespace, String listPrefix, List<XmlNode> childrenList, String childNodeName, String childNamespace, String childPrefix, Type prototype) {
        if (isSerialization) {
            Dom.XmlNode listNode = this.node.addChildElement(listName, listNamespace, listPrefix);

            for (XmlNode childNode : childrenList) {
                childNode.node = listNode.addChildElement(childNodeName, childNamespace, childPrefix);
                childNode.registerXML_internal();
            }

        } else {
            Dom.XmlNode listNode = this.node.getChildElement(listName, listNamespace);

            for (Dom.XmlNode childDomNode : listNode.getChildElements()) {
                if (childDomNode.getName() == childNodeName && childDomNode.getNamespace() == childNamespace) {
                    XmlNode childNode = (XmlNode) prototype.newInstance();
                    childNode.node = childDomNode;
                    childNode.registerXML_internal();

                    childrenList.add(childNode);
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
    protected void setNamespace(String prefix, String namespace) {
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
        if (isSerialization) {
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
        if (isSerialization) {
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
            if (isSerialization) {
                this.document = new Dom.Document();
                this.node = this.document.createRootElement(nodeName, namespace, prefix);
            }
        }

        public Dom.Document serialize() {
            isSerialization = true;
            registerXML_internal();
            return document;
        }

        public String toXmlString() {
            serialize();
            return document.toXmlString();
        }

        public virtual void load(String xmlStr) {
            Dom.Document document = new Dom.Document();
            document.load(xmlStr);
            load(document);
        }

        public virtual void load(Dom.Document document) {
            isSerialization = false;
            this.node = document.getRootElement();
            registerXML_internal();
        }
    }
}