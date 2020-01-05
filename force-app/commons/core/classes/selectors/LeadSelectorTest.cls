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
private class LeadSelectorTest {

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
        SelectorTest.assertEquals(
                ([SELECT Id FROM Lead WHERE Name = 'Name 1']),
                new LeadSelector().byName('Name 1'));

        SelectorTest.assertEquals(
                ([SELECT Id FROM Lead WHERE Name IN ('Name 1', 'Name 2')]),
                new LeadSelector().byName(new List<String>{'Name 1', 'Name 2'}));
    }

    @IsTest
    static void testSelectByEmail() {
        SelectorTest.assertEquals(
                ([SELECT Id FROM Lead WHERE Email = 'Email1@example.com']),
                new LeadSelector().byEmail('Email1@example.com'));

        SelectorTest.assertEquals(
                ([SELECT Id FROM Lead WHERE Email IN ('Email1@example.com', 'Email2@example.com')]),
                new LeadSelector().byEmail(new List<String>{'Email1@example.com', 'Email2@example.com'}));
    }

    @IsTest
    static void testSelectByCompany() {
        SelectorTest.assertEquals(
                ([SELECT Id FROM Lead WHERE Company = 'Company 1']),
                new LeadSelector().byCompany('Company 1'));

        SelectorTest.assertEquals(
                ([SELECT Id FROM Lead WHERE Company IN ('Company 1', 'Company 2')]),
                new LeadSelector().byCompany(new List<String>{'Company 1', 'Company 2'}));
    }
}