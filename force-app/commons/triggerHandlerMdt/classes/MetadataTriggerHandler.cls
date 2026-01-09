// SPDX-License-Identifier: MIT
// Copyright 2019 Piotr Kożuchowski

public virtual with sharing class MetadataTriggerHandler extends TriggerHandler {
    private static TriggerLogicSelector logicSelector = new TriggerLogicSelector();

    public override List<TriggerAction> beforeInsert(List<SObject> triggerNew, TriggerContext ctx) {
        return logicSelector.getTriggerActions(ctx);
    }

    public override List<TriggerAction> afterInsert(List<SObject> triggerNew, TriggerContext ctx) {
        return logicSelector.getTriggerActions(ctx);
    }

    public override List<TriggerAction> beforeUpdate(List<SObject> triggerNew, TriggerContext ctx) {
        return logicSelector.getTriggerActions(ctx);
    }

    public override List<TriggerAction> afterUpdate(List<SObject> triggerNew, TriggerContext ctx) {
        return logicSelector.getTriggerActions(ctx);
    }

    public override List<TriggerAction> beforeDelete(List<SObject> triggerOld, TriggerContext ctx) {
        return logicSelector.getTriggerActions(ctx);
    }

    public override List<TriggerAction> afterDelete(List<SObject> triggerOld, TriggerContext ctx) {
        return logicSelector.getTriggerActions(ctx);
    }

    public override List<TriggerAction> afterUndelete(List<SObject> triggerNew, TriggerContext ctx) {
        return logicSelector.getTriggerActions(ctx);
    }

    /**
     * Mocks Trigger Logic defined in TriggerLogic__mdt custom metadata for unit testing purposes.
     */
    @TestVisible
    private static void mockMetadata(List<TriggerLogic__mdt> logic) {
        logicSelector = new TriggerLogicSelector.MockSelector(logic);
    }
}