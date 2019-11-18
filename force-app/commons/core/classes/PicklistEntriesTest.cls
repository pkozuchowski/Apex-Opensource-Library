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
@IsTest
private class PicklistEntriesTest {
    private static String defaultValue;
    private static List<String> values;
    private static String testValue;

    static {
        values = new List<String>();
        for (PicklistEntry picklistEntry : Account.AccountSource.getDescribe().getPicklistValues()) {
            if (picklistEntry.isActive()) {
                values.add(picklistEntry.getValue());
                testValue = PicklistEntry.getValue();

                if (picklistEntry.isDefaultValue()) {
                    defaultValue = picklistEntry.getValue();
                }
            }
        }
    }


    @IsTest
    static void testBehavior() {
        PicklistEntries accountSource = PicklistEntries.of(Account.AccountSource);

        System.assertEquals(false, accountSource.isDependentPicklist());
        System.assertEquals(false, accountSource.isRestrictedPicklist());
        System.assertEquals(defaultValue, accountSource.getDefaultValue());
        System.assertEquals(values, accountSource.getValues());
        System.assertEquals(true, accountSource.containsValue(testValue));
        System.assertEquals(true, accountSource.containsValue(testValue.toUpperCase()));
        System.assertEquals(true, accountSource.containsValue(testValue.toLowerCase()));
        System.assertEquals(false, accountSource.containsValue('PicklistEntriesTest'));

        List<PicklistEntries.Entry> entries = accountSource.getEntries();
        List<SelectOption> selectOptions = accountSource.getSelectOptions();

        for (Integer i = 0; i < entries.size(); i++) {
            System.assertEquals(values[i], entries[i].value);
            System.assertEquals(values[i], selectOptions[i].getValue());
        }
    }
}