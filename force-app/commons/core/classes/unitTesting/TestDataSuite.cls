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

/**
 * Suite of test data which reassembles static map, but is persisted between test setup and test methods.
 * Developer can use this to create several different test suites in single @TestSetup and later retrieve ids of
 * records in particular test suite using unique name assigned to the record.
 *
 * The example usage of this class are Trigger Handler tests with many different scenarios,
 * where we want to create all data in @TestSetup, but at the same time we want to segregate data into suites for different scenarios.
 *
 * This is best used with UnitOfWork pattern to save DMLs.
 */
@IsTest
public class TestDataSuite {
    private static Manager suitesManager = new Manager();

    private Map<String, Id> recordIdsByUniqueName = new Map<String, Id>();
    private Map<String, SObject> recordsByUniqueName = new Map<String, SObject>();


    /**
     * Factory Method that creates TestDataSuite and registers it internally.
     * This method should be called in @TestSetup to create suite of data.
     */
    public static TestDataSuite registerSuite(String uniqueName) {
        TestDataSuite suite = new TestDataSuite();
        suitesManager.registerSuite(uniqueName, suite);

        return suite;
    }

    /**
     * This method persists TestDataSuites creates in @TestSetup.
     * It should be called at the end of @TestSetup when all test data is already inserted.
     */
    public static void saveSuites() {
        suitesManager.saveSuites();
    }

    /**
     * @return Retrieves previously creates Data Suite by it's unique name.
     * This method should be called in test methods.
     */
    public static TestDataSuite getSuite(String uniqueName) {
        return suitesManager.getSuite(uniqueName);
    }


    /**
     * Suite should be created through TestDataSuite.registerSuite()
     */
    private TestDataSuite() {}

    /**
     * Registers record in test data suite by unique name.
     * Record Id can be later retrieved in unit test using getId() method.
     */
    public void registerRecord(String uniqueName, SObject record) {
        recordsByUniqueName.put(uniqueName, record);
    }

    /**
     * Registers record in test data suite by unique name.
     * Record Id can be later retrieved in unit test using getId() method.
     */
    public void registerRecords(SObjectField field, SObject[] records) {
        for (SObject record : records) {
            String key = '' + record.get(field);
            recordsByUniqueName.put(key, record);
        }
    }

    /**
     * @return Id of record registered in the test data suite under give unique name.
     */
    public Id getId(String uniqueName) {
        return recordIdsByUniqueName.get(uniqueName);
    }

    /**
     * @return Ids of all records of given SObjectType in suite.
     */
    public Set<Id> getIds(SObjectType type) {
        Set<Id> ids = new Set<Id>();

        for (Id recordId : recordIdsByUniqueName.values()) {
            if (recordId.getSobjectType() == type) {
                ids.add(recordId);
            }
        }

        return ids;
    }

    
    /**
     * Resolves ids of records for persisting after everything is inserted in @TestSetup
     */
    private void resolveIds() {
        for (String key : recordsByUniqueName.keySet()) {
            SObject record = recordsByUniqueName.get(key);

            if (String.isEmpty(record.Id)) {
                throw new TestDataSuiteException('Suite cannot be saved until all records are inserted.');
            }

            recordIdsByUniqueName.put(key, record.Id);
        }
    }


    /**
     * Manages and persistence of collection of data suites
     */
    private class Manager {
        private Map<String, TestDataSuite> suitesByName;

        private Manager() {
            this.suitesByName = getTestDataSuiteMap();
        }

        public TestDataSuite getSuite(String name) {
            if (suitesByName.containsKey(name)) {
                return suitesByName.get(name);

            } else {
                throw new TestDataSuiteException('Test Data Suite with this name does not exist: ' + name);
            }
        }

        public void registerSuite(String uniqueName, TestDataSuite instance) {
            suitesByName.put(uniqueName, instance);
        }

        public void saveSuites() {
            for (TestDataSuite testDataSuite : suitesByName.values()) {
                testDataSuite.resolveIds();
            }

            ContentVersion resource = new ContentVersion(
                    Title = 'TestDataSuite',
                    VersionData = Blob.valueOf(JSON.serialize(suitesByName)),
                    PathOnClient = 'testSuite.json'
            );
            insert resource;
        }

        private Map<String, TestDataSuite> getTestDataSuiteMap() {
            String body = [
                    SELECT VersionData
                    FROM ContentVersion
                    WHERE Title = 'TestDataSuite'
            ]?.VersionData?.toString();

            if (String.isNotEmpty(body)) {
                return (Map<String, TestDataSuite>) JSON.deserialize(body, Map<String, TestDataSuite>.class);
            } else {
                return new Map<String, TestDataSuite>();
            }
        }
    }

    public class TestDataSuiteException extends Exception {}
}