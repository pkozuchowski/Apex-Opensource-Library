/**
* MIT License
*
* Copyright (c) 2019 Piotr Kożuchowski
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
private class ApexTest {

    public class ExampleClass {
    }


    /**
     *@description
     * Apex.getRunningType() returns running type of the object instance.
     */
    @IsTest
    static void testGetRunningType() {
        ExampleClass instance = new ExampleClass();
        System.assertEquals(ExampleClass.class, Apex.getRunningType(instance));
    }

    @IsTest
    static void testGetDatesRunningType() {
        Date instance = Date.today();
        System.assertEquals(Date.class, Apex.getRunningType(instance));
    }


    /**
     *@description
     * Apex.getRunningType() returns name of running type of the object instance.
     */
    @IsTest
    static void testGetRunningTypeName() {
        ExampleClass instance = new ExampleClass();
        System.assertEquals('ApexTest.ExampleClass', Apex.getRunningTypeName(instance));
    }

    /**
     *@description
     * Apex.getListItemType() returns type of elements in given list
     */
    @IsTest
    static void testGetListItemType() {
        System.assertEquals(Account.class, Apex.getListItemType(new List<Account>()));

        List<SObject> records = new List<Opportunity>();
        System.assertEquals(Opportunity.class, Apex.getListItemType(records));
    }


    /**
     *@description
     * Apex.newListOfTheSameType returns new list of the same item type as param.
     */
    @IsTest
    static void testNewListOfTheSameType() {
        List<SObject> records = new List<Opportunity>();
        List<Object> result = Apex.newListOfTheSameType(records);

        System.assert(result instanceof List<Opportunity>);
    }

    /**
     *@description
     * Apex.newListOfItemType returns new list with the given item type
     */
    @IsTest
    static void testNewListOfItemType() {
        List<Object> result = Apex.newListOfItemType(Opportunity.class);
        System.assert(result instanceof List<Opportunity>);
    }
}