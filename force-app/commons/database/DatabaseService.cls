/**
* MIT License
*
* Copyright (c) 2018 Piotr Kożuchowski
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
 * Contains methods for creating and manipulating data with isolated sharing from the
 * client class.
 * @see DatabaseServiceTest
 */
public class DatabaseService {
    private static Integer cnt = 0;
    private Database.DMLOptions dmlOptions = new Database.DMLOptions();
    private AccessLevel level = AccessLevel.SYSTEM_MODE;
    private DMLIssuer dmlIssuer = new InheritedSharingDMLIssuer();

    /**
     * @return Unique fake id for given SObject.
     */
    public static Id getFakeId(SObjectType sObjectType) {
        String keyPrefix = SchemaDescriptions.getSObjectDescribe('' + sObjectType).getKeyPrefix();
        return keyPrefix + ('' + (cnt++)).leftPad(12, '0');
    }


    public DatabaseService() {
        this.dmlOptions.optAllOrNone = true;
    }

    /**
     * Executes DMLs and Quries in With Sharing context
     */
    public DatabaseService withSharing() {
        this.dmlIssuer = new WithSharingDMLIssuer();
        return this;
    }

    /**
     * Executes DMLs and Quries in Without Sharing context
     */
    public DatabaseService withoutSharing() {
        this.dmlIssuer = new WithoutSharingDMLIssuer();
        return this;
    }


    /**
     * SYSTEM_MODE - Execution mode in which the the object and field-level permissions of the current user are ignored,
     * and the record sharing rules are controlled by the class sharing keywords.<br/>
     * USER_MODE - Execution mode in which the object permissions, field-level security, and sharing rules of the current user are enforced.
     */
    public DatabaseService setAccessLevel(AccessLevel level) {
        this.level = level;
        return this;
    }

    public DatabaseMock useMock() {
        DatabaseMock mock = new DatabaseMock();
        this.dmlIssuer = new MockedDmlIssuer(mock);
        return mock;
    }

    /**
     * Sets DML Options to use for DMLs issued with this service.
     */
    public DatabaseService setDMLOptions(Database.DMLOptions options) {
        this.dmlOptions = options;
        return this;
    }

    /**
     * Sets All Or None in DML Options
     */
    public DatabaseService allOrNone(Boolean allOrNone) {
        this.dmlOptions.optAllOrNone = allOrNone;
        return this;
    }


    /**
     * Executes database query
     * @param query Query string (ex. 'SELECT Id FROM Account')
     */
    public List<SObject> query(String query) {
        return query(query, null);
    }

    /**
     * Executes database query with given bound variables
     * @param query Query string (ex. 'SELECT Id FROM Account WHERE Name IN: names')
     * @param boundVars Variables to bind to query ex. {'names' => ['Name 1', 'Name 2']}
     */
    public List<SObject> query(String query, Map<String, Object> boundVars) {
        return dmlIssuer.query(query, boundVars == null ? new Map<String, Object>() : boundVars, level);
    }


    /**
     * @param query Query string (ex. 'SELECT Id FROM Account')
     * @return QueryLocator for given query
     */
    public Database.QueryLocator getQueryLocator(String query) {
        return getQueryLocator(query, null);
    }

    /**
     * @param query Query string (ex. 'SELECT Id FROM Account')
     * @param boundVars Variables to bind to query ex. {'names' => ['Name 1', 'Name 2']}
     * @return QueryLocator for given query and bound variables
     */
    public Database.QueryLocator getQueryLocator(String query, Map<String, Object> boundVars) {
        return dmlIssuer.getQueryLocator(query, boundVars == null ? new Map<String, Object>() : boundVars, level);
    }

    public Database.SaveResult insertRecord(SObject record) {
        return insertRecords(new List<SObject>{record})[0];
    }
    public List<Database.SaveResult> insertRecords(List<SObject> records) {
        return dmlIssuer.insertRecords(records, dmlOptions, level);
    }


    public Database.SaveResult updateRecord(SObject record) {
        return updateRecords(new List<SObject>{record})[0];
    }
    public List<Database.SaveResult> updateRecords(List<SObject> records) {
        return dmlIssuer.updateRecords(records, dmlOptions, level);
    }


    public Database.UpsertResult upsertRecord(SObject record, SObjectField field) {
        return upsertRecords(nonGenericSObjectList(record), field)[0];
    }
    public List<Database.UpsertResult> upsertRecords(List<SObject> records, SObjectField field) {
        return dmlIssuer.upsertRecords(records, field, dmlOptions?.optAllOrNone == true, level);
    }


    public Database.DeleteResult deleteRecord(SObject record) {
        return deleteRecords(new List<SObject>{record})[0];
    }

    public List<Database.DeleteResult> deleteRecords(List<SObject> records) {
        return dmlIssuer.deleteRecords(records, isAllOrNone(), level);
    }


    public Database.UndeleteResult undeleteRecord(SObject record) {
        return undeleteRecords(new List<SObject>{record})[0];
    }

    public List<Database.UndeleteResult> undeleteRecords(List<SObject> records) {
        return dmlIssuer.undeleteRecords(records, isAllOrNone(), level);
    }


    /**
     * Upsert will not work on generic List<SObject>, it requires concrete type.
     */
    private List<SObject> nonGenericSObjectList(SObject record) {
        List<SObject> records = (List<SObject>) Type.forName('List<' + record.getSObjectType() + '>')
            .newInstance();
        records.add(record);
        return records;
    }

    private Boolean isAllOrNone() {
        return dmlOptions.optAllOrNone == null ? true : dmlOptions.optAllOrNone;
    }


    /**
    * Interface for classes that will handle DML operations
    * */
    public interface DMLIssuer {
        List<Database.SaveResult> insertRecords(List<SObject> records, Database.DMLOptions options, AccessLevel accessLevel);
        List<Database.SaveResult> updateRecords(List<SObject> records, Database.DMLOptions options, AccessLevel accessLevel);
        List<Database.UpsertResult> upsertRecords(List<SObject> records, SObjectField field, Boolean allOrNone, AccessLevel accessLevel);
        List<Database.DeleteResult> deleteRecords(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel);
        List<Database.UndeleteResult> undeleteRecords(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel);
        List<SObject> query(String query, Map<String, Object> boundVars, AccessLevel accessLevel);
        Database.QueryLocator getQueryLocator(String query, Map<String, Object> boundVars, AccessLevel accessLevel);
    }

    /**
    * Issues DMLs with sharing
    * */
    private with sharing class WithSharingDMLIssuer implements DMLIssuer {
        private InheritedSharingDMLIssuer inheritedIssuer = new InheritedSharingDMLIssuer();

        public List<Database.SaveResult> insertRecords(List<SObject> records, Database.DMLOptions options, AccessLevel accessLevel) {
            return Database.insert(records, options, accessLevel);
        }
        public List<Database.SaveResult> updateRecords(List<SObject> records, Database.DMLOptions options, AccessLevel accessLevel) {
            return Database.update(records, options, accessLevel);
        }
        public List<Database.UpsertResult> upsertRecords(List<SObject> records, SObjectField field, Boolean allOrNone, AccessLevel accessLevel) {
            return Database.upsert(records, field, allOrNone, accessLevel);
        }
        public List<Database.DeleteResult> deleteRecords(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel) {
            return Database.delete(records, allOrNone, accessLevel);
        }
        public List<Database.UndeleteResult> undeleteRecords(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel) {
            return Database.undelete(records, allOrNone, accessLevel);
        }
        public List<SObject> query(String query, Map<String, Object> boundVars, AccessLevel accessLevel) {
            return Database.queryWithBinds(query, boundVars, accessLevel);
        }
        public Database.QueryLocator getQueryLocator(String query, Map<String, Object> boundVars, AccessLevel accessLevel) {
            return Database.getQueryLocatorWithBinds(query, boundVars, accessLevel);
        }
    }


    /**
    * Issues DMLs without sharing
    * */
    private without sharing class WithoutSharingDMLIssuer implements DMLIssuer {
        private InheritedSharingDMLIssuer issuer = new InheritedSharingDMLIssuer();

        public List<Database.SaveResult> insertRecords(List<SObject> records, Database.DMLOptions options, AccessLevel accessLevel) {
            return Database.insert(records, options, accessLevel);
        }
        public List<Database.SaveResult> updateRecords(List<SObject> records, Database.DMLOptions options, AccessLevel accessLevel) {
            return Database.update(records, options, accessLevel);
        }
        public List<Database.UpsertResult> upsertRecords(List<SObject> records, SObjectField field, Boolean allOrNone, AccessLevel accessLevel) {
            return Database.upsert(records, field, allOrNone, accessLevel);
        }
        public List<Database.DeleteResult> deleteRecords(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel) {
            return Database.delete(records, allOrNone, accessLevel);
        }
        public List<Database.UndeleteResult> undeleteRecords(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel) {
            return Database.undelete(records, allOrNone, accessLevel);
        }
        public List<SObject> query(String query, Map<String, Object> boundVars, AccessLevel accessLevel) {
            return Database.queryWithBinds(query, boundVars, accessLevel);
        }
        public Database.QueryLocator getQueryLocator(String query, Map<String, Object> boundVars, AccessLevel accessLevel) {
            return Database.getQueryLocatorWithBinds(query, boundVars, accessLevel);
        }
    }


    /**
    * Issues DMLs with inherited sharing
    * */
    private inherited sharing class InheritedSharingDMLIssuer implements DMLIssuer {
        public List<Database.SaveResult> insertRecords(List<SObject> records, Database.DMLOptions options, AccessLevel accessLevel) {
            return Database.insert(records, options, accessLevel);
        }
        public List<Database.SaveResult> updateRecords(List<SObject> records, Database.DMLOptions options, AccessLevel accessLevel) {
            return Database.update(records, options, accessLevel);
        }
        public List<Database.UpsertResult> upsertRecords(List<SObject> records, SObjectField field, Boolean allOrNone, AccessLevel accessLevel) {
            return Database.upsert(records, field, allOrNone, accessLevel);
        }
        public List<Database.DeleteResult> deleteRecords(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel) {
            return Database.delete(records, allOrNone, accessLevel);
        }
        public List<Database.UndeleteResult> undeleteRecords(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel) {
            return Database.undelete(records, allOrNone, accessLevel);
        }
        public List<SObject> query(String query, Map<String, Object> boundVars, AccessLevel accessLevel) {
            return Database.queryWithBinds(query, boundVars, accessLevel);
        }
        public Database.QueryLocator getQueryLocator(String query, Map<String, Object> boundVars, AccessLevel accessLevel) {
            return Database.getQueryLocatorWithBinds(query, boundVars, accessLevel);
        }
    }


    /**
     * Mocks all DML operations and saves them in DatabaseMock instance.
     * Queries are not mocked.
     */
    private class MockedDmlIssuer implements DMLIssuer {
        private final DatabaseMock mock;

        private MockedDmlIssuer(DatabaseMock mock) {
            this.mock = mock;
        }

        public List<Database.SaveResult> insertRecords(List<SObject> records, Database.DMLOptions options, AccessLevel accessLevel) {
            return (List<Database.SaveResult>) doMockedDML(
                DmlType.INSERT_DML, records, options.optAllOrNone, mock.insertedRecords, List<Database.SaveResult>.class
            );
        }

        public List<Database.SaveResult> updateRecords(List<SObject> records, Database.DMLOptions options, AccessLevel accessLevel) {
            return (List<Database.SaveResult>) doMockedDML(
                DmlType.UPDATE_DML, records, options.optAllOrNone, mock.updatedRecords, List<Database.SaveResult>.class
            );
        }

        public List<Database.UpsertResult> upsertRecords(List<SObject> records, SObjectField field, Boolean allOrNone, AccessLevel accessLevel) {
            return (List<Database.UpsertResult>) doMockedDML(
                DmlType.UPSERT_DML, records, allOrNone, mock.upsertedRecords, List<Database.UpsertResult>.class
            );
        }

        public List<Database.DeleteResult> deleteRecords(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel) {
            return (List<Database.DeleteResult>) doMockedDML(
                DmlType.DELETE_DML, records, allOrNone, mock.deletedRecords, List<Database.DeleteResult>.class
            );
        }

        public List<Database.UndeleteResult> undeleteRecords(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel) {
            return (List<Database.UndeleteResult>) doMockedDML(
                DmlType.UNDELETE_DML, records, allOrNone, mock.undeletedRecords, List<Database.UndeleteResult>.class
            );
        }

        public List<SObject> query(String query, Map<String, Object> boundVars, AccessLevel accessLevel) {
            return Database.queryWithBinds(query, boundVars, accessLevel);
        }

        public Database.QueryLocator getQueryLocator(String query, Map<String, Object> boundVars, AccessLevel accessLevel) {
            return Database.getQueryLocatorWithBinds(query, boundVars, accessLevel);
        }

        private Object doMockedDML(DmlType dmlType, List<SObject> records, Boolean allOrNone, List<SObject> targetList, Type resultType) {
            List<DmlResult> results = new List<DmlResult>();

            for (SObject record : records) {
                if (String.isBlank(record.Id)) {
                    record.Id = DatabaseService.getFakeId(record.getSObjectType());
                }

                List<DatabaseService.DmlError> dmlErrors = mock.getDMLErrors(dmlType, record);
                DmlResult dmlResult = new DmlResult(record.Id, dmlErrors);

                if (!dmlResult.success && allOrNone == true) {
                    throw new DmlException(dmlResult.errors?.get(0)?.message);
                }

                results.add(dmlResult);
                targetList.add(record);
            }

            return getResult(results, resultType);
        }

        /**
         * Changes run-type of DmlResult into one of standard Database.*Result classes.
         */
        private Object getResult(List<DmlResult> results, Type resultType) {
            return JSON.deserialize(JSON.serialize(results), resultType);
        }
    }

    private class DmlResult {
        public Boolean success;
        public Id id;
        public List<DmlError> errors = new List<DmlError>();

        public DmlResult(Id id, List<DmlError> errors) {
            this.id = id;
            this.errors = errors;
            this.success = errors == null || errors.isEmpty();
            // For undelete, this list needs to be null.
        }
    }

    public class DmlError {
        public List<String> fields;
        public String message;
        public StatusCode statusCode;

        public DmlError(String message) {
            this.message = message;
            this.fields = fields;
            this.statusCode = System.StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION;
        }
    }
}