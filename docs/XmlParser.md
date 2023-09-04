# XML to JSON
*Translate XML document into JSON*

---
## Documentation
Simple parser that traverses through XML document and maps it into untyped Map<String,Object map.

```apex | Usage
Map<String, Object> untypedMap = new XmlParser(xmlString).getUntyped();

//or as concrete type
XmlParser xmlParser = new XmlParser(PROFILE_XML);
xmlParser.setAttributePrefix('attr_');

Profile p = (Profile) xmlParser.getAs(Profile.class, false);
```

Given Profile XML:

<details>
    <summary>Profile XML</summary>

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Profile xmlns="http://soap.sforce.com/2006/04/metadata">
    <classAccesses someAttribute="Test">
        <apexClass>AccountSelector</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>AccountTriggerHandler</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <custom>false</custom>
    <fieldPermissions>
        <editable>false</editable>
        <field>Log__c.ApexClass__c</field>
        <readable>false</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Log__c.LoggingLevel__c</field>
        <readable>false</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Log__c.Message__c</field>
        <readable>false</readable>
    </fieldPermissions>
    <layoutAssignments>
        <layout>Account-Account Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>LogRetention__mdt-Logging Setting Layout</layout>
    </layoutAssignments>
    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>true</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>true</modifyAllRecords>
        <object>Log__c</object>
        <viewAllRecords>true</viewAllRecords>
    </objectPermissions>
    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>true</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>true</modifyAllRecords>
        <object>LoggingEvent__e</object>
        <viewAllRecords>true</viewAllRecords>
    </objectPermissions>
    <pageAccesses>
        <apexPage>TestPage</apexPage>
        <enabled>true</enabled>
    </pageAccesses>
    <tabVisibilities>
        <tab>Log__c</tab>
        <visibility>DefaultOn</visibility>
    </tabVisibilities>
    <tabVisibilities>
        <tab>Test</tab>
        <visibility>DefaultOn</visibility>
    </tabVisibilities>
    <userLicense>Salesforce</userLicense>
    <userPermissions>
        <enabled>true</enabled>
        <name>ActivateContract</name>
    </userPermissions>
    <userPermissions>
        <enabled>true</enabled>
        <name>ActivateOrder</name>
    </userPermissions>
    <userPermissions>
        <enabled>true</enabled>
        <name>ActivitiesAccess</name>
    </userPermissions>
</Profile>
```
</details>


Output for `Map<String,Object> result = new XmlParser(PROFILE_XML).getUntyped();` will look as follows:

<details>
    <summary>Untyped Map</summary>

```json
{
    "Profile": {
        "userPermissions": [
            {
                "name": "ActivateContract",
                "enabled": true
            },
            {
                "name": "ActivateOrder",
                "enabled": true
            },
            {
                "name": "ActivitiesAccess",
                "enabled": true
            }
        ],
        "userLicense": "Salesforce",
        "tabVisibilities": [
            {
                "visibility": "DefaultOn",
                "tab": "Log__c"
            },
            {
                "visibility": "DefaultOn",
                "tab": "Test"
            }
        ],
        "pageAccesses": [
            {
                "enabled": true,
                "apexPage": "TestPage"
            }
        ],
        "objectPermissions": [
            {
                "viewAllRecords": true,
                "object": "Log__c",
                "modifyAllRecords": true,
                "allowRead": true,
                "allowEdit": true,
                "allowDelete": true,
                "allowCreate": true
            },
            {
                "viewAllRecords": true,
                "object": "LoggingEvent__e",
                "modifyAllRecords": true,
                "allowRead": true,
                "allowEdit": true,
                "allowDelete": true,
                "allowCreate": true
            }
        ],
        "layoutAssignments": [
            {
                "layout": "Account-Account Layout"
            },
            {
                "layout": "LogRetention__mdt-Logging Setting Layout"
            }
        ],
        "fieldPermissions": [
            {
                "readable": false,
                "field": "Log__c.ApexClass__c",
                "editable": false
            },
            {
                "readable": false,
                "field": "Log__c.LoggingLevel__c",
                "editable": false
            },
            {
                "readable": false,
                "field": "Log__c.Message__c",
                "editable": false
            }
        ],
        "custom": false,
        "classAccesses": [
            {
                "enabled": true,
                "apexClass": "AccountSelector",
                "@someAttribute": "Test"
            },
            {
                "enabled": true,
                "apexClass": "AccountTriggerHandler"
            }
        ]
    }
}
```
test
</details>


---
## Methods

- `void setAttributePrefix(String prefix)` - Sets prefix in JSON key that will indicate attribute. Defaults to '@'
```xml

<person gender="female">
    <firstname>Anna</firstname>
    <lastname>Smith</lastname>
</person>
```

```json
{
    "person": {
        "@gender": "female",
        "firstname": "Anna",
        "lastname": "Smith"
    }
}
```

- `Map<String,Object> getUntyped()` - returns raw Map<String,Object>
- `Object getAs(Type apexType, Boolean withEnvelope)` - Deserializes untyped map to given apex type.
    - `apexType` - Apex Type to deserialize to
    - `withEnvelope` - If true, only xml's root element is deserialized into type instead of envelope
```text
{ // <----- This is object returned withEnvelope=true
     "Profile":{ // <--- This is object returned withEnvelope=false
         "classAccesses":[...]
     }
}
```