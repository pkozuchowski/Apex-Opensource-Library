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
private class LeadQueryTest {

    @TestSetup
    static void testSetup() {
        insert new List<Lead>{
                new Lead(LastName = 'Name 1', Company = 'Company 1', Email = 'Email1@example.com'),
                new Lead(LastName = 'Name 2', Company = 'Company 2', Email = 'Email2@example.com'),
                new Lead(LastName = 'Name 3', Company = 'Company 3', Email = 'Email3@example.com'),
                new Lead(LastName = 'Name 4', Company = 'Company 4', Email = 'Email4@example.com')
        };
    }

    @IsTest
    static void testSelectByName() {
        QueryObjectTest.assertEquals(
                ([SELECT Id FROM Lead WHERE Name = 'Name 1']),
                new LeadQuery().byName('Name 1').getList());
    }

    @IsTest
    static void testSelectByEmail() {
        QueryObjectTest.assertEquals(
                ([SELECT Id FROM Lead WHERE Email = 'Email1@example.com']),
                new LeadQuery().byEmail('Email1@example.com').getList());
    }

    @IsTest
    static void testSelectByCompany() {
        QueryObjectTest.assertEquals(
                ([SELECT Id FROM Lead WHERE Company = 'Company 1']),
                new LeadQuery().byCompany('Company 1').getList());
    }
}