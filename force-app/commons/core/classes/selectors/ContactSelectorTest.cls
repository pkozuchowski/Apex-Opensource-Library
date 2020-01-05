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
private class ContactSelectorTest {

    @TestSetup
    static void testSetup() {
        Account account = new Account(Name = 'Parent Account');
        insert account;

        insert new List<Contact>{
                new Contact(AccountId = account.Id, LastName = 'Name 1', Email = '1@example.com'),
                new Contact(AccountId = account.Id, LastName = 'Name 2', Email = '2@example.com'),
                new Contact(AccountId = account.Id, LastName = 'Name 3', Email = '3@example.com')
        };
    }

    @IsTest
    static void testSelectWithParentAccount() {
        System.assertEquals('Parent Account',
                new ContactSelector()
                        .withParentAccount()
                        .byName(new List<String>{'Name 1'})[0]
                        .Account.Name
        );
    }

    @IsTest
    static void testSelectByName() {
        SelectorTest.assertEquals(
                ([SELECT Id FROM Contact WHERE Name = 'Name 1']),
                new ContactSelector().byName('Name 1'));

        SelectorTest.assertEquals(
                ([SELECT Id FROM Contact WHERE Name IN ('Name 1', 'Name 2')]),
                new ContactSelector().byName(new List<String>{'Name 1', 'Name 2'}));
    }

    @IsTest
    static void testSelectByEmail() {
        SelectorTest.assertEquals(
                ([SELECT Id FROM Contact WHERE Email = '1@example.com']),
                new ContactSelector().byEmail('1@example.com'));

        SelectorTest.assertEquals(
                ([SELECT Id FROM Contact WHERE Email IN ('1@example.com', '2@example.com')]),
                new ContactSelector().byEmail(new List<String>{'1@example.com', '2@example.com'}));
    }

    @IsTest
    static void testSelectByAccountId() {
        Account account = [SELECT Id FROM Account];

        SelectorTest.assertEquals(
                ([SELECT Id FROM Contact WHERE AccountId = :account.Id]),
                new ContactSelector().byAccountId(account.Id));

        SelectorTest.assertEquals(
                ([SELECT Id FROM Contact WHERE AccountId IN (:account.Id)]),
                new ContactSelector().byAccountId(new List<Id>{account.Id}));
    }
}