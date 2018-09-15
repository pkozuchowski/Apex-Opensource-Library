/**
* XML Tree generation tool
* Used to create XML Tree from hierarchy of classess extending this abstract class
* @author Piotr Kożuchowski
* */
public abstract class XmlNode {
    private transient Dom.XmlNode node;
    private transient Dom.XmlNode parent;
    private static Boolean isSerialization;


    /**
     *
     */
    protected abstract void registerXML();

    /**
     * This method is required to clean up node and parent after work is done.
     * It significantly reduces required heap size (by half).
     */
    private void registerXML_internal() {
        registerXML();
        this.node = null;
        this.parent = null;
    }


    /**
    * During serialization creates node for this element in parent node.
    * During deserialization, searches for node in parent element node.
    * */
    protected virtual void registerThisNode(String nodeName, String namespace, String prefix) {
        if (this.node == null) {
            if (isSerialization) {
                this.node = this.parent.addChildElement(nodeName, namespace, prefix);
            } else {
                this.node = this.parent.getChildElement(nodeName, namespace);
            }
        }
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
            return getValue(valueType, name, namespace);
        }
    }

    /**
    * @return Value of the text node child specified by name and namespace.
    * Value is parsed to given primitive or enum type, or returned as String if type is not supported.
    * */
    private Object getValue(Type t, String name, String namespace) {
        Dom.XmlNode textNode = this.node.getChildElement(name, namespace);
        String value = textNode == null ? '' : textNode.getText();

        if (String.isNotBlank(value)) {
            if (t == String.class) return String.valueOf(value);
            if (t == Double.class) return Double.valueOf(value);
            if (t == Decimal.class) return Decimal.valueOf(value);
            if (t == Integer.class) return Integer.valueOf(value);
            if (t == Long.class) return Long.valueOf(value);
            if (t == Date.class) return Date.valueOf(value);
            if (t == Datetime.class) return Datetime.valueOf(value);
            if (t == Boolean.class) return Boolean.valueOf(value);

            /*Attempt to cast string value to Enum. This is only possible through JSON deserialization to List<Enums>*/
            try {
                List<Object> enums = (List<Object>) JSON.deserialize('["' + value + '"]', Type.forName('List<' + t + '>'));
                return enums[0];
            } catch (Exception ex) {
            }

            return value;
        }
        return null;
    }


    /**
     * Links child node to the current node and execute's it's registerXML() method.
     * NPE Safe.
     */
    protected void registerChild(XmlNode childNode) {
        if (childNode != null) {
            childNode.parent = this.node;
            childNode.registerXML_internal();
        }
    }


    /**
     *
     *
     * @param childNodes
     * @param name
     * @param namespace
     * @param prefix
     * @param prototype
     *
     * @return
     */
    protected List<XmlNode> registerChildren(List<XmlNode> childNodes, String name, String namespace, String prefix, Type prototype) {
        if (childNodes != null) {
            if (isSerialization) {
                for (XmlNode childNode : childNodes) {
                    registerChild(childNode);
                }

            } else {
                for (Dom.XmlNode childDomNode : getChildElements()) {
                    if (childDomNode.getName() == name) {
                        XmlNode childNode = (XmlNode) prototype.newInstance();
                        childNode.node = childDomNode;
                        childNode.registerXML_internal();

                        childNodes.add(childNode);
                    }
                }
            }
        }
        return childNodes;
    }


    /**
     *
     *
     * @param listName
     * @param listNamespace
     * @param listPrefix
     * @param childrenList
     * @param childNodeName
     * @param prototype
     */
    protected virtual void registerList(String listName, String listNamespace, String listPrefix, List<XmlNode> childrenList, String childNodeName, Type prototype) {
        if (isSerialization) {
            Dom.XmlNode listNode = this.node.addChildElement(listName, listNamespace, listPrefix);

            for (XmlNode childNode : childrenList) {
                childNode.parent = listNode;
                childNode.registerXML_internal();
            }

        } else {
            Dom.XmlNode listNode = this.node.getChildElement(listName, listNamespace);

            for (Dom.XmlNode childDomNode : listNode.getChildElements()) {
                if (childDomNode.getName() == childNodeName) {
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
    * Sets attribute for current node
    * */
    protected void setAttribute(String key, String value) {
        this.node.setAttribute(key, value);
    }

    /**
    * Sets attribute for current node
    * */
    protected void setAttribute(String key, String value, String keyNamespace, String valueNamespace) {
        this.node.setAttributeNs(key, value, keyNamespace, valueNamespace);
    }


    /**
    * Unique kind of XML Node which is restricted only for top most node - a root node
    * This implementation can convert all class hierarchy into a Dom document and deserialize Dom Document into
    * class hierarchy.
    * */
    public abstract class XmlRootNode extends XmlNode {
        private transient Dom.Document document;

        protected override void registerThisNode(String nodeName, String namespace, String prefix) {
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