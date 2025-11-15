// SPDX-License-Identifier: MIT
// Copyright 2019 Piotr Kożuchowski


/**
 * Metadata-driven implementation of TriggerHandler which executes trigger logic
 * based on TriggerAction__mdt custom metadata configuration.
 */
public virtual with sharing class MetadataTriggerHandler extends TriggerHandler {
    private static MetadataTriggerSelector logicSelector = new MetadataTriggerSelector();

    /**
     * Executes initialization logic before trigger processing
     */
    protected override void initialize(List<SObject> triggerNew, TriggerContext ctx) {
        execute('INITIALIZE', triggerNew, ctx);
    }

    /**
     * Executes finalization logic after trigger processing
     */
    protected override void finalize(List<SObject> triggerNew, TriggerContext ctx) {
        execute('FINALIZE', triggerNew, ctx);
    }

    /**
     * Executes metadata defined trigger actions for non-standard operation types (init, finalize)
     */
    private void execute(String type, List<SObject> triggerNew, TriggerContext ctx) {
        List<TriggerAction> triggerActions = logicSelector.getTriggerActions(ctx.sObjectType, type);
        executeActions(triggerActions, triggerNew, ctx);
    }

    /**
     * Retrieves trigger actions for the current operation type
     */
    protected override List<TriggerAction> getActions(TriggerContext ctx) {
        return logicSelector.getTriggerActions(ctx.sObjectType, ctx.operationType.name());
    }

    /**
     * Mocks Trigger Logic defined in TriggerAction__mdt custom metadata for unit testing purposes.
     */
    @TestVisible
    private static void mockMetadata(List<TriggerAction__mdt> logic) {
        logicSelector = new MetadataTriggerSelector.MockSelector(logic);
    }
}