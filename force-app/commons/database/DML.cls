/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2024 Piotr Kożuchowski
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 * /
 * *
 */

/**
 * Namespace class for DML related classes:
 * - DML Type
 * - DML Results
 * - DML Errors
 * - DML Operations
 * - DML Options
 * - DML Mocks
 */
public with sharing class DML {
    public final static String GENERIC_ERROR = 'Mocked DML Error';

    /**
     * Type of the Database operation
     */
    public enum Type {
        INSERT_DML,
        UPDATE_DML,
        UPSERT_DML,
        DELETE_DML,
        UNDELETE_DML,
        MERGE_DML,
        CONVERT_LEAD_DML,
        QUERY,
        QUERY_COUNT,
        QUERY_LOCATOR,
        QUERY_CURSOR
    }

    /**
     * Register of Database Operations for reference in unit tests.
     */
    public class Register {
        private Map<DML.Type, Operation[]> operationsByType = new Map<DML.Type, DML.Operation[]>{
            DML.Type.INSERT_DML => new DML.InsertDML[]{},
            DML.Type.UPDATE_DML => new DML.UpdateDML[]{},
            DML.Type.UPSERT_DML => new DML.UpsertDML[]{},
            DML.Type.DELETE_DML => new DML.DeleteDML[]{},
            DML.Type.UNDELETE_DML => new DML.UndeleteDML[]{},
            DML.Type.MERGE_DML => new DML.MergeDML[]{},
            DML.Type.CONVERT_LEAD_DML => new DML.ConvertLeadDML[]{},
            DML.Type.QUERY => new DML.QueryOperation[]{},
            DML.Type.QUERY_COUNT => new DML.QueryCountOperation[]{},
            DML.Type.QUERY_LOCATOR => new DML.QueryLocatorOperation[]{},
            DML.Type.QUERY_CURSOR => new DML.QueryCursorOperation[]{}
        };

        public DML.InsertDML[] inserts = (InsertDML[]) get(DML.Type.INSERT_DML);
        public DML.UpdateDML[] updates = (UpdateDML[]) get(DML.Type.UPDATE_DML);
        public DML.UpsertDML[] upserts = (UpsertDML[]) get(DML.Type.UPSERT_DML);
        public DML.DeleteDML[] deletes = (DeleteDML[]) get(DML.Type.DELETE_DML);
        public DML.UndeleteDML[] undeletes = (UndeleteDML[]) get(DML.Type.UNDELETE_DML);
        public DML.MergeDML[] merges = (MergeDML[]) get(DML.Type.MERGE_DML);
        public DML.QueryOperation[] queries = (QueryOperation[]) get(DML.Type.QUERY);

        public SObject[] inserted { get {return getRecords(inserts);} }
        public SObject[] updated { get {return getRecords(updates);} }
        public SObject[] upserted { get {return getRecords(upserts);} }
        public SObject[] deleted { get {return getRecords(deletes);} }
        public SObject[] undeleted { get {return getRecords(undeletes);} }

        public void add(Operation operation) {
            operationsByType.get(operation.dmlType).add(operation);
        }

        public Operation[] get(Type dmlType) {
            return operationsByType.get(dmlType);
        }

        private List<SObject> getRecords(DMLOperation[] operations) {
            List<SObject> records = new List<SObject>();

            for (DMLOperation operation : operations) {
                for (Integer i = 0; i < operation.successRows.size(); i++) {
                    records.add((SObject) operation.successRows[i]);
                }
            }

            return records;
        }
    }

    /**
     * Wrapper for passing Database Operation Options
     */
    public class Options {
        public transient AccessLevel accessLevel = System.AccessLevel.SYSTEM_MODE;
        public Database.DMLOptions dmlOptions = new Database.DMLOptions();
        public List<DML.DmlResultMock> dmlMocks = new List<DML.DmlResultMock>();
        public Map<String, Object> queryMocks = new Map<String, Object>();

        public Boolean isAllOrNone() {
            return this.dmlOptions?.optAllOrNone != false;
        }
    }


    /*
    * Issuers
    * */

    /**
     * Represents DML Options, which can execute DML Operations in certain sharing context, dmlOptions and accessLevel
     */
    public interface Issuer {
        Object execute(DML.Operation operation, DML.Options options);
    }

    public inherited sharing class IssuerInheritedSharing implements Issuer {
        public Object execute(DML.Operation operation, DML.Options options) {
            return operation.execute(options);
        }
    }
    public with sharing class IssuerWithSharing implements Issuer {
        public Object execute(DML.Operation operation, DML.Options options) {
            return operation.execute(options);
        }
    }
    public without sharing class IssuerWithoutSharing implements Issuer {
        public Object execute(DML.Operation operation, DML.Options options) {
            return operation.execute(options);
        }
    }


    /*
    * Results
    * */

    /**
     * Result of the DML operation
     */
    public virtual class Result {
        @AuraEnabled public Boolean success;
        @AuraEnabled public Id id;
        @AuraEnabled public List<Error> errors;
        @AuraEnabled public DML.Type dmlType;

        public Result(Boolean success) {
            this(null, success, success ? null : new List<Error>{new Error(GENERIC_ERROR)});
        }

        public Result(Id id, Boolean success, List<Database.Error> errors) {
            this(id, success, new List<Error>());
            withErrors(errors);
        }

        public Result(Id id, Boolean success, List<Error> errors) {
            this.id = id;
            this.success = success;
            this.errors = errors;
        }

        public virtual Result withDmlRow(Object dmlRow) {
            this.id = ((SObject) dmlRow).Id;
            return this;
        }

        private void withErrors(List<Database.Error> dbErrors) {
            for (Integer i = 0; i < dbErrors?.size(); i++) {
                errors.add(new Error(dbErrors[i]));
            }
        }
    }

    public class MergeResult extends Result {
        @AuraEnabled public List<String> mergedRecordIds;
        @AuraEnabled public List<String> updatedRelatedIds;

        public MergeResult(Boolean success) {
            super(success);
        }

        public MergeResult(Database.MergeResult result) {
            super(result.id, result.success, result.errors);
            this.mergedRecordIds = result.mergedRecordIds;
            this.updatedRelatedIds = result.updatedRelatedIds;
        }
    }

    public class LeadConvertResult extends Result {
        @AuraEnabled public Id accountId;
        @AuraEnabled public Id contactId;
        @AuraEnabled public Id leadId;
        @AuraEnabled public Id opportunityId;
        @AuraEnabled public Id relatedPersonAccountId;

        public LeadConvertResult(Boolean success) {
            super(success);
        }

        public LeadConvertResult(Database.LeadConvertResult result) {
            super(result.leadId, result.success, result.errors);
            this.accountId = result.accountId;
            this.contactId = result.contactId;
            this.leadId = result.leadId;
            this.opportunityId = result.opportunityId;
            this.relatedPersonAccountId = result.relatedPersonAccountId;
        }

        public override Result withDmlRow(Object dmlRow) {
            this.leadId = ((Database.LeadConvert) dmlRow).leadId;
            return this;
        }
    }

    public virtual class Error {
        @AuraEnabled public List<String> fields { get; private set; }
        @AuraEnabled public String message { get; private set; }
        @AuraEnabled public StatusCode statusCode { get; private set; }

        public Error(Database.Error error) {
            this(error.message, error.statusCode, error.fields);
        }

        public Error(String message) {
            this(message, System.StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, new List<String>());
        }

        public Error(String message, StatusCode statusCode, List<String> fields) {
            this.fields = fields;
            this.message = message;
            this.statusCode = statusCode;
        }
    }


    /*
    * Operations
    * */

    /**
     * Defines operation order for Unit of Work, if explicit order is specified.
     */
    public class Order {
        public final String operationId { get; private set; }


        public Order(SObjectType sObjectType) {
            this.operationId = '' + sObjectType;
        }

        public Order(SObjectType sObjectType, DML.Type dmlType) {
            this.operationId = ('' + sObjectType + '.' + dmlType.name());
        }

        public Order(SObjectType sObjectType, DML.Type dmlType, SObjectField upsertField) {
            this.operationId = ('' + sObjectType + '.' + dmlType.name() + '.' + (upsertField?.toString() ?? 'Id'));
        }
    }

    /**
     * Represents Database Operation, which can be executed by DML Options
     * or queued in queued in certain order in Unit of Work
     */
    public abstract class Operation {
        public DML.Type dmlType { get; protected set; }

        public abstract Object execute(Options options);
    }


    /**
     * Represents DML Database Operation - Insert, Update, Upsert, Delete, Undelete, Merge, Convert Lead
     */
    public abstract class DMLOperation extends Operation {
        public String operationId { get; protected set; }
        public transient SObjectType sObjectType { get; protected set; }
        private Map<Object, Object> mappedDmlRows;
        public List<Object> dmlRows { get; protected set; }
        public List<Object> successRows { get; protected set; }
        public List<Object> errorRows { get; protected set; }
        public List<Result> results { get; protected set; }
        public Boolean success { get; protected set; }

        protected DMLOperation(DML.Type dmlType, List<Object> dmlRows, SObjectType sObjectType) {
            init(dmlType, dmlRows, sObjectType);
        }

        protected DMLOperation(DML.Type dmlType, List<SObject> records) {
            init(dmlType, records, records.getSObjectType());
        }

        public DMLOperation clone(SObjectType sObjectType) {
            DMLOperation clone = this.clone();
            clone.init(dmlType, new List<SObject>(), sObjectType);
            return clone;
        }

        protected void init(DML.Type dmlType, List<Object> inputs, SObjectType sObjectType) {
            this.dmlType = dmlType;
            this.dmlRows = inputs;
            this.successRows = new List<Object>();
            this.errorRows = new List<Object>();
            this.sObjectType = sObjectType;
            this.operationId = '' + (sObjectType?.toString() ?? 'MIXED_DML') + '.' + dmlType.name();
            this.results = new List<DML.Result>();
            this.success = true;
        }

        /**
         * Adds new records to the DML operation, without duplicates.
         * If there are any records with the same Id/ExternalId, they will be merged.
         * If there are no Ids, they will be added as is.
         */
        public virtual void addWithoutDuplicates(List<Object> newDmlRows) {
            if (mappedDmlRows == null) {
                mappedDmlRows = new Map<Object, Object>();

                List<SObject> records = (List<SObject>) dmlRows;

                for (Integer i = 0; i < records.size(); i++) {
                    mappedDmlRows.put(
                        getRecordId(records[0]),
                        records[0]
                    );
                }
            }

            for (Integer i = 0; i < newDmlRows.size(); i++) {
                SObject record = (SObject) newDmlRows.get(i);
                Object id = getRecordId(record);

                if (mappedDmlRows.containsKey(id)) {
                    // If it's an update or upsert, apply new fields to existing record.
                    if (dmlType == DML.Type.UPDATE_DML || dmlType == DML.Type.UPSERT_DML) {
                        SObject existingRecord = (SObject) mappedDmlRows.get(id);
                        Map<String, Object> populatedFields = record.getPopulatedFieldsAsMap();

                        for (String field : populatedFields.keySet()) {
                            existingRecord.put(field, populatedFields.get(field));
                        }
                    }
                } else {
                    mappedDmlRows.put(id, record);
                    this.dmlRows.add(record);
                }
            }
        }

        /**
         * Executes DML operation with given DMLOptions and AccessLevel.
         * If there are any mocked results, they will be used instead of actual DML.
         */
        public override Object execute(Options options) {
            List<Result> mockResults = new List<DML.Result>(dmlRows.size());
            List<Object> rowsToDML = this.dmlRows;
            List<Object> dbResults;

            if (Test.isRunningTest() && !options.dmlMocks.isEmpty()) {
                rowsToDML = getMockResultsAndRemainingRecords(mockResults, options);
            }

            dbResults = executeDML(rowsToDML, options);
            mapDatabaseResults(mockResults, dbResults);
            return results;
        }

        protected virtual Object getRecordId(SObject record) {
            return record.Id;
        }

        /**
         * Checks if there are any mocked results for given DML operation and records.
         * If there is mocked results, record will be excluded from the DML.
         * If there are any errors and this is AllOrNone, then DMLException will be thrown.
         */
        private List<Object> getMockResultsAndRemainingRecords(List<Result> mockResults, Options options) {
            List<Object> recordsForDML = dmlRows.clone();
            recordsForDML.clear();

            for (Integer i = 0; i < dmlRows.size(); i++) {
                Result mockResult = mockResults[i] = getMockResult(options.dmlMocks, dmlRows[i]);

                /*No mocked results, record will have actual DML*/
                if (mockResult == null) {
                    recordsForDML.add(dmlRows[i]);

                } else if (options.isAllOrNone() && !mockResult.success) {
                    /*Throw exception to prevent any records from being DMLed*/
                    throw new DmlException(mockResult.errors[0].message);
                }
            }

            return recordsForDML;
        }

        /**
         * @return Mocked DML.Result for given record matched by registered criteria
         */
        private Result getMockResult(List<DmlResultMock> mocks, Object dmlRow) {
            for (Integer i = mocks.size() - 1; i >= 0; i--) {
                Result mock = mocks[i].getResult(this, dmlRow);

                if (mock != null) {
                    return mock;
                }
            }

            return null;
        }

        /**
         * Merges mock results and actual database results into one list.
         * Records that had mocked result were not commited to the database, so the lists may be different sizes.
         */
        private void mapDatabaseResults(List<Result> mockResults, List<Object> partialDatabaseResults) {
            for (Integer i = 0, partialIndex = 0, size = dmlRows.size(); i < size; i++) {
                Result result = mockResults[i] ?? getResult(partialDatabaseResults[partialIndex++]);
                result.dmlType = dmlType;
                this.success = this.success && result.success;
                results.add(result);
                (this.success ? successRows : errorRows).add(dmlRows[i]);
            }
        }

        protected abstract List<Object> executeDML(List<Object> dmlRows, Options options);
        protected abstract Result getResult(Object dbResult);
    }


    /**
     * OPERATIONS
     */


    /**
     * Insert DML operation, which inserts records into the database.
     */
    public inherited sharing class InsertDML extends DMLOperation {
        public InsertDML(List<SObject> records) {
            super(DML.Type.INSERT_DML, records);
        }
        protected override List<Object> executeDML(List<Object> records, Options opts) {
            return Database.insert((List<SObject>) records, opts.dmlOptions, opts.accessLevel);
        }
        protected override Result getResult(Object dbResult) {
            Database.SaveResult result = (Database.SaveResult) dbResult;
            return new Result(result.id, result.success, result.errors);
        }
        public override void addWithoutDuplicates(List<Object> newDmlRows) {
            this.dmlRows.addAll(newDmlRows);
        }
    }

    /**
     * Update DML operation, which updates records in the database.
     */
    public inherited sharing class UpdateDML extends DMLOperation {
        public UpdateDML(List<SObject> records) {
            super(DML.Type.UPDATE_DML, records);
        }
        protected override List<Object> executeDML(List<Object> records, Options opts) {
            return Database.update((List<SObject>) records, opts.dmlOptions, opts.accessLevel);
        }
        protected override Result getResult(Object dbResult) {
            Database.SaveResult result = (Database.SaveResult) dbResult;
            return new Result(result.id, result.success, result.errors);
        }
    }


    /**
     * Upsert DML operation, which can use a specific field for upsert or default to Id.
     * If upsertField is null, it will use Id as the upsert field.
     */
    public inherited sharing class UpsertDML extends DMLOperation {
        public transient SObjectField upsertField { get; private set; }
        private String upsertFieldName;

        public UpsertDML(List<SObject> records, SObjectField upsertField) {
            super(DML.Type.UPSERT_DML, records);
            this.upsertField = upsertField;
            this.upsertFieldName = upsertField?.toString() ?? 'Id';
            this.operationId = this.operationId + '.' + upsertFieldName;
        }

        protected override List<Object> executeDML(List<Object> records, Options opts) {
            return upsertField == null ?
                Database.upsert((List<SObject>) records, opts.isAllOrNone(), opts.accessLevel)
                : Database.upsert((List<SObject>) records, upsertField, opts.isAllOrNone(), opts.accessLevel);
        }

        protected override Result getResult(Object dbResult) {
            Database.UpsertResult result = (Database.UpsertResult) dbResult;
            return new Result(result.id, result.success, result.errors);
        }

        protected override Object getRecordId(SObject record) {
            return record.get(upsertFieldName);
        }
    }

    /**
     * Delete DML operation, which deletes records from the database.
     */
    public inherited sharing class DeleteDML extends DMLOperation {
        public DeleteDML(List<SObject> records) {
            super(DML.Type.DELETE_DML, records);
        }
        protected override List<Object> executeDML(List<Object> records, Options opts) {
            return Database.delete((List<SObject>) records, opts.isAllOrNone(), opts.accessLevel);
        }
        protected override Result getResult(Object dbResult) {
            Database.DeleteResult result = (Database.DeleteResult) dbResult;
            return new Result(result.id, result.success, result.errors);
        }
    }

    /**
     * Undelete DML operation, which restores deleted records in the database.
     */
    public inherited sharing class UndeleteDML extends DMLOperation {
        public UndeleteDML(List<SObject> records) {
            super(DML.Type.UNDELETE_DML, records);
        }
        protected override List<Object> executeDML(List<Object> records, Options opts) {
            return Database.undelete((List<SObject>) records, opts.isAllOrNone(), opts.accessLevel);
        }
        protected override Result getResult(Object dbResult) {
            Database.UndeleteResult result = (Database.UndeleteResult) dbResult;
            return new Result(result.id, result.success, result.errors);
        }
    }

    /**
     * Merge DML operation, which merges records in the database.
     * The primaryRecord is the record that will be kept, and duplicates are the records that will be merged into it.
     */
    public inherited sharing class MergeDML extends DMLOperation {
        public List<MergeResult> results { get {return (List<MergeResult>) super.results;} }
        public SObject primaryRecord { get; private set; }
        public List<Id> duplicates { get; private set; }

        public MergeDML(SObject primaryRecord, List<Id> duplicates) {
            super(DML.Type.MERGE_DML, new List<SObject>{primaryRecord});
            super.results = new List<MergeResult>();
            this.primaryRecord = primaryRecord;
            this.duplicates = duplicates;
            this.sObjectType = primaryRecord.getSObjectType();
            this.operationId = this.operationId + '.' + primaryRecord.Id;
        }

        protected override List<Object> executeDML(List<Object> records, Options opts) {
            return records.isEmpty() ?
                new List<Database.MergeResult>()
                : Database.merge((SObject) records[0], duplicates, opts.isAllOrNone(), opts.accessLevel);
        }

        protected override Result getResult(Object dbResult) {
            return new MergeResult((Database.MergeResult) dbResult);
        }
    }

    /**
     * Convert Lead DML operation, which converts leads in the database.
     * The leadConverts is a list of Database.LeadConvert objects that specify the leads to convert.
     */
    public inherited sharing class ConvertLeadDML extends DMLOperation {
        public List<LeadConvertResult> results { get {return (List<LeadConvertResult>) super.results;} }

        public ConvertLeadDML(List<Database.LeadConvert> leadConverts) {
            super(DML.Type.CONVERT_LEAD_DML, leadConverts, Lead.SObjectType);
            super.results = new List<LeadConvertResult>();
        }

        protected override List<Object> executeDML(List<Object> records, Options opts) {
            return Database.convertLead((List<Database.LeadConvert>) records, opts.isAllOrNone(), opts.accessLevel);
        }

        protected override Result getResult(Object dbResult) {
            return new LeadConvertResult((Database.LeadConvertResult) dbResult);
        }
    }

    /**
     * Query operations, which can be used to execute SOQL queries with or without binds.
     * These operations can be used to mock query results in tests.
     */
    private abstract class BaseQueryOperation extends Operation {
        public String mockId { get; protected set; }
        public String soql { get; protected set; }
        public Map<String, Object> boundVars { get; protected set; }

        protected BaseQueryOperation(DML.Type dmlType, String soql, Map<String, Object> boundVars) {
            this.dmlType = dmlType;
            this.soql = soql;
            this.boundVars = boundVars ?? new Map<String, Object>();
        }

        public abstract override Object execute(Options opts);

        protected Object getMock(Options opts) {
            if (Test.isRunningTest() && !opts.queryMocks.isEmpty()) {
                String fromSObject = soql.toLowerCase().substringAfter('from ').substringBefore(' ');

                Object result = opts.queryMocks.get(mockId) ?? opts.queryMocks.get(fromSObject);
                if (result instanceof QueryException) {
                    throw (Exception) result;
                }
                return result;
            }
            return null;
        }
    }

    /**
     * Query operation, which executes a SOQL query and returns the results as a List<SObject>.
     * If there are any mocked results, they will be used instead of actual query.
     */
    public inherited sharing virtual class QueryOperation extends BaseQueryOperation {
        public List<SObject> results { get; protected set; }

        public QueryOperation(String mockId, String soql, Map<String, Object> boundVars) {
            super(DML.Type.QUERY, soql, boundVars);
            this.mockId = mockId;
        }
        public virtual override Object execute(Options opts) {
            return results = (List<SObject>) (getMock(opts) ?? Database.queryWithBinds(soql, boundVars, opts.accessLevel));
        }
    }

    /**
     * Query operations, which can be used to execute SOQL queries with query locator
     * These operations can be used to mock query results in tests.
     */
    public inherited sharing class QueryLocatorOperation extends BaseQueryOperation {
        public QueryLocatorOperation(String query, Map<String, Object> boundVars) {
            super(DML.Type.QUERY_LOCATOR, query, boundVars);
        }
        public override Object execute(Options opts) {
            return Database.getQueryLocatorWithBinds(soql, boundVars, opts.accessLevel);
        }
    }

    /**
     * Query operations, which can be used to execute SOQL queries with cursor.
     * These operations can be used to mock query results in tests.
     */
    public inherited sharing class QueryCursorOperation extends BaseQueryOperation {
        public QueryCursorOperation(String query, Map<String, Object> boundVars) {
            super(DML.Type.QUERY_CURSOR, query, boundVars);
        }
        public override Object execute(Options opts) {
            return Database.getCursorWithBinds(soql, boundVars, opts.accessLevel);
        }
    }

    public inherited sharing class QueryCountOperation extends BaseQueryOperation {
        public Integer result { get; private set; }

        public QueryCountOperation(String mockId, String query, Map<String, Object> boundVars) {
            super(DML.Type.QUERY_COUNT, query, boundVars);
            this.mockId = mockId;
        }
        public override Object execute(Options opts) {
            return result = (Integer) (getMock(opts) ?? Database.countQueryWithBinds(soql, boundVars, opts.accessLevel));
        }
    }


    /*
    * Mocks
    * */

    /**
     * Mocks DML operation, which can be used to fake DML results for given records.
     */
    public virtual class DmlResultMock {
        private final DML.Type matchingDmlType;
        private final SObjectType matchingSObjectType;
        private final Map<String, Object> matchingFieldValues;
        private final Result result;

        public DmlResultMock() {}

        public DmlResultMock(DML.Type matchingDmlType, SObject matchingRecord, Result result) {
            this(matchingDmlType, matchingRecord?.getPopulatedFieldsAsMap(), result);
            this.matchingSObjectType = matchingRecord?.getSObjectType();
        }

        public DmlResultMock(DML.Type matchingDmlType, Map<String, Object> fields, Result result) {
            this.matchingDmlType = matchingDmlType;
            this.matchingFieldValues = fields;
            this.result = result;
        }

        public virtual Result getResult(DML.DMLOperation operation, Object dmlRow) {
            return matches(operation, dmlRow) ? getResultInstance(operation, dmlRow) : null;
        }

        /**
         * @return True, if given operation and record match the criteria:
         * - operationType is the same as this matcher's operationType
         * - mockedSObjectType is the same as record's SObjectType
         * - all fields in matchingFieldValues are the same as in record
         */
        protected virtual Boolean matches(DML.DMLOperation operation, Object dmlRow) {
            return (matchingDmlType == null || matchingDmlType == operation.dmlType)
                && (matchingSObjectType == null || operation.sObjectType == matchingSObjectType)
                && (matchingFieldValues == null || isDmlRowMatching(dmlRow));
        }

        protected Boolean isDmlRowMatching(Object dmlRow) {
            if (dmlRow instanceof Id) {
                return matchingFieldValues.get('Id') == dmlRow;

            } else if (dmlRow instanceof Database.LeadConvert) {
                return matchingFieldValues.get('Id') == ((Database.LeadConvert) dmlRow).leadId;

            } else if (dmlRow instanceof SObject) {
                SObject record = (SObject) dmlRow;

                for (String field : matchingFieldValues.keySet()) {
                    if (record.get(field) != matchingFieldValues.get(field)) {
                        return false;
                    }
                }
            }

            return true;
        }

        protected Result getResultInstance(DML.Operation operation, Object dmlRow) {
            Result clone = result.clone();
            clone.dmlType = operation.dmlType;
            clone.withDmlRow(dmlRow);
            return clone;
        }
    }

    /**
     * Fakes all DMLs by assigning fake Ids to records without Ids.
     */
    public class FakeDmlMock extends DmlResultMock {

        public FakeDmlMock() {
            this.result = new Result(true);
        }

        public override Result getResult(DML.DMLOperation operation, Object dmlRow) {
            SObject record = (SObject) dmlRow;

            if (String.isBlank(record.Id)) {
                if (operation instanceof InsertDML || operation instanceof UpsertDML) {
                    record.Id = DatabaseService.getFakeId(record.getSObjectType());
                }
            }

            return new Result(record.Id, true, new List<Database.Error>());
        }
    }
}