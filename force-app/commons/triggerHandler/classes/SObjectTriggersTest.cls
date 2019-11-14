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
                tc.triggerNewMap.keySet(),
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
                System.debug(record);
                processedIds.add(record.Id);
            }
        }
    }
}