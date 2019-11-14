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
private class SObjectFieldDefaultsTest {

    /**
     * Trigger should execute field default rules specified in custom metadata for before insert trigger.
     */
    @IsTest
    static void testBeforeInsertPopulation() {
        List<Account> accounts = new List<Account>{
                new Account(),
                new Account(),
                new Account()
        };
        TriggerContext tc = new TriggerContext(TriggerOperation.BEFORE_INSERT, accounts, null);
        TriggerLogicSettingSelector.mockResponse = new List<TriggerLogic__mdt>{
                new TriggerLogic__mdt(
                        IsEnabled__c = true,
                        ApexClass__c = 'SObjectFieldDefaultsTest.TestAccountNameDefault',
                        Trigger__c = 'BEFORE_INSERT',
                        SObject__c = 'Account',
                        Type__c = 'Field Default'
                ),
                new TriggerLogic__mdt(
                        IsEnabled__c = true,
                        ApexClass__c = 'SObjectFieldDefaultsTest.TestAccountBillingAddressDefault',
                        Trigger__c = 'BEFORE_INSERT',
                        SObject__c = 'Account',
                        Type__c = 'Field Default'
                )
        };

        Test.startTest();
        SObjectFieldDefaults.apply(accounts, tc);
        Test.stopTest();


        for (Account account : accounts) {
            System.assertEquals('Test', account.Name);
            System.assertEquals('USA', account.BillingCountry);
        }
    }


    /**
     * Trigger should execute field default rules specified in custom metadata for before update trigger.
     */
    @IsTest
    static void testBeforeUpdatePopulation() {
        List<Account> accounts = new List<Account>{
                new Account(Id = '001000000000000'),
                new Account(Id = '001000000000001'),
                new Account(Id = '001000000000002')
        };
        TriggerContext tc = new TriggerContext(TriggerOperation.BEFORE_UPDATE, accounts, accounts);
        TriggerLogicSettingSelector.mockResponse = new List<TriggerLogic__mdt>{
                new TriggerLogic__mdt(
                        IsEnabled__c = true,
                        ApexClass__c = 'SObjectFieldDefaultsTest.TestAccountBillingAddressDefault',
                        Trigger__c = 'BEFORE_UPDATE',
                        SObject__c = 'Account',
                        Type__c = 'Field Default'
                )
        };


        Test.startTest();
        SObjectFieldDefaults.apply(accounts, tc);
        Test.stopTest();


        for (Account account : accounts) {
            System.assertNotEquals('Test', account.Name);
            System.assertEquals('USA', account.BillingCountry);
        }
    }


    /**
     * When invalid or unreachable type is specified in custom metadata, TypeException should be thrown with meaningful message.
     */
    @IsTest
    static void testInvalidClass() {
        List<Account> accounts = new List<Account>{
                new Account(Id = '001000000000000'),
                new Account(Id = '001000000000001'),
                new Account(Id = '001000000000002')
        };
        TriggerContext tc = new TriggerContext(TriggerOperation.BEFORE_DELETE, accounts, accounts);
        TriggerLogicSettingSelector.mockResponse = new List<TriggerLogic__mdt>{
                new TriggerLogic__mdt(
                        IsEnabled__c = true,
                        ApexClass__c = 'SObjectFieldDefaultsTest.InvalidClass',
                        Trigger__c = 'BEFORE_DELETE',
                        SObject__c = 'Account',
                        Type__c = 'Field Default'
                )
        };
        Exception ex;


        Test.startTest();
        try {
            SObjectFieldDefaults.apply(accounts, tc);
        } catch (Exception e) {
            ex = e;
        }
        Test.stopTest();


        System.assert(ex instanceof TypeException);
    }


    /**
     * Test field default.
     * Populates Account's Name to be "Test".
     */
    public class TestAccountNameDefault implements TriggerFieldDefault {
        public void prepare(List<SObject> records, TriggerContext tc) {
        }

        public void populate(SObject record, TriggerContext tc) {
            ((Account) record).Name = 'Test';
        }
    }

    /**
     * Test field default.
     * Populates Account's Name to be "Test".
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
}