// SPDX-License-Identifier: MIT
// Copyright 2019 Piotr Kożuchowski

@SuppressWarnings('PMD')
@IsTest
public class MetadataTriggerHandlerTest {

    private static final String
        COUNTRY_USA = 'USA',
        CLASS_NAME = MetadataTriggerHandlerTest.class.toString();

    private static List<Account> accounts = new List<Account>{
        new Account(Id = '001000000000000', Name = 'Test 1', BillingCountry = COUNTRY_USA),
        new Account(Id = '001000000000001', Name = 'Test 2', BillingCountry = COUNTRY_USA),
        new Account(Id = '001000000000002', Name = 'Test 3', BillingCountry = COUNTRY_USA)
    };

    public class AccountShippingCountryFiller implements TriggerAction {
        public void execute(List<Account> records, TriggerContext ctx) {
            for (Account acc : records) {
                if (ctx.isNew() && String.isBlank(acc.ShippingCountry)) {
                    acc.ShippingCountry = acc.BillingCountry;
                }
            }
        }
    }

    public class AccountPopulateFields implements TriggerAction {
        public void execute(List<SObject> triggerNew, TriggerContext ctx) {}
    }

    public class AccountValidate implements TriggerAction {
        public void execute(List<SObject> triggerNew, TriggerContext ctx) {}
    }

    public class AccountLinkContacts implements TriggerAction {
        public void execute(List<SObject> triggerNew, TriggerContext ctx) {}
    }

    public class AccountPreventMoreThanOneContact implements TriggerAction {
        public void execute(List<SObject> triggerNew, TriggerContext ctx) {}
    }

    /**
     * Example of TriggerAction class which can be parametrized through custom metadata.
     */
    public class ParameterizableAction implements TriggerAction {
        private String parameterName;

        public void execute(List<SObject> records, TriggerContext ctx) {
            for (Account acc : (Account[]) records) {
                acc.Name = parameterName;
            }
        }
    }

    @IsTest
    static void triggerShouldExecuteTriggerLogicClassesDefinedInSettings() {
        TriggerContext tc = new TriggerContext(TriggerOperation.BEFORE_INSERT, accounts, null);
        MetadataTriggerHandler.mock(
            new TriggerSetting__mdt(),
            new List<TriggerAction__mdt>{
                new TriggerAction__mdt(ApexClass__c = CLASS_NAME + '.AccountShippingCountryFiller')
            }
        );


        Test.startTest();
        new MetadataTriggerHandler().run(tc);
        Test.stopTest();


        for (Account acc : accounts) {
            Assert.areEqual(COUNTRY_USA, acc.BillingCountry, 'TriggerHandler should set Billing country');
        }
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
        TriggerContext tc = new TriggerContext(TriggerOperation.BEFORE_DELETE, accounts, accounts);
        MetadataTriggerHandler.mock(
            new TriggerSetting__mdt(),
            new List<TriggerAction__mdt>{
                new TriggerAction__mdt(ApexClass__c = CLASS_NAME + '.InvalidClass')
            }
        );
        Exception ex;


        Test.startTest();
        try {
            new MetadataTriggerHandler().run(tc);
        } catch (Exception e) {
            ex = e;
        }
        Test.stopTest();


        Assert.isTrue(ex instanceof TypeException
            && ex.getMessage().contains(CLASS_NAME + '.InvalidClass)'),
            'If TriggerAction cannot be constructed, TypeException should be thrown.');
    }

    @IsTest
    static void testCoverage() {
        MetadataTriggerHandler.mock(
            new TriggerSetting__mdt(),
            new List<TriggerAction__mdt>{
                new TriggerAction__mdt(ApexClass__c = CLASS_NAME + '.AccountShippingCountryFiller')
            }
        );

        for (TriggerOperation triggerOperation : TriggerOperation.values()) {
            new MetadataTriggerHandler().run(
                new TriggerContext(
                    triggerOperation,
                    new List<Account>(),
                    new List<Account>()
                )
            );
        }
        Assert.isTrue(true, 'No exception is expected to happen');
    }


    /**
    *@description
    * Custom Metadata defined triggers should have Parameters field which can be passed down to instance to reuse single class
    * in many situations.
    */
    @IsTest
    static void customMetadataTriggerShouldBeParameterizable() {
        List<Account> accounts = new List<Account>{
            new Account(Id = '001000000000000', Name = 'Test'),
            new Account(Id = '001000000000001', Name = 'Test'),
            new Account(Id = '001000000000002', Name = 'Test')
        };
        TriggerContext tc = new TriggerContext(
            TriggerOperation.BEFORE_INSERT,
            accounts,
            null
        );

        MetadataTriggerHandler.mock(
            new TriggerSetting__mdt(),
            new List<TriggerAction__mdt>{
                new TriggerAction__mdt(
                    ApexClass__c = CLASS_NAME + '.ParameterizableAction',
                    Parameters__c = '{"parameterName":"New Name"}')
            }
        );


        Test.startTest();
        new MetadataTriggerHandler().run(tc);
        Test.stopTest();


        for (Account account : accounts) {
            Assert.areEqual('New Name', account.Name, 'Name should be updated to the value passed in custom metadata parameter.');
        }
    }
}