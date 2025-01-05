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
@IsTest(IsParallel=true)
private class DatabaseServiceTest {

    @IsTest
    static void testDML() {
        Account acc = new Account(
            Name = 'Test'
        );

        coverDatabaseServiceMethods(new DatabaseService().asUser(), acc);
        coverDatabaseServiceMethods(new DatabaseService().asSystem(), acc);
        coverDatabaseServiceMethods(new DatabaseService().asSystemWithSharing(), acc);
        coverDatabaseServiceMethods(new DatabaseService().asSystemWithoutSharing(), acc);
    }

    private static void coverDatabaseServiceMethods(DatabaseService databaseService, Account acc) {
        databaseService.mockDmls()
            .withDMLOptions(new DMLOptionsBuilder()
                .allowDuplicates(true)
                .build());

        databaseService.insertRecord(acc);
        databaseService.updateRecord(acc);
        databaseService.upsertRecord(acc, Account.Id);
        databaseService.deleteRecord(acc);
        databaseService.undeleteRecord(acc);
        databaseService.query('SELECT Id FROM User');
        databaseService.getCursor('SELECT Id FROM User', null);
        databaseService.getQueryLocator('SELECT Id FROM User');
    }

    @IsTest
    static void testQuery() {
        DatabaseService databaseService = new DatabaseService()
            .asSystemWithSharing();

        List<User> expected = [SELECT Id FROM User LIMIT 5];
        String query = 'SELECT ID FROM User WHERE ID IN :users';
        Map<String, Object> bindings = new Map<String, Object>{'users' => expected};

        List<User> actual = databaseService.query(query, bindings);
        Database.QueryLocator queryLocator = databaseService.getQueryLocator(query, bindings);

        Assert.areEqual(
            new Map<Id, User>(expected).keySet(),
            new Map<Id, User>(actual).keySet()
        );

        databaseService.asSystemWithoutSharing();
        actual = databaseService.query(query, bindings);
        queryLocator = databaseService.getQueryLocator(query, bindings);

        Assert.areEqual(
            new Map<Id, User>(expected).keySet(),
            new Map<Id, User>(actual).keySet()
        );
    }

    @IsTest
    static void testFakeIds() {
        Assert.areEqual('001000000000000', DatabaseService.getFakeId(Account.SObjectType));
        Assert.areEqual('001000000000001', DatabaseService.getFakeId(Account.SObjectType));
        Assert.areEqual('001000000000002', DatabaseService.getFakeId(Account.SObjectType));
        Assert.areEqual('003000000000003', DatabaseService.getFakeId(Contact.SObjectType));
    }

    /**
     * Example of class that does some business logic and will have DMLs mocked.
     */
    private class DummyAccountService {
        @TestVisible private DatabaseService databaseService = new DatabaseService();

        public void doBusinessLogic() {
            Account parentAccount = new Account(Name = 'Parent Account');
            databaseService.insertRecord(parentAccount);

            Account childAccount = new Account(Name = 'Child Account', ParentId = parentAccount.Id);
            databaseService.insertRecord(childAccount);

            List<Contact> contacts = new List<Contact>{
                new Contact(FirstName = 'John', LastName = 'Doe1', AccountId = childAccount.Id),
                new Contact(FirstName = 'John', LastName = 'Doe2', AccountId = childAccount.Id),
                new Contact(FirstName = 'John', LastName = 'Doe3', AccountId = childAccount.Id)
            };
            databaseService.insertRecords(contacts);

            contacts[0].MailingCity = 'Test City';
            databaseService.updateRecord(contacts[0]);
            databaseService.upsertRecord(contacts[1], Contact.Id);
            databaseService.deleteRecord(contacts[2]);
        }
    }

    @IsTest
    static void shouldAssignCorrectIds() {
        DummyAccountService service = new DummyAccountService();
        DatabaseService db = service.databaseService.mockDmls();


        Test.startTest();
        service.doBusinessLogic();
        Test.stopTest();


        Assert.areEqual(3, db.register.inserts.size());
        Account parentAccount = (Account) db.register.inserts[0].dmlRows[0];
        Account childAccount = (Account) db.register.inserts[1].dmlRows[0];
        Contact contact1 = (Contact) db.register.inserts[2].dmlRows[0];
        Contact contact2 = (Contact) db.register.inserts[2].dmlRows[1];

        Assert.areEqual('Parent Account', parentAccount.Name);
        Assert.isNotNull(parentAccount.Id);
        Assert.areEqual(Account.SObjectType, parentAccount.Id.getSobjectType());

        Assert.areEqual('Child Account', childAccount.Name);
        Assert.areEqual(parentAccount.Id, childAccount.ParentId);
        Assert.areNotEqual(parentAccount.Id, childAccount.Id);
        Assert.isNotNull(childAccount.Id);
        Assert.areEqual(Account.SObjectType, childAccount.Id.getSobjectType());

        Assert.areEqual('Doe1', contact1.LastName);
        Assert.areEqual(childAccount.Id, contact1.AccountId);
        Assert.isNotNull(contact1.Id);
        Assert.areEqual(Contact.SObjectType, contact1.Id.getSobjectType());
        Assert.areNotEqual(contact1.Id, contact2.Id);

        Assert.areEqual(1, db.register.updates.size());
        Assert.areEqual(1, db.register.upserts.size());
        Assert.areEqual(1, db.register.deletes.size());
    }


    @IsTest
    static void shouldMockDMLErrorForAllContactsOnDelete() {
        DatabaseService db = new DatabaseService()
            .allOrNone(false)
            .mockDmls()
            .mockDmlError(DML.Type.DELETE_DML, new Contact());

        Test.startTest();
        List<DML.Result> deleteResults = db.deleteRecords(new List<Contact>{
            new Contact(LastName = 'Doe1'),
            new Contact(LastName = 'Doe2'),
            new Contact(LastName = 'Doe3')
        });
        Test.stopTest();


        for (DML.Result result : deleteResults) {
            Assert.areEqual(false, result.success);
            Assert.areEqual(1, result.errors.size());
            Assert.areEqual(DML.GENERIC_ERROR, result.errors.get(0).message);
        }
    }


    /**
     * Mock should match records by provided fields. If all fields match, error is added to that record.
     * Here we expect contact with AccountId = accountId2 to fail during delete.
     */
    @IsTest
    static void shouldMockDMLErrorForSpecificContact() {
        Id accountId = DatabaseService.getFakeId(Account.SObjectType);

        DatabaseService db = new DatabaseService()
            .allOrNone(false)
            .mockDmls()
            .mockDmlError(DML.Type.DELETE_DML, new Contact(
                AccountId = accountId
            ));


        Test.startTest();
        List<DML.Result> deleteResults = db.deleteRecords(new List<Contact>{
            new Contact(Id = DatabaseService.getFakeId(Contact.SObjectType), FirstName = 'John', LastName = 'Doe1', AccountId = DatabaseService.getFakeId(Account.SObjectType)),
            new Contact(Id = DatabaseService.getFakeId(Contact.SObjectType), FirstName = 'John', LastName = 'Doe2', AccountId = accountId),
            new Contact(Id = DatabaseService.getFakeId(Contact.SObjectType), FirstName = 'John', LastName = 'Doe3', AccountId = DatabaseService.getFakeId(Account.SObjectType))
        });
        Test.stopTest();


        Assert.isTrue(deleteResults[0].success);
        Assert.isFalse(deleteResults[1].success);
        Assert.isTrue(deleteResults[2].success);
    }


    @IsTest
    static void shouldMatchDMLErrorByDMLType() {
        DatabaseService db = new DatabaseService()
            .allOrNone(false)
            .mockDmls()
            .mockDmlError(DML.Type.UPDATE_DML, new Contact(LastName = 'Doe1'))
            .mockDmlError(DML.Type.DELETE_DML);

        Account account = new Account();
        Contact contact = new Contact(LastName = 'Doe1');


        Assert.isTrue(db.insertRecord(account).success);
        Assert.isTrue(db.updateRecord(account).success);
        Assert.isTrue(db.upsertRecord(account, Schema.Account.Id).success);
        Assert.isFalse(db.deleteRecord(account).success, 'All deletes should fail');
        Assert.isTrue(db.undeleteRecord(account).success);

        Assert.isTrue(db.insertRecord(contact).success);
        Assert.isFalse(db.updateRecord(contact).success, 'Specific Contact Updates should fail');
        Assert.isTrue(db.upsertRecord(contact, Schema.Account.Id).success);
        Assert.isFalse(db.deleteRecord(contact).success, 'All deletes should fail');
    }


    @IsTest
    static void shouldFailOnAnyDMLForSpecificSObject() {
        DatabaseService db = new DatabaseService()
            .allOrNone(false)
            .mockDmls()
            .mockDmlError(new Contact());

        Account account = new Account();
        Contact contact = new Contact();


        DML.Result result = db.insertRecord(account);
        Assert.isTrue(result.success);
        Assert.isTrue(db.updateRecord(account).success);
        Assert.isTrue(db.upsertRecord(account, Schema.Account.Id).success);
        Assert.isTrue(db.deleteRecord(account).success);
        Assert.isTrue(db.undeleteRecord(account).success);

        Assert.isFalse(db.insertRecord(contact).success);
        Assert.isFalse(db.updateRecord(contact).success);
        Assert.isFalse(db.upsertRecord(contact, Schema.Account.Id).success);
        Assert.isFalse(db.deleteRecord(contact).success);
        Assert.isFalse(db.undeleteRecord(contact).success);
    }


    @IsTest
    static void shouldThrowDMLExceptionOnError() {
        DatabaseService db = new DatabaseService()
            .mockDmls()
            .mockDmlError(DML.Type.INSERT_DML);

        try {
            db.insertRecord(new Contact(LastName = 'Doe1'));
            Assert.fail('Should throw exception');

        } catch (Exception e) {
            Assert.isInstanceOfType(e, DmlException.class);
            Assert.areEqual(DML.GENERIC_ERROR, e.getMessage());
        }
    }

    @IsTest
    static void shouldMockQuery() {
        Account account = new Account(Name = 'Test');
        DatabaseService db = new DatabaseService()
            .mockQuery('getById', new List<Account>{account});

        List<SObject> result = db.query('getById', 'SELECT Id FROM Account WHERE Name = :accName',
            new Map<String, Object>{'accName' => 'Test'});

        Assert.isInstanceOfType(result, List<Account>.class);
        Assert.areEqual(1, result.size());
        Assert.areEqual('Test', result[0].get('Name'));
        Assert.areEqual(1, db.register.queries.size());
        List<Account> records = (List<Account>) db.register.queries[0].results;
        Assert.areEqual(account, records.get(0));
    }

    @IsTest
    static void shouldMockQueryBySObject() {
        DatabaseService db = new DatabaseService()
            .mockQuery(new List<Account>{new Account(Name = 'Test')});

        List<SObject> result = db.query('SELECT Id FROM Account WHERE Name = :accName',
            new Map<String, Object>{'accName' => 'Test'});

        Assert.isInstanceOfType(result, List<Account>.class);
        Assert.areEqual(1, result.size());
        Assert.areEqual('Test', result[0].get('Name'));
    }

    @IsTest
    static void shouldThrowMockedQueryException() {
        DatabaseService db = new DatabaseService()
            .mockQuery(Account.SObjectType, new QueryException('Test Exception'));

        try {
            db.query('SELECT Id FROM Account');
            Assert.fail();
        } catch (Exception e) {
            Assert.isInstanceOfType(e, QueryException.class);
            Assert.areEqual('Test Exception', e.getMessage());
        }

    }

    @IsTest
    static void shouldMergeRecords() {
        DatabaseService db = new DatabaseService()
            .mockDmls();

        Account account1 = new Account(Id = DatabaseService.getFakeId(Account.SObjectType), Name = 'Test1');
        List<Id> duplicateIds = new List<Id>{
            DatabaseService.getFakeId(Account.SObjectType),
            DatabaseService.getFakeId(Account.SObjectType)
        };
        Test.startTest();
        DML.MergeResult mergeResult = db.mergeRecords(account1, duplicateIds);
        Test.stopTest();

        Assert.isTrue(mergeResult.success);
    }

    @IsTest
    static void shouldMergeRecordsWithError() {
        DatabaseService db = new DatabaseService()
            .allOrNone(false)
            .mockDmlError(DML.Type.MERGE_DML);

        Account account1 = new Account(Id = DatabaseService.getFakeId(Account.SObjectType), Name = 'Test1');
        List<Id> duplicateIds = new List<Id>{
            DatabaseService.getFakeId(Account.SObjectType),
            DatabaseService.getFakeId(Account.SObjectType)
        };

        Test.startTest();
        DML.MergeResult mergeResult = db.mergeRecords(account1, duplicateIds);
        Test.stopTest();


        Assert.isFalse(mergeResult.success);
    }

    @IsTest
    static void shouldConvertLeads() {
        DatabaseService db = new DatabaseService()
            .mockDmls();

        Database.LeadConvert leadConvert = new Database.LeadConvert();
        leadConvert.setLeadId(DatabaseService.getFakeId(Lead.SObjectType));

        Test.startTest();
        DML.Result leadConvertResult = db.convertLead(leadConvert);
        Test.stopTest();


        Assert.isTrue(leadConvertResult.success);
    }

    @IsTest
    static void shouldConvertLeadsWithErrors() {
        DatabaseService db = new DatabaseService()
            .allOrNone(false)
            .mockDmls()
            .mockDmlError(DML.Type.CONVERT_LEAD_DML);

        Database.LeadConvert leadConvert = new Database.LeadConvert();
        leadConvert.setLeadId(DatabaseService.getFakeId(Lead.SObjectType));

        Test.startTest();
        DML.Result leadConvertResult = db.convertLead(leadConvert);
        Test.stopTest();


        Assert.isFalse(leadConvertResult.success);
    }

    @IsTest
    static void testCountQuery() {
        String soql = 'SELECT COUNT() FROM User';
        DatabaseService db = new DatabaseService();

        Assert.areEqual(
            Database.countQuery(soql),
            db.countQuery(soql)
        );
    }

    @IsTest
    static void testCountQueryWithMock() {
        String soql = 'SELECT COUNT() FROM User';
        String mockId = 'myQuery';
        Integer mockResult = 5;

        DatabaseService db = new DatabaseService()
            .mockQuery(mockId, mockResult);

        Assert.areEqual(
            mockResult,
            db.countQuery(mockId, soql, null)
        );
        Assert.areEqual(0, Limits.getQueries());
        Assert.areEqual(0, Limits.getQueryRows());

        DML.QueryCountOperation[] operations = (DML.QueryCountOperation[]) db.register.get(DML.Type.QUERY_COUNT);
        Assert.areEqual(1, operations.size());
        Assert.areEqual(mockResult, operations[0].result);
        Assert.areEqual(soql, operations[0].soql);
    }
}