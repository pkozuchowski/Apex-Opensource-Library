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
 *
 * Dependencies:
 * @see SchemaDescriptions
 */
public without sharing class LocalizationCtrl {
    /**
     * These variables are used to fix JSON if custom labels
     */
    @TestVisible private static final String LOCALIZATION_START = 'LOCALIZATION_START';
    @TestVisible private static final String LOCALIZATION_VALUE = 'LOCALIZATION_VALUE';

    @TestVisible private static String mockPageContent;
    public String content { get; set; }
    public String localizationValue { get; set; }
    public String localizationStart { get; set; }


    public void init() {
        try {
            this.localizationStart = LOCALIZATION_START;
            this.localizationValue = LOCALIZATION_VALUE;
            this.initFields();
            this.initPicklists();

        } catch (Exception e) {
            this.content = JSON.serialize(new Map<String, String>{
                    'LocalizationCtrlException' => e.getMessage()
            });
        }
    }

    public List<String> getLabels() {
        return getParams('labels');
    }

    public void initFields() {
        List<String> fields = getParams('fields');

        if (fields != null) {
            Map<String, String> labelsByField = new Map<String, String>();

            for (String sObjectFieldConcatenation : fields) {
                String label = SchemaDescriptions.getSObjectFieldDescribe(sObjectFieldConcatenation).getLabel();
                labelsByField.put(sObjectFieldConcatenation, label);
            }

            this.content = JSON.serialize(labelsByField);
        }
    }

    public void initPicklists() {
        List<String> picklists = getParams('picklists');

        if (picklists != null) {
            Map<String, Map<String, String>> optionsByField = new Map<String, Map<String, String>>();

            for (String sObjectFieldConcatenation : picklists) {
                Picklist picklist = new Picklist(sObjectFieldConcatenation);
                optionsByField.put(sObjectFieldConcatenation, picklist.getEntriesMap());
            }

            this.content = JSON.serialize(optionsByField);
        }
    }

    private List<String> getParams(String name) {
        String param = ApexPages.currentPage().getParameters().get(name);
        return String.isEmpty(param) ? null : param.split(',');
    }


    public static String getJsonPageContent(Map<String, String> parameters) {
        PageReference p = Page.Localization;
        p.getParameters().putAll(parameters);

        String content = Test.isRunningTest() ? mockPageContent : p.getContent().toString();

        Boolean requireSanitization = parameters.containsKey('labels');
        if (requireSanitization == true) {
            content = sanitizeJSONString(content);
        }

        return content;
    }

    /**
     * Fixes JSON if custom label translation contained quote marks
     */
    @TestVisible
    private static String sanitizeJSONString(String pageContent) {
        String content = pageContent
                .replaceAll(',(\\s)*}', '}');

        List<String> parts = content.split(LOCALIZATION_VALUE);
        for (Integer i = 0; i < parts.size(); i++) {
            String part = parts.get(i);

            if (part.startsWith(LOCALIZATION_START)) {
                parts.set(i, part
                        .replaceAll('"', '\\\\"')
                        .replaceAll(LOCALIZATION_START, '')
                        .trim()
                );
            }
        }

        content = String.join(parts, '');
        return content;
    }
}