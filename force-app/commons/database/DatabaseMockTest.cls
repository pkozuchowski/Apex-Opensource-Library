/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2022 Piotr Kożuchowski
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
*/

@IsTest(IsParallel=true)
private class DatabaseMockTest {
    private static DatabaseService dbService = new DatabaseService();
    private static DatabaseMock dbMock = dbService.useMock();

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
            databaseService.upsertRecord(contacts[1], Contact.Name);
            databaseService.deleteRecord(contacts[2]);
        }
    }


    @IsTest
    static void shouldAssignCorrectIds() {
        DummyAccountService service = new DummyAccountService();
        DatabaseMock db = service.databaseService.useMock();


        Test.startTest();
        service.doBusinessLogic();
        Test.stopTest();

        System.debug(JSON.serializePretty(db));

        Assert.areEqual(5, db.insertedRecords.size());
        Account parentAccount = (Account) db.insertedRecords.get(0);
        Account childAccount = (Account) db.insertedRecords.get(1);
        Contact contact1 = (Contact) db.insertedRecords.get(2);
        Contact contact2 = (Contact) db.insertedRecords.get(3);

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

        Assert.areEqual(1, db.updatedRecords.size());
        Assert.areEqual(1, db.upsertedRecords.size());
        Assert.areEqual(1, db.deletedRecords.size());
    }


    @IsTest
    static void shouldMockDMLErrorForAllContactsOnDelete() {
        dbService.allOrNone(false);
        dbMock.mockDmlError(DmlType.DELETE_DML, new Contact());


        Test.startTest();
        List<Database.DeleteResult> deleteResults = dbService.deleteRecords(new List<Contact>{
            new Contact(LastName = 'Doe1'),
            new Contact(LastName = 'Doe2'),
            new Contact(LastName = 'Doe3')
        });
        Test.stopTest();


        for (Database.DeleteResult deleteResult : deleteResults) {
            Assert.areEqual(false, deleteResult.success);
            Assert.areEqual(1, deleteResult.errors.size());
            Assert.areEqual(DatabaseMock.GENERIC_ERROR, deleteResult.errors.get(0).message);
        }
    }


    /**
     * Mock should match records by provided fields. If all fields match, error is added to that record.
     * Here we expect contact with AccountId = accountId2 to fail during delete.
     */
    @IsTest
    static void shouldMockDMLErrorForSpecificContact() {
        Id accountId = DatabaseService.getFakeId(Account.SObjectType);

        dbService.allOrNone(false);
        dbMock.mockDmlError(DmlType.DELETE_DML, new Contact(
            AccountId = accountId
        ));


        Test.startTest();
        List<Database.DeleteResult> deleteResults = dbService.deleteRecords(new List<Contact>{
            new Contact(FirstName = 'John', LastName = 'Doe1', AccountId = DatabaseService.getFakeId(Account.SObjectType)),
            new Contact(FirstName = 'John', LastName = 'Doe2', AccountId = accountId),
            new Contact(FirstName = 'John', LastName = 'Doe3', AccountId = DatabaseService.getFakeId(Account.SObjectType))
        });
        Test.stopTest();


        Assert.isTrue(deleteResults[0].success);
        Assert.isFalse(deleteResults[1].success);
        Assert.isTrue(deleteResults[2].success);
    }


    @IsTest
    static void shouldMatchDMLErrorByDMLType() {
        dbService.allOrNone(false);
        dbMock.mockDmlError(DmlType.UPDATE_DML, new Contact(LastName = 'Doe1'))
            .mockDmlError(DmlType.DELETE_DML);

        Account account = new Account();
        Contact contact = new Contact(LastName = 'Doe1');


        Assert.isTrue(dbService.insertRecord(account).success);
        Assert.isTrue(dbService.updateRecord(account).success);
        Assert.isTrue(dbService.upsertRecord(account, Schema.Account.Name).success);
        Assert.isFalse(dbService.deleteRecord(account).success, 'All deletes should fail');
        Assert.isTrue(dbService.undeleteRecord(account).success);

        Assert.isTrue(dbService.insertRecord(contact).success);
        Assert.isFalse(dbService.updateRecord(contact).success, 'Specific Contact Updates should fail');
        Assert.isTrue(dbService.updateRecord(new Contact(LastName = 'OtherDoe')).success);
        Assert.isTrue(dbService.upsertRecord(contact, Schema.Account.Name).success);
        Assert.isFalse(dbService.deleteRecord(contact).success, 'All deletes should fail');
    }


    @IsTest
    static void shouldFailOnAnyDMLForSpecificSObject() {
        dbService.allOrNone(false);
        dbMock.mockDmlError(new Contact());

        Account account = new Account();
        Contact contact = new Contact();

        Assert.isTrue(dbService.insertRecord(account).success);
        Assert.isTrue(dbService.updateRecord(account).success);
        Assert.isTrue(dbService.upsertRecord(account, Schema.Account.Name).success);
        Assert.isTrue(dbService.deleteRecord(account).success);
        Assert.isTrue(dbService.undeleteRecord(account).success);

        Assert.isFalse(dbService.insertRecord(contact).success);
        Assert.isFalse(dbService.updateRecord(contact).success);
        Assert.isFalse(dbService.upsertRecord(contact, Schema.Account.Name).success);
        Assert.isFalse(dbService.deleteRecord(contact).success);
        Assert.isFalse(dbService.undeleteRecord(contact).success);
    }


    @IsTest
    static void shouldThrowDMLExceptionOnError() {
        dbService.allOrNone(true);
        dbMock.mockDmlError(DmlType.ANY_DML);


        try {
            Database.SaveResult saveResults = dbService.insertRecord(new Contact(LastName = 'Doe1'));
            Assert.fail('Should throw exception');

        } catch (Exception e) {
            Assert.isInstanceOfType(e, DmlException.class);
            Assert.areEqual(DatabaseMock.GENERIC_ERROR, e.getMessage());
        }
    }

    @IsTest
    static void shouldMockQuery() {
        dbMock.mockQuery('getById', new List<Account>{new Account(Name = 'Test')});

        List<SObject> result = dbService.query('getById', 'SELECT Id FROM Account WHERE Name = :accName',
            new Map<String, Object>{'accName' => 'Test'});

        Assert.isInstanceOfType(result, List<Account>.class);
        Assert.areEqual(1, result.size());
        Assert.areEqual('Test', result[0].get('Name'));
    }

    @IsTest
    static void testMockCursor() {
        Database.Cursor c = (Database.Cursor) Test.createStub(List<Database.Cursor>.class, new DatabaseMock.CursorMock(new List<User>{
            new User(LastName = 'Dupa'),
            new User(LastName = 'Dupa1')
        }));
    }
}