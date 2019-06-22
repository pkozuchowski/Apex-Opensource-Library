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
private class TriggerHandlerTest {

    /**
     * Emulation of AccountTriggerHandler class
     */
    private class TestAccountTriggerHandler extends TriggerHandler {
        protected override void onBeforeUpdate(List<SObject> triggerNew, TriggerContext tc) {
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
     *@description
     * This test simulates Account saving execution with triggers, workflow field updates and process builders.
     *
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
        doUpdate(record, oldRecord);


        /*Workflow updates field on the record. Trigger is rerun with updated Trigger.new and original Trigger.old*/
        record.Website = 'www.TestAccount.com';
        doUpdate(record, oldRecord);


        /*Process Builder updates field on the record. Trigger is rerun with updated Trigger.new and Trigger.old*/
        oldRecord = record.clone(true);
        record.Phone = '(541) 754-3010';
        doUpdate(record, oldRecord);
        Test.stopTest();


        System.assertEquals(1, record.NumberOfEmployees, 'Record should go through trigger logic only once, because workflow did not change any of the observed fields.');
    }

    private static void doUpdate(SObject newRecord, SObject oldRecord) {
        TestAccountTriggerHandler beforeTrigger = new TestAccountTriggerHandler();
        beforeTrigger.triggerContext.isExecuting = true;
        beforeTrigger.triggerContext.isUpdate = true;
        beforeTrigger.triggerContext.operationType = TriggerOperation.BEFORE_UPDATE;
        beforeTrigger.triggerContext.triggerNew = new List<SObject>{newRecord};
        beforeTrigger.triggerContext.triggerNewMap = new Map<Id, SObject>{newRecord.Id => newRecord};
        beforeTrigger.triggerContext.triggerOldMap = new Map<Id, SObject>{
                newRecord.Id => oldRecord
        };
        beforeTrigger.run();

        TestAccountTriggerHandler afterTrigger = new TestAccountTriggerHandler();
        afterTrigger.triggerContext.isExecuting = true;
        afterTrigger.triggerContext.isUpdate = true;
        afterTrigger.triggerContext.operationType = TriggerOperation.AFTER_UPDATE;
        afterTrigger.triggerContext.triggerNew = new List<SObject>{newRecord};
        afterTrigger.triggerContext.triggerNewMap = new Map<Id, SObject>{newRecord.Id => newRecord};
        afterTrigger.triggerContext.triggerOldMap = new Map<Id, SObject>{
                newRecord.Id => oldRecord
        };
        afterTrigger.run();
    }


    @IsTest
    static void testCoverage() {
        TestAccountTriggerHandler handler = new TestAccountTriggerHandler();
        handler.triggerContext.isExecuting = true;
        handler.triggerContext.triggerNew = new List<Account>();
        handler.triggerContext.triggerOld = new List<Account>();
        handler.triggerContext.triggerNewMap = new Map<Id, Account>();
        handler.triggerContext.triggerOldMap = new Map<Id, Account>();

        for (TriggerOperation triggerOperation : TriggerOperation.values()) {
            handler.triggerContext.operationType = triggerOperation;
            handler.run();
        }
    }


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

        TriggerContext ctx = new TriggerContext();
        ctx.triggerNew = new List<SObject>{record};
        ctx.triggerOldMap = new Map<Id, SObject>{record.Id => oldRecord};
        ctx.isUpdate = true;

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


        ctx.isUpdate = false;
        System.assertEquals(false, ctx.isChanged(record, Account.BillingCountry));
        System.assertEquals(false, ctx.isChangedTo(record, Account.BillingCity, 'New York'));
        System.assertEquals(false, ctx.isChangedFrom(record, Account.BillingCity, null));
    }
}