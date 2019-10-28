public with sharing class SObjectTriggers {
    @TestVisible private static TriggerLogicSelector settingsSelector = new TriggerLogicSelector();

    /**
     * Executes trigger logic classes defined in custom metadata.
     */
    public static void execute(List<SObject> records, TriggerContext tc) {
        execute(records, tc, getConfiguredLogic(tc));
    }

    /**
     * Executes given trigger logic implementations.
     */
    public static void execute(List<SObject> records, TriggerContext tc, List<TriggerLogic> triggerLogics) {
        for (TriggerLogic logic : triggerLogics) {
            logic.execute(records, tc);
        }
    }


    /**
     * @return ValidationRules defined in custom metadata.
     */
    private static List<TriggerLogic> getConfiguredLogic(TriggerContext tc) {
        List<TriggerLogic> logics = new List<TriggerLogic>();

        for (TriggerLogic__mdt setting : settingsSelector.getSettings(tc)) {
            try {
                Type ruleClass = Type.forName(setting.ApexClass__c);
                TriggerLogic triggerLogic = (TriggerLogic) ruleClass.newInstance();
                logics.add(triggerLogic);

            } catch (Exception ex) {
                throw new TypeException('Trigger Logic "' + setting.DeveloperName + '" is invalid. ' +
                        'Please check if corresponding class is public and implements TriggerLogic interface.');
            }
        }

        return logics;
    }


    /**
     * Selector for custom metadata defined field defaults.
     */
    @TestVisible
    private virtual class TriggerLogicSelector {
        public virtual List<TriggerLogic__mdt> getSettings(TriggerContext tc) {
            return [
                    SELECT ApexClass__c, DeveloperName
                    FROM TriggerLogic__mdt
                    WHERE IsEnabled__c = TRUE
                    AND SObject__c = :String.valueOf(tc.sObjectType)
                    AND Trigger__c = :tc.operationType.name()
                    ORDER BY Order__c NULLS LAST
            ];
        }
    }
}