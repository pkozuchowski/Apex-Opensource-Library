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
    * During serialization creates node for this element in parent.
    * During deserialization, searches for node in parent element
    * */
    protected void registerThisNode(String nodeName) {
        registerThisNode(nodeName, null, null);
    }

    /**
    * During serialization creates node for this element in parent.
    * During deserialization, searches for node in parent element
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


    protected Object registerTextNode(Type t, String name, Object value) {
        return registerTextNode(t, name, null, null, value);
    }
    protected Object registerTextNode(Type t, String name, String namespace, String prefix, Object value) {
        if (isSerialization) {
            if (value != null) {
                Dom.XmlNode txtNode = this.node.addChildElement(name, namespace, prefix);
                String textValue = String.valueOf(value).escapeXml();
                txtNode.addTextNode(textValue);
            }
            return value;

        } else {
            return getValue(t, getStringValue(name, namespace));
        }
    }

    private Object getValue(Type t, String value) {
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


    protected abstract void registerXML();
    private void registerXML_internal() {
        registerXML();
        this.node = null;
        this.parent = null;
    }


    /**
    * Add argument as child node
    * */
    protected void registerChild(XmlNode childNode) {
        if (childNode != null) {
            childNode.parent = this.node;
            childNode.registerXML_internal();
        }
    }

    protected List<XmlNode> registerChildren(List<XmlNode> childNodes, String name, String namespace, String prefix, Type prototype) {
        if (childNodes != null) {
            if (isSerialization) {
                for (XmlNode childNode : childNodes) {
                    registerChild(childNode);
                }

            } else {
                for (Dom.XmlNode childDomNode : node.getChildElements()) {
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

    protected virtual List<Dom.XmlNode> getChildElements() {
        return node.getChildElements();
    }

    protected String getStringValue() {
        return this.node.getText();
    }
    protected String getStringValue(String name, String namespace) {
        Dom.XmlNode textNode = this.node.getChildElement(name, namespace);
        return textNode == null ? '' : textNode.getText();
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

        public virtual Dom.Document serialize() {
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