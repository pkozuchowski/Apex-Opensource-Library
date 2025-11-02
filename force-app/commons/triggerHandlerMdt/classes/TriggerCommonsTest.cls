// SPDX-License-Identifier: MIT
// Copyright 2023 Piotr Kożuchowski

@IsTest
private class TriggerCommonsTest {

    @IsTest
    static void testFieldSetter() {
        Account account = new Account(BillingCountry = 'US');

        Test.startTest();
        MetadataTriggerHandler.mockMetadata(new List<TriggerAction__mdt>{
            new TriggerAction__mdt(
                ApexClass__c = 'TriggerCommons.FieldSetter',
                Parameters__c = '{"field":"ShippingCountry","formula":"{!BillingCountry}","replaceIfSet":false}'
            )
        });

        TriggerContext ctx = new TriggerContext(TriggerOperation.BEFORE_INSERT,
            new List<Account>{account}, null);

        TriggerDispatcher.run(new MetadataTriggerHandler(), ctx);
        Test.stopTest();


        Assert.areEqual(account.BillingCountry, account.ShippingCountry);
    }
}