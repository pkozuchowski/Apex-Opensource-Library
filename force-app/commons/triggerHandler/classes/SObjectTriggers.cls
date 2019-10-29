public with sharing class SObjectTriggers {

    /**
     * Executes trigger logic classes defined in custom metadata.
     */
    public static void execute(List<SObject> records, TriggerContext triggerContext) {
        execute(records, triggerContext, (List<TriggerLogic>) MetadataDefinedTriggerClasses.getInstances(
                TriggerLogic__mdt.SObjectType,
                triggerContext,
                new List<TriggerLogic>()
        ));
    }

    /**
     * Executes given trigger logic implementations.
     */
    public static void execute(List<SObject> records, TriggerContext tc, List<TriggerLogic> triggerLogics) {
        for (TriggerLogic logic : triggerLogics) {
            logic.execute(records, tc);
        }
    }
}