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
 * Localization issues PageReference.getContent() which counts as callout and is not supported in unit tests.
 */
@IsTest(IsParallel=true)
private class LocalizationTest {

    /**
     * Localization.getCustomLabel() should return translated custom label values for given API names in current user's locale
     */
    @IsTest
    static void getCustomLabelShouldReturnValueForGivenAPIName() {
        LocalizationCtrl.mockPageContent = '{"Site.logout":"' + LocalizationCtrl.LOCALIZATION_VALUE
                + LocalizationCtrl.LOCALIZATION_START
                + 'Logout'
                + LocalizationCtrl.LOCALIZATION_VALUE + '"}';

        System.assertEquals('Logout', Localization.getCustomLabel('Site.logout'));
        System.assertEquals(
                new Map<String, String>{'Site.logout' => 'Logout'},
                Localization.getCustomLabels(new List<String>{'Site.logout'})
        );
    }

    /**
     * Localization.getCustomLabel() should return translated custom label values for given API names and locale
     */
    @IsTest
    static void getCustomLabelShouldReturnTranslatedValueForGivenAPINameAndLocale() {
        LocalizationCtrl.mockPageContent = '{"Site.logout":"Abmelden"}';


        System.assertEquals('Abmelden', Localization.getCustomLabel('Site.logout', 'de'));
        System.assertEquals(
                new Map<String, String>{'Site.logout' => 'Abmelden'},
                Localization.getCustomLabels(new List<String>{'Site.logout'}, 'de')
        );
    }


    /**
     * Localization.getFieldLabel() should return translated sobject field label for given API names in current user's locale
     */
    @IsTest
    static void getFieldLabelShouldReturnTranslatedSObjectFieldLabel() {
        LocalizationCtrl.mockPageContent = '{"Account.Site":"Account Site"}';

        System.assertEquals('Account Site', Localization.getFieldLabel('Account.Site'));
        System.assertEquals(
                new Map<String, String>{'Account.Site' => 'Account Site'},
                Localization.getFieldLabels(new List<String>{'Account.Site'})
        );
    }

    /**
     * Localization.getFieldLabel() should return translated sobject field label for given API names in current user's locale
     */
    @IsTest
    static void getFieldLabelShouldReturnTranslatedSObjectFieldLabelForGivenLocale() {
        LocalizationCtrl.mockPageContent = '{"Account.Site":"Accountstandort"}';

        System.assertEquals('Accountstandort', Localization.getFieldLabel('Account.Site', 'de'));
        System.assertEquals(
                new Map<String, String>{'Account.Site' => 'Accountstandort'},
                Localization.getFieldLabels(new List<String>{'Account.Site', 'de'})
        );
    }


    /**
     *@description
     * Localization.getPicklistLabels() should return Map of picklist API names and translated labels
     */
    @IsTest
    static void getPicklistLabelsShouldReturnTranslatedOptions() {
        LocalizationCtrl.mockPageContent = '{ ' +
                '"Account.Type":{ ' +
                '   "Prospect":"ProspectDE", ' +
                '   "Customer - Direct":"Customer - Direct", ' +
                '   "Other":"Andere"' +
                '   }' +
                '}';

        Map<String, String> labelsByAPIName = Localization.getPicklistLabels('Account.Type', 'de');
        System.assertEquals('ProspectDE', labelsByAPIName.get('Prospect'));
        System.assertEquals('Andere', labelsByAPIName.get('Other'));
    }


    @IsTest
    static void coverageLabels() {
        PageReference localizationPage = Page.Localization;
        localizationPage.getParameters().putAll(new Map<String, String>{
                'labels' => 'Site.logout,Site.email'
        });


        Test.startTest();
        Test.setCurrentPage(localizationPage);
        LocalizationCtrl localizationCtrl = new LocalizationCtrl();
        List<String> labels = localizationCtrl.getLabels();
        Test.stopTest();


        System.assertEquals(new List<String>{'Site.logout', 'Site.email'}, labels);
    }

    @IsTest
    static void coverageFields() {
        PageReference localizationPage = Page.Localization;
        localizationPage.getParameters().putAll(new Map<String, String>{
                'fields' => 'Account.Name,Account.Site'
        });


        Test.startTest();
        Test.setCurrentPage(localizationPage);
        LocalizationCtrl ctrl = new LocalizationCtrl();
        ctrl.init();
        Test.stopTest();


        Map<String, String> labelMap = (Map<String, String>) JSON.deserialize(ctrl.content, Map<String, String>.class);
        System.assertEquals(Account.Name.getDescribe().getLabel(), labelMap.get('Account.Name'));
        System.assertEquals(Account.Site.getDescribe().getLabel(), labelMap.get('Account.Site'));
    }

    @IsTest
    static void coveragePicklists() {
        PageReference localizationPage = Page.Localization;
        localizationPage.getParameters().putAll(new Map<String, String>{
                'picklists' => 'Account.Type'
        });


        Test.startTest();
        Test.setCurrentPage(localizationPage);
        LocalizationCtrl ctrl = new LocalizationCtrl();
        ctrl.init();
        Test.stopTest();


        Map<String, Map<String, String>> content = (Map<String, Map<String, String>>) JSON.deserialize(ctrl.content, Map<String, Map<String, String>>.class);
        System.assertEquals(true, content.containsKey('Account.Type'));
    }

    @IsTest
    static void shouldCheckSObjectValidityCtrl() {
        PageReference localizationPage = Page.Localization;
        localizationPage.getParameters().putAll(new Map<String, String>{
                'picklists' => 'AccountFake.Type'
        });


        Test.startTest();
        Test.setCurrentPage(localizationPage);
        LocalizationCtrl ctrl = new LocalizationCtrl();
        ctrl.init();
        Test.stopTest();


        Map<String, String> content = (Map<String, String>) JSON.deserialize(ctrl.content, Map<String, String>.class);
        System.assertEquals('Invalid SObject: AccountFake', content.get('LocalizationCtrlException'));
    }

    @IsTest
    static void shouldCheckSObjectValidity() {
        PageReference localizationPage = Page.Localization;
        localizationPage.getParameters().putAll(new Map<String, String>{
                'picklists' => 'AccountFake.Type'
        });
        Exception ex;


        try {
            Test.startTest();
            Test.setCurrentPage(localizationPage);
            LocalizationCtrl ctrl = new LocalizationCtrl();
            ctrl.init();
            LocalizationCtrl.mockPageContent = ctrl.content;
            Localization.getPicklistLabels('AccountFake.Type', 'de');
            Test.stopTest();
        } catch (Exception e) {
            ex = e ;
        }


        System.assertNotEquals(null, ex);
        System.assertEquals('Invalid SObject: AccountFake', ex.getMessage());
    }
}