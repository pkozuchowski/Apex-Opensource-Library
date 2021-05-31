/**
* MIT License
*
* Copyright (c) 2021 Piotr Kożuchowski
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
/**
*  Please find the newest source code at https://github.com/amorek/Apex-Opensource-Library
*
*/

/**
 * Settings for Trigger logic.
 * This class allows enabling and disabling triggers for single SObject type as well as enabling/disabling
 * all customizations (triggers, flows, validation rules) as long as they incorporate switch logic.
 */
public inherited sharing class TriggerSettings {
    private static Boolean triggersEnabled = true;
    private final static LogicSwitch__c logicSwitchSetting = LogicSwitch__c.getInstance();
    private final static Set<SObjectType> disabledTriggers = new Set<SObjectType>();
    private static TriggerLogicSelector logicSelector = new TriggerLogicSelector();


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
     * Mocks Trigger Logic defined in TriggerLogic__mdt custom metadata for unit testing purposes.
     */
    @TestVisible
    private static void mockMetadata(List<TriggerLogic__mdt> logic) {
        mockSelector(new TriggerLogicSelector.MockSelector(logic));
    }

    /**
     * Mocks TriggerLogicSelector used to query TriggerLogic__mdt records for unit testing purposes.
     */
    @TestVisible
    private static void mockSelector(TriggerLogicSelector selector) {
        logicSelector = selector;
    }

    /**
     * @return Selector class which queries metadata-defined trigger logic.
     */
    public static TriggerLogicSelector getLogicSelector() {
        return logicSelector;
    }

    /**
    * Disable all logic (Workflow RUles, Triggers, Process Builders, Validation Rules) which handle LogicSwitch__c.
    * Disablement is done by temporarily upserting LogicSwitch__c record for running user and restoring it later with enableAllAutomations.
    * This action performs DML.
    */
    public static void disableAllLogic() {
        LogicSwitch__c clone = LogicSwitch__c.getInstance();
        clone.DisableWorkflowRules__c = true;
        clone.DisableTriggers__c = true;
        clone.DisableProcessBuilders__c = true;
        clone.DisableValidationRules__c = true;
        upsert clone;
    }

    /**
    * Restores previous LogicSwitch values on the user.
    * This action performs DML.
    */
    public static void enableAllLogic() {
        delete [SELECT Id FROM LogicSwitch__c WHERE SetupOwnerId = :UserInfo.getUserId()];
    }

    private TriggerSettings() {}
}