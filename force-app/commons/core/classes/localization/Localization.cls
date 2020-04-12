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
 * This class can dynamically fetch Custom Labels and Field labels for given names and locale
 * It utilizes PageReference.getContent() method, which counts as callout and has to be mocked in unit tests.
 */
public with sharing class Localization {
    @TestVisible private static Map<String, String> mockResponse = new Map<String, String>();

    public List<String> getLabels() {
        return getParams('labels');
    }

    public List<List<String>> getFields() {
        List<String> fields = getParams('fields');

        if (fields != null) {
            List<List<String>> pairs = new List<List<String>>();

            for (String field : fields) {
                pairs.add(field.split('\\.'));
            }

            return pairs;

        } else {
            return null;
        }
    }

    private List<String> getParams(String name) {
        String param = ApexPages.currentPage().getParameters().get(name);
        return String.isEmpty(param) ? null : param.split(',');
    }


    /**
     * @param labelName API name of the label
     *
     * @return Value of the Custom Label for user's locale
     */
    @AuraEnabled
    public static String getCustomLabel(String labelName) {
        return getCustomLabel(labelName, null);
    }

    /**
     * @param labelName API name of the label
     * @param locale Locale key of the translation to retrieve. Same format as User's LocaleSidKey or LanguageLocaleKey (en/en_US/de/de_De/ru etc.)
     *
     * @return Value of the Custom Label translated to given locale
     */
    @AuraEnabled
    public static String getCustomLabel(String labelName, String locale) {
        return getCustomLabels(new List<String>{labelName}, locale).get(labelName);
    }

    /**
     * @param labelNames API name of the labels to retrieve
     *
     * @return Map of label developer names and translations in user's locale
     */
    @AuraEnabled
    public static Map<String, String> getCustomLabels(String[] labelNames) {
        return getCustomLabels(labelNames, null);
    }

    /**
     * @param labelNames API name of the labels to retrieve
     * @param locale Locale key of the translation to retrieve. Same format as User's LocaleSidKey or LanguageLocaleKey (en/en_US/de/de_De/ru etc.)
     *
     * @return Map of label developer names and translations in given locale
     */
    @AuraEnabled
    public static Map<String, String> getCustomLabels(String[] labelNames, String locale) {
        return getContent(new Map<String, String>{
                'labels' => String.join(labelNames, ','),
                'locale' => locale
        });
    }


    /**
     * @param field API name of the sobject and field (ex. "Account.Name")
     *
     * @return Field's label in current user's locale
     */
    @AuraEnabled
    public static String getFieldLabel(String field) {
        return getFieldLabel(field, null);
    }

    /**
     * @param field API name of the sobject and field (ex. "Account.Name")
     * @param locale Locale key of the translation to retrieve. Same format as User's LocaleSidKey or LanguageLocaleKey (en/en_US/de/de_De/ru etc.)
     *
     * @return Field's label translated to given locale
     */
    @AuraEnabled
    public static String getFieldLabel(String field, String locale) {
        return getFieldLabels(new List<String>{field}, locale).get(field);
    }

    /**
     * @param fields API names of the sobject and field (ex. "Account.Name")
     *
     * @return Map of field API names and translated labels and current user's locale
     */
    @AuraEnabled
    public static Map<String, String> getFieldLabels(String[] fields) {
        return getFieldLabels(fields, null);
    }

    /**
     * @param fields API names of the sobject and field (ex. "Account.Name")
     * @param locale Locale key of the translation to retrieve. Same format as User's LocaleSidKey or LanguageLocaleKey (en/en_US/de/de_De/ru etc.)
     *
     * @return Map of field API names and translated labels and given locale
     */
    @AuraEnabled
    public static Map<String, String> getFieldLabels(String[] fields, String locale) {
        return getContent(new Map<String, String>{
                'fields' => String.join(fields, ','),
                'locale' => locale
        });
    }


    private static Map<String, String> getContent(Map<String, String> parameters) {
        try {
            PageReference p = Page.Localization;
            p.getParameters().putAll(parameters);

            if (Test.isRunningTest()) {
                return mockResponse;

            } else {
                String content = p.getContent().toString().replaceFirst(',(\\s)*}', '}');
                return (Map<String, String>) JSON.deserialize(content, Map<String, String>.class);
            }

        } catch (Exception e) {
            throw new LocalizationException(e.getMessage().replace('Field $Label.', 'Label '));
        }
    }

    public class LocalizationException extends Exception {
    }
}