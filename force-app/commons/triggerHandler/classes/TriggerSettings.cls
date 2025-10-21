// SPDX-License-Identifier: MIT
// Copyright 2019 Piotr Kożuchowski

/**
 * Settings for Trigger logic.
 * This class allows enabling and disabling triggers for single SObject type as well as enabling/disabling
 * all customizations (triggers, flows, validation rules) as long as they incorporate switch logic.
 */
public inherited sharing class TriggerSettings {
    private static Boolean triggersEnabled = true;
    private static LogicSwitch__c settings;
    private static Set<String> disabledTriggers;
    private static Set<String> disabledActions;

    /**
    * Load disabled actions from LogicSwitch__c setting
    */
    static {
        refreshSettings();
    }

    /**
     * Refreshes settings from LogicSwitch__c custom setting.
     * All previously disabled triggers and actions are cleared.
     */
    public static void refreshSettings() {
        triggersEnabled = true;
        settings = LogicSwitch__c.getInstance();
        disabledActions.clear();
        disabledTriggers.clear();
        addSettingLines(settings.DisableActions__c, disabledActions);
        addSettingLines(settings.DisableSelectedTriggers__c, disabledTriggers);
    }

    /**
     * Disables triggers on all SObjects
     */
    public static void disableTriggers() {
        triggersEnabled = false;
    }

    /**
     * Enables triggers on all SObjects
     */
    public static void enableTriggers() {
        triggersEnabled = true;
    }

    /**
    * Disable all triggers execution for given sObjectType for current transaction or until enableTrigger is called
    */
    public static void disableTrigger(SObjectType sObjectType) {
        disabledTriggers.add(sObjectType.toString());
    }

    /**
    * Enabled previously disabled trigger execution for given sObjectType
    */
    public static void enableTrigger(SObjectType sObjectType) {
        disabledTriggers.remove(sObjectType.toString());
    }

    /**
     * Checks if triggers should run in the current context.
     *
     * @param ctx The trigger context to check
     * @return True if triggers should run, false otherwise
     */
    public static Boolean shouldRun(TriggerContext ctx) {
        String sobjectName = ctx.sObjectType.toString().toLowerCase();
        return ctx.isExecuting
            && triggersEnabled == true
            && settings.DisableTriggers__c == false
            && disabledTriggers.contains(sobjectName) == false
            && disabledTriggers.contains(
            (sobjectName + '.' + ctx.operationType).toLowerCase()
        ) == false;
    }

    /**
     * Checks if a specific trigger action is enabled.
     * Trigger Dispatcher checks this before executing each action.
     *
     * @param action Class name of trigger action to check
     * @return True if the action is enabled (no actions are disabled or this specific action is disabled)
     */
    public static Boolean isActionEnabled(String actionClass) {
        return disabledActions.isEmpty()
            || !disabledActions.contains(actionClass);
    }

    /**
     * Enables a specific trigger action type.
     *
     * @param actionType The type of trigger action to enable
     */
    public static void enableAction(Type actionType) {
        disabledActions.remove(actionType.getName());
    }

    /**
     * Disables a specific trigger action type.
     * 
     * @param actionType The type of trigger action to disable
     */
    public static void disableAction(Type actionType) {
        disabledActions.add(actionType.getName());
    }


    /**
    * Disable all logic (Workflow Rules, Triggers, Process Builders, Validation Rules) which handle LogicSwitch__c.
    * Disablement is done by temporarily upserting LogicSwitch__c record for running user..
    * This action performs DML.
    */
    public static void disableAllLogic() {
        setUserSettings(true);
    }

    /**
    * Enables all logic (Workflow Rules, Triggers, Process Builders, Validation Rules) in LogicSwitch__c.
    * Creates new settings for running user with all options enabled.
    * This action performs DML.
    */
    public static void enableAllLogic() {
        setUserSettings(false);
    }

    private static void setUserSettings(Boolean value) {
        LogicSwitch__c clone = LogicSwitch__c.getInstance();
        clone.DisableWorkflowRules__c = value;
        clone.DisableTriggers__c = value;
        clone.DisableProcessBuilders__c = value;
        clone.DisableValidationRules__c = value;
        clone.DisableFlows__c = value;
        upsert as system clone;
        settings = clone;
    }

    /**
    * Reverts to org defaults by deleting LogicSwitch__c record for assigned to running user.
    * This action performs DML.
    */
    public static void removeUserSettings() {
        delete [SELECT Id FROM LogicSwitch__c WHERE SetupOwnerId = :UserInfo.getUserId() WITH SYSTEM_MODE];
        settings = LogicSwitch__c.getInstance();
    }

    private static void addSettingLines(String fieldValue, Set<String> disabledOptions) {
        if (String.isNotBlank(fieldValue)) {
            List<String> actions = fieldValue.split('\r\n');

            for (String action : actions) {
                disabledOptions.add(action.trim().toLowerCase());
            }
        }
    }

    private TriggerSettings() {}
}