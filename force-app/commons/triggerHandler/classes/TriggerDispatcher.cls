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
    public static void run() {
        run(new TriggerHandler());
    }

    /**
     * Runs instance of concrete Trigger Handler implementation
     */
    public static void run(TriggerHandler triggerHandler) {
        run(triggerHandler, new TriggerContext());
    }

    @TestVisible
    private static void run(TriggerHandler triggerHandler, TriggerContext triggerContext) {
        if (triggerContext.isExecuting && !Bypass_Settings__c.getInstance().Bypass_Triggers__c) {
            SObjectFieldDefaults.apply(triggerContext.getRecords(), triggerContext);
            SObjectValidator.validate(triggerContext.getRecords(), triggerContext);
            SObjectTriggers.execute(triggerContext.getRecords(), triggerContext);

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
                    triggerContext.cacheOldMap(new Context());
                }
                when AFTER_DELETE {
                    triggerHandler.onAfterDelete(triggerContext.getRecords(), triggerContext);
                }
                when AFTER_UNDELETE {
                    triggerHandler.onAfterUndelete(triggerContext.getRecords(), triggerContext);
                }
            }
        }
    }

    /**
     * Flag class which ensures TriggerContext.cacheOldMap() is called only in this context.
     */
    public class Context {
        @TestVisible
        private Context() {
        }
    }
}