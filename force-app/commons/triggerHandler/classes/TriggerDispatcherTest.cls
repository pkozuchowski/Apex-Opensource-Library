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

    /**
     * This constructor can be called in Unit Tests to mock trigger execution for certain
     */
    private class TestTriggerContextImpl extends TriggerContext {
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


    /**
     * Emulation of AccountTriggerHandler class
     */
    private class TestAccountTriggerHandler extends TriggerHandler {
        public override void handleBeforeUpdate(List<SObject> triggerNew, TriggerContext tc) {
            this.execute(triggerNew, tc, new List<TriggerHandler.Logic>{
                    new TestTriggerLogic()
            });
        }
    }

    /**
     * Emulation of Trigger logic class
     */
    public class TestTriggerLogic implements TriggerHandler.Logic {
        public void execute(List<SObject> records, TriggerContext ctx) {
            System.debug('test');
            for (Account acc : (Account[]) records) {
                if (String.isBlank(acc.BillingCountry)) {
                    acc.BillingCountry = 'US';
                }

                if (ctx.isChanged(acc, Account.BillingCountry)) {
                    acc.ShippingCountry = acc.BillingCountry;
                    acc.ShippingCity = acc.BillingCity;
                }
            }
        }
    }


    @IsTest
    static void triggerShouldExecuteTriggerLogicClassesDefinedInSettings() {
        List<Account> accounts = new List<Account>{
                new Account(Id = '001000000000000', Name = 'Test'),
                new Account(Id = '001000000000001', Name = 'Test'),
                new Account(Id = '001000000000002', Name = 'Test')
        };
        TriggerContext tc = new TestTriggerContextImpl(TriggerOperation.BEFORE_UPDATE, accounts, accounts);
        TriggerLogicSelector.mockMetadata = new List<TriggerLogic__mdt>{
                new TriggerLogic__mdt(
                        Enabled__c = true,
                        ApexClass__c = 'TriggerDispatcherTest.TestTriggerLogic',
                        BeforeUpdate__c = true,
                        SObject__c = 'Account'
                )
        };


        Test.startTest();
        TriggerDispatcher.runMetadataDefinedTriggers(tc);
        Test.stopTest();


        for (Account acc : accounts) {
            System.assertEquals('US', acc.BillingCountry);
        }
    }

    @IsTest
    static void triggerShouldExecuteTriggerHandler() {
        List<Account> accounts = new List<Account>{
                new Account(Id = '001000000000000', Name = 'Test'),
                new Account(Id = '001000000000001', Name = 'Test'),
                new Account(Id = '001000000000002', Name = 'Test')
        };
        TriggerContext tc = new TestTriggerContextImpl(TriggerOperation.BEFORE_UPDATE, accounts, accounts);
        TriggerLogicSelector.mockMetadata = new List<TriggerLogic__mdt>{
                new TriggerLogic__mdt(
                        Enabled__c = true,
                        ApexClass__c = 'TriggerDispatcherTest.TestTriggerLogic',
                        BeforeUpdate__c = true,
                        SObject__c = 'Account'
                )
        };


        Test.startTest();
        TriggerDispatcher.run(new TestAccountTriggerHandler(), tc);
        Test.stopTest();


        for (Account acc : accounts) {
            System.assertEquals('US', acc.BillingCountry);
        }
    }


    /**
     * Example of metadata defined Async logic which filters records and does callout
     */
    public class TestAsyncLogic implements TriggerHandler.AsyncLogic {

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

    private class AsyncCalloutMock implements HttpCalloutMock {
        public List<Account> records;

        public HttpResponse respond(HttpRequest request) {
            this.records = (List<Account>) JSON.deserialize(request.getBody(), List<Account>.class);
            return new HttpResponse();
        }
    }

    /**
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
        TriggerLogicSelector.mockMetadata = new List<TriggerLogic__mdt>{
                new TriggerLogic__mdt(
                        Enabled__c = true,
                        ApexClass__c = 'TriggerDispatcherTest.TestAsyncLogic',
                        AfterInsert__c = true,
                        SObject__c = 'Account',
                        Async__c = true
                )
        };


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        TriggerDispatcher.runMetadataDefinedTriggers(tc);

        System.assertEquals(null, mock.records, 'Async logic should be executed only after Test.stopTest()');
        Test.stopTest();


        System.assertEquals(1, mock.records.size());
        System.assertEquals('USA', mock.records[0].BillingCountry);
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
        TriggerLogicSelector.mockMetadata = new List<TriggerLogic__mdt>{
                new TriggerLogic__mdt(
                        Enabled__c = true,
                        ApexClass__c = 'TriggerDispatcherTest.InvalidClass',
                        BeforeDelete__c = true,
                        SObject__c = 'Account'
                )
        };
        Exception ex;


        Test.startTest();
        try {
            TriggerDispatcher.runMetadataDefinedTriggers(tc);
        } catch (Exception e) {
            ex = e;
        }
        Test.stopTest();


        System.assert(ex instanceof TypeException);
        System.assert(ex.getMessage().contains('(TriggerDispatcherTest.InvalidClass)'));
    }

    @IsTest
    static void testCoverage() {
        for (TriggerOperation triggerOperation : TriggerOperation.values()) {
            TriggerDispatcher.run(new TestAccountTriggerHandler(), new TestTriggerContextImpl(triggerOperation, new List<SObject>(), new List<SObject>()));
        }
        TriggerDispatcher.runMetadataDefinedTriggers();
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
        System.assert(ctx.getOldMap().containsKey('001000000000000'));
    }

    /**
     * Trigger should not execute when it's disabled for transaction using TriggerDispatcher.disableTrigger() method
     */
    @IsTest
    static void triggerShouldNotExecuteWhenDisabledForTransaction() {
        List<Account> accounts = new List<Account>{
                new Account(Id = '001000000000000', Name = 'Test')
        };
        TriggerContext tc = new TestTriggerContextImpl(TriggerOperation.AFTER_UPDATE, accounts, accounts);
        TriggerLogicSelector.mockMetadata = new List<TriggerLogic__mdt>{
                new TriggerLogic__mdt(
                        Enabled__c = true,
                        ApexClass__c = 'TriggerDispatcherTest.TestTriggerLogic',
                        AfterUpdate__c = true,
                        SObject__c = 'Account'
                )
        };


        Test.startTest();
        TriggerDispatcher.disableTrigger(Account.SObjectType);
        TriggerDispatcher.run(new TestAccountTriggerHandler(), tc);
        TriggerDispatcher.enableTrigger(Account.SObjectType);
        Test.stopTest();


        for (Account account : accounts) {
            System.assertEquals(false, account.Name.startsWith('(Customer)'));
        }
    }


    /**
     * Trigger should not execute when it's disabled via custom setting
     */
    @IsTest
    static void triggerShouldNotExecuteWhenDisabledInCustomSetting() {
        upsert new LogicSwitch__c(
                SetupOwnerId = UserInfo.getUserId(),
                DisableTriggers__c = true
        );
        List<Account> accounts = new List<Account>{
                new Account(Id = '001000000000000', Name = 'Test')
        };
        TriggerContext tc = new TestTriggerContextImpl(TriggerOperation.AFTER_UPDATE, accounts, accounts);
        TriggerLogicSelector.mockMetadata = new List<TriggerLogic__mdt>{
                new TriggerLogic__mdt(
                        Enabled__c = true,
                        ApexClass__c = 'TriggerDispatcherTest.TestTriggerLogic',
                        AfterUpdate__c = true,
                        SObject__c = 'Account'
                )
        };


        Test.startTest();
        TriggerDispatcher.run(new TestAccountTriggerHandler(), tc);
        Test.stopTest();


        for (Account account : accounts) {
            System.assertEquals(false, account.Name.startsWith('(Customer)'));
        }
    }


    /**
     * .disableLogic() should insert LogicSwitch__c setting for current user with all logic disabled
     * .enableAllLogic() should delete that setting afterwards.
     */
    @IsTest
    static void disableLogicShouldDisableAllOptionsInLogicSwitch() {
        Test.startTest();
        TriggerDispatcher.disableAllLogic();
        LogicSwitch__c setting = LogicSwitch__c.getInstance();
        System.assertEquals(true, setting.DisableWorkflowRules__c);
        System.assertEquals(true, setting.DisableValidationRules__c);
        System.assertEquals(true, setting.DisableProcessBuilders__c);
        System.assertEquals(true, setting.DisableTriggers__c);
        TriggerDispatcher.enableAllLogic();


        setting = LogicSwitch__c.getInstance();
        System.assertEquals(false, setting.DisableWorkflowRules__c);
        System.assertEquals(false, setting.DisableValidationRules__c);
        System.assertEquals(false, setting.DisableProcessBuilders__c);
        System.assertEquals(false, setting.DisableTriggers__c);
        Test.stopTest();
    }
}