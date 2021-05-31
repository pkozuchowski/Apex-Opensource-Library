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

@SuppressWarnings('sf:CommentRequired')
@IsTest(IsParallel=true)
private class TriggerDispatcherTest {
    private static final String
        ID_1 = '001000000000000',
        ID_2 = '001000000000001',
        ID_3 = '001000000000002',
        NAME_TEST = 'Test',
        SOBJECT_ACCOUNT = 'Account',
        COUNTRY_USA = 'USA',
        CITY_NY = 'New York';

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
        public override void onBeforeUpdate(List<SObject> triggerNew, TriggerContext tc) {
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
            for (Account acc : (Account[]) records) {
                if (String.isBlank(acc.BillingCountry)) {
                    acc.BillingCountry = COUNTRY_USA;
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
            new Account(Id = ID_1, Name = NAME_TEST),
            new Account(Id = ID_2, Name = NAME_TEST),
            new Account(Id = ID_3, Name = NAME_TEST)
        };
        TriggerContext tc = new TestTriggerContextImpl(TriggerOperation.BEFORE_UPDATE, accounts, accounts);
        TriggerSettings.mockMetadata(new List<TriggerLogic__mdt>{
            new TriggerLogic__mdt(
                Enabled__c = true,
                ApexClass__c = 'TriggerDispatcherTest.TestTriggerLogic',
                BeforeUpdate__c = true,
                SObject__c = SOBJECT_ACCOUNT
            )
        });


        Test.startTest();
        TriggerDispatcher.runMetadataDefinedTriggers(tc);
        Test.stopTest();


        for (Account acc : accounts) {
            System.assertEquals(COUNTRY_USA, acc.BillingCountry, 'TriggerHandler should set Billing country');
        }
    }

    @IsTest
    static void triggerShouldExecuteTriggerHandler() {
        List<Account> accounts = new List<Account>{
            new Account(Id = ID_1, Name = NAME_TEST),
            new Account(Id = ID_2, Name = NAME_TEST),
            new Account(Id = ID_3, Name = NAME_TEST)
        };
        TriggerContext tc = new TestTriggerContextImpl(TriggerOperation.BEFORE_UPDATE, accounts, accounts);


        Test.startTest();
        TriggerDispatcher.run(new TestAccountTriggerHandler(), tc);
        Test.stopTest();


        for (Account acc : accounts) {
            System.assertEquals(COUNTRY_USA, acc.BillingCountry, 'TriggerHandler should set Billing country');
        }
    }


    /**
     * When invalid or unreachable type is specified in custom metadata, TypeException should be thrown with meaningful message.
     */
    @IsTest
    static void typeExceptionShouldBeThrownWhenInvalidClassIsDefinedInSettings() {
        List<Account> accounts = new List<Account>{
            new Account(Id = ID_1),
            new Account(Id = ID_2),
            new Account(Id = ID_3)
        };
        TriggerContext tc = new TestTriggerContextImpl(TriggerOperation.BEFORE_DELETE, accounts, accounts);
        TriggerSettings.mockMetadata(new List<TriggerLogic__mdt>{
            new TriggerLogic__mdt(
                Enabled__c = true,
                ApexClass__c = 'TriggerDispatcherTest.InvalidClass',
                BeforeDelete__c = true,
                SObject__c = SOBJECT_ACCOUNT
            )
        });
        Exception ex;


        Test.startTest();
        try {
            TriggerDispatcher.runMetadataDefinedTriggers(tc);
        } catch (Exception e) {
            ex = e;
        }
        Test.stopTest();


        System.assert(ex instanceof TypeException && ex.getMessage().contains('(TriggerDispatcherTest.InvalidClass)'),
            'If TriggerLogic cannot be constructed, TypeException should be thrown.');
    }

    @IsTest
    static void testCoverage() {
        for (TriggerOperation triggerOperation : TriggerOperation.values()) {
            TriggerDispatcher.run(new TestAccountTriggerHandler(), new TestTriggerContextImpl(triggerOperation, new List<SObject>(), new List<SObject>()));
        }
        TriggerDispatcher.runMetadataDefinedTriggers();
        System.assert(true, 'No exception is expected to happen');
    }


    /**
     * Coverage tests for TriggerContext helper methods
     */
    @IsTest
    @SuppressWarnings('sf:UnitAssertionsShouldIncludeMessage')
    static void testIsChangedHelperMethods() {
        Account record = new Account(
            Id = ID_1,
            Name = NAME_TEST,
            BillingCountry = COUNTRY_USA,
            BillingCity = CITY_NY,
            NumberOfEmployees = 0,
            Phone = '(541) 754-3010'
        );
        Account oldRecord = new Account(
            Id = ID_1,
            Name = NAME_TEST,
            Phone = '(541) 754-3011'
        );

        TriggerContext ctx = new TestTriggerContextImpl(TriggerOperation.AFTER_UPDATE, new List<SObject>{record}, new List<SObject>{oldRecord});

        System.assertEquals(false, ctx.isNew());
        System.assertEquals(true, ctx.isChanged());
        System.assertEquals(false, ctx.isChanged(record, Account.Name));
        System.assertEquals(true, ctx.isChanged(record, Account.BillingCountry));
        System.assertEquals(true, ctx.isChanged(record, Account.BillingCity));
        System.assertEquals(true, ctx.isChanged(record, Account.Phone));

        System.assertEquals(true, ctx.isChangedTo(record, Account.BillingCountry, COUNTRY_USA));
        System.assertEquals(true, ctx.isChangedTo(record, Account.BillingCity, CITY_NY));
        System.assertEquals(true, ctx.isChangedTo(record, Account.Phone, '(541) 754-3010'));
        System.assertEquals(false, ctx.isChangedTo(record, Account.BillingCity, 'Washington'));

        System.assertEquals(true, ctx.isChangedFrom(record, Account.BillingCountry, null));
        System.assertEquals(true, ctx.isChangedFrom(record, Account.BillingCity, null));
        System.assertEquals(true, ctx.isChangedFrom(record, Account.Phone, '(541) 754-3011'));
        System.assertEquals(false, ctx.isChangedFrom(record, Account.Name, 'Washington'));

        System.assertEquals(true, ctx.isChangedFromTo(record, Account.BillingCity, null, CITY_NY));


        ctx = new TestTriggerContextImpl(TriggerOperation.AFTER_INSERT, new List<SObject>{record}, new List<SObject>{oldRecord});
        System.assertEquals(false, ctx.isChanged(record, Account.BillingCountry));
        System.assertEquals(false, ctx.isChangedTo(record, Account.BillingCity, CITY_NY));
        System.assertEquals(false, ctx.isChangedFrom(record, Account.BillingCity, null));
        System.assert(ctx.getRecordsMap().containsKey(ID_1));
        System.assert(ctx.getRecordsIds().contains(ID_1));
        System.assert(ctx.getOldMap().containsKey(ID_1));
    }

    /**
     * Trigger should not execute when it's disabled for transaction using TriggerSettings.disableTrigger() method
     */
    @IsTest
    static void triggerShouldNotExecuteWhenDisabledForTransaction() {
        List<Account> accounts = new List<Account>{
            new Account(Id = ID_1, Name = NAME_TEST)
        };
        TriggerContext tc = new TestTriggerContextImpl(TriggerOperation.AFTER_UPDATE, accounts, accounts);
        TriggerSettings.mockMetadata(new List<TriggerLogic__mdt>{
            new TriggerLogic__mdt(
                Enabled__c = true,
                ApexClass__c = 'TriggerDispatcherTest.TestTriggerLogic',
                AfterUpdate__c = true,
                SObject__c = SOBJECT_ACCOUNT
            )
        });


        Test.startTest();
        TriggerSettings.disableTrigger(Account.SObjectType);
        TriggerDispatcher.run(new TestAccountTriggerHandler(), tc);
        TriggerSettings.enableTrigger(Account.SObjectType);
        Test.stopTest();


        for (Account account : accounts) {
            System.assertEquals(false, account.Name.startsWith('(Customer)'), 'Triggers should be disabled and do not update records');
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
            new Account(Id = ID_1, Name = NAME_TEST)
        };
        TriggerContext tc = new TestTriggerContextImpl(TriggerOperation.AFTER_UPDATE, accounts, accounts);
        TriggerSettings.mockMetadata(new List<TriggerLogic__mdt>{
            new TriggerLogic__mdt(
                Enabled__c = true,
                ApexClass__c = 'TriggerDispatcherTest.TestTriggerLogic',
                AfterUpdate__c = true,
                SObject__c = SOBJECT_ACCOUNT
            )
        });


        Test.startTest();
        TriggerDispatcher.run(new TestAccountTriggerHandler(), tc);
        Test.stopTest();


        for (Account account : accounts) {
            System.assertEquals(false, account.Name.startsWith('(Customer)'), 'When triggers are disabled in LogicSwitch__c, triggers shouldn\'t process any records');
        }
    }


    /**
     * TriggerSettings.disableTriggers();  and TriggerSettings.enableTriggers(); can be used to switch on/off all trigger execution.
     */
    @IsTest
    static void triggerShouldNotRunWhenAllTriggersDisabled() {
        List<Account> accounts = new List<Account>{
            new Account(Id = ID_1, Name = NAME_TEST)
        };
        TriggerContext tc = new TestTriggerContextImpl(TriggerOperation.AFTER_UPDATE, accounts, accounts);
        TriggerSettings.mockMetadata(new List<TriggerLogic__mdt>{
            new TriggerLogic__mdt(
                Enabled__c = true,
                ApexClass__c = 'TriggerDispatcherTest.TestTriggerLogic',
                AfterUpdate__c = true,
                SObject__c = SOBJECT_ACCOUNT
            )
        });


        Test.startTest();
        TriggerSettings.disableTriggers();
        TriggerDispatcher.run(new TestAccountTriggerHandler(), tc);
        TriggerSettings.enableTriggers();
        Test.stopTest();


        for (Account account : accounts) {
            System.assertEquals(false, account.Name.startsWith('(Customer)'), 'Triggers should be disabled and do not update records');
        }
    }


    /**
     * .disableLogic() should insert LogicSwitch__c setting for current user with all logic disabled
     * .enableAllLogic() should delete that setting afterwards.
     */
    @IsTest
    static void disableLogicShouldDisableAllOptionsInLogicSwitch() {
        Test.startTest();
        TriggerSettings.disableAllLogic();
        LogicSwitch__c setting = LogicSwitch__c.getInstance();
        String expectedDisabled = 'TriggerSettings.disableAllLogic() should check all checkboxes on LogicSwitch';
        System.assertEquals(true, setting.DisableWorkflowRules__c, expectedDisabled);
        System.assertEquals(true, setting.DisableValidationRules__c, expectedDisabled);
        System.assertEquals(true, setting.DisableProcessBuilders__c, expectedDisabled);
        System.assertEquals(true, setting.DisableTriggers__c, expectedDisabled);


        TriggerSettings.enableAllLogic();
        setting = LogicSwitch__c.getInstance();
        String expectedEnabled = 'TriggerSettings.enableAllLogic() should uncheck all checkboxes on LogicSwitch';
        System.assertEquals(false, setting.DisableWorkflowRules__c, expectedEnabled);
        System.assertEquals(false, setting.DisableValidationRules__c, expectedEnabled);
        System.assertEquals(false, setting.DisableProcessBuilders__c, expectedEnabled);
        System.assertEquals(false, setting.DisableTriggers__c, expectedEnabled);
        Test.stopTest();
    }


    /**
     *@description
     * Custom Metadata defined triggers should have Parameters field which can be passed down to instance to reuse single class
     * in many situations.
     */
    @IsTest
    static void customMetadataTriggerShouldBeParameterizable() {
        List<Account> accounts = new List<Account>{
            new Account(Id = ID_1, Name = NAME_TEST),
            new Account(Id = ID_2, Name = NAME_TEST),
            new Account(Id = ID_3, Name = NAME_TEST)
        };
        TriggerContext tc = new TestTriggerContextImpl(TriggerOperation.BEFORE_INSERT, accounts, null);
        TriggerSettings.mockMetadata(new List<TriggerLogic__mdt>{
            new TriggerLogic__mdt(
                Enabled__c = true,
                ApexClass__c = 'TriggerDispatcherTest.ParameterizableLogic',
                BeforeInsert__c = true,
                SObject__c = SOBJECT_ACCOUNT,
                Parameters__c = 'New Name'
            )
        });


        Test.startTest();
        TriggerDispatcher.runMetadataDefinedTriggers(tc);
        Test.stopTest();


        for (Account account : accounts) {
            System.assertEquals('New Name', account.Name, 'Name should be updated to the value passed in custom metadata parameter.');
        }
    }


    /**
     * Example of TriggerHandler.Logic class which can be parametrized through custom metadata.
     */
    public class ParameterizableLogic implements TriggerHandler.Logic, TriggerHandler.Parameterizable {
        private String parameterName;

        public void execute(List<SObject> records, TriggerContext ctx) {
            for (Account acc : (Account[]) records) {
                acc.Name = parameterName;
            }
        }

        public void setParameters(String parameters) {
            this.parameterName = parameters;
        }
    }
}