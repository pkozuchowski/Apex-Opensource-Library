// SPDX-License-Identifier: MIT
// Copyright 2019 Piotr Kożuchowski

/**
 * Settings for Trigger logic.
 * This class allows enabling and disabling triggers for single SObject type as well as enabling/disabling
 * all customizations (triggers, flows, validation rules) as long as they incorporate switch logic.
 */
public inherited sharing class TriggerSettings {
    private static Boolean triggersEnabled = true;
    private static LogicSwitch__c logicSwitchSetting = LogicSwitch__c.getInstance();
    private static Set<SObjectType> disabledTriggers = new Set<SObjectType>();


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
        disabledTriggers.add(sObjectType);
    }

    /**
    * Enabled previously disabled trigger execution for given sObjectType
    */
    public static void enableTrigger(SObjectType sObjectType) {
        disabledTriggers.remove(sObjectType);
    }

    /**
     * @return True, if triggers for given SObject Type are enabled.
     */
    public static Boolean isSObjectTriggerEnabled(SObjectType sObjectType) {
        return disabledTriggers.contains(sObjectType) == false
            && logicSwitchSetting.DisableTriggers__c == false
            && triggersEnabled == true;
    }

    /**
    * Disable all logic (Workflow Rules, Triggers, Process Builders, Validation Rules) which handle LogicSwitch__c.
    * Disablement is done by temporarily upserting LogicSwitch__c record for running user and restoring it later with enableAllAutomations.
    * This action performs DML.
    */
    public static void disableAllLogic() {
        LogicSwitch__c clone = LogicSwitch__c.getInstance();
        clone.DisableWorkflowRules__c = true;
        clone.DisableTriggers__c = true;
        clone.DisableProcessBuilders__c = true;
        clone.DisableValidationRules__c = true;
        clone.DisableFlows__c = true;
        upsert as system clone;
        logicSwitchSetting = clone;
    }

    /**
    * Restores previous LogicSwitch values on the user.
    * This action performs DML.
    */
    public static void enableAllLogic() {
        delete [SELECT Id FROM LogicSwitch__c WHERE SetupOwnerId = :UserInfo.getUserId() WITH SYSTEM_MODE];
        logicSwitchSetting = LogicSwitch__c.getInstance();
    }

    private TriggerSettings() {}
}