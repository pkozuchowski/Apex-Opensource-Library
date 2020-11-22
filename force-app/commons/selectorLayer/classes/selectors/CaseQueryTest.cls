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
private class CaseQueryTest {

    @TestSetup
    static void testSetup() {
        Account account = new Account(Name = 'Parent Account');
        insert account;

        Contact contact = new Contact(AccountId = account.Id, LastName = 'Doe');
        insert contact;

        insert new List<Case>{
                new Case(AccountId = account.Id, Subject = 'Subject 1', Status = 'New', Origin = 'Web'),
                new Case(AccountId = account.Id, Subject = 'Subject 2', Status = 'New', Origin = 'Web'),
                new Case(AccountId = account.Id, Subject = 'Subject 3', Status = 'New', Origin = 'Web', ContactId = contact.Id)
        };
    }

    @IsTest
    static void testSelectWithParentAccount() {
        Case c = (Case) new CaseQuery()
                .withParentAccount()
                .bySubject(new Set<String>{'Subject 1'})
                .getFirstOrNull();

        System.assertEquals('Parent Account', c.Account.Name);
    }

    @IsTest
    static void testSelectBySubject() {
        QueryObjectTest.assertEquals(
                ([SELECT Id FROM Case WHERE Subject = 'Subject 1']),
                new CaseQuery().bySubject('Subject 1').getList());
    }

    @IsTest
    static void testSelectByAccountId() {
        Account account = [SELECT Id FROM Account];

        QueryObjectTest.assertEquals(
                ([SELECT Id FROM Case WHERE AccountId = :account.Id]),
                new CaseQuery().byAccountId(account.Id).getList());
    }

    @IsTest
    static void testSelectByContactId() {
        Contact contact = [SELECT Id FROM Contact];

        QueryObjectTest.assertEquals(
                ([SELECT Id FROM Case WHERE ContactId = :contact.Id]),
                new CaseQuery().byContactId(contact.Id).getList());
    }
}