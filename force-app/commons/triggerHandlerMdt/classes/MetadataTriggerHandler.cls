// SPDX-License-Identifier: MIT
// Copyright 2019 Piotr Kożuchowski


/**
 * Metadata-driven implementation of TriggerHandler which executes trigger action
 * based on TriggerAction__mdt custom metadata configuration.
 */
public virtual with sharing class MetadataTriggerHandler extends TriggerHandler {
    private static List<TriggerSetting__mdt> mockSettings;
    private static List<TriggerAction__mdt> mockActions;

    @TestVisible
    private static void mock(TriggerSetting__mdt setting, List<TriggerAction__mdt> actions) {
        mockSettings = new List<TriggerSetting__mdt>{setting};
        mockActions = actions;
    }

    /**
     * Executes initialization actions before trigger processing
     */
    protected override void initialize(List<SObject> triggerNew, TriggerContext ctx) {
        execute('INITIALIZE', triggerNew, ctx);
    }

    /**
     * Executes finalization actions after trigger processing
     */
    protected override void finalize(List<SObject> triggerNew, TriggerContext ctx) {
        execute('FINALIZE', triggerNew, ctx);
    }

    /**
     * Executes metadata defined trigger actions for non-standard operation types (init, finalize)
     */
    private void execute(String type, List<SObject> triggerNew, TriggerContext ctx) {
        List<TriggerAction> triggerActions = getMetadataActions(ctx, type);
        executeActions(triggerActions, triggerNew, ctx);
    }

    /**
     * Overrides TriggerHandler method to ignore actions returned from beforeInsert, afterInsert etc.
     * Instead retrieves trigger actions for the current operation type from custom metadata.
     */
    protected override List<TriggerAction> getActions(TriggerContext ctx) {
        return getMetadataActions(ctx, ctx.operationType.name());
    }

    /**
     * Retrieves metadata-defined trigger actions for given sObject type and operation.
     * Actions are filtered by custom permissions (bypass/required) and return only those that should be executed.
     * @param ctx Trigger Context containing information about trigger execution
     * @param operationType Operation type name: INITIALIZE, BEFORE_INSERT, AFTER_INSERT, etc.
     * @return List of trigger action instances that should be executed for this trigger operation
     */
    private List<TriggerAction> getMetadataActions(TriggerContext ctx, String operationType) {
        List<TriggerAction> classes = new List<TriggerAction>();
        TriggerSetting__mdt[] triggerSettings = getTriggerSettings(ctx, operationType);

        for (Integer i = 0; i < triggerSettings.size(); i++) {
            TriggerSetting__mdt setting = triggerSettings.get(i);

            if (isPermitted(setting.BypassPermission__c, setting.RequiredPermission__c)) {
                List<TriggerAction__mdt> actions = getTriggerActions(setting);

                for (Integer j = 0; j < actions.size(); j++) {
                    TriggerAction action = getActionInstance(actions[j]);
                    if (action != null) {
                        classes.add(action);
                    }
                }
            }
        }

        return classes;
    }


    /**
     * @return List of trigger settings metadata for given sObject type.
     */
    private List<TriggerSetting__mdt> getTriggerSettings(TriggerContext ctx, String operation) {
        return mockSettings ?? [
            SELECT DeveloperName, BypassPermission__c, RequiredPermission__c, (
                SELECT NamespacePrefix, DeveloperName, ApexClass__c, Parameters__c,
                    BypassPermission__c, RequiredPermission__c
                FROM TriggerActions__r
                WHERE Operation__c = :operation
                AND Active__c = TRUE
                ORDER BY Order__c ASC, ApexClass__c ASC
            )

            FROM TriggerSetting__mdt
            WHERE SObjectType__c = :ctx.sObjectType.toString()
            AND Active__c = TRUE
            WITH SYSTEM_MODE
        ];
    }

    /**
     * @return List of trigger actions metadata for given trigger setting.
     */
    private List<TriggerAction__mdt> getTriggerActions(TriggerSetting__mdt setting) {
        return mockActions ?? setting.TriggerActions__r;
    }

    /**
     * Creates instance of TriggerAction defined in custom metadata and returns it.
     */
    private TriggerAction getActionInstance(TriggerAction__mdt actionMdt) {
        try {
            if (isPermitted(actionMdt.BypassPermission__c, actionMdt.RequiredPermission__c)) {
                Type actionClass = Type.forName(actionMdt.NamespacePrefix, actionMdt.ApexClass__c);
                return (TriggerAction) JSON.deserialize(actionMdt.Parameters__c ?? '{}', actionClass);
            }
            return null;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex.getMessage());
            System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
            TypeException typeException = new TypeException(
                'Apex class defined in custom metadata TriggerAction__mdt.' + actionMdt.DeveloperName
                + ' (' + actionMdt.ApexClass__c + ') is invalid. ' +
                'Please check if corresponding class is public and implements correct interface.'
            );
            typeException.initCause(ex);
            throw typeException;
        }
    }

    /**
     * @return True if CustomPermissions is blank or user has defined custom permission.
     */
    private Boolean isPermitted(String bypassPermission, String requiredPermission) {
        if (String.isNotBlank(bypassPermission) && FeatureManagement.checkPermission(bypassPermission)) {
            return false;
        }

        if (String.isNotBlank(requiredPermission) && !FeatureManagement.checkPermission(requiredPermission)) {
            return false;
        }

        return true;
    }
}