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
 * Controller for Localization page. Should not be used for anything else.
 */
public without sharing class LocalizationCtrl {
    @TestVisible private static String mockPageContent;

    public String localizationValue {
        get {
            return 'LOCALIZATION_VALUE';
        }
    }

    public String localizationStart {
        get {
            return 'LOCALIZATION_START';
        }
    }


    public List<String> getLabels() {
        return getParams('labels');
    }

    public List<List<String>> getFields() {
        List<String> fields = getParams('fields');

        if (fields != null) {
            List<List<String>> pairs = new List<List<String>>();

            Map<String, SObjectType> globalDescribe = Schema.getGlobalDescribe();
            for (String sObjectFieldConcatenation : fields) {
                List<String> pair = sObjectFieldConcatenation.split('\\.');
                String sObjectName = pair[0];
                String sObjectFieldName = pair[1];

                assert(globalDescribe.containsKey(sObjectName), 'Invalid SObjectType: ' + sObjectName);

                SObjectType sObjectType = globalDescribe.get(sObjectName);
                DescribeSObjectResult sobjectDescribe = sObjectType.getDescribe();
                Map<String, SObjectField> fieldsMap = sobjectDescribe.fields.getMap();
                assert(fieldsMap.containsKey(sObjectFieldName), 'Invalid SObjectField: ' + sObjectFieldConcatenation);


                pairs.add(pair);
            }

            return pairs;

        } else {
            return null;
        }
    }

    public Map<String, List<PicklistPair>> getPicklists() {
        List<String> fields = getParams('picklists');

        if (fields != null) {
            Map<String, SObjectType> globalDescribe = Schema.getGlobalDescribe();
            Map<String, List<PicklistPair>> picklistOptionsByField = new Map<String, List<PicklistPair>>();

            for (String sObjectFieldConcatenation : fields) {
                List<String> pair = sObjectFieldConcatenation.split('\\.');
                String sObjectName = pair[0];
                String sObjectFieldName = pair[1];

                assert(globalDescribe.containsKey(sObjectName), 'Invalid SObjectType: ' + sObjectName);
                SObjectType sObjectType = globalDescribe.get(sObjectName);
                DescribeSObjectResult sobjectDescribe = sObjectType.getDescribe();

                Map<String, SObjectField> fieldsMap = sobjectDescribe.fields.getMap();
                assert(fieldsMap.containsKey(sObjectFieldName), 'Invalid SObjectField: ' + sObjectFieldConcatenation);

                SObjectField field = fieldsMap.get(sObjectFieldName);
                Picklist picklist = new Picklist(field);
                assert(picklist.getValues().isEmpty() == false, 'Field is not a picklist: ' + sObjectFieldConcatenation);

                List<PicklistPair> pPairs = picklistOptionsByField.get(sObjectFieldConcatenation);
                pPairs = pPairs == null ? new List<PicklistPair>() : pPairs;

                for (String picklistValue : picklist.getValues()) {
                    PicklistPair pPair = new PicklistPair();
                    pPair.field = sObjectFieldName;
                    pPair.value = picklistValue;
                    pPair.record = sObjectType.newSObject();
                    pPair.record.put(field, picklistValue);

                    pPairs.add(pPair);
                }

                picklistOptionsByField.put(sObjectFieldConcatenation, pPairs);
            }

            return picklistOptionsByField;
        } else {
            return null;
        }
    }

    private void assert(Boolean condition, String errorMessage) {
        if (condition == false) throw new LocalizationException(errorMessage);
    }

    @TestVisible
    private class PicklistPair {
        public String field { get; set; }
        public String value { get; set; }
        public SObject record { get; set; }
    }

    private List<String> getParams(String name) {
        String param = ApexPages.currentPage().getParameters().get(name);
        return String.isEmpty(param) ? null : param.split(',');
    }


    public String getJsonPageContent(Map<String, String> parameters) {
        PageReference p = Page.Localization;
        p.getParameters().putAll(parameters);

        String content = Test.isRunningTest() ? mockPageContent : p.getContent().toString();
        return sanitizeJSONString(content);
    }

    @TestVisible
    private String sanitizeJSONString(String pageContent) {
        String content = pageContent
                .stripHtmlTags()
                .replaceAll(',(\\s)*}', '}');

        List<String> parts = content.split(localizationValue);
        for (Integer i = 0; i < parts.size(); i++) {
            String part = parts.get(i);

            if (part.startsWith(localizationStart)) {
                parts.set(i, part
                        .replaceAll('"', '\\\\"')
                        .replaceAll(localizationStart, '')
                        .trim()
                );
            }
        }

        content = String.join(parts, '');
        return content;
    }
}