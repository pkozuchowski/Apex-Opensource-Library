// SPDX-License-Identifier: MIT
// Copyright 2019 Piotr Kożuchowski

public virtual with sharing class MetadataTriggerHandler extends TriggerHandler {
    private static TriggerLogicSelector logicSelector = new TriggerLogicSelector();

    public override void initialize(List<SObject> triggerNew, TriggerContext ctx) {
        execute(ctx, 'INITIALIZE', triggerNew);
    }

    public override List<TriggerAction> beforeInsert(List<SObject> triggerNew, TriggerContext ctx) {
        return logicSelector.getTriggerActions(ctx.sObjectType, ctx.operationType.name());
    }

    public override List<TriggerAction> afterInsert(List<SObject> triggerNew, TriggerContext ctx) {
        return logicSelector.getTriggerActions(ctx.sObjectType, ctx.operationType.name());
    }

    public override List<TriggerAction> beforeUpdate(List<SObject> triggerNew, TriggerContext ctx) {
        return logicSelector.getTriggerActions(ctx.sObjectType, ctx.operationType.name());
    }

    public override List<TriggerAction> afterUpdate(List<SObject> triggerNew, TriggerContext ctx) {
        return logicSelector.getTriggerActions(ctx.sObjectType, ctx.operationType.name());
    }

    public override List<TriggerAction> beforeDelete(List<SObject> triggerOld, TriggerContext ctx) {
        return logicSelector.getTriggerActions(ctx.sObjectType, ctx.operationType.name());
    }

    public override List<TriggerAction> afterDelete(List<SObject> triggerOld, TriggerContext ctx) {
        return logicSelector.getTriggerActions(ctx.sObjectType, ctx.operationType.name());
    }

    public override List<TriggerAction> afterUndelete(List<SObject> triggerNew, TriggerContext ctx) {
        return logicSelector.getTriggerActions(ctx.sObjectType, ctx.operationType.name());
    }

    public override void finalize(List<SObject> triggerNew, TriggerContext ctx) {
        execute(ctx, 'FINALIZE', triggerNew);
    }

    private void execute(TriggerContext ctx, String type, List<SObject> triggerNew) {
        List<TriggerAction> triggerActions = logicSelector.getTriggerActions(
            ctx.sObjectType, type);

        for (TriggerAction triggerAction : triggerActions) {
            triggerAction.execute(triggerNew, ctx);
        }
    }

    /**
     * Mocks Trigger Logic defined in TriggerAction__mdt custom metadata for unit testing purposes.
     */
    @TestVisible
    private static void mockMetadata(List<TriggerAction__mdt> logic) {
        logicSelector = new TriggerLogicSelector.MockSelector(logic);
    }
}