/**
* MIT License
*
* Copyright (c) 2020 Piotr Kożuchowski
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
 * Utility class for easy access to Schema classes and descriptions
 */
public without sharing class SchemaDescriptions {
    private static Map<String, SObjectType> globalDescribe = Schema.getGlobalDescribe();
    private static Map<String, Map<String, SObjectField>> fieldMap = new Map<String, Map<String, SObjectField>>();
    private static Map<String, DescribeSObjectResult> sObjectDescribeMap = new Map<String, DescribeSObjectResult>();
    private static Map<String, DescribeFieldResult> fieldDescribeMap = new Map<String, DescribeFieldResult>();


    /**
     * @param sobjectType API Name of SOBject - 'Account'
     * @return SObjectType for given API Name
     */
    public static SObjectType getSObjectType(String sobjectType) {
        assert(globalDescribe.containsKey(sobjectType), 'Invalid SObject: ' + sobjectType);

        return globalDescribe.get(sobjectType);
    }

    /**
     * @param sobjectType API Name of SOBject - 'Account'
     * @return SObject Description for given API Name
     */
    public static DescribeSObjectResult getSObjectDescribe(String sobjectType) {
        if (sObjectDescribeMap.containsKey(sobjectType)) {
            return sObjectDescribeMap.get(sobjectType);

        } else {
            DescribeSObjectResult sobjectDescribe = getSObjectType(sobjectType).getDescribe();
            sObjectDescribeMap.put(sobjectType, sobjectDescribe);
            return sobjectDescribe;
        }
    }


    /**
     * @param sObjectType SObject token ex. Account.SObjectType
     * @return All fields of that SObject
     */
    public static Map<String, SObjectField> getFieldsMap(SObjectType sObjectType) {
        return getFieldsMap('' + sObjectType);
    }

    /**
     * @param sObjectType API Name of SOBject ex. 'Account'
     * @return All fields of that SObject
     */
    public static Map<String, SObjectField> getFieldsMap(String sObjectType) {
        if (fieldMap.containsKey(sObjectType)) {
            return fieldMap.get(sObjectType);

        } else {
            DescribeSObjectResult describeSObject = getSObjectDescribe(sObjectType);
            fieldMap.put(sObjectType, describeSObject.fields.getMap());
            return fieldMap.get(sObjectType);
        }
    }


    /**
     * @param sobjectField Concatenation of SObjectType and SObjectField - 'Account.Name'
     * @return SObjectField for given API Name
     */
    public static SObjectField getSObjectField(String sobjectField) {
        String[] pair = sobjectField.split('\\.');
        String sObjectName = pair[0];
        String sObjectFieldName = pair[1];

        if (fieldMap.containsKey(sObjectName)) {
            return fieldMap.get(sObjectName).get(sObjectFieldName);

        } else {
            DescribeSObjectResult sobjectDescribe = getSObjectDescribe(sObjectName);
            Map<String, SObjectField> sobjectFieldsMap = sobjectDescribe.fields.getMap();
            fieldMap.put(sObjectName, sobjectFieldsMap);

            assert(sobjectFieldsMap.containsKey(sObjectFieldName), 'Invalid SObjectField: ' + sobjectField);
            SObjectField field = sobjectFieldsMap.get(sObjectFieldName);

            return field;
        }
    }

    /**
     * @param sobjectField Concatenation of SObjectType and SObjectField - 'Account.Name'
     * @return SObjectField description for given API Name
     */
    public static DescribeFieldResult getSObjectFieldDescribe(String sobjectField) {
        if (fieldDescribeMap.containsKey(sobjectField)) {
            return fieldDescribeMap.get(sobjectField);

        } else {
            DescribeFieldResult fieldResult = getSObjectField(sobjectField).getDescribe();
            fieldDescribeMap.put(sobjectField, fieldResult);

            return fieldResult;
        }
    }

    private static void assert(Boolean condition, String message) {
        if (!condition) throw new SchemaException(message);
    }

    public class SchemaException extends System.Exception {
    }
}