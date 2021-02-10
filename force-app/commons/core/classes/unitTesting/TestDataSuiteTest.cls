/**
* MIT License
*
* Copyright (c) 2021 Piotr Kożuchowski
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
private class TestDataSuiteTest {

    /**
     * This is very primitive implementation to showcase suites.
     * Consider using UnitOfWork pattern to save DML statements between many suites.
     */
    @TestSetup
    static void testSetup() {
        TestDataBuilder dataBuilder = new TestDataBuilder();

        List<Account> accounts = dataBuilder
                .create(new Account(Name = '1'))
                .create(new Account(Name = '2'))
                .insertRecords();

        Case[] cases = (Case[]) dataBuilder
                .create(new Case(Subject = 'Case 1', AccountId = accounts[0].Id))
                .similarly(new Case(Subject = 'Case 2'))
                .similarly(new Case(Subject = 'Case 3'))
                .insertRecords();


        TestDataSuite suite1 = TestDataSuite.registerSuite('Account with related');
        suite1.registerRecord('Account', accounts[0]);
        suite1.registerRecords(Case.Subject, cases);

        TestDataSuite suite2 = TestDataSuite.registerSuite('Account without related');
        suite2.registerRecord('Account', accounts[1]);

        TestDataSuite.saveSuites();
    }


    @IsTest
    static void testSuiteWithRelated() {
        TestDataSuite suite = TestDataSuite.getSuite('Account with related');

        Account acc = [SELECT Id, Name FROM Account WHERE Id = :suite.getId('Account')];
        System.assertEquals('1', acc.Name);
        System.assertEquals(1, suite.getIds(Account.SObjectType).size());

        Set<Id> caseIds = suite.getIds(Case.SObjectType);
        System.assertEquals(3, caseIds.size());

        System.assertNotEquals(null, suite.getId('Case 1'));
        System.assertNotEquals(null, suite.getId('Case 2'));
        System.assertNotEquals(null, suite.getId('Case 3'));
    }

    @IsTest
    static void testSuiteWithoutRelated() {
        TestDataSuite suite = TestDataSuite.getSuite('Account without related');

        Account acc = [SELECT Id, Name FROM Account WHERE Id = :suite.getId('Account')];
        System.assertEquals('2', acc.Name);
        System.assertEquals(1, suite.getIds(Account.SObjectType).size());

        Set<Id> caseIds = suite.getIds(Case.SObjectType);
        System.assertEquals(0, caseIds.size());
    }
}