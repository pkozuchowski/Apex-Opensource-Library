/**
* XML Tree generation tool
* Used to create XML Tree from hierarchy of classess extending this abstract class
* @author Piotr Kożuchowski
* */
public abstract class XmlNode {
    private transient Dom.XmlNode node;
    private transient Dom.XmlNode parent;
    private static XmlNode.OperationMode mode;

    private enum OperationMode {
        SERIALIZE,
        DESERIALIZE
    }

    /**
    * Creates node for this element in parent
    * */
    protected void registerThisNode(String nodeName) {
        registerThisNode(nodeName, null, null);
    }

    protected virtual void registerThisNode(String nodeName, String namespace, String prefix) {
        if (this.node == null) {
            if (XmlNode.mode == OperationMode.SERIALIZE) {
                this.node = this.parent.addChildElement(nodeName, namespace, prefix);
            } else {
                this.node = this.parent.getChildElement(nodeName, namespace);
            }
        }
    }


    /**
    * Add argument as child node
    * */
    protected void addChildElement(XmlNode childNode) {
        if (childNode != null) {
            childNode.parent = this.node;
            childNode.serializeToXML();
        }
    }

    protected void addChildrenElements(List<XmlNode> childNodes) {
        if (childNodes != null) {
            for (XmlNode childNode : childNodes) {
                addChildElement(childNode);
            }
        }
    }

    protected Dom.XmlNode addChildElement(String name, String namespace, String prefix) {
        return this.node.addChildElement(name, namespace, prefix);
    }


    protected void addChildTextElement(String name, Object value) {
        addChildTextElement(name, null, null, value);
    }

    protected void addChildTextElement(String name, String namespace, String prefix, Object value) {
        if (value != null) {
            Dom.XmlNode node = addChildElement(name, namespace, prefix);
            String textValue = String.valueOf(value).escapeXml();
            node.addTextNode(textValue);
        }
    }


    /**
    * Sets namespace for current node
    * */
    protected void setNamespace(String prefix, String namespace) {
        this.node.setNamespace(prefix, namespace);
    }

    /**
    * Sets namespace for current node
    * */
    protected void setAttribute(String key, String value) {
        this.node.setAttribute(key, value);
    }

    protected void setAttribute(String key, String value, String keyNamespace, String valueNamespace) {
        this.node.setAttributeNs(key, value, keyNamespace, valueNamespace);
    }


    protected abstract void serializeToXML();
    protected abstract void deserializeXML();

    protected virtual void deserializeChild(XmlNode childNode) {
        if (childNode != null) {
            childNode.parent = this.node;
            childNode.deserializeXMLImpl();
        }
    }

    public void deserializeXML(Dom.XmlNode thisNode) {
        this.node = thisNode;
        deserializeXML();
        this.node = null;
        this.parent = null;
    }

    public void deserializeXMLImpl() {
        deserializeXML();
        this.node = null;
        this.parent = null;
    }

    protected virtual void deserializeList(String name, String namespace, List<XmlNode> childrenList, String childNodeName, Type prototype) {
        Dom.XmlNode listNode = this.node.getChildElement(name, namespace);

        for (Dom.XmlNode childDomNode : listNode.getChildElements()) {
            if (childDomNode.getName() == childNodeName) {
                XmlNode childNode = (XmlNode) prototype.newInstance();
                childNode.deserializeXML(childDomNode);

                childrenList.add(childNode);
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

    protected Double getDoubleValue(String name, String namespace) {
        String textValue = getStringValue(name, namespace);
        return String.isEmpty(textValue) ? null : Double.valueOf(textValue);
    }

    protected Decimal getDecimalValue(String name, String namespace) {
        String textValue = getStringValue(name, namespace);
        return String.isEmpty(textValue) ? null : Decimal.valueOf(textValue);
    }

    protected Integer getIntegerValue(String name, String namespace) {
        String textValue = getStringValue(name, namespace);
        return String.isEmpty(textValue) ? null : Integer.valueOf(textValue);
    }

    protected Long getLongValue(String name, String namespace) {
        String textValue = getStringValue(name, namespace);
        return String.isEmpty(textValue) ? null : Long.valueOf(textValue);
    }

    protected Boolean getBooleanValue(String name, String namespace) {
        String textValue = getStringValue(name, namespace);
        return String.isEmpty(textValue) ? null : Boolean.valueOf(textValue);
    }

    protected String getStringAttribute(String name, String namespace) {
        String value = node.getAttribute(name, namespace);
        return value == null ? '' : value;
    }


    /**
    * Unique kind of XML Node which is restricted only for top most node - a root node
    * This implementation can convert all class hierarchy into a Dom document and deserialize Dom Document into
    * class hierarchy.
    * */
    public abstract class XmlRootNode extends XmlNode {
        private transient Dom.Document document;

        protected override void registerThisNode(String nodeName, String namespace, String prefix) {
            if (mode == OperationMode.SERIALIZE) {
                this.document = new Dom.Document();
                this.node = this.document.createRootElement(nodeName, namespace, prefix);
            }
        }

        public virtual Dom.Document serialize() {
            mode = OperationMode.SERIALIZE;
            serializeToXML();
            return document;
        }

        public virtual void load(Dom.Document document) {
            mode = OperationMode.DESERIALIZE;
            deserializeXML(document.getRootElement());
        }

        public virtual void load(String xmlStr) {
            mode = OperationMode.DESERIALIZE;
            this.document = new Dom.Document();
            this.document.load(xmlStr);
            deserializeXML(document.getRootElement());
        }
    }
}