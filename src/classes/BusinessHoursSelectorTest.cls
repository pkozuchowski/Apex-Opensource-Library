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
private class BusinessHoursSelectorTest {

    @IsTest
    static void testGetDefault() {
        BusinessHours[] expected = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE];
        BusinessHours actual = new BusinessHoursSelector().getDefault();

        if (!expected.isEmpty()) {
            System.assertEquals(expected[0].Id, actual.Id);
        }
    }


    @IsTest
    static void testGetByName() {
        BusinessHours[] expected = [SELECT Id,Name FROM BusinessHours WHERE IsActive = TRUE];

        if (!expected.isEmpty()) {
            System.assertEquals(
                    expected[0].Id,
                    new BusinessHoursSelector().getByName(expected[0].Name).Id
            );
        }
    }

    @IsTest
    static void testGetById() {
        BusinessHours[] expected = [SELECT Id,Name FROM BusinessHours WHERE IsActive = TRUE];

        if (!expected.isEmpty()) {
            System.assertEquals(
                    expected[0].Id,
                    new BusinessHoursSelector().getById(expected[0].Id).Id
            );
        }
    }
}