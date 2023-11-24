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
public inherited sharing class TriggerDispatcher {


    /**
     * Runs instance of concrete Trigger Handler implementation
     */
    public static void run(TriggerHandler triggerHandler) {
        run(triggerHandler, TriggerContext.getInstance());
    }

    @TestVisible
    private static void run(TriggerHandler triggerHandler, TriggerContext triggerContext) {
        try {
            if (shouldRun(triggerContext, triggerHandler)) {
                switch on triggerContext.operationType {
                    when BEFORE_INSERT {
                        triggerHandler.beforeInsert(triggerContext.getRecords(), triggerContext);
                    }
                    when BEFORE_UPDATE {
                        triggerHandler.beforeUpdate(triggerContext.getRecords(), triggerContext);
                    }
                    when BEFORE_DELETE {
                        triggerHandler.beforeDelete(triggerContext.getRecords(), triggerContext);
                    }
                    when AFTER_INSERT {
                        triggerHandler.afterInsert(triggerContext.getRecords(), triggerContext);
                    }
                    when AFTER_UPDATE {
                        triggerHandler.afterUpdate(triggerContext.getRecords(), triggerContext);
                    }
                    when AFTER_DELETE {
                        triggerHandler.afterDelete(triggerContext.getRecords(), triggerContext);
                    }
                    when AFTER_UNDELETE {
                        triggerHandler.afterUndelete(triggerContext.getRecords(), triggerContext);
                    }
                }
            }
        } catch (Exception e) {
            // Plug-in Logger implementation
            // Logger.error(new Log(e));
            throw e;
        }
    }


    /**
    * @return True when:
    * - is in trigger context (can be mocked in unit tests)
    * - if it's not disabled in Bypass Triggers settings
    * - if it's not manually disabled in code via  disableTrigger();
    */
    private static Boolean shouldRun(TriggerContext triggerContext, TriggerHandler th) {
        String thName = th.toString().substringBefore(':');
        return triggerContext.isExecuting
            && TriggerSettings.isSObjectTriggerEnabled(triggerContext.sObjectType)
            && TriggerSettings.isTriggerHandlerEnabled(thName);
    }

    private TriggerDispatcher() {}
}