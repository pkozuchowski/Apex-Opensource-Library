// SPDX-License-Identifier: MIT
// Copyright 2019 Piotr Kożuchowski

@IsTest
private class MetadataTriggerHandlerTest {
    private static final String
        COUNTRY_USA = 'USA';

    private static List<Account> accounts = new List<Account>{
        new Account(Id = '001000000000000', Name = 'Test 1', BillingCountry = COUNTRY_USA),
        new Account(Id = '001000000000001', Name = 'Test 2', BillingCountry = COUNTRY_USA),
        new Account(Id = '001000000000002', Name = 'Test 3', BillingCountry = COUNTRY_USA)
    };

    @IsTest
    static void triggerShouldExecuteTriggerLogicClassesDefinedInSettings() {
        TriggerContext tc = new TriggerContext(TriggerOperation.BEFORE_INSERT, accounts, null);
        MetadataTriggerHandler.mockMetadata(new List<TriggerLogic__mdt>{
            new TriggerLogic__mdt(ApexClass__c = 'MetadataTriggerHandlerTest.AccountShippingCountryFiller')
        });


        Test.startTest();
        TriggerDispatcher.run(new MetadataTriggerHandler(), tc);
        Test.stopTest();


        for (Account acc : accounts) {
            System.assertEquals(COUNTRY_USA, acc.BillingCountry, 'TriggerHandler should set Billing country');
        }
    }

    public class AccountShippingCountryFiller implements TriggerAction {
        public void execute(List<Account> records, TriggerContext ctx) {
            for (Account acc : records) {
                if (ctx.isNew() && String.isBlank(acc.ShippingCountry)) {
                    acc.ShippingCountry = acc.BillingCountry;
                }
            }
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
        MetadataTriggerHandler.mockMetadata(new List<TriggerLogic__mdt>{
            new TriggerLogic__mdt(ApexClass__c = 'MetadataTriggerHandlerTest.InvalidClass')
        });
        Exception ex;


        Test.startTest();
        try {
            TriggerDispatcher.run(new MetadataTriggerHandler(), tc);
        } catch (Exception e) {
            ex = e;
        }
        Test.stopTest();


        System.assert(ex instanceof TypeException && ex.getMessage().contains('(MetadataTriggerHandlerTest.InvalidClass)'),
            'If TriggerLogic cannot be constructed, TypeException should be thrown.');
    }

    @IsTest
    static void testCoverage() {
        for (TriggerOperation triggerOperation : TriggerOperation.values()) {
            TriggerDispatcher.run(new MetadataTriggerHandler(), new TriggerContext(triggerOperation, new List<SObject>(), new List<SObject>()));
        }
        System.assert(true, 'No exception is expected to happen');
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
        TriggerContext tc = new TriggerContext(TriggerOperation.BEFORE_INSERT, accounts, null);
        MetadataTriggerHandler.mockMetadata(new List<TriggerLogic__mdt>{
            new TriggerLogic__mdt(
                ApexClass__c = 'MetadataTriggerHandlerTest.ParameterizableLogic',
                Parameters__c = '{"parameterName":"New Name"}'
            )
        });


        Test.startTest();
        TriggerDispatcher.run(new MetadataTriggerHandler(), tc);
        Test.stopTest();


        for (Account account : accounts) {
            System.assertEquals('New Name', account.Name, 'Name should be updated to the value passed in custom metadata parameter.');
        }
    }


    /**
     * Example of TriggerHandler.Logic class which can be parametrized through custom metadata.
     */
    public class ParameterizableLogic implements TriggerAction {
        private String parameterName;

        public void execute(List<SObject> records, TriggerContext ctx) {
            for (Account acc : (Account[]) records) {
                acc.Name = parameterName;
            }
        }
    }
}