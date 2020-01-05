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
private without sharing class AccountSelectorTest {

    @TestSetup
    static void testSetup() {
        List<Account> accounts = new List<Account>{
                new Account(Name = 'Name 0'),
                new Account(Name = 'Name 1'),
                new Account(Name = 'Name 2'),
                new Account(Name = 'Name 3')
        };
        insert accounts;

        Account account = new Account(ParentId = accounts[0].Id, Name = 'Test Child Account');
        insert account;

        insert new Contact(AccountId = account.Id, LastName = 'Test Contact');
        insert new Case(AccountId = account.Id, Subject = 'Test Case');
        insert new Opportunity(AccountId = account.Id, Name = 'Test Opportunity', CloseDate = Date.today(), StageName = 'Prospecting');
    }

    @IsTest
    static void testSelectByName() {
        SelectorTest.assertEquals(
                ([SELECT Id FROM Account WHERE Name = 'Name 1']),
                new AccountSelector().byName('Name 1'));

        SelectorTest.assertEquals(
                ([SELECT Id FROM Account WHERE Name IN ('Name 1', 'Name 2')]),
                new AccountSelector().byName(new List<String>{'Name 1', 'Name 2'}));
    }

    @IsTest
    static void testSelectWithRelated() {
        Account expected = [
                SELECT Id,Name, (SELECT Id FROM Contacts), (SELECT Id FROM Cases), (SELECT Id FROM Opportunities), (SELECT Id FROM ChildAccounts),
                        Parent.Name
                FROM Account
                WHERE Name = 'Test Child Account'
        ];

        Account actual = new AccountSelector()
                .withParentAccount()
                .withChildrenAccounts()
                .withContacts()
                .withCases()
                .withOpportunities()
                .byName(expected.Name)[0];

        System.assertEquals(expected.Id, actual.Id);
        System.assertEquals(expected.Parent.Name, actual.Parent.Name);
        System.assertEquals(expected.ChildAccounts.size(), actual.ChildAccounts.size());
        System.assertEquals(expected.Contacts.size(), actual.Contacts.size());
        System.assertEquals(expected.Cases.size(), actual.Cases.size());
        System.assertEquals(expected.Opportunities.size(), actual.Opportunities.size());
    }
}