// SPDX-License-Identifier: MIT
// Copyright 2019 Piotr Kożuchowski

@IsTest(IsParallel=true)
public class TriggerHandlerTest {

    @SuppressWarnings('PMD.AvoidHardcodingId')
    private static final String
        ID_1 = '001000000000000',
        ID_2 = '001000000000001',
        ID_3 = '001000000000002',
        ID_4 = '001000000000003',
        NAME_TEST = 'Test',
        COUNTRY_USA = 'USA',
        CITY_NY = 'New York';

    private static Integer sharedContextInitCounter = 0;

    private class SharedAccountData {
        public List<Contact> contacts;

        public SharedAccountData(List<Account> accounts) {
            sharedContextInitCounter++;
            contacts = new List<Contact>();
            /*Simulate related Contacts query*/
            for (Account acc : accounts) {
                contacts.add(new Contact(LastName = 'Test', AccountId = acc.Id));
            }
        }
    }

    /**
     * Emulation of AccountTriggerHandler class
     */
    public class TestAccountTriggerHandler extends TriggerHandler {

        protected override void initialize(List<SObject> triggerNew, TriggerContext ctx) {
            ctx.setSharedState(new SharedAccountData(triggerNew));
        }

        public override List<TriggerAction> beforeUpdate(List<SObject> triggerNew, TriggerContext tc) {
            return new List<TriggerAction>{
                new TestAccountAddressPopulator()
            };
        }

        protected override List<TriggerAction> afterUpdate(List<SObject> triggerNew, TriggerContext ctx) {
            Assert.isNotNull(ctx.getSharedState());

            return new List<TriggerAction>{
                new TestContactUpdater()
            };
        }
    }

    public class TestContactTriggerHandler extends TriggerHandler {
        protected override void initialize(List<SObject> triggerNew, TriggerContext ctx) {
            Assert.isNull(ctx.getSharedState());
            ctx.setSharedState(123);
        }

        public override List<TriggerAction> beforeUpdate(List<SObject> triggerNew, TriggerContext ctx) {
            Assert.areEqual(123, ctx.getSharedState());
            return new List<TriggerAction>{};
        }

        protected override List<TriggerAction> afterUpdate(List<SObject> triggerNew, TriggerContext ctx) {
            Assert.areEqual(123, ctx.getSharedState());
            return new List<TriggerAction>{};
        }
    }


    /**
     * Emulation of Trigger logic class
     */
    public class TestAccountAddressPopulator implements TriggerAction {
        public void execute(List<Account> records, TriggerContext ctx) {
            for (Account acc : (Account[]) records) {
                if (String.isBlank(acc.BillingCountry)) {
                    acc.BillingCountry = COUNTRY_USA;
                }

                if (ctx.isChanged(acc, Account.BillingCountry)) {
                    acc.ShippingCountry = acc.BillingCountry;
                    acc.ShippingCity = acc.BillingCity;
                }

                if (ctx.isFirstActionRun(acc.Id, true)) {
                    // Increment to test trigger recursion
                    acc.NumberOfEmployees = acc.NumberOfEmployees == null ? 1 : acc.NumberOfEmployees + 1;
                }
            }
        }
    }

    public class TestContactUpdater implements TriggerAction {
        public void execute(List<SObject> records, TriggerContext ctx) {
            SharedAccountData sharedData = (SharedAccountData) ctx.getSharedState();
            Assert.isNotNull(sharedData);
            Assert.areEqual(records.size(), sharedData.contacts.size());
            List<Contact> contacts = new List<Contact>();

            /*Simulate related Contacts update*/
            new TestContactTriggerHandler().run(new TriggerContext(
                TriggerOperation.BEFORE_UPDATE, contacts, contacts));

            new TestContactTriggerHandler().run(new TriggerContext(
                TriggerOperation.AFTER_UPDATE, contacts, contacts));
        }
    }


    @IsTest
    static void triggerShouldExecuteTriggerHandler() {
        List<Account> accounts = new List<Account>{
            new Account(Id = ID_1, Name = NAME_TEST),
            new Account(Id = ID_2, Name = NAME_TEST),
            new Account(Id = ID_3, Name = NAME_TEST)
        };
        TriggerContext tc = new TriggerContext(TriggerOperation.BEFORE_UPDATE, accounts, accounts);


        Test.startTest();
        new TestAccountTriggerHandler().run(tc);
        Test.stopTest();


        for (Account acc : accounts) {
            Assert.areEqual(COUNTRY_USA, acc.BillingCountry, 'TriggerHandler should set Billing country');
        }
    }


    /**
     * Coverage tests for TriggerContext helper methods
     */
    @IsTest
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

        TriggerContext ctx = new TriggerContext(TriggerOperation.AFTER_UPDATE, new List<SObject>{record}, new List<SObject>{oldRecord});

        Assert.areEqual(false, ctx.isNew());
        Assert.areEqual(true, ctx.isChanged());
        Assert.areEqual(false, ctx.isChanged(record, Account.Name));
        Assert.areEqual(true, ctx.isChanged(record, Account.BillingCountry));
        Assert.areEqual(true, ctx.isChanged(record, Account.BillingCity));
        Assert.areEqual(true, ctx.isChanged(record, Account.Phone));

        Assert.areEqual(true, ctx.isChangedTo(record, Account.BillingCountry, COUNTRY_USA));
        Assert.areEqual(true, ctx.isChangedTo(record, Account.BillingCity, CITY_NY));
        Assert.areEqual(true, ctx.isChangedTo(record, Account.Phone, '(541) 754-3010'));
        Assert.areEqual(false, ctx.isChangedTo(record, Account.BillingCity, 'Washington'));

        Assert.areEqual(true, ctx.isChangedFrom(record, Account.BillingCountry, null));
        Assert.areEqual(true, ctx.isChangedFrom(record, Account.BillingCity, null));
        Assert.areEqual(true, ctx.isChangedFrom(record, Account.Phone, '(541) 754-3011'));
        Assert.areEqual(false, ctx.isChangedFrom(record, Account.Name, 'Washington'));

        Assert.areEqual(true, ctx.isChangedFromTo(record, Account.BillingCity, null, CITY_NY));


        ctx = new TriggerContext(TriggerOperation.AFTER_INSERT, new List<SObject>{record}, new List<SObject>{oldRecord});
        Assert.areEqual(false, ctx.isChanged(record, Account.BillingCountry));
        Assert.areEqual(false, ctx.isChangedTo(record, Account.BillingCity, CITY_NY));
        Assert.areEqual(false, ctx.isChangedFrom(record, Account.BillingCity, null));
        Assert.isTrue(ctx.getRecordsMap().containsKey(ID_1));
        Assert.isTrue(ctx.getRecordsIds().contains(ID_1));
        Assert.isTrue(ctx.getOldMap().containsKey(ID_1));
        Assert.areEqual(ID_1, ctx.getOld()[0].Id);
    }

    /**
     * Trigger should not execute when it's disabled for transaction using TriggerSettings.disableTrigger() method
     */
    @IsTest
    static void triggerShouldNotExecuteWhenDisabledForTransaction() {
        List<Account> accounts = new List<Account>{
            new Account(Id = ID_1, Name = NAME_TEST)
        };
        TriggerContext tc = new TriggerContext(TriggerOperation.AFTER_UPDATE, accounts, accounts);


        Test.startTest();
        TriggerSettings.disableTrigger(Account.SObjectType);
        new TestAccountTriggerHandler().run(tc);
        TriggerSettings.enableTrigger(Account.SObjectType);
        Test.stopTest();


        for (Account account : accounts) {
            Assert.areEqual(false, account.Name.startsWith('(Customer)'), 'Triggers should be disabled and do not update records');
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
        TriggerContext tc = new TriggerContext(TriggerOperation.AFTER_UPDATE, accounts, accounts);


        Test.startTest();
        new TestAccountTriggerHandler().run(tc);
        Test.stopTest();


        for (Account account : accounts) {
            Assert.areEqual(false, account.Name.startsWith('(Customer)'), 'When triggers are disabled in LogicSwitch__c, triggers shouldn\'t process any records');
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
        TriggerContext tc = new TriggerContext(TriggerOperation.AFTER_UPDATE, accounts, accounts);


        Test.startTest();
        TriggerSettings.disableTriggers();
        new TestAccountTriggerHandler().run(tc);
        TriggerSettings.enableTriggers();
        Test.stopTest();


        for (Account account : accounts) {
            Assert.areEqual(false, account.Name.startsWith('(Customer)'), 'Triggers should be disabled and do not update records');
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
        Assert.areEqual(true, setting.DisableWorkflowRules__c, expectedDisabled);
        Assert.areEqual(true, setting.DisableValidationRules__c, expectedDisabled);
        Assert.areEqual(true, setting.DisableProcessBuilders__c, expectedDisabled);
        Assert.areEqual(true, setting.DisableTriggers__c, expectedDisabled);


        TriggerSettings.removeUserSettings();
        setting = LogicSwitch__c.getInstance();
        String expectedEnabled = 'TriggerSettings.enableAllLogic() should uncheck all checkboxes on LogicSwitch';
        Assert.areEqual(false, setting.DisableWorkflowRules__c, expectedEnabled);
        Assert.areEqual(false, setting.DisableValidationRules__c, expectedEnabled);
        Assert.areEqual(false, setting.DisableProcessBuilders__c, expectedEnabled);
        Assert.areEqual(false, setting.DisableTriggers__c, expectedEnabled);
        Test.stopTest();
    }


    @IsTest
    static void testGetChangedRecords() {
        TriggerContext tc = new TriggerContext(TriggerOperation.AFTER_UPDATE,
            new List<Account>{
                new Account(Id = ID_1, Name = 'Test 1 - new'),
                new Account(Id = ID_2, Name = 'Test 2 - new'),
                new Account(Id = ID_3, Name = 'Test 3 - new'),
                new Account(Id = ID_4, Name = 'Test 4', BillingCountry = COUNTRY_USA)
            },
            new List<Account>{
                new Account(Id = ID_1, Name = 'Test 1'),
                new Account(Id = ID_2, Name = 'Test 2'),
                new Account(Id = ID_3, Name = 'Test 3'),
                new Account(Id = ID_4, Name = 'Test 4')
            });

        Assert.areEqual(3, tc.getChanged(Account.Name).size());
        Assert.areEqual(1, tc.getChangedToValue(Account.Name, new Set<Object>{'Test 3 - new'}).size());
        Assert.areEqual(2, tc.getChangedFromValue(Account.Name, new Set<Object>{'Test 1', 'Test 2'}).size());
    }

    @IsTest
    static void testTriggerCounter() {
        List<Account> accounts = new List<Account>{
            new Account(Id = ID_1, Name = NAME_TEST, NumberOfEmployees = 0)
        };
        TriggerContext tc = new TriggerContext(TriggerOperation.BEFORE_UPDATE, accounts, accounts);


        Test.startTest();
        new TestAccountTriggerHandler().run(tc);
        new TestAccountTriggerHandler().run(tc);
        new TestAccountTriggerHandler().run(tc);
        new TestAccountTriggerHandler().run(tc);
        Test.stopTest();

        Assert.areEqual(1, accounts[0].NumberOfEmployees);
    }

    @IsTest
    static void testOperationCoverage() {
        List<Account> accounts = new List<Account>{
            new Account(Id = ID_1, Name = NAME_TEST, NumberOfEmployees = 0)
        };
        TriggerContext t = TriggerContext.getInstance();
        Assert.isNull(t);

        for (TriggerOperation op : TriggerOperation.values()) {
            TriggerContext tc = new TriggerContext(op, accounts, accounts);
            new TriggerHandler().run(tc);
        }
    }

    public class TestTriggerExceptionHandler implements TriggerExceptionHandler {
        public Exception handledException;

        public void onException(List<SObject> records, TriggerContext ctx, Exception ex) {
            handledException = ex;
        }
    }

    public class TestFailingAction implements TriggerAction {
        public void execute(List<SObject> records, TriggerContext ctx) {
            throw new DmlException('Simulated exception in TriggerAction');
        }
    }

    public class TestFailingHandler extends TriggerHandler {
        public override List<TriggerAction> afterUpdate(List<SObject> triggerNew, TriggerContext tc) {
            return new List<TriggerAction>{
                new TestFailingAction()
            };
        }
    }

    /**
     * Tests the exception handling functionality of the Trigger Handler by simulating a failing trigger action.
     * Verifies that:
     * - The exception is properly caught and handled by the TestTriggerExceptionHandler
     * - The original exception is re-thrown after handling
     * - The handled exception matches the thrown exception
     */
    @IsTest
    static void testExceptionHandler() {
        List<Account> accounts = new List<Account>{
            new Account(Id = ID_1, Name = NAME_TEST)
        };
        TriggerContext tc = new TriggerContext(TriggerOperation.AFTER_UPDATE, accounts, accounts);
        TestTriggerExceptionHandler testExHandler = new TestTriggerExceptionHandler();
        TriggerHandler.exceptionHandlers = new List<TriggerExceptionHandler>{testExHandler};

        Test.startTest();
        try {
            new TestFailingHandler().run(tc);
            Assert.fail();
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e);
        }
        Test.stopTest();


        Assert.isNotNull(testExHandler.handledException);
        Assert.areEqual('Simulated exception in TriggerAction', testExHandler.handledException.getMessage());
    }

    @IsTest
    static void testDisablingAction() {
        List<Account> accounts = new List<Account>{
            new Account(Id = ID_1, Name = NAME_TEST)
        };
        TriggerContext tc = new TriggerContext(TriggerOperation.AFTER_UPDATE, accounts, accounts);
        TriggerSettings.disableAction(TestFailingAction.class);
        Exception ex1;
        Exception ex2;

        Test.startTest();
        try {
            new TestFailingHandler().run(tc);
        } catch (Exception e) {
            ex1 = e;
        }

        TriggerSettings.enableAction(TestFailingAction.class);

        try {
            new TestFailingHandler().run(tc);
        } catch (Exception e) {
            ex2 = e;
        }
        Test.stopTest();

        Assert.isNull(ex1);
        Assert.isNotNull(ex2);
    }

    @IsTest
    static void testDisableTriggerOperation() {
        LogicSwitch__c setting = LogicSwitch__c.getInstance();
        setting.DisableSelectedTriggers__c = 'Account.BEFORE_UPDATE';
        upsert setting;

        List<Account> accounts = new List<Account>{
            new Account(Id = ID_1, Name = NAME_TEST)
        };
        TriggerContext tc = new TriggerContext(TriggerOperation.BEFORE_UPDATE, accounts, accounts);


        Test.startTest();
        new TestAccountTriggerHandler().run(tc);
        Test.stopTest();

        Assert.isNull(accounts[0].BillingCountry);
    }

    /**
     * In this test, we verify that the shared context initialized just once per trigger execution.
     * This test assumes accounts trigger is executed twice, so the shared context should
     * be initialized two times only.
     */
    @IsTest
    static void testInitializeIsNotMixedBetweenTriggersAndRunOnce() {
        List<Account> accounts = new List<Account>{
            new Account(Id = ID_1, Name = NAME_TEST)
        };

        Test.startTest();
        for (Integer i = 0; i < 2; i++) {
            new TestAccountTriggerHandler().run(
                new TriggerContext(TriggerOperation.BEFORE_UPDATE, accounts, accounts)
            );
            new TestAccountTriggerHandler().run(
                new TriggerContext(TriggerOperation.AFTER_UPDATE, accounts, accounts)
            );
        }
        Test.stopTest();


        Assert.areEqual(2, sharedContextInitCounter);
        Assert.areEqual(0, TriggerHandler.stackDepth);
        Assert.isTrue(TriggerHandler.sharedStates.isEmpty());
    }
}