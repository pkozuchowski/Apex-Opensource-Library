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
    private static DatabaseMock databaseMock = new DatabaseMock();
    private Database.DMLOptions dmlOptions = new Database.DMLOptions();
    private DMLIssuer dmlIssuer = new InheritedSharingDMLIssuer();

    public static Id getFakeId(SObjectType sObjectType) {
        String keyPrefix = SchemaDescriptions.getSObjectDescribe('' + sObjectType).getKeyPrefix();
        return keyPrefix + ('' + (cnt++)).leftPad(12, '0');
    }

    public DatabaseService() {
        this.dmlOptions.optAllOrNone = true;
    }

    /**
     * Sets sharing mode on Database Service:
     * - With Sharing
     * - Without Sharing
     * - Inherited Sharing (default)
     */
    public DatabaseService setSharing(Sharing sharing) {
        switch on sharing {
            when WITH_SHARING {
                this.dmlIssuer = new WithSharingDMLIssuer();
            }
            when WITHOUT_SHARING {
                this.dmlIssuer = new WithoutSharingDMLIssuer();
            }
            when INHERITED_SHARING {
                this.dmlIssuer = new InheritedSharingDMLIssuer();
            }
        }
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
        return dmlIssuer.query(query, boundVars == null ? new Map<String, Object>() : boundVars);
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
        return dmlIssuer.getQueryLocator(query, boundVars == null ? new Map<String, Object>() : boundVars);
    }

    public Database.SaveResult insertRecord(SObject record) {
        return insertRecords(new List<SObject>{record})[0];
    }
    public List<Database.SaveResult> insertRecords(List<SObject> records) {
        return dmlIssuer.insertRecords(records, dmlOptions);
    }


    public Database.SaveResult updateRecord(SObject record) {
        return updateRecords(new List<SObject>{record})[0];
    }
    public List<Database.SaveResult> updateRecords(List<SObject> records) {
        return dmlIssuer.updateRecords(records, dmlOptions);
    }


    public Database.UpsertResult upsertRecord(SObject record, SObjectField field) {
        return upsertRecords(nonGenericSObjectList(record), field)[0];
    }
    public List<Database.UpsertResult> upsertRecords(List<SObject> records, SObjectField field) {
        return dmlIssuer.upsertRecords(records, field, dmlOptions?.optAllOrNone == true);
    }


    public Database.DeleteResult deleteRecord(SObject record) {
        return deleteRecords(new List<SObject>{record})[0];
    }

    public List<Database.DeleteResult> deleteRecords(List<SObject> records) {
        return dmlIssuer.deleteRecords(records, isAllOrNone());
    }


    public Database.UndeleteResult undeleteRecord(SObject record) {
        return undeleteRecords(new List<SObject>{record})[0];
    }

    public List<Database.UndeleteResult> undeleteRecords(List<SObject> records) {
        return dmlIssuer.undeleteRecords(records, isAllOrNone());
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
        return dmlOptions.OptAllOrNone == null ? true : dmlOptions.OptAllOrNone;
    }


    /**
    * Interface for classes that will handle DML operations
    * */
    public interface DMLIssuer {
        List<Database.SaveResult> insertRecords(List<SObject> records, Database.DMLOptions options);
        List<Database.SaveResult> updateRecords(List<SObject> records, Database.DMLOptions options);
        List<Database.UpsertResult> upsertRecords(List<SObject> records, SObjectField field, Boolean allOrNone);
        List<Database.DeleteResult> deleteRecords(List<SObject> records, Boolean allOrNone);
        List<Database.UndeleteResult> undeleteRecords(List<SObject> records, Boolean allOrNone);
        List<SObject> query(String query, Map<String, Object> boundVars);
        Database.QueryLocator getQueryLocator(String query, Map<String, Object> boundVars);
    }


    private abstract inherited sharing class AbstractDMLIssuer implements DMLIssuer {
        public virtual List<SObject> query(String query, Map<String, Object> boundVars) {
            Object var0, var1, var2, var3, var4, var5, var6, var7, var8, var9;
            String finalQuery = query;

            Integer i = 0;
            for (String var : boundVars.keySet()) {
                finalQuery = finalQuery.replace(':' + var, ':var' + i);

                if (i == 0) var0 = boundVars.get(var);
                if (i == 1) var1 = boundVars.get(var);
                if (i == 2) var2 = boundVars.get(var);
                if (i == 3) var3 = boundVars.get(var);
                if (i == 4) var4 = boundVars.get(var);
                if (i == 5) var5 = boundVars.get(var);
                if (i == 6) var6 = boundVars.get(var);
                if (i == 7) var7 = boundVars.get(var);
                if (i == 8) var8 = boundVars.get(var);
                if (i == 9) var9 = boundVars.get(var);
                i++;
            }

            return Database.query(finalQuery);
        }

        public virtual Database.QueryLocator getQueryLocator(String query, Map<String, Object> boundVars) {
            Object var0, var1, var2, var3, var4, var5, var6, var7, var8, var9;
            String finalQuery = query;

            Integer i = 0;
            for (String var : boundVars.keySet()) {
                finalQuery = finalQuery.replace(':' + var, ':var' + i);

                if (i == 0) var0 = boundVars.get(var);
                if (i == 1) var1 = boundVars.get(var);
                if (i == 2) var2 = boundVars.get(var);
                if (i == 3) var3 = boundVars.get(var);
                if (i == 4) var4 = boundVars.get(var);
                if (i == 5) var5 = boundVars.get(var);
                if (i == 6) var6 = boundVars.get(var);
                if (i == 7) var7 = boundVars.get(var);
                if (i == 8) var8 = boundVars.get(var);
                if (i == 9) var9 = boundVars.get(var);
                i++;
            }

            return Database.getQueryLocator(finalQuery);
        }
    }


    /**
    * Issues DMLs with sharing
    * */
    private with sharing class WithSharingDMLIssuer extends AbstractDMLIssuer {
        public List<Database.SaveResult> insertRecords(List<SObject> records, Database.DMLOptions options) { return Database.insert(records, options); }
        public List<Database.SaveResult> updateRecords(List<SObject> records, Database.DMLOptions options) { return Database.update(records, options); }
        public List<Database.UpsertResult> upsertRecords(List<SObject> records, SObjectField field, Boolean allOrNone) { return Database.upsert(records, field, allOrNone); }
        public List<Database.DeleteResult> deleteRecords(List<SObject> records, Boolean allOrNone) { return Database.delete(records, allOrNone); }
        public List<Database.UndeleteResult> undeleteRecords(List<SObject> records, Boolean allOrNone) { return Database.undelete(records, allOrNone); }
        public override List<SObject> query(String query, Map<String, Object> boundVars) { return super.query(query, boundVars); }
        public override Database.QueryLocator getQueryLocator(String query, Map<String, Object> boundVars) { return super.getQueryLocator(query, boundVars); }
    }


    /**
    * Issues DMLs without sharing
    * */
    private without sharing class WithoutSharingDMLIssuer extends AbstractDMLIssuer {
        public List<Database.SaveResult> insertRecords(List<SObject> records, Database.DMLOptions options) { return Database.insert(records, options); }
        public List<Database.SaveResult> updateRecords(List<SObject> records, Database.DMLOptions options) { return Database.update(records, options); }
        public List<Database.UpsertResult> upsertRecords(List<SObject> records, SObjectField field, Boolean allOrNone) { return Database.upsert(records, field, allOrNone); }
        public List<Database.DeleteResult> deleteRecords(List<SObject> records, Boolean allOrNone) { return Database.delete(records, allOrNone); }
        public List<Database.UndeleteResult> undeleteRecords(List<SObject> records, Boolean allOrNone) { return Database.undelete(records, allOrNone); }
        public override List<SObject> query(String query, Map<String, Object> boundVars) { return super.query(query, boundVars); }
        public override Database.QueryLocator getQueryLocator(String query, Map<String, Object> boundVars) { return super.getQueryLocator(query, boundVars); }
    }


    /**
    * Issues DMLs with inherited sharing
    * */
    private inherited sharing class InheritedSharingDMLIssuer extends AbstractDMLIssuer {
        public List<Database.SaveResult> insertRecords(List<SObject> records, Database.DMLOptions options) { return Database.insert(records, options); }
        public List<Database.SaveResult> updateRecords(List<SObject> records, Database.DMLOptions options) { return Database.update(records, options); }
        public List<Database.UpsertResult> upsertRecords(List<SObject> records, SObjectField field, Boolean allOrNone) { return Database.upsert(records, field, allOrNone); }
        public List<Database.DeleteResult> deleteRecords(List<SObject> records, Boolean allOrNone) { return Database.delete(records, allOrNone); }
        public List<Database.UndeleteResult> undeleteRecords(List<SObject> records, Boolean allOrNone) { return Database.undelete(records, allOrNone); }
        public override List<SObject> query(String query, Map<String, Object> boundVars) { return super.query(query, boundVars); }
        public override Database.QueryLocator getQueryLocator(String query, Map<String, Object> boundVars) { return super.getQueryLocator(query, boundVars); }
    }


    /**
     * Mocks all DML operations and saves them in DatabaseMock instance.
     * Queries are not mocked.
     */
    private class MockedDmlIssuer extends AbstractDMLIssuer {
        private DatabaseMock mock;

        private MockedDmlIssuer(DatabaseMock mock) {
            this.mock = mock;
        }

        public List<Database.SaveResult> insertRecords(List<SObject> records, Database.DMLOptions options) {
            return (List<Database.SaveResult>) doMockedDML(
                DmlType.INSERT_DML, records, options.optAllOrNone, mock.insertedRecords, List<Database.SaveResult>.class
            );
        }

        public List<Database.SaveResult> updateRecords(List<SObject> records, Database.DMLOptions options) {
            return (List<Database.SaveResult>) doMockedDML(
                DmlType.UPDATE_DML, records, options.optAllOrNone, mock.updatedRecords, List<Database.SaveResult>.class
            );
        }

        public List<Database.UpsertResult> upsertRecords(List<SObject> records, SObjectField field, Boolean allOrNone) {
            return (List<Database.UpsertResult>) doMockedDML(
                DmlType.UPSERT_DML, records, allOrNone, mock.upsertedRecords, List<Database.UpsertResult>.class
            );
        }

        public List<Database.DeleteResult> deleteRecords(List<SObject> records, Boolean allOrNone) {
            return (List<Database.DeleteResult>) doMockedDML(
                DmlType.DELETE_DML, records, allOrNone, mock.deletedRecords, List<Database.DeleteResult>.class
            );
        }

        public List<Database.UndeleteResult> undeleteRecords(List<SObject> records, Boolean allOrNone) {
            return (List<Database.UndeleteResult>) doMockedDML(
                DmlType.UNDELETE_DML, records, allOrNone, mock.undeletedRecords, List<Database.UndeleteResult>.class
            );
        }

        public override List<SObject> query(String query, Map<String, Object> boundVars) {
            return super.query(query, boundVars);
        }

        public override Database.QueryLocator getQueryLocator(String query, Map<String, Object> boundVars) {
            return super.getQueryLocator(query, boundVars);
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