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
    private Map<String, SObject> sobjectByUniqueName = new Map<String, SObject>();
    private Map<String, SObject[]> sobjectBySObjectType = new Map<String, SObject[]>();
    private Map<String, SObject[]> sobjectByGroup = new Map<String, SObject[]>();


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
        sobjectByUniqueName.put(uniqueName, record);
        registerRecordUnderObject(record);
    }

    /**
     * Registers record in test data suite by group.
     * Record Ids can be later retrieved in unit test using getRecords() method.
     */
    public void registerRecordsUnderGroup(String groupName, SObject[] records) {
        if (!sobjectByGroup.containsKey(groupName)) {
            sobjectByGroup.put(groupName, new List<SObject>());
        }

        List<SObject> groupOfRecords = sobjectByGroup.get(groupName);
        for (SObject record : records) {
            groupOfRecords.add(record);
            registerRecordUnderObject(record);
        }

        sobjectByGroup.put(groupName, groupOfRecords);
    }


    /**
     * @return Record registered in the test data suite under give unique name.
     */
    public SObject get(String uniqueName) {
        return sobjectByUniqueName.get(uniqueName);
    }

    /**
     * @return All records of given SObjectType in suite.
     */
    public List<SObject> get(SObjectType type) {
        List<SObject> records = new List<SObject>();
        String typeName = '' + type;

        if (sobjectBySObjectType.containsKey(typeName)) {
            for (SObject record : sobjectBySObjectType.get(typeName)) {
                records.add(record);
            }
        }

        return records;
    }

    /**
     * @return All records registered in given group.
     * Respects order in which records were added to the group.
     */
    public List<SObject> getGroup(String groupName) {
        List<SObject> records = new List<SObject>();

        if (sobjectByGroup.containsKey(groupName)) {
            for (SObject record : sobjectByGroup.get(groupName)) {
                records.add(record);
            }
        }

        return records;
    }


    /**
     * Registers record under SObject group
     */
    private void registerRecordUnderObject(SObject record) {
        String key = '' + record.getSObjectType();

        if (sobjectBySObjectType.containsKey(key)) {
            sobjectBySObjectType.get(key).add(record);

        } else {
            sobjectBySObjectType.put(key, new List<SObject>{record});
        }
    }

    public class TestDataSuiteException extends Exception {}
}