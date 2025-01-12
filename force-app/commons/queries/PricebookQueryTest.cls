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
private class PricebookQueryTest {

    @IsTest
    static void testWithEntries() {
        QueryObjectTest.assertSOQLContains(
            new PricebookQuery().withEntries(),
            'FROM PricebookEntries'
        );
    }

    /**
     * Standard pricebook Id value in unit test context should be the same as Test.getStandardPricebookId() call result.
     */
    @IsTest
    static void testSelectStandardPricebookId() {
        System.assertEquals(
            Test.getStandardPricebookId(),
            new PricebookQuery().getStandardPricebookId()
        );
    }

    @IsTest
    static void testSelectByName() {
        String value = 'Pricebook Name';
        PricebookQuery query = new PricebookQuery().byName(value);
        QueryObjectTest.assertSOQLContainsFieldInClause(query, Pricebook2.Name, new Set<String>{value});
    }

}