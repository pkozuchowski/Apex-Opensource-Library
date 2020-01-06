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
@IsTest
private class SObjectTriggersTest {
    private static Set<Id> processedIds = new Set<Id>();

    @IsTest
    static void testBehavior() {
        List<Account> accounts = new List<Account>{
                new Account(Id = '001000000000000', Name = 'Test'),
                new Account(Id = '001000000000001', Name = 'Test'),
                new Account(Id = '001000000000002', Name = 'Test')
        };
        TriggerContext tc = new TriggerContext(TriggerOperation.AFTER_UPDATE, accounts, accounts);


        Test.startTest();
        TriggerLogicSettingSelector.mockResponse = new List<TriggerLogic__mdt>{
                new TriggerLogic__mdt(
                        IsEnabled__c = true,
                        ApexClass__c = 'SObjectTriggersTest.TestTriggerLogic',
                        Trigger__c = 'AFTER_UPDATE',
                        SObject__c = 'Account'
                )
        };
        SObjectTriggers.execute(accounts, tc);
        Test.stopTest();


        System.assertEquals(
                tc.getRecordsIds(),
                processedIds,
                'Trigger should create instance of TestTriggerLogic defined in custom metadata and the instance should process records.'
        );
    }


    /**
     * Simulates custom metadata defined class which performs some trigger logic.
     */
    public class TestTriggerLogic implements TriggerLogic {
        public void execute(List<SObject> records, TriggerContext ctx) {
            for (SObject record : records) {
                processedIds.add(record.Id);
            }
        }
    }
}