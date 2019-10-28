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
private class SObjectValidatorTest {
    private static Map<Id, Boolean> ERRORS = new Map<Id, Boolean>();

    /**
     * Trigger should execute field default rules specified in custom metadata for before insert trigger.
     */
    @IsTest
    static void testBeforeInsertValidation() {
        List<Account> accounts = new List<Account>{
                new Account(Id = '001000000000001', Name = 'Test'),
                new Account(Id = '001000000000002', Name = 'Test', BillingCountry = 'USA'),
                new Account(Id = '001000000000003', Name = 'Test')
        };
        TriggerContext tc = new TriggerContext(TriggerOperation.BEFORE_INSERT, accounts, null);


        Test.startTest();
        SObjectValidator.settingsSelector = new TestValidationRuleSelector();
        SObjectValidator.validate(accounts, tc);
        Test.stopTest();


        for (Account account : accounts) {
            Boolean hasError = String.isEmpty(account.BillingCountry);
            System.assertEquals(hasError, ERRORS.containsKey(account.Id));
        }
    }


    /**
     * When invalid or unreachable type is specified in custom metadata, TypeException should be thrown with meaningful message.
     */
    @IsTest
    static void testInvalidClass() {
        List<Account> accounts = new List<Account>{
                new Account(Id = '001000000000001'),
                new Account(Id = '001000000000002'),
                new Account(Id = '001000000000003')
        };
        TriggerContext tc = new TriggerContext(TriggerOperation.BEFORE_DELETE, accounts, accounts);


        Test.startTest();
        SObjectValidator.settingsSelector = new TestValidationRuleSelector();
        Exception ex;

        try {
            SObjectValidator.validate(accounts, tc);

        } catch (Exception e) {
            ex = e;
        }
        Test.stopTest();


        System.assert(ex instanceof TypeException);
    }


    /**
     * Since custom metadata cannot be inserted in unit tests, this selector implementation returns mock custom metadata.
     */
    private class TestValidationRuleSelector extends SObjectValidator.ValidationRuleSelector {
        public override List<TriggerValidationRule__mdt> getSettings(TriggerContext tc) {
            if (tc.operationType == TriggerOperation.BEFORE_INSERT) {
                return new List<TriggerValidationRule__mdt>{
                        new TriggerValidationRule__mdt(IsEnabled__c = true, ApexClass__c = 'SObjectValidatorTest.TestAccountBillingCountryValidation', Trigger__c = 'BEFORE_UPDATE', SObject__c = 'Account')
                };
            } else {
                return new List<TriggerValidationRule__mdt>{
                        new TriggerValidationRule__mdt(IsEnabled__c = true, ApexClass__c = 'SObjectValidatorTest.InvalidClass', Trigger__c = 'BEFORE_DELETE', SObject__c = 'Account')
                };
            }
        }
    }

    /**
     * Test Validation Rule.
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
}