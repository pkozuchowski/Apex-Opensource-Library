/**
* MIT License
*
* Copyright (c) 2018 Piotr Kożuchowski
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
@IsTest(IsParallel=true)
private class PicklistTest {
    private static String defaultValue;
    private static List<String> values;
    private static List<String> labels;
    private static String testValue, testLabel;

    static {
        values = new List<String>();
        labels = new List<String>();

        for (PicklistEntry entry : Account.AccountSource.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                values.add(entry.getValue());
                labels.add(entry.getLabel());
                testValue = entry.getValue();
                testLabel = entry.getLabel();

                if (entry.isDefaultValue()) {
                    defaultValue = entry.getValue();
                }
            }
        }
    }


    @IsTest
    static void testBehavior() {
        Picklist accountSource = new Picklist(Account.AccountSource);
        accountSource = new Picklist('Account.AccountSource');

        System.assertEquals(false, accountSource.isDependent());
        System.assertEquals(false, accountSource.isRestricted());
        System.assertEquals(defaultValue, accountSource.getDefaultValue());
        System.assertEquals(values, accountSource.getValues());
        System.assertEquals(labels, accountSource.getLabels());
        System.assertEquals(true, accountSource.containsValue(testValue));
        System.assertEquals(testLabel, accountSource.getLabel(testValue));
        System.assertEquals(true, accountSource.containsValue(testValue.toUpperCase()));
        System.assertEquals(true, accountSource.containsValue(testValue.toLowerCase()));
        System.assertEquals(false, accountSource.containsValue('PicklistEntriesTest'));

        List<Picklist.Entry> entries = accountSource.getEntries();
        Map<String, String> entriesMap = accountSource.getEntriesMap();
        List<SelectOption> selectOptions = accountSource.getSelectOptions();

        for (Integer i = 0; i < entries.size(); i++) {
            System.assert(entriesMap.containsKey(values[i]));
            System.assertEquals(values[i], entries[i].value);
            System.assertEquals(values[i], selectOptions[i].getValue());
        }

        Map<Object, Picklist.Entry[]> entriesByController = accountSource.getEntriesByControllingValue();
    }

    @IsTest
    static void shouldThrowExceptionWhenFieldIsNotPicklist() {
        Exception ex;

        try {
            Picklist p = new Picklist('Account.Name');
        } catch (Exception e) {
            ex = e;
        }

        System.assertNotEquals(null, ex);
        System.assertNotEquals('Field is not a picklist: Account.Name', ex.getMessage());
    }
}