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
private class BusinessHoursQueryTest {

    @IsTest
    static void testSelectDefault() {
        QueryObject query = new BusinessHoursQuery().byDefault(true);
        String soql = query.toSOQL();
        String whereClause = 'WHERE (IsDefault = :var0)';

        Assert.isTrue(soql.containsIgnoreCase(whereClause),
            String.format('SOQL "{0}" should contain WHERE clause: "{1}"',
                new List<Object>{soql, whereClause}
            )
        );
        Assert.areEqual(true, query.getBinding(':var0'));
    }


    @IsTest
    static void testSelectByName() {
        String value = 'Test Value';
        QueryObject query = new BusinessHoursQuery().byName(value);
        QueryObjectTest.assertSOQLContainsFieldInClause(query, BusinessHours.Name, value);
    }
}