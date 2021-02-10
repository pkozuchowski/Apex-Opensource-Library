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
public abstract class TestDataSuite {
    public abstract void registerRecord(String uniqueName, SObject record);
    public abstract Id getId(SObjectType type, String uniqueName);

    private static Manager suitesManager = new Manager();

    public static TestDataSuite registerSuite(String uniqueName) {
        TestDataSuite suite = new TestDataSuiteImpl();
        suitesManager.registerSuite(uniqueName, suite);

        return suite;
    }

    public static TestDataSuite getSuite(String uniqueName) {
        return suitesManager.getSuite(uniqueName);
    }

    public static void saveSuites() {
        suitesManager.saveSuites();
    }


    private class TestDataSuiteImpl extends TestDataSuite {
        private Map<String, Id> recordIdsByUniqueName = new Map<String, Id>();
        private Map<String, SObject> recordsByUniqueName = new Map<String, SObject>();

        public override void registerRecord(String uniqueName, SObject record) {
            String key = '' + record.getSObjectType() + '_' + uniqueName;
            recordsByUniqueName.put(key, record);
        }

        public override Id getId(SObjectType type, String uniqueName) {
            String key = '' + type + '_' + uniqueName;
            return recordIdsByUniqueName.get(key);
        }

        private void resolveIds() {
            for (String key : recordsByUniqueName.keySet()) {
                SObject record = recordsByUniqueName.get(key);

                if (String.isEmpty(record.Id)) {
                    throw new TestDataSuiteException('Suite cannot be saved until all records are inserted.');
                }

                recordIdsByUniqueName.put(key, record.Id);
            }
        }
    }


    private class Manager {
        private String uniqueName;
        private Map<String, TestDataSuite> suitesByName;

        private Manager() {
            this.uniqueName = 'TestSuites_' + Runtime.getCaller();
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
                ((TestDataSuiteImpl) testDataSuite).resolveIds();
            }

            ContentVersion resource = new ContentVersion(
                    Title = this.uniqueName,
                    VersionData = Blob.valueOf(JSON.serialize(suitesByName)),
                    PathOnClient = 'testSuite.json'
            );
            insert resource;
        }

        private Map<String, TestDataSuite> getTestDataSuiteMap() {
            String body = [
                    SELECT VersionData
                    FROM ContentVersion
                    WHERE Title = :uniqueName
            ]?.VersionData?.toString();

            if (String.isNotEmpty(body)) {
                return (Map<String, TestDataSuite>) JSON.deserialize(body, Map<String, TestDataSuiteImpl>.class);
            } else {
                return new Map<String, TestDataSuite>();
            }
        }
    }

    public class TestDataSuiteException extends Exception {}
}