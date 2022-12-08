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
 * /
 * *
 *  Please find newest source code at https://github.com/amorek/Apex-Opensource-Library
 * /
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
            databaseService.doInsert(parentAccount);

            Account childAccount = new Account(Name = 'Child Account', ParentId = parentAccount.Id);
            databaseService.doInsert(childAccount);


            List<Contact> contacts = new List<Contact>{
                new Contact(FirstName = 'John', LastName = 'Doe1', AccountId = childAccount.Id),
                new Contact(FirstName = 'John', LastName = 'Doe2', AccountId = childAccount.Id),
                new Contact(FirstName = 'John', LastName = 'Doe3', AccountId = childAccount.Id)
            };
            databaseService.doInsert(contacts);

            contacts[0].MailingCity = 'Test City';
            databaseService.doUpdate(contacts[0]);
            databaseService.doUpsert(contacts[1], Contact.Name);
            databaseService.doDelete(contacts[2]);
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

        Assert.areEqual(5, db.inserted.size());
        Account parentAccount = (Account) db.inserted.get(0);
        Account childAccount = (Account) db.inserted.get(1);
        Contact contact1 = (Contact) db.inserted.get(2);
        Contact contact2 = (Contact) db.inserted.get(3);

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

        Assert.areEqual(1, db.updated.size());
        Assert.areEqual(1, db.upserted.size());
        Assert.areEqual(1, db.deleted.size());
    }


    @IsTest
    static void shouldMockDMLErrorForAllContactsOnDelete() {
        dbService.allOrNone(false);
        dbMock.mockDmlError(DmlType.DELETE_DML, new Contact());


        Test.startTest();
        List<Database.DeleteResult> deleteResults = dbService.doDelete(new List<Contact>{
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
        List<Database.DeleteResult> deleteResults = dbService.doDelete(new List<Contact>{
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


        Assert.isTrue(dbService.doInsert(account).success);
        Assert.isTrue(dbService.doUpdate(account).success);
        Assert.isTrue(dbService.doUpsert(account, Schema.Account.Name).success);
        Assert.isFalse(dbService.doDelete(account).success, 'All deletes should fail');
        Assert.isTrue(dbService.doUndelete(account).success);

        Assert.isTrue(dbService.doInsert(contact).success);
        Assert.isFalse(dbService.doUpdate(contact).success, 'Specific Contact Updates should fail');
        Assert.isTrue(dbService.doUpdate(new Contact(LastName = 'OtherDoe')).success);
        Assert.isTrue(dbService.doUpsert(contact, Schema.Account.Name).success);
        Assert.isFalse(dbService.doDelete(contact).success, 'All deletes should fail');
    }


    @IsTest
    static void shouldFailOnAnyDMLForSpecificSObject() {
        dbService.allOrNone(false);
        dbMock.mockDmlError(new Contact());

        Account account = new Account();
        Contact contact = new Contact();

        Assert.isTrue(dbService.doInsert(account).success);
        Assert.isTrue(dbService.doUpdate(account).success);
        Assert.isTrue(dbService.doUpsert(account, Schema.Account.Name).success);
        Assert.isTrue(dbService.doDelete(account).success);
        Assert.isTrue(dbService.doUndelete(account).success);

        Assert.isFalse(dbService.doInsert(contact).success);
        Assert.isFalse(dbService.doUpdate(contact).success);
        Assert.isFalse(dbService.doUpsert(contact, Schema.Account.Name).success);
        Assert.isFalse(dbService.doDelete(contact).success);
        Assert.isFalse(dbService.doUndelete(contact).success);
    }


    @IsTest
    static void shouldThrowDMLExceptionOnError() {
        dbService.allOrNone(true);
        dbMock.mockDmlError(DmlType.ANY_DML);


        try {
            Database.SaveResult saveResults = dbService.doInsert(new Contact(LastName = 'Doe1'));
            Assert.fail('Should throw exception');

        } catch (Exception e) {
            Assert.isInstanceOfType(e, DmlException.class);
            Assert.areEqual(DatabaseMock.GENERIC_ERROR, e.getMessage());
        }
    }
}