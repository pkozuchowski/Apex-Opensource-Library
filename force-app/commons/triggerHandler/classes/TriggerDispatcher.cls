/**
* MIT License
*
* Copyright (c) 2019 Piotr Kożuchowski
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
public with sharing class TriggerDispatcher {
    private static Set<SObjectType> disabledTriggers = new Set<SObjectType>();
    private static TriggerLogicSelector logicSelector = new TriggerLogicSelector();
    private static LogicSwitch__c logicSwitchSetting = LogicSwitch__c.getInstance();

    /**
     * Runs trigger field defaults, validations and logic defined in custom metadata
     */
    public static void run() {
        System.debug(JSON.serializePretty(LogicSwitch__c.getInstance()));
        run(new TriggerHandler());
    }

    /**
     * Runs instance of concrete Trigger Handler implementation
     */
    public static void run(TriggerHandler triggerHandler) {
        run(triggerHandler, new TriggerContextImpl());
    }

    @TestVisible
    private static void run(TriggerHandler triggerHandler, TriggerContext triggerContext) {
        if (shouldRun(triggerContext)) {
            triggerHandler.apply(triggerContext.getRecords(), triggerContext, logicSelector.getFieldDefault(triggerContext));
            triggerHandler.validate(triggerContext.getRecords(), triggerContext, logicSelector.getValidationRules(triggerContext));
            triggerHandler.execute(triggerContext.getRecords(), triggerContext, logicSelector.getLogic(triggerContext));
            triggerHandler.executeAsync(triggerContext.getRecords(), triggerContext, logicSelector.getAsyncLogic(triggerContext));

            switch on triggerContext.operationType {
                when BEFORE_INSERT {
                    triggerHandler.handleBeforeInsert(triggerContext.getRecords(), triggerContext);
                }
                when BEFORE_UPDATE {
                    triggerHandler.handleBeforeUpdate(triggerContext.getRecords(), triggerContext);
                }
                when BEFORE_DELETE {
                    triggerHandler.handleBeforeDelete(triggerContext.getRecords(), triggerContext);
                }
                when AFTER_INSERT {
                    triggerHandler.handleAfterInsert(triggerContext.getRecords(), triggerContext);
                }
                when AFTER_UPDATE {
                    triggerHandler.handleAfterUpdate(triggerContext.getRecords(), triggerContext);
                    ((TriggerContextImpl) triggerContext).cacheOldMap();
                }
                when AFTER_DELETE {
                    triggerHandler.handleAfterDelete(triggerContext.getRecords(), triggerContext);
                }
                when AFTER_UNDELETE {
                    triggerHandler.handleAfterUndelete(triggerContext.getRecords(), triggerContext);
                }
            }
        }
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
    * Disable all logic (Workflow RUles, Triggers, Process Builders, Validation Rules) which handle LogicSwitch__c.
    * Disablement is done by temporarily upserting LogicSwitch__c record for running user and restoring it later with enableAllAutomations.
    * This action performs DML.
    */
    public static void disableAllLogic() {
        LogicSwitch__c clone = logicSwitchSetting.clone(true);
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
        if (String.isEmpty(logicSwitchSetting.Id)) {
            delete [SELECT Id FROM LogicSwitch__c WHERE SetupOwnerId = :UserInfo.getUserId()];

        } else {
            upsert logicSwitchSetting;
        }
    }


    /**
    * Trigger should run:
    * - Only in trigger context
    * - Only if it's not disabled in Bypass Triggers settings
    * - Only if it's not manually disabled in code via  disableTrigger();
    */
    private static Boolean shouldRun(TriggerContext triggerContext) {
        return triggerContext.isExecuting
                && !LogicSwitch__c.getInstance().DisableTriggers__c
                && !disabledTriggers.contains(triggerContext.sObjectType);
    }

    private TriggerDispatcher() {
    }

    @TestVisible
    private virtual class TriggerContextImpl extends TriggerContext {
        /**
         * Caches value of the new map at the end of trigger execution, so subsequent reruns of the same trigger on workflow updates
         * will not rerun the same methods again if they check for updated fields.
         *
         * For example, when trigger logic was executed on Account.Name change and workflow updated different field,
         * the subsequent trigger run will see new account name as "old" and will not execute logic.
         */
        private void cacheOldMap() {
            getPreviousMapsCache().put(originalOldMap, triggerNewMap);
        }
    }
}