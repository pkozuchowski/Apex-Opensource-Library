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
 * /
 * *
 *  Please find newest source code at https://github.com/amorek/Apex-Opensource-Library
 * /
 */

@IsTest(IsParallel=true)
private class XmlParserTest {
    private static String PROFILE_XML = ''
        + '<?xml version="1.0" encoding="UTF-8"?>'
        + '<Profile xmlns="http://soap.sforce.com/2006/04/metadata">'
        + '    <classAccesses someAttribute="Test">'
        + '        <apexClass>AccountSelector</apexClass>'
        + '        <enabled>true</enabled>'
        + '    </classAccesses>'
        + '    <classAccesses>'
        + '        <apexClass>AccountTriggerHandler</apexClass>'
        + '        <enabled>true</enabled>'
        + '    </classAccesses>'
        + '    <custom>false</custom>'
        + '    <fieldPermissions>'
        + '        <editable>false</editable>'
        + '        <field>Log__c.ApexClass__c</field>'
        + '        <readable>false</readable>'
        + '    </fieldPermissions>'
        + '    <fieldPermissions>'
        + '        <editable>false</editable>'
        + '        <field>Log__c.LoggingLevel__c</field>'
        + '        <readable>false</readable>'
        + '    </fieldPermissions>'
        + '    <fieldPermissions>'
        + '        <editable>false</editable>'
        + '        <field>Log__c.Message__c</field>'
        + '        <readable>false</readable>'
        + '    </fieldPermissions>'
        + '    <layoutAssignments>'
        + '        <layout>Account-Account Layout</layout>'
        + '    </layoutAssignments>'
        + '    <layoutAssignments>'
        + '        <layout>LogRetention__mdt-Logging Setting Layout</layout>'
        + '    </layoutAssignments>'
        + '    <objectPermissions>'
        + '        <allowCreate>true</allowCreate>'
        + '        <allowDelete>true</allowDelete>'
        + '        <allowEdit>true</allowEdit>'
        + '        <allowRead>true</allowRead>'
        + '        <modifyAllRecords>true</modifyAllRecords>'
        + '        <object>Log__c</object>'
        + '        <viewAllRecords>true</viewAllRecords>'
        + '    </objectPermissions>'
        + '    <objectPermissions>'
        + '        <allowCreate>true</allowCreate>'
        + '        <allowDelete>true</allowDelete>'
        + '        <allowEdit>true</allowEdit>'
        + '        <allowRead>true</allowRead>'
        + '        <modifyAllRecords>true</modifyAllRecords>'
        + '        <object>LoggingEvent__e</object>'
        + '        <viewAllRecords>true</viewAllRecords>'
        + '    </objectPermissions>'
        + '    <pageAccesses>'
        + '        <apexPage>TestPage</apexPage>'
        + '        <enabled>true</enabled>'
        + '    </pageAccesses>'
        + '    <tabVisibilities>'
        + '        <tab>Log__c</tab>'
        + '        <visibility>DefaultOn</visibility>'
        + '    </tabVisibilities>'
        + '    <tabVisibilities>'
        + '        <tab>Test</tab>'
        + '        <visibility>DefaultOn</visibility>'
        + '    </tabVisibilities>'
        + '    <userLicense>Salesforce</userLicense>'
        + '    <userPermissions>'
        + '        <enabled>true</enabled>'
        + '        <name>ActivateContract</name>'
        + '    </userPermissions>'
        + '    <userPermissions>'
        + '        <enabled>true</enabled>'
        + '        <name>ActivateOrder</name>'
        + '    </userPermissions>'
        + '    <userPermissions>'
        + '        <enabled>true</enabled>'
        + '        <name>ActivitiesAccess</name>'
        + '    </userPermissions>'
        + '</Profile>';

    @IsTest
    static void shouldParseXmlToJson() {
        Map<String, Object> untypedMap = new XmlParser(PROFILE_XML).getUntyped();

        Assert.areEqual(JSON.deserializeUntyped('{' +
            '    "Profile": {' +
            '        "classAccesses": [' +
            '            {' +
            '                "@someAttribute": "Test",' +
            '                "apexClass": "AccountSelector",' +
            '                "enabled": true' +
            '            },' +
            '            {' +
            '                "apexClass": "AccountTriggerHandler",' +
            '                "enabled": true' +
            '            }' +
            '        ],' +
            '        "custom": false,' +
            '        "fieldPermissions": [' +
            '            {' +
            '                "editable": false,' +
            '                "field": "Log__c.ApexClass__c",' +
            '                "readable": false' +
            '            },' +
            '            {' +
            '                "editable": false,' +
            '                "field": "Log__c.LoggingLevel__c",' +
            '                "readable": false' +
            '            },' +
            '            {' +
            '                "editable": false,' +
            '                "field": "Log__c.Message__c",' +
            '                "readable": false' +
            '            }' +
            '        ],' +
            '        "layoutAssignments": [' +
            '            {"layout": "Account-Account Layout"},' +
            '            {"layout": "LogRetention__mdt-Logging Setting Layout"}' +
            '        ],' +
            '        "objectPermissions": [' +
            '            {' +
            '                "allowCreate": true,' +
            '                "allowDelete": true,' +
            '                "allowEdit": true,' +
            '                "allowRead": true,' +
            '                "modifyAllRecords": true,' +
            '                "object": "Log__c",' +
            '                "viewAllRecords": true' +
            '            },' +
            '            {' +
            '                "allowCreate": true,' +
            '                "allowDelete": true,' +
            '                "allowEdit": true,' +
            '                "allowRead": true,' +
            '                "modifyAllRecords": true,' +
            '                "object": "LoggingEvent__e",' +
            '                "viewAllRecords": true' +
            '            }' +
            '        ],' +
            '        "pageAccesses": [' +
            '            {' +
            '                "apexPage": "TestPage",' +
            '                "enabled": true' +
            '            }' +
            '        ],' +
            '        "tabVisibilities": [' +
            '            {' +
            '                "tab": "Log__c",' +
            '                "visibility": "DefaultOn"' +
            '            },' +
            '            {' +
            '                "tab": "Test",' +
            '                "visibility": "DefaultOn"' +
            '            }' +
            '        ],' +
            '        "userLicense": "Salesforce",' +
            '        "userPermissions": [' +
            '            {' +
            '                "enabled": true,' +
            '                "name": "ActivateContract"' +
            '            },' +
            '            {' +
            '                "enabled": true,' +
            '                "name": "ActivateOrder"' +
            '            },' +
            '            {' +
            '                "enabled": true,' +
            '                "name": "ActivitiesAccess"' +
            '            }' +
            '        ]' +
            '    }' +
            '}'), untypedMap);
    }

    @IsTest
    static void shouldParseXmlToType() {
        XmlParser xmlParser = new XmlParser(PROFILE_XML);
        xmlParser.setAttributePrefix('attr_');

        Profile p = (Profile) xmlParser.getAs(Profile.class, false);

        Assert.areEqual(2, p.classAccesses.size());
        Assert.areEqual('Test', p.classAccesses[0].attr_someAttribute);
        Assert.areEqual('AccountSelector', p.classAccesses[0].apexClass);
        Assert.areEqual(true, p.classAccesses[0].enabled);

        Assert.areEqual('AccountTriggerHandler', p.classAccesses[1].apexClass);
        Assert.areEqual(true, p.classAccesses[1].enabled);
    }

    private class Profile {
        ClassAccess[] classAccesses;
    }

    private class ClassAccess {
        String attr_someAttribute;
        String apexClass;
        Boolean enabled;
    }
}