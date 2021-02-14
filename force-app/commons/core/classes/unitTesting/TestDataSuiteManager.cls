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
 * Manages and persistence of collection of test data suites
 */
public inherited sharing class TestDataSuiteManager {
    private final static String FILE_NAME = 'TestDataSuite';
    private final static Map<String, TestDataSuite> suitesToSave = new Map<String, TestDataSuite>();
    private final static Map<String, TestDataSuite> suitesByName {
        get {
            if (suitesByName == null) {
                suitesByName = getTestDataSuiteMap();
            }

            return suitesByName;
        }
        set;
    }


    /**
     * Factory Method that creates TestDataSuite and registers it internally.
     * This method should be called in @TestSetup to create suite of data.
     */
    public static TestDataSuite registerSuite(String uniqueName) {
        TestDataSuite suite = new TestDataSuiteImpl();
        suitesToSave.put(uniqueName, suite);

        return suite;
    }

    /**
     * @return Retrieves previously creates Data Suite by it's unique name.
     * This method should be called in test methods.
     */
    public static TestDataSuite getSuite(String uniqueName) {
        if (suitesByName.containsKey(uniqueName)) {
            return suitesByName.get(uniqueName);

        } else {
            throw new TestDataSuite.TestDataSuiteException('Test Data Suite with this name does not exist: ' + uniqueName);
        }
    }

    /**
     * This method persists TestDataSuites creates in @TestSetup.
     * It should be called at the end of @TestSetup when all test data is already inserted.
     */
    public static void saveSuites() {
        ContentVersion resource = new ContentVersion(
                Title = FILE_NAME,
                VersionData = Blob.valueOf(JSON.serialize(suitesToSave)),
                PathOnClient = 'testSuite.json'
        );
        insert resource;
    }

    /**
     * Persists TestDataSuites in ContentVersion to store the context in-between TestSetup and Tests
     */
    private static Map<String, TestDataSuite> getTestDataSuiteMap() {
        String body = [
                SELECT VersionData
                FROM ContentVersion
                WHERE Title = :FILE_NAME
        ]?.VersionData?.toString();

        if (String.isNotEmpty(body)) {
            return (Map<String, TestDataSuite>) JSON.deserialize(body, Map<String, TestDataSuiteImpl>.class);
        } else {
            return new Map<String, TestDataSuite>();
        }
    }

    /**
     * Friendly constructor to limit construction of TestDataSuites to Manager alone
     */
    private class TestDataSuiteImpl extends TestDataSuite {}
    private TestDataSuiteManager() {}
}