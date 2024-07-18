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
@IsTest(IsParallel=false)
private class TestDataSuiteTest {

    @TestSetup
    static void testSetup() {
        List<Account> accounts = new List<Account>{
            new Account(Id='001000000000001', Name = '1'),
            new Account(Id='001000000000002', Name = '2')
        };

        List<Case> cases = new List<Case>{
            new Case(Subject = 'Case 1', AccountId = accounts[0].Id),
            new Case(Subject = 'Case 2', AccountId = accounts[0].Id),
            new Case(Subject = 'Case 3', AccountId = accounts[0].Id)
        };

        List<Contact> contacts = new List<Contact>{
            new Contact(LastName = 'Doe1', AccountId = accounts[0].Id),
            new Contact(LastName = 'Doe2', AccountId = accounts[0].Id),
            new Contact(LastName = 'Doe3', AccountId = accounts[0].Id),
            new Contact(LastName = 'Doe4', AccountId = accounts[0].Id)
        };

        TestDataSuite suite1 = TestDataSuiteManager.registerSuite('Account with related');
        suite1.registerRecord('Account', accounts[0]);
        suite1.registerRecords(Case.Subject, cases);
        suite1.registerRecordsUnderGroup('Contacts to process', new List<Contact>{contacts[0], contacts[1]});
        suite1.registerRecordsUnderGroup('Contacts to remove', new List<Contact>{contacts[2], contacts[3]});

        TestDataSuite suite2 = TestDataSuiteManager.registerSuite('Account without related');
        suite2.registerRecord('Account', accounts[1]);

        TestDataSuiteManager.saveSuites();
    }


    /**
     * @description
     * TestDataSuite.get() should retrieve record registered in that suite or null if no record was registered by that name;
     */
    @IsTest
    static void shouldRetrieveRecordIdByUniqueName() {
        TestDataSuite suite = TestDataSuiteManager.getSuite('Account with related');
        System.assertEquals(null, suite.get('Other'), 'Should return null if unique name was not registered');

        Account account = (Account) suite.get('Account');
        System.assertEquals('1', account.Name, 'Should retrieve Account registered under "Account" name');
    }


    /**
     * @description
     * TestDataSuite.getIdsUnderGroup() should retrieve ids of records registered under given group.
     * The order in which records were registered is persisted.
     * If group was not registered, empty list is returned.
     */
    @IsTest
    static void shouldRetrieveRecordsByGroupName() {
        TestDataSuite suite = TestDataSuiteManager.getSuite('Account with related');

        System.assertEquals(true, suite.getGroup('other').isEmpty(), 'Should return empty list for unregistered group');
        System.assertEquals(2, suite.getGroup('Contacts to process').size(), 'Should return ids of records registered under group');
    }


    /**
     * @description
     * TestDataSuite.getIds(SObjectType) should retrieve ids of registered records (under unique name or group) with given SObjectType.
     * Order of returned ids is not guaranteed (Set).
     */
    @IsTest
    static void shouldRetrieveSObjectName() {
        TestDataSuite suite = TestDataSuiteManager.getSuite('Account with related');

        System.assertEquals(true, suite.get(User.SObjectType).isEmpty(), 'Should return empty list if no records of given SObject Type were registered');
        System.assertEquals(1, suite.get(Account.SObjectType).size(), 'Should return all records of given SObjectType registered under group');
    }


    /**
     * @description
     * TestDataSuiteManager.getSuite() should throw exception, if no suite was registered under that name.
     */
    @IsTest
    static void shouldThrowErrorWhenSuiteIsNotRegister() {
        delete [SELECT Id FROM ContentDocument WHERE Title = :TestDataSuiteManager.FILE_NAME];
        Exception ex;

        try {
            TestDataSuiteManager.getSuite('other');
        } catch (TestDataSuite.TestDataSuiteException e) {
            ex = e;
        }

        System.assertNotEquals(null, ex, 'Should throw exception, when suite was not registered in TestSetup');
    }
}