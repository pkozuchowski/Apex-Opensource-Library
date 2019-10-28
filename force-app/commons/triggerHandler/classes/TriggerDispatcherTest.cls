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
     * Emulation of AccountTriggerHandler class
     */
    private class TestAccountTriggerHandler implements TriggerHandler {

        public void onBeforeInsert(List<SObject> triggerNew, TriggerContext tc) {
        }

        public void onBeforeUpdate(List<SObject> triggerNew, TriggerContext tc) {
            new AccountAddressPopulator().copyBillingAddressToEmptyShippingAddress(triggerNew, tc);
        }

        public void onBeforeDelete(List<SObject> triggerOld, TriggerContext tc) {
        }

        public void onAfterInsert(List<SObject> triggerNew, TriggerContext tc) {
        }

        public void onAfterUpdate(List<SObject> triggerNew, TriggerContext tc) {
        }

        public void onAfterDelete(List<SObject> triggerOld, TriggerContext tc) {
        }

        public void onAfterUndelete(List<SObject> triggerNew, TriggerContext tc) {
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
        TriggerDispatcher.run(new TestAccountTriggerHandler(), new TriggerContext(TriggerOperation.BEFORE_UPDATE, new List<SObject>{newRecord}, new List<SObject>{oldRecord}));
        TriggerDispatcher.run(new TestAccountTriggerHandler(), new TriggerContext(TriggerOperation.AFTER_UPDATE, new List<SObject>{newRecord}, new List<SObject>{oldRecord}));
    }


    @IsTest
    static void testCoverage() {
        for (TriggerOperation triggerOperation : TriggerOperation.values()) {
            TriggerDispatcher.run(new TestAccountTriggerHandler(), new TriggerContext(triggerOperation, new List<SObject>(), new List<SObject>()));
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

        TriggerContext ctx = new TriggerContext(TriggerOperation.AFTER_UPDATE, new List<SObject>{record}, new List<SObject>{oldRecord});

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


        ctx = new TriggerContext(TriggerOperation.AFTER_INSERT, new List<SObject>{record}, new List<SObject>{oldRecord});
        System.assertEquals(false, ctx.isChanged(record, Account.BillingCountry));
        System.assertEquals(false, ctx.isChangedTo(record, Account.BillingCity, 'New York'));
        System.assertEquals(false, ctx.isChangedFrom(record, Account.BillingCity, null));
    }
}