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

        Contact[] contacts = (Contact[]) dataBuilder
                .create(new Contact(FirstName = 'Joe', LastName = 'Doe1', AccountId = accounts[0].Id))
                .similarly(new Contact(LastName = 'Doe2'))
                .similarly(new Contact(LastName = 'Doe3'))
                .similarly(new Contact(LastName = 'Doe4'))
                .insertRecords();


        TestDataSuite suite1 = TestDataSuiteManager.registerSuite('Account with related');
        suite1.registerRecord('Account', accounts[0]);
        suite1.registerRecords(Case.Subject, cases);
        suite1.registerRecordsUnderGroup('Contacts to process', (Contact[]) Collection.of(contacts).slice(0, 1).get());
        suite1.registerRecordsUnderGroup('Contacts to remove', (Contact[]) Collection.of(contacts).slice(2, 3).get());

        TestDataSuite suite2 = TestDataSuiteManager.registerSuite('Account without related');
        suite2.registerRecord('Account', accounts[1]);

        TestDataSuiteManager.saveSuites();
    }


    /**
     *@description
     * TestDataSuite.getId() should retrieve Id of record registered in that suite or null if no record was registered by that name;
     */
    @IsTest
    static void shouldRetrieveRecordIdByUniqueName() {
        TestDataSuite suite = TestDataSuiteManager.getSuite('Account with related');
        System.assertEquals(null, suite.getId('Other'), 'Should return null if unique name was not registered');

        Id accountId = suite.getId('Account');
        System.assert(accountId != null && accountId.getSobjectType() == Account.SObjectType, 'Should retrieve Id of account registered under "Account" name');
    }


    /**
     *@description
     * TestDataSuite.getIdsUnderGroup() should retrieve ids of records registered under given group.
     * The order in which records were registered is persisted.
     * If group was not registered, empty list is returned.
     */
    @IsTest
    static void shouldRetrieveIdsByGroupName() {
        TestDataSuite suite = TestDataSuiteManager.getSuite('Account with related');

        System.assertEquals(true, suite.getIdsUnderGroup('other').isEmpty(), 'Should return empty list for unregistered group');
        System.assertEquals(2, suite.getIdsUnderGroup('Contacts to process').size(), 'Should return ids of records registered under group');
    }


    /**
     *@description
     * TestDataSuite.getIds(SObjectType) should retrieve ids of registered records (under unique name or group) with given SObjectType.
     * Order of returned ids is not guaranteed (Set).
     */
    @IsTest
    static void shouldRetrieveIdsBySObjectName() {
        TestDataSuite suite = TestDataSuiteManager.getSuite('Account with related');

        System.assertEquals(true, suite.getIds(User.SObjectType).isEmpty(), 'Should return empty list if no records of given SObject Type were registered');
        System.assertEquals(1, suite.getIds(Account.SObjectType).size(), 'Should return all records of given SObjectType registered under group');
    }


    /**
     *@description
     * TestDataSuiteManager.getSuite() should throw exception, if no suite was registered under that name.
     */
    @IsTest
    static void shouldThrowErrorWhenSuiteIsNotRegister() {
        Exception ex;

        try {
            TestDataSuiteManager.getSuite('other');
        } catch (TestDataSuite.TestDataSuiteException e) {
            ex = e;
        }

        System.assertNotEquals(null, ex, 'Should throw exception, when suite was not registered in TestSetup');
    }
}