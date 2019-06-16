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
        protected override void onBeforeUpdate(List<SObject> triggerNew, Map<Id, SObject> triggerOldMap) {
            new AccountAddressPopulator().copyBillingAddressToEmptyShippingAddress(triggerNew, triggerOldMap);
        }
    }

    /**
     * Emulation of Trigger logic class
     */
    private class AccountAddressPopulator {
        public void copyBillingAddressToEmptyShippingAddress(List<Account> accounts, Map<Id, SObject> oldMap) {
            for (Account account : accounts) {
                Account old = (Account) oldMap.get(account.Id);

                if (account.BillingCountry != old.BillingCountry) {
                    account.ShippingCountry = account.BillingCountry;
                    account.ShippingCity = account.BillingCity;
                    /*Count how many times address is changed by triggers*/
                    account.NumberOfEmployees++;
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
        TestAccountTriggerHandler triggerHandler = new TestAccountTriggerHandler();
        TriggerContext ctx = triggerHandler.triggerContext;

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
        ctx.triggerNew = new List<SObject>{record};
        ctx.triggerOldMap = new Map<Id, SObject>{
                record.Id => oldRecord
        };
        ctx.isExecuting = true;

        ctx.operationType = TriggerOperation.BEFORE_UPDATE;
        triggerHandler.run();

        ctx.operationType = TriggerOperation.AFTER_UPDATE;
        triggerHandler.run();


        /*Workflow updates field on the record. Trigger is rerun with updated Trigger.new and original Trigger.old*/
        record.Website = 'www.TestAccount.com';
        ctx.operationType = TriggerOperation.BEFORE_UPDATE;
        triggerHandler.run();

        ctx.operationType = TriggerOperation.AFTER_UPDATE;
        triggerHandler.run();


        /*Process Builder updates field on the record. Trigger is rerun with updated Trigger.new and Trigger.old*/
        oldRecord = record.clone(true);
        record.Phone = '(541) 754-3010';

        ctx.triggerNew = new List<SObject>{record};
        ctx.triggerOldMap = new Map<Id, SObject>{
                record.Id => oldRecord
        };
        ctx.operationType = TriggerOperation.BEFORE_UPDATE;
        triggerHandler.run();

        ctx.operationType = TriggerOperation.AFTER_UPDATE;
        triggerHandler.run();
        Test.stopTest();


        System.assertEquals(1, record.NumberOfEmployees, 'Record should go through trigger logic only once, because workflow did not change any of the observed fields.');
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
}