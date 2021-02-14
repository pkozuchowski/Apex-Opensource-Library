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
 */
public abstract class TestDataSuite {
    private Map<String, SObjectId> sobjectIdByUniqueName = new Map<String, SObjectId>();
    private Map<String, SObjectId[]> sobjectIdsBySObjectType = new Map<String, SObjectId[]>();
    private Map<String, SObjectId[]> sobjectIdsByGroup = new Map<String, SObjectId[]>();


    /**
     * Suite should be created through TestDataSuite.registerSuite()
     */
    protected TestDataSuite() {}


    /**
     * Registers record in test data suite by unique name.
     * Record Id can be later retrieved in unit test using getId() method.
     */
    public void registerRecords(SObjectField field, SObject[] records) {
        for (SObject record : records) {
            registerRecord('' + record.get(field), record);
        }
    }

    /**
     * Registers record in test data suite by unique name.
     * Record Id can be later retrieved in unit test using getId() method.
     */
    public void registerRecord(String uniqueName, SObject record) {
        sobjectIdByUniqueName.put(uniqueName, new SObjectId(record));
        registerRecordUnderObject(record);
    }

    /**
     * Registers record in test data suite by group.
     * Record Ids can be later retrieved in unit test using getRecords() method.
     */
    public void registerRecordsUnderGroup(String groupName, SObject[] records) {
        if (!sobjectIdsByGroup.containsKey(groupName)) {
            sobjectIdsByGroup.put(groupName, new List<SObjectId>());
        }

        List<SObjectId> groupOfRecords = sobjectIdsByGroup.get(groupName);
        for (SObject record : records) {
            groupOfRecords.add(new SObjectId(record));
            registerRecordUnderObject(record);
        }

        sobjectIdsByGroup.put(groupName, groupOfRecords);
    }


    /**
     * @return Id of record registered in the test data suite under give unique name.
     */
    public Id getId(String uniqueName) {
        return sobjectIdByUniqueName.get(uniqueName)?.id;
    }

    /**
     * @return Ids of all records of given SObjectType in suite.
     */
    public Set<Id> getIds(SObjectType type) {
        Set<Id> ids = new Set<Id>();
        String typeName = '' + type;

        if (sobjectIdsBySObjectType.containsKey(typeName)) {
            for (SObjectId recordId : sobjectIdsBySObjectType.get(typeName)) {
                ids.add(recordId.id);
            }
        }

        return ids;
    }

    /**
     * @return Ids of all records registered in given group.
     * Respects order in which records were added to the group.
     */
    public List<Id> getIdsUnderGroup(String groupName) {
        List<Id> ids = new List<Id>();

        if (sobjectIdsByGroup.containsKey(groupName)) {
            for (SObjectId recordId : sobjectIdsByGroup.get(groupName)) {
                ids.add(recordId.id);
            }
        }

        return ids;
    }


    /**
     * Registers record under SObject group
     */
    private void registerRecordUnderObject(SObject record) {
        TestDataSuite.SObjectId sObjectId = new SObjectId(record);
        String key = '' + record.getSObjectType();

        if (sobjectIdsBySObjectType.containsKey(key)) {
            sobjectIdsBySObjectType.get(key).add(sObjectId);

        } else {
            sobjectIdsBySObjectType.put(key, new List<SObjectId>{sObjectId});
        }
    }

    /**
     * Helper SObject wrapper which is saved as Id during JSON serialization.
     */
    private class SObjectId {
        public Id id {
            get {
                if (record != null) {
                    return record.Id;
                } else {
                    return id;
                }
            }
            set;
        }
        private transient SObject record;

        public SObjectId(SObject record) {
            this.record = record;
        }
    }

    public class TestDataSuiteException extends Exception {}
}