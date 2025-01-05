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
public inherited sharing virtual class DatabaseService {
    private static Map<SObjectType, String> prefixBySObject = new Map<SObjectType, String>();
    private static Integer cnt = 0;

    protected DML.Issuer dmlIssuer;
    protected DML.Options options = new DML.Options();
    @TestVisible DML.Register register;


    /**
     * @return Unique fake id for given SObject.
     */
    public static Id getFakeId(SObjectType sObjectType) {
        String keyPrefix = prefixBySObject.get(sObjectType);

        if (String.isBlank(keyPrefix)) {
            keyPrefix = sObjectType.getDescribe().getKeyPrefix();
            prefixBySObject.put(sObjectType, keyPrefix);
        }

        return keyPrefix + ('' + (cnt++)).leftPad(12, '0');
    }


    /**
     * Constructs DatabaseService with System Inherited Sharing setup and All or None option.
     */
    public DatabaseService() {
        asSystemWithSharing();
        allOrNone(true);

        if (Test.isRunningTest()) {
            this.register = new DML.Register();
        }
    }

    /**
     * Execution mode in which the object permissions, field-level security, and sharing rules of the current user are enforced.
     */
    public DatabaseService asUser() {
        this.dmlIssuer = new DML.IssuerWithSharing();
        return withAccessLevel(AccessLevel.USER_MODE);
    }

    /**
     * DEVELOPER PREVIEW
     * Execution mode in which the object permissions, field-level security, and sharing rules of the current user are enforced.
     * Permission Set permissions are added on top of user permissions.
     */
    public DatabaseService asUserWithPermissionSetId(Id permissionSetId) {
        this.dmlIssuer = new DML.IssuerWithSharing();
        return withAccessLevel(AccessLevel.USER_MODE.withPermissionSetId(permissionSetId));
    }

    /**
     * Execution mode in which the object permissions, field-level security, and sharing rules are inherited
     * from calling class.
     * Default execution mode.
     */
    public DatabaseService asSystem() {
        this.dmlIssuer = new DML.IssuerInheritedSharing();
        return withAccessLevel(AccessLevel.SYSTEM_MODE);
    }

    /**
     * Execution mode in which the the object and field-level permissions of the current user are ignored,
     * and the record sharing rules are enforced.
     */
    public DatabaseService asSystemWithSharing() {
        this.dmlIssuer = new DML.IssuerWithSharing();
        return withAccessLevel(AccessLevel.SYSTEM_MODE);
    }

    /**
     * Execution mode in which the the object and field-level permissions of the current user are ignored,
     * and access to all records is permitted.
     */
    public DatabaseService asSystemWithoutSharing() {
        this.dmlIssuer = new DML.IssuerWithoutSharing();
        return withAccessLevel(AccessLevel.SYSTEM_MODE);
    }


    /**
     * SYSTEM_MODE - Execution mode in which the the object and field-level permissions of the current user are ignored,
     * and the record sharing rules are controlled by the class sharing keywords.<br/>
     * USER_MODE - Execution mode in which the object permissions, field-level security, and sharing rules of the current user are enforced.
     */
    public DatabaseService withAccessLevel(AccessLevel level) {
        this.options.accessLevel = level;
        return this;
    }

    /**
     * Sets DML Options to use for DMLs issued with this service.
     */
    public DatabaseService withDMLOptions(Database.DMLOptions options) {
        this.options.dmlOptions = options;
        return this;
    }

    /**
     * Sets All Or None in DML Options
     */
    public DatabaseService allOrNone(Boolean allOrNone) {
        this.options.dmlOptions.optAllOrNone = allOrNone;
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
        return query(null, query, boundVars);
    }

    /**
     * Executes database query with given bound variables
     * @param mockId Name used for mocking purposes
     * @param query Query string (ex. 'SELECT Id FROM Account WHERE Name IN: names')
     * @param boundVars Variables to bind to query ex. {'names' => ['Name 1', 'Name 2']}. Can be null.
     */
    public List<SObject> query(String mockId, String query, Map<String, Object> boundVars) {
        return (List<SObject>) execute(new DML.QueryOperation(mockId, query, boundVars));
    }

    public Integer countQuery(String query) {
        return countQuery(query, null);
    }

    public Integer countQuery(String query, Map<String, Object> boundVars) {
        return countQuery(null, query, boundVars);
    }

    public Integer countQuery(String mockId, String query, Map<String, Object> boundVars) {
        return (Integer) execute(new DML.QueryCountOperation(mockId, query, boundVars));
    }

    /**
     * Creates a cursor when the specified SOQL query is executed.
     * @param query Query string (ex. 'SELECT Id FROM Account WHERE Name IN: names')
     * @param boundVars Variables to bind to query ex. {'names' => ['Name 1', 'Name 2']}. Can be null.
     * @return Database.Cursor for given query
     */
    public Database.Cursor getCursor(String query, Map<String, Object> boundVars) {
        return (Database.Cursor) execute(new DML.QueryCursorOperation(query, boundVars));
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
        return (Database.QueryLocator) execute(new DML.QueryLocatorOperation(query, boundVars));
    }


    public DML.Result insertRecord(SObject record) {
        List<SObject> records = newConcreteSObjectList(record);
        return getFirstResult(insertRecords(records));
    }
    public List<DML.Result> insertRecords(List<SObject> records) {
        return (List<DML.Result>) execute(new DML.InsertDML(records));
    }


    public DML.Result updateRecord(SObject record) {
        List<SObject> records = newConcreteSObjectList(record);
        return getFirstResult(updateRecords(records));
    }
    public List<DML.Result> updateRecords(List<SObject> records) {
        return (List<DML.Result>) execute(new DML.UpdateDML(records));
    }


    public DML.Result upsertRecord(SObject record, SObjectField field) {
        List<SObject> records = newConcreteSObjectList(record);
        return getFirstResult(upsertRecords(records, field));
    }
    public List<DML.Result> upsertRecords(List<SObject> records, SObjectField field) {
        return (List<DML.Result>) execute(new DML.UpsertDML(records, field));
    }


    public DML.Result deleteRecord(SObject record) {
        List<SObject> records = newConcreteSObjectList(record);
        return getFirstResult(deleteRecords(records));
    }
    public List<DML.Result> deleteRecords(List<SObject> records) {
        return (List<DML.Result>) execute(new DML.DeleteDML(records));
    }


    public DML.Result undeleteRecord(SObject record) {
        List<SObject> records = newConcreteSObjectList(record);
        return getFirstResult(undeleteRecords(records));
    }
    public List<DML.Result> undeleteRecords(List<SObject> records) {
        return (List<DML.Result>) execute(new DML.UndeleteDML(records));
    }


    public DML.MergeResult mergeRecords(SObject primary, List<Id> duplicates) {
        List<DML.MergeResult> results = (List<DML.MergeResult>) execute(new DML.MergeDML(primary, duplicates));
        return (DML.MergeResult) getFirstResult(results);
    }


    public DML.LeadConvertResult convertLead(Database.LeadConvert convert) {
        List<DML.Result> results = convertLeads(new List<Database.LeadConvert>{convert});
        return (DML.LeadConvertResult) getFirstResult(results);
    }
    public List<DML.LeadConvertResult> convertLeads(List<Database.LeadConvert> converts) {
        return (List<DML.LeadConvertResult>) execute(new DML.ConvertLeadDML(converts));
    }


    /**
     * Executes Database Operation using Issuer and current DML Options and Access Level.
    */
    protected virtual Object execute(DML.Operation operation) {
        Object results = this.dmlIssuer.execute(operation, options);
        register?.add(operation);
        return results;
    }


    /**
     * Upsert will not work on generic List<SObject>, it requires concrete type.
     */
    protected List<SObject> newConcreteSObjectList(SObject record) {
        List<SObject> records = (List<SObject>) Type.forName('List<' + record.getSObjectType() + '>')
            .newInstance();
        records.add(record);
        return records;
    }

    protected DML.Result getFirstResult(List<DML.Result> results) {
        return results?.isEmpty() == false ? results.get(0) : null;
    }

    /**
     * Mocks response from .query() call, for queries for specified SObject Type.
     * Records list must have concrete sobject type (ex. List<Account>)
     */
    @TestVisible DatabaseService mockQuery(List<SObject> records) {
        if (records.getSObjectType() == null) {
            throw new QueryException('Unexpected generic sobject list.');
        }
        return mockQuery(records.getSObjectType(), records);
    }

    /**
     * Mocks response from .query() call, for queries for specified SObject Type.
     */
    @TestVisible DatabaseService mockQuery(SObjectType sObjectType, Object result) {
        return mockQuery(sObjectType.toString().toLowerCase(), result);
    }

    /**
     * Mocks response from .query() call, for queries with specified mockId.
     */
    @TestVisible DatabaseService mockQuery(String mockId, Object result) {
        this.options.queryMocks.put(mockId, result);
        return this;
    }

    /**
     * All DMLs will be mocked with success response. Records will have fake Ids assigned.
     */
    @TestVisible DatabaseService mockDmls() {
        mockDmlResult(new DML.FakeDmlMock());
        mockDmlResult(DML.Type.CONVERT_LEAD_DML, null, new DML.LeadConvertResult(true));
        mockDmlResult(DML.Type.MERGE_DML, null, new DML.MergeResult(true));
        return this;
    }

    /**
     * Any DML against records that has the same field as provided in param, will have DML Error.
     */
    @TestVisible DatabaseService mockDmlError(SObject matcherRecord) {
        return mockDmlError(null, matcherRecord);
    }

    /**
     * Any DML of given type should fail.
     */
    @TestVisible DatabaseService mockDmlError(DML.Type dmlType) {
        return mockDmlError(dmlType, null);
    }

    /**
     * Specified DML against records that has the same field as provided in param, will have DML Error
     */
    @TestVisible DatabaseService mockDmlError(DML.Type dmlType, SObject matcherRecord) {
        return mockDmlResult(dmlType, matcherRecord, false);
    }

    /**
     * Mocks DML Result with specified result.
     */
    @TestVisible DatabaseService mockDmlResult(DML.Type dmlType, SObject matcherRecord, Boolean success) {
        DML.Result result =
            dmlType == DML.Type.CONVERT_LEAD_DML ? new DML.LeadConvertResult(success)
                : dmlType == DML.Type.MERGE_DML ? new DML.MergeResult(success)
                : new DML.Result(success);

        return mockDmlResult(dmlType, matcherRecord, result);
    }

    /**
     * Specified DML against records that has the same field as provided in param, will have DML Error
     * @param dmlType INSERT/UPDATE/DELETE etc. null to match any.
     * @param matcherRecord If not null, this record is used to match which records should have error.
     * @param result JSON map that will be typed to Database.*Result class.
     */
    @TestVisible DatabaseService mockDmlResult(DML.Type dmlType, SObject matcherRecord, DML.Result result) {
        return mockDmlResult(new DML.DmlResultMock(dmlType, matcherRecord, result));
    }

    @TestVisible DatabaseService mockDmlResult(DML.DmlResultMock mock) {
        this.options.dmlMocks.add(mock);
        return this;
    }
}