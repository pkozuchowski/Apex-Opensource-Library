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

@IsTest(IsParallel=true)
private class DatabaseUnitOfWorkTest {

    @IsTest
    static void shouldCommitDMLs() {
        DatabaseUnitOfWork uow = (DatabaseUnitOfWork) new DatabaseUnitOfWork()
            .mockDmls();

        Account account = new Account(Name = 'Test');
        uow.insertRecord(account);
        uow.commitWork();

        Assert.isNotNull(account.Id);
        Assert.areEqual(account, uow.register.inserts[0].dmlRows[0]);
    }

    @IsTest
    static void shouldResolveLookups() {
        Account parent = new Account(Name = 'Test');
        Contact child = new Contact();

        DatabaseUnitOfWork uow = (DatabaseUnitOfWork) new DatabaseUnitOfWork()
            .mockDmls();

        uow.insertRecord(parent);
        uow.insertRecord(child, Contact.AccountId, parent);
        uow.commitWork();

        Assert.isNotNull(parent.Id);
        Assert.isNotNull(child.Id);
        Assert.areEqual(parent.Id, child.AccountId);
    }

    /**
     * In this test, we areing insert and subsequent update of the same record.
     */
    @IsTest
    static void shouldUpdateRecords() {
        DatabaseUnitOfWork uow = (DatabaseUnitOfWork) new DatabaseUnitOfWork()
            .mockDmls();

        Account acc = new Account(Name = 'Test');
        Account sameAccountUpdated = new Account(Name = 'Test2');

        Test.startTest();
        uow.insertRecord(acc);
        uow.updateRecord(sameAccountUpdated, Account.Id, acc);
        uow.commitWork();
        Test.stopTest();

        Assert.isNotNull(acc.Id);
        Assert.areEqual(acc.Id, sameAccountUpdated.Id);
        Assert.areEqual(1, uow.register.inserts.size());
        Assert.areEqual(1, uow.register.updates.size());
        Assert.areEqual(acc, uow.register.inserts[0].dmlRows[0]);
        Assert.areEqual(sameAccountUpdated, uow.register.updates[0].dmlRows[0]);
    }

    @IsTest
    static void shouldAutomaticallyUseDMLOperationsOrder() {
        DatabaseUnitOfWork uow = (DatabaseUnitOfWork) new DatabaseUnitOfWork()
            .mockDmls();

        Account parentAccount = new Account(Name = 'Test');
        Contact childContact = new Contact(LastName = 'Doe');


        Test.startTest();
        uow.insertRecord(parentAccount);
        uow.upsertRecord(childContact, Contact.Id, Contact.AccountId, parentAccount);
        uow.updateRecord(childContact);
        uow.upsertRecord(new User(), Schema.User.Username);
        uow.deleteRecord(childContact);
        uow.deleteRecord(parentAccount);
        uow.undeleteRecord(parentAccount);
        uow.insertRecord(new Account());
        uow.insertRecord(new Account());
        uow.insertRecord(new Contact());

        List<DML.DMLOperation> operations = uow.commitWork();
        Test.stopTest();

        Assert.isTrue(isOperationOrderValid(new List<DML.Order >{
            new DML.Order(Account.SObjectType, DML.Type.INSERT_DML),
            new DML.Order(Contact.SObjectType, DML.Type.UPSERT_DML, Contact.Id),
            new DML.Order(Contact.SObjectType, DML.Type.UPDATE_DML),
            new DML.Order(User.SObjectType, DML.Type.UPSERT_DML, Schema.User.Username),
            new DML.Order(Contact.SObjectType, DML.Type.DELETE_DML),
            new DML.Order(Account.SObjectType, DML.Type.DELETE_DML),
            new DML.Order(Account.SObjectType, DML.Type.UNDELETE_DML),
            new DML.Order(Contact.SObjectType, DML.Type.INSERT_DML)
        }, operations));
    }

    @IsTest
    static void shouldUseSpecifiedOrderList() {
        DatabaseUnitOfWork uow = (DatabaseUnitOfWork) new DatabaseUnitOfWork(new List<DML.Order>{
            new DML.Order(User.SObjectType, DML.Type.UPSERT_DML, Schema.User.Username),
            new DML.Order(User.SObjectType, DML.Type.UPSERT_DML, Schema.User.FederationIdentifier),
            new DML.Order(Contact.SObjectType, DML.Type.INSERT_DML),
            new DML.Order(Opportunity.SObjectType, DML.Type.DELETE_DML),
            new DML.Order(Opportunity.SObjectType, DML.Type.INSERT_DML)
        }).mockDmls();

        Test.startTest();
        uow.insertRecord(new Account());
        uow.insertRecord(new Contact());
        uow.insertRecord(new Opportunity());
        uow.deleteRecord(new Opportunity(Id = DatabaseService.getFakeId(Opportunity.SObjectType)));
        uow.upsertRecord(new User(), User.FederationIdentifier);
        uow.upsertRecord(new User(), User.Username);

        List<DML.DMLOperation> operations = uow.commitWork();
        Test.stopTest();

        Assert.isTrue(isOperationOrderValid(new List<DML.Order>{
            new DML.Order(User.SObjectType, DML.Type.UPSERT_DML, Schema.User.Username),
            new DML.Order(User.SObjectType, DML.Type.UPSERT_DML, Schema.User.FederationIdentifier),
            new DML.Order(Contact.SObjectType, DML.Type.INSERT_DML),
            new DML.Order(Opportunity.SObjectType, DML.Type.DELETE_DML),
            new DML.Order(Opportunity.SObjectType, DML.Type.INSERT_DML),
            new DML.Order(Account.SObjectType, DML.Type.INSERT_DML)
        }, operations));
    }


    @IsTest
    static void shouldUseSpecifiedSObjectOrderList() {
        DatabaseUnitOfWork uow = (DatabaseUnitOfWork) new DatabaseUnitOfWork(new List<SObjectType>{
            Account.SObjectType,
            Contact.SObjectType,
            User.SObjectType
        })
            .mockDmls();

        Account acc = new Account();
        Contact cntc = new Contact();
        User usr = new User();

        Test.startTest();
        uow.insertRecord(acc);
        uow.insertRecord(cntc);
        uow.insertRecord(usr);
        uow.updateRecord(acc);
        uow.updateRecord(cntc);
        uow.updateRecord(usr);
        Test.stopTest();


        List<DML.DMLOperation> operations = uow.commitWork();
        Assert.isTrue(isOperationOrderValid(new List<DML.Order>{
            new DML.Order(Account.SObjectType, DML.Type.INSERT_DML),
            new DML.Order(Account.SObjectType, DML.Type.UPDATE_DML),
            new DML.Order(Contact.SObjectType, DML.Type.INSERT_DML),
            new DML.Order(Contact.SObjectType, DML.Type.UPDATE_DML),
            new DML.Order(User.SObjectType, DML.Type.INSERT_DML),
            new DML.Order(User.SObjectType, DML.Type.UPDATE_DML)
        }, operations));
    }

    @IsTest
    static void shouldRegisterUpsertRecords() {
        DatabaseUnitOfWork uow = (DatabaseUnitOfWork) new DatabaseUnitOfWork()
            .mockDmls();

        User usr = new User(Username = 'test');


        Test.startTest();
        uow.upsertRecord(usr, User.Username);
        uow.commitWork();
        Test.stopTest();


        Assert.isNotNull(usr.Id);
        Assert.areEqual(usr, uow.register.upserts[0].dmlRows[0]);
    }

    @IsTest
    static void shouldRegisterDeletedRecords() {
        DatabaseUnitOfWork uow = (DatabaseUnitOfWork) new DatabaseUnitOfWork()
            .mockDmls();
        Account account = new Account(Name = 'Test');


        Test.startTest();
        uow.insertRecord(account);
        uow.deleteRecord(account);
        uow.undeleteRecord(account);
        uow.commitWork();
        Test.stopTest();


        Assert.areEqual(account, uow.register.inserts[0].dmlRows[0]);
        Assert.areEqual(account, uow.register.deletes[0].dmlRows[0]);
        Assert.areEqual(account, uow.register.undeletes[0].dmlRows[0]);
    }

    @IsTest
    static void shouldHaveCorrectOrderInMixedLists() {
        DatabaseUnitOfWork uow = (DatabaseUnitOfWork) new DatabaseUnitOfWork()
            .mockDmls();


        Test.startTest();
        uow.insertRecords(new List<SObject>{
            new Account(),
            new Contact(),
            new Opportunity(),
            new Contact(),
            new Account()
        });
        List<DML.DMLOperation> operations = uow.commitWork();
        Test.stopTest();


        Assert.isTrue(isOperationOrderValid(new List<DML.Order>{
            new DML.Order(Account.SObjectType, DML.Type.INSERT_DML),
            new DML.Order(Contact.SObjectType, DML.Type.INSERT_DML),
            new DML.Order(Opportunity.SObjectType, DML.Type.INSERT_DML)
        }, operations));
    }

    @IsTest
    static void shouldHaveCorrectOrderWithMixedOrderItems() {
        DatabaseUnitOfWork uow = (DatabaseUnitOfWork) new DatabaseUnitOfWork(new List<DML.Order>{
            new DML.Order(Opportunity.SObjectType),
            new DML.Order(Account.SObjectType),
            new DML.Order(Account.SObjectType, DML.Type.INSERT_DML)
        })
            .mockDmls();

        uow.insertRecord(new Account());
        uow.updateRecord(new Account());
        uow.insertRecord(new Opportunity());
        uow.insertRecord(new Contact());

        List<DML.DMLOperation> operations = uow.commitWork();


        Assert.isTrue(isOperationOrderValid(new List<DML.Order>{
            new DML.Order(Opportunity.SObjectType, DML.Type.INSERT_DML),
            new DML.Order(Account.SObjectType, DML.Type.UPDATE_DML),
            new DML.Order(Account.SObjectType, DML.Type.INSERT_DML),
            new DML.Order(Contact.SObjectType, DML.Type.INSERT_DML)
        }, operations));
    }

    @IsTest
    static void shouldBeAbleToDiscardWork() {
        DatabaseUnitOfWork uow = (DatabaseUnitOfWork) new DatabaseUnitOfWork()
            .mockDmls();

        Test.startTest();
        uow.insertRecords(new List<SObject>{
            new Account(Name = 'Test 1'),
            new Contact(),
            new Opportunity(),
            new Account(Name = 'Test 2')
        });

        List<DML.Operation> discardedOperations = uow.discardWork();
        List<DML.Operation> executedOperations = uow.commitWork();
        Test.stopTest();


        Assert.areEqual(3, discardedOperations.size());
        Assert.isTrue(executedOperations.isEmpty());
    }

    @IsTest
    static void shouldDiscardWorkOnCommit() {
        DatabaseUnitOfWork uow = (DatabaseUnitOfWork) new DatabaseUnitOfWork()
            .mockDmls();

        Test.startTest();
        uow.insertRecords(new List<SObject>{
            new Account(),
            new Contact(),
            new Opportunity()
        });

        List<DML.Operation> operation1 = uow.commitWork();
        List<DML.Operation> operation2 = uow.commitWork();

        uow.insertRecord(new Account());
        List<DML.DMLOperation> operation3 = uow.commitWork();
        Test.stopTest();


        Assert.areEqual(3, operation1.size(), 'Should commit all work on first call');
        Assert.isTrue(operation2.isEmpty(), 'Should not repeat DMLs on subsequent calls');
        Assert.areEqual(1, operation3.size(), 'Should only commit new work on subsequent calls');
        Assert.isInstanceOfType(operation3.get(0), DML.InsertDML.class);
        Assert.areEqual(Account.SObjectType, operation3.get(0).sObjectType);
    }

    @IsTest
    static void shouldRollbackOnError() {
        DatabaseUnitOfWork uow = (DatabaseUnitOfWork) new DatabaseUnitOfWork()
            .allOrNone(true)
            .mockDmls()
            .mockDmlError(DML.Type.INSERT_DML, new Contact());

        Exception ex;
        Integer dmls;

        Test.startTest();
        try {
            uow.insertRecords(new List<SObject>{
                new Account(),
                new Contact(),
                new Opportunity()
            });
            uow.commitWork();
        } catch (Exception e) {
            ex = e;
            dmls = Limits.getDmlStatements();
        }
        Test.stopTest();


        Assert.isNotNull(ex, 'Should throw exception');
        Assert.areEqual(3, dmls, 'Should call setSavepoint, rollbackSavepoint and releaseSavepoint');
    }

    @IsTest
    static void shouldPopulateSaveResultsWhenCommited() {
        DatabaseUnitOfWork uow = (DatabaseUnitOfWork) new DatabaseUnitOfWork()
            .allOrNone(false)
            .mockDmls()
            .mockDmlError(DML.Type.INSERT_DML, new Contact());

        DML.Result[] saveResultsAccount = uow.insertRecords(new List<Account>{
            new Account()
        });

        DML.Result[] saveResultsContact = uow.insertRecords(new List<Contact>{
            new Contact()
        });

        Assert.isTrue(saveResultsAccount.isEmpty());
        Assert.isTrue(saveResultsContact.isEmpty());

        uow.commitWork();
        Assert.areEqual(1, saveResultsAccount.size());
        Assert.areEqual(1, saveResultsContact.size());
        Assert.isTrue(saveResultsAccount.get(0).success);
        Assert.isFalse(saveResultsContact.get(0).success);
    }

    @IsTest
    static void shouldUpdateTheSameRecordWhenItsUpdatedInManyFlows() {
        DatabaseUnitOfWork uow = DatabaseUnitOfWorkFlow.uow;
        uow.mockDmls();

        Id accountId = DatabaseService.getFakeId(Account.SObjectType);
        Id accountId2 = DatabaseService.getFakeId(Account.SObjectType);

        //Simulate the invocable method calls
        DatabaseUnitOfWorkFlow.execute(new List<DatabaseUnitOfWorkFlow.Input>{
            input('update', new Account(Id = accountId, Name = 'Test1'), null),
            input('update', new Account(Id = accountId2, Name = 'Test2'), null)
        });

        // Second Flow call with the same record
        DatabaseUnitOfWorkFlow.execute(new List<DatabaseUnitOfWorkFlow.Input>{
            input('update', new Account(Id = accountId, ShippingCity = 'Warsaw'), null)
        });

        // Third Flow call
        DatabaseUnitOfWorkFlow.execute(new List<DatabaseUnitOfWorkFlow.Input>{
            input('insert', new Account(BillingCity = 'London'), null)
        });

        DatabaseUnitOfWorkFlow.execute(new List<DatabaseUnitOfWorkFlow.Input>{
            input('commit', null, null)
        });


        Assert.areEqual(1, uow.register.inserts.size());
        Assert.areEqual(1, uow.register.updates.size());
        Assert.areEqual(2, uow.register.updated.size());

        Account account = (Account) uow.register.updated[0];
        Assert.areEqual('Test1', account.Name);
        Assert.areEqual('Warsaw', account.ShippingCity);
    }

    @IsTest
    static void shouldDeduplicateRecordOnUpsert() {
        DatabaseUnitOfWork uow = DatabaseUnitOfWorkFlow.uow;
        uow.mockDmls();

        Id userId = DatabaseService.getFakeId(User.SObjectType);

        //Simulate the invocable method calls
        DatabaseUnitOfWorkFlow.execute(new List<DatabaseUnitOfWorkFlow.Input>{
            input('upsert', new User(Username = 'test@test.com', LastName = 'Doe'), 'Username')
        });

        // Second Flow call with the same record
        DatabaseUnitOfWorkFlow.execute(new List<DatabaseUnitOfWorkFlow.Input>{
            input('upsert', new User(Username = 'test@test.com', FirstName = 'John'), 'Username')
        });

        // Second Flow call with the same record
        DatabaseUnitOfWorkFlow.execute(new List<DatabaseUnitOfWorkFlow.Input>{
            input('delete', new User(Id = userId), null)
        });

        DatabaseUnitOfWorkFlow.Input input = input('commit', null, null);
        input.runInMode = 'systemWithSharing';
        DatabaseUnitOfWorkFlow.execute(new List<DatabaseUnitOfWorkFlow.Input>{
            input
        });


        Assert.areEqual(1, uow.register.upserts.size());
        Assert.areEqual(1, uow.register.deletes.size());

        User usr = (User) uow.register.upserted[0];
        Assert.areEqual('John', usr.FirstName);
        Assert.areEqual('Doe', usr.LastName);
        Assert.areEqual('test@test.com', usr.Username);
    }

    private static DatabaseUnitOfWorkFlow.Input input(
        String operationType,
        SObject record,
        String upsertField
    ) {
        DatabaseUnitOfWorkFlow.Input op = new DatabaseUnitOfWorkFlow.Input();
        op.operationType = operationType;
        op.record = record;
        op.upsertField = upsertField;

        return op;
    }

    /**
     * Validates that the order of operations in the actual list matches the expected order.
     *
     * @param expected The expected order of operations.
     * @param actual The actual list of DMLOperations.
     * @return True if the order is valid, false otherwise.
     */
    private static Boolean isOperationOrderValid(List<DML.Order> expected, List<DML.DMLOperation> actual) {
        Assert.areEqual(expected.size(), actual.size());

        for (Integer i = 0; i < expected.size(); i++) {
            Assert.areEqual(expected[i].operationId, actual[i].operationId);
        }

        return true;
    }
}