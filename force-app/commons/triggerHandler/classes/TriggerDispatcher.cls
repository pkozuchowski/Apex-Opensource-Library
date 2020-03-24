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
    private static TriggerLogicSelector logicSelector = new TriggerLogicSelector();

    /**
     * Runs trigger field defaults, validations and logic defined in custom metadata
     */
    public static void run() {
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
        if (triggerContext.isExecuting && !Bypass_Settings__c.getInstance().Bypass_Triggers__c) {
            triggerHandler.apply(triggerContext.getRecords(), triggerContext, logicSelector.getTriggerFieldDefault(triggerContext));
            triggerHandler.validate(triggerContext.getRecords(), triggerContext, logicSelector.getTriggerValidationRules(triggerContext));
            triggerHandler.execute(triggerContext.getRecords(), triggerContext, logicSelector.getTriggerLogic(triggerContext));

            switch on triggerContext.operationType {
                when BEFORE_INSERT {
                    triggerHandler.onBeforeInsert(triggerContext.getRecords(), triggerContext);
                }
                when BEFORE_UPDATE {
                    triggerHandler.onBeforeUpdate(triggerContext.getRecords(), triggerContext);
                }
                when BEFORE_DELETE {
                    triggerHandler.onBeforeDelete(triggerContext.getRecords(), triggerContext);
                }
                when AFTER_INSERT {
                    triggerHandler.onAfterInsert(triggerContext.getRecords(), triggerContext);
                }
                when AFTER_UPDATE {
                    triggerHandler.onAfterUpdate(triggerContext.getRecords(), triggerContext);
                    ((TriggerContextImpl) triggerContext).cacheOldMap();
                }
                when AFTER_DELETE {
                    triggerHandler.onAfterDelete(triggerContext.getRecords(), triggerContext);
                }
                when AFTER_UNDELETE {
                    triggerHandler.onAfterUndelete(triggerContext.getRecords(), triggerContext);
                }
            }

            triggerHandler.executeAsync(triggerContext.getRecords(), triggerContext, logicSelector.getTriggerAsyncLogic(triggerContext));
        }
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