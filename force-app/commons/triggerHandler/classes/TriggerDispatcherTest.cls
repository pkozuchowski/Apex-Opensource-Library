/**
* MIT License
*
* Copyright (c) 2019 Piotr Kożuchowski
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
private class TriggerDispatcherTest {
    private static Map<Id, Boolean> ERRORS = new Map<Id, Boolean>();


    /**
     * This constructor can be called in Unit Tests to mock trigger execution for certain
     */
    private class TestTriggerContextImpl extends TriggerDispatcher.TriggerContextImpl {
        private TestTriggerContextImpl(TriggerOperation operation, List<SObject> triggerNew, List<SObject> triggerOld) {
            this.isExecuting = true;
            this.operationType = operation;
            this.isInsert = operation.name().contains('INSERT');
            this.isUpdate = operation.name().contains('UPDATE');
            this.isDelete = operation.name().contains('DELETE');
            this.isUndelete = operation.name().contains('UNDELETE');
            this.isBefore = operation.name().contains('BEFORE');
            this.isAfter = operation.name().contains('AFTER');
            this.size = triggerNew.size();

            this.triggerNew = triggerNew;
            this.triggerOld = triggerOld;
            this.triggerOldMap = triggerOld == null ? null : new Map<Id, SObject>(triggerOld);
            if (triggerNew != null && operation != TriggerOperation.BEFORE_INSERT) {
                this.triggerNewMap = new Map<Id, SObject>(triggerNew);
            }
            this.sObjectType = getRecords().getSObjectType();
        }
    }

    public static void mockInsert(List<SObject> records) {
        TriggerDispatcher.run(new TestAccountTriggerHandler(), new TestTriggerContextImpl(TriggerOperation.BEFORE_INSERT, records, null));
        TriggerDispatcher.run(new TestAccountTriggerHandler(), new TestTriggerContextImpl(TriggerOperation.AFTER_INSERT, records, null));
    }

    public static void mockUpdate(List<SObject> records, List<SObject> oldRecords) {
        TriggerDispatcher.run(new TestAccountTriggerHandler(), new TestTriggerContextImpl(TriggerOperation.BEFORE_UPDATE, records, oldRecords));
        TriggerDispatcher.run(new TestAccountTriggerHandler(), new TestTriggerContextImpl(TriggerOperation.AFTER_UPDATE, records, oldRecords));
    }

    public static void mockDelete(List<SObject> records) {
        TriggerDispatcher.run(new TestAccountTriggerHandler(), new TestTriggerContextImpl(TriggerOperation.BEFORE_DELETE, records, null));
        TriggerDispatcher.run(new TestAccountTriggerHandler(), new TestTriggerContextImpl(TriggerOperation.AFTER_DELETE, records, null));
    }

    public static void mockUndelete(List<SObject> records) {
        TriggerDispatcher.run(new TestAccountTriggerHandler(), new TestTriggerContextImpl(TriggerOperation.AFTER_UNDELETE, records, null));
    }

    /**
     * Emulation of AccountTriggerHandler class
     */
    private class TestAccountTriggerHandler extends TriggerHandler {
        public override void onBeforeUpdate(List<SObject> triggerNew, TriggerContext tc) {
            new AccountAddressPopulator().copyBillingAddressToEmptyShippingAddress(triggerNew, tc);
        }
    }

    /**
     * Emulation of Trigger logic class
     */
    private class AccountAddressPopulator {
        public void copyBillingAddressToEmptyShippingAddress(List<Account> accounts, TriggerContext tc) {

            for (Account record : accounts) {
                if (tc.isChanged(record, Account.BillingCountry)) {
                    record.ShippingCountry = record.BillingCountry;
                    record.ShippingCity = record.BillingCity;
                    /*Count how many times address is changed by triggers*/
                    record.NumberOfEmployees++;
                }
            }
        }
    }

    /**
     * Populates Billing Country to USA if it's blank
     */
    public class TestAccountBillingAddressDefault implements TriggerFieldDefault {
        public void prepare(List<SObject> records, TriggerContext tc) {
        }

        public void populate(SObject record, TriggerContext tc) {
            Account account = (Account) record;

            if (String.isBlank(account.BillingCountry)) {
                account.BillingCountry = 'USA';
            }
        }
    }

    /**
     * Checks if Billing Country is filled.
     * ERRORS map is only populated because field.addError() can't be tested without inserting records.
     */
    public class TestAccountBillingCountryValidation implements TriggerValidationRule {
        public void prepare(List<SObject> records, TriggerContext tc) {
        }

        public void validate(SObject record, TriggerContext tc) {
            Account account = (Account) record;

            if (String.isEmpty(account.BillingCountry)) {
                ERRORS.put(record.Id, true);
                ((Account) record).BillingCountry.addError('Billing Country cannot be empty');
            }
        }
    }

    /**
     * Simulates custom metadata defined class which performs some trigger logic.
     */
    public class TestTriggerLogic implements TriggerLogic {
        public void execute(List<SObject> records, TriggerContext ctx) {
            List<Account> accounts = records;

            for (Account account : accounts) {
                if (!account.Name.contains('(Customer)')) {
                    account.Name = '(Customer) ' + account.Name;
                }
            }
        }
    }

    /**
     * Example of metadata defined Async logic which filters records and does callout
     */
    public class TestAsyncLogic implements TriggerAsyncLogic {

        public List<SObject> filter(List<SObject> records, TriggerContext ctx) {
            List<SObject> filtered = new List<SObject>();

            for (Account account : (List<Account>) records) {
                if (String.isNotBlank(account.BillingCountry)) {
                    filtered.add(account);
                }
            }

            return filtered;
        }

        public void execute(List<SObject> records, QueueableContext ctx) {
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setEndpoint('https://example.com');
            request.setBody(JSON.serialize(records));

            new Http().send(request);
        }
    }


    /**
     *@description
     * This test simulates Account saving execution with triggers, workflow field updates and process builders.
     */
    @IsTest
    static void testUpdateFlow() {
        Account record = new Account(
                Id = '001000000000000',
                Name = 'Test Account',
                BillingCountry = 'USA',
                BillingCity = 'New York',
                NumberOfEmployees = 0
        );
        Account oldRecord = new Account(
                Id = '001000000000000',
                Name = 'Test Account'
        );


        Test.startTest();
        /*Record is updated from user interface and Billing address is added*/
        mockUpdate(new List<Account>{record}, new List<Account>{oldRecord});


        /*Workflow updates field on the record. Trigger is rerun with updated Trigger.new and original Trigger.old*/
        record.Website = 'www.TestAccount.com';
        mockUpdate(new List<Account>{record}, new List<Account>{oldRecord});


        /*Process Builder updates field on the record. Trigger is rerun with updated Trigger.new and Trigger.old*/
        oldRecord = record.clone(true);
        record.Phone = '(541) 754-3010';
        mockUpdate(new List<Account>{record}, new List<Account>{oldRecord});
        Test.stopTest();


        System.assertEquals(1, record.NumberOfEmployees, 'Record should go through trigger logic only once, because workflow did not change any of the observed fields.');
    }


    @IsTest
    static void testCoverage() {
        for (TriggerOperation triggerOperation : TriggerOperation.values()) {
            TriggerDispatcher.run(new TestAccountTriggerHandler(), new TestTriggerContextImpl(triggerOperation, new List<SObject>(), new List<SObject>()));
        }
    }


    /**
     * Coverage tests for TriggerContext helper methods
     */
    @IsTest
    static void testIsChangedHelperMethods() {
        Account record = new Account(
                Id = '001000000000000',
                Name = 'Test Account',
                BillingCountry = 'USA',
                BillingCity = 'New York',
                NumberOfEmployees = 0,
                Phone = '(541) 754-3010'
        );
        Account oldRecord = new Account(
                Id = '001000000000000',
                Name = 'Test Account',
                Phone = '(541) 754-3011'
        );

        TriggerContext ctx = new TestTriggerContextImpl(TriggerOperation.AFTER_UPDATE, new List<SObject>{record}, new List<SObject>{oldRecord});

        System.assertEquals(false, ctx.isNew());
        System.assertEquals(true, ctx.isChanged());
        System.assertEquals(false, ctx.isChanged(record, Account.Name));
        System.assertEquals(true, ctx.isChanged(record, Account.BillingCountry));
        System.assertEquals(true, ctx.isChanged(record, Account.BillingCity));
        System.assertEquals(true, ctx.isChanged(record, Account.Phone));

        System.assertEquals(true, ctx.isChangedTo(record, Account.BillingCountry, 'USA'));
        System.assertEquals(true, ctx.isChangedTo(record, Account.BillingCity, 'New York'));
        System.assertEquals(true, ctx.isChangedTo(record, Account.Phone, '(541) 754-3010'));
        System.assertEquals(false, ctx.isChangedTo(record, Account.BillingCity, 'Washington'));

        System.assertEquals(true, ctx.isChangedFrom(record, Account.BillingCountry, null));
        System.assertEquals(true, ctx.isChangedFrom(record, Account.BillingCity, null));
        System.assertEquals(true, ctx.isChangedFrom(record, Account.Phone, '(541) 754-3011'));
        System.assertEquals(false, ctx.isChangedFrom(record, Account.Name, 'Washington'));

        System.assertEquals(true, ctx.isChangedFromTo(record, Account.BillingCity, null, 'New York'));


        ctx = new TestTriggerContextImpl(TriggerOperation.AFTER_INSERT, new List<SObject>{record}, new List<SObject>{oldRecord});
        System.assertEquals(false, ctx.isChanged(record, Account.BillingCountry));
        System.assertEquals(false, ctx.isChangedTo(record, Account.BillingCity, 'New York'));
        System.assertEquals(false, ctx.isChangedFrom(record, Account.BillingCity, null));
        System.assert(ctx.getRecordsMap().containsKey('001000000000000'));
        System.assert(ctx.getRecordsIds().contains('001000000000000'));
    }


    /**
     * Trigger should execute field default rules specified in custom metadata for before update trigger.
     */
    @IsTest
    static void triggerShouldPopulateFieldsUsingTriggerFieldDefaultDefinedInSettings() {
        List<Account> accounts = new List<Account>{
                new Account(Id = '001000000000000'),
                new Account(Id = '001000000000001'),
                new Account(Id = '001000000000002')
        };
        TriggerContext tc = new TestTriggerContextImpl(TriggerOperation.BEFORE_UPDATE, accounts, accounts);
        TriggerLogicSelector.mockResponseByType.put('Field Default', new List<TriggerLogic__mdt>{
                new TriggerLogic__mdt(
                        IsEnabled__c = true,
                        ApexClass__c = 'TriggerDispatcherTest.TestAccountBillingAddressDefault',
                        Trigger__c = 'BEFORE_UPDATE',
                        SObject__c = 'Account',
                        Type__c = 'Field Default'
                )
        });


        Test.startTest();
        TriggerDispatcher.run(new TestAccountTriggerHandler(), tc);
        Test.stopTest();


        for (Account account : accounts) {
            System.assertEquals('USA', account.BillingCountry);
        }
    }


    /**
     * When invalid or unreachable type is specified in custom metadata, TypeException should be thrown with meaningful message.
     */
    @IsTest
    static void typeExceptionShouldBeThrownWhenInvalidClassIsDefinedInSettings() {
        List<Account> accounts = new List<Account>{
                new Account(Id = '001000000000000'),
                new Account(Id = '001000000000001'),
                new Account(Id = '001000000000002')
        };
        TriggerContext tc = new TestTriggerContextImpl(TriggerOperation.BEFORE_DELETE, accounts, accounts);
        TriggerLogicSelector.mockResponseByType.put('Field Default', new List<TriggerLogic__mdt>{
                new TriggerLogic__mdt(
                        IsEnabled__c = true,
                        ApexClass__c = 'TriggerDispatcherTest.InvalidClass',
                        Trigger__c = 'BEFORE_DELETE',
                        SObject__c = 'Account',
                        Type__c = 'Field Default'
                )
        });
        Exception ex;


        Test.startTest();
        try {
            TriggerDispatcher.run(new TestAccountTriggerHandler(), tc);
        } catch (Exception e) {
            ex = e;
        }
        Test.stopTest();


        System.assert(ex instanceof TypeException);
        System.assert(ex.getMessage().contains('(TriggerDispatcherTest.InvalidClass)'));
    }


    @IsTest
    static void triggerShouldExecuteTriggerLogicClassesDefinedInSettings() {
        List<Account> accounts = new List<Account>{
                new Account(Id = '001000000000000', Name = 'Test'),
                new Account(Id = '001000000000001', Name = 'Test'),
                new Account(Id = '001000000000002', Name = 'Test')
        };
        TriggerContext tc = new TestTriggerContextImpl(TriggerOperation.AFTER_UPDATE, accounts, accounts);
        TriggerLogicSelector.mockResponseByType.put('Logic', new List<TriggerLogic__mdt>{
                new TriggerLogic__mdt(
                        IsEnabled__c = true,
                        ApexClass__c = 'TriggerDispatcherTest.TestTriggerLogic',
                        Trigger__c = 'AFTER_UPDATE',
                        SObject__c = 'Account'
                )
        });


        Test.startTest();
        TriggerDispatcher.run(new TestAccountTriggerHandler(), tc);
        Test.stopTest();


        for (Account account : accounts) {
            System.assert(account.Name.startsWith('(Customer)'));
        }
    }


    /**
     * Trigger should execute field default rules specified in custom metadata for before insert trigger.
     */
    @IsTest
    static void triggerShouldValidateRecordsUsingValidationRulesDefinedInSettings() {
        List<Account> accounts = new List<Account>{
                new Account(Id = '001000000000001', Name = 'Test'),
                new Account(Id = '001000000000002', Name = 'Test', BillingCountry = 'USA'),
                new Account(Id = '001000000000003', Name = 'Test')
        };
        TriggerContext tc = new TestTriggerContextImpl(TriggerOperation.BEFORE_INSERT, accounts, null);
        TriggerLogicSelector.mockResponseByType.put('Validation Rule', new List<TriggerLogic__mdt>{
                new TriggerLogic__mdt(
                        IsEnabled__c = true,
                        ApexClass__c = 'TriggerDispatcherTest.TestAccountBillingCountryValidation',
                        Trigger__c = 'BEFORE_INSERT',
                        SObject__c = 'Account',
                        Type__c = 'Validation Rule'
                )
        });


        Test.startTest();
        TriggerDispatcher.run(new TestAccountTriggerHandler(), tc);
        Test.stopTest();


        for (Account account : accounts) {
            Boolean hasError = String.isEmpty(account.BillingCountry);
            System.assertEquals(hasError, ERRORS.containsKey(account.Id));
        }
    }


    /**
     *@description
     * Trigger should execute logic described in Async Logic setting in separate transaction using Queueable
     */
    @IsTest
    static void triggerShouldExecuteAsyncLogicDefinedInTriggerSettings() {
        List<Account> accounts = new List<Account>{
                new Account(Id = '001000000000001', Name = 'Test'),
                new Account(Id = '001000000000002', Name = 'Test', BillingCountry = 'USA')
        };
        AsyncCalloutMock mock = new AsyncCalloutMock();

        TriggerContext tc = new TestTriggerContextImpl(TriggerOperation.AFTER_INSERT, accounts, null);
        TriggerLogicSelector.mockResponseByType.put('Async Logic', new List<TriggerLogic__mdt>{
                new TriggerLogic__mdt(
                        IsEnabled__c = true,
                        ApexClass__c = 'TriggerDispatcherTest.TestAsyncLogic',
                        Trigger__c = 'AFTER_INSERT',
                        SObject__c = 'Account',
                        Type__c = 'Async Logic'
                )
        });


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        TriggerDispatcher.run(new TestAccountTriggerHandler(), tc);

        System.assertEquals(null, mock.records, 'Async logic should be executed only after Test.stopTest()');
        Test.stopTest();


        System.assertEquals(1, mock.records.size());
        System.assertEquals('USA', mock.records[0].BillingCountry);
    }

    private class AsyncCalloutMock implements HttpCalloutMock {
        public List<Account> records;

        public HttpResponse respond(HttpRequest request) {
            this.records = (List<Account>) JSON.deserialize(request.getBody(), List<Account>.class);
            return new HttpResponse();
        }
    }
}