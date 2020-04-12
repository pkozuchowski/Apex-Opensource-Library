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
@IsTest
private class LocalizationTest {

    /**
     * Localization.getCustomLabel() should return translated custom label values for given API names in current user's locale
     */
    @IsTest
    static void getCustomLabelShouldReturnValueForGivenAPIName() {
        Localization.mockResponse = new Map<String, String>{'Site.logout' => 'Logout'};

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
        Localization.mockResponse = new Map<String, String>{'Site.logout' => 'Abmelden'};

        System.assertEquals('Abmelden', Localization.getCustomLabel('Site.logout', 'de'));
        System.assertEquals(
                new Map<String, String>{'Site.logout' => 'Abmelden'},
                Localization.getCustomLabels(new List<String>{'Site.logout'}, 'de')
        );
    }


    /**
     * Localization.getFieldLabe() should return translated sobject field label for given API names in current user's locale
     */
    @IsTest
    static void getFieldLabelShouldReturnTranslatedSObjectFieldLabel() {
        Localization.mockResponse = new Map<String, String>{'Account.Site' => 'Account Site'};

        System.assertEquals('Account Site', Localization.getFieldLabel('Account.Site'));
        System.assertEquals(
                new Map<String, String>{'Account.Site' => 'Account Site'},
                Localization.getFieldLabels(new List<String>{'Account.Site'})
        );
    }

    /**
     * Localization.getFieldLabe() should return translated sobject field label for given API names in current user's locale
     */
    @IsTest
    static void getFieldLabelShouldReturnTranslatedSObjectFieldLabelForGivenLocale() {
        Localization.mockResponse = new Map<String, String>{'Account.Site' => 'Accountstandort'};

        System.assertEquals('Accountstandort', Localization.getFieldLabel('Account.Site', 'de'));
        System.assertEquals(
                new Map<String, String>{'Account.Site' => 'Accountstandort'},
                Localization.getFieldLabels(new List<String>{'Account.Site', 'de'})
        );
    }


    @IsTest
    static void testControllerGetters() {
        PageReference localizationPage = Page.Localization;
        localizationPage.getParameters().putAll(new Map<String, String>{
                'labels' => 'Site.logout,Site.email',
                'fields' => 'Account.Site,Account.Name'
        });


        Test.startTest();
        Test.setCurrentPage(localizationPage);
        Localization localization = new Localization();
        List<String> labels = localization.getLabels();
        List<String[]> fields = localization.getFields();
        Test.stopTest();


        System.assertEquals(new List<String>{'Site.logout', 'Site.email'}, labels);
        System.assertEquals(new List<String[]>{
                new List<String>{'Account', 'Site'},
                new List<String>{'Account', 'Name'}
        }, fields);
    }
}