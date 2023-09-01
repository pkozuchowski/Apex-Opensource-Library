/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2023 Piotr Kożuchowski
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

@IsTest
private class TriggerCommonsTest {

    @IsTest
    static void testCopyField() {
        Account account = new Account(BillingCountry = 'US');

        Test.startTest();
        MetadataTriggerHandler.mockMetadata(new List<TriggerLogic__mdt>{
            new TriggerLogic__mdt(
                ApexClass__c = 'TriggerCommons.CopyField',
                Parameters__c = 'BillingCountry:ShippingCountry'
            )
        });
        TriggerContext ctx = new TriggerContext(TriggerOperation.BEFORE_INSERT,
            new List<Account>{account}, null);

        TriggerDispatcher.run(new MetadataTriggerHandler(), ctx);
        Test.stopTest();


        Assert.areEqual(account.BillingCountry, account.ShippingCountry);
    }

    @IsTest
    static void testDefaultField() {
        Account account = new Account();

        Test.startTest();
        MetadataTriggerHandler.mockMetadata(new List<TriggerLogic__mdt>{
            new TriggerLogic__mdt(
                ApexClass__c = 'TriggerCommons.DefaultField',
                Parameters__c = 'BillingCountry:US'
            )
        });
        TriggerContext ctx = new TriggerContext(TriggerOperation.BEFORE_INSERT,
            new List<Account>{account}, null);

        TriggerDispatcher.run(new MetadataTriggerHandler(), ctx);
        Test.stopTest();


        Assert.areEqual('US', account.BillingCountry);
    }

    @IsTest
    static void testExecuteFlowCoverage() {
        Account account = new Account();
        Exception ex;

        Test.startTest();
        MetadataTriggerHandler.mockMetadata(new List<TriggerLogic__mdt>{
            new TriggerLogic__mdt(
                ApexClass__c = 'TriggerCommons.ExecuteFlow',
                Parameters__c = 'namespace__FlowName\n' +
                    'param1:value1\n' +
                    'param2:value2'
            )
        });
        TriggerContext ctx = new TriggerContext(TriggerOperation.BEFORE_INSERT,
            new List<Account>{account}, null);

        try {
            TriggerDispatcher.run(new MetadataTriggerHandler(), ctx);

        } catch (Exception e) {
            ex = e;
        }
        Test.stopTest();


        Assert.isInstanceOfType(ex, TypeException.class);
    }

    @IsTest
    static void testExecuteFlowRecordUpdate() {
        Account account = new Account();

        TriggerCommons.ExecuteFlow executeFlow = new TriggerCommons.ExecuteFlow();
        TriggerContext ctx = new TriggerContext(TriggerOperation.BEFORE_INSERT,
            new List<Account>{account}, null);


        executeFlow.updateRecord(new Account(BillingCountry = 'US'), account, ctx);
        Assert.areEqual('US', account.BillingCountry, 'Should restore fields set in flow.');
    }
}