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

    /**
     * Runs trigger field defaults, validations and logic defined in custom metadata
     */
    public static void runMetadataDefinedTriggers() {
        runMetadataDefinedTriggers(TriggerContext.getInstance());
    }

    @TestVisible
    private static void runMetadataDefinedTriggers(TriggerContext triggerContext) {
        TriggerHandler metadataTrigger = new CustomMetadataTrigger();

        if (shouldRun(triggerContext)) {
            TriggerLogicSelector logicSelector = TriggerSettings.getLogicSelector();
            metadataTrigger.execute(triggerContext.getRecords(), triggerContext, logicSelector.getLogic(triggerContext));
            metadataTrigger.executeAsync(triggerContext.getRecords(), triggerContext, logicSelector.getAsyncLogic(triggerContext));
        }
    }


    /**
     * Runs instance of concrete Trigger Handler implementation
     */
    public static void run(TriggerHandler triggerHandler) {
        run(triggerHandler, TriggerContext.getInstance());
    }

    @TestVisible
    private static void run(TriggerHandler triggerHandler, TriggerContext triggerContext) {
        if (shouldRun(triggerContext)) {
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
    * Trigger should run:
    * - Only in trigger context
    * - Only if it's not disabled in Bypass Triggers settings
    * - Only if it's not manually disabled in code via  disableTrigger();
    */
    private static Boolean shouldRun(TriggerContext triggerContext) {
        return triggerContext.isExecuting
                && TriggerSettings.isSObjectTriggerEnabled(triggerContext.sObjectType)
                && TriggerSettings.isTriggerSettingEnabled();
    }

    private TriggerDispatcher() {
    }


    /**
     * Empty Implementation of Trigger Handler without any explicitly defined logic.
     * Trigger will use only logic defined in custom metadata
     */
    private class CustomMetadataTrigger extends TriggerHandler {
    }
}