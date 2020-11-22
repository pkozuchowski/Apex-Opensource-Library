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
private class OpportunityQueryTest {

    @TestSetup
    static void testSetup() {
        Account account = new Account(Name = 'Parent Account');
        insert account;

        insert new List<Opportunity>{
                new Opportunity(AccountId = account.Id, Name = 'Name 1', CloseDate = Date.today(), StageName = 'Prospecting'),
                new Opportunity(AccountId = account.Id, Name = 'Name 2', CloseDate = Date.today(), StageName = 'Prospecting'),
                new Opportunity(AccountId = account.Id, Name = 'Name 3', CloseDate = Date.today(), StageName = 'Prospecting')
        };
    }

    @IsTest
    static void testSelectWithParentAccount() {
        Opportunity opp = (Opportunity) new OpportunityQuery()
                .withParentAccount()
                .byName(new Set<String>{'Name 1'})
                .getFirstOrNull();

        System.assertEquals('Parent Account', opp.Account.Name);
    }

    @IsTest
    static void testSelectByName() {
        QueryObjectTest.assertEquals(
                ([SELECT Id FROM Opportunity WHERE Name = 'Name 1']),
                new OpportunityQuery().byName('Name 1').getList());
    }

    @IsTest
    static void testSelectByAccountId() {
        Account account = [SELECT Id FROM Account];

        QueryObjectTest.assertEquals(
                ([SELECT Id FROM Opportunity WHERE AccountId = :account.Id]),
                new OpportunityQuery().byAccountId(account.Id).getList());
    }
}