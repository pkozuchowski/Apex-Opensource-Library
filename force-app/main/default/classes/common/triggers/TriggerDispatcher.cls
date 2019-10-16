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

    public static void run(TriggerHandler triggerHandler) {
        run(triggerHandler, new TriggerContext());
    }

    @TestVisible
    private static void run(TriggerHandler triggerHandler, TriggerContext triggerContext) {
        if (triggerContext.isExecuting && !Bypass_Settings__c.getInstance().Bypass_Triggers__c) {
            switch on triggerContext.operationType {
                when BEFORE_INSERT {
                    SObjectFieldDefaults.apply(triggerContext.triggerNew, triggerContext);
                    SObjectValidator.validate(triggerContext.triggerNew, triggerContext);
                    triggerHandler.onBeforeInsert(triggerContext.triggerNew, triggerContext);
                }
                when BEFORE_UPDATE {
                    SObjectFieldDefaults.apply(triggerContext.triggerNew, triggerContext);
                    SObjectValidator.validate(triggerContext.triggerNew, triggerContext);
                    triggerHandler.onBeforeUpdate(triggerContext.triggerNew, triggerContext);
                }
                when BEFORE_DELETE {
                    SObjectValidator.validate(triggerContext.triggerOld, triggerContext);
                    triggerHandler.onBeforeDelete(triggerContext.triggerOld, triggerContext);
                }
                when AFTER_INSERT {
                    SObjectValidator.validate(triggerContext.triggerNew, triggerContext);
                    triggerHandler.onAfterInsert(triggerContext.triggerNew, triggerContext);
                }
                when AFTER_UPDATE {
                    SObjectValidator.validate(triggerContext.triggerNew, triggerContext);
                    triggerHandler.onAfterUpdate(triggerContext.triggerNew, triggerContext);
                    triggerContext.cacheOldMap();
                }
                when AFTER_DELETE {
                    SObjectValidator.validate(triggerContext.triggerOld, triggerContext);
                    triggerHandler.onAfterDelete(triggerContext.triggerOld, triggerContext);
                }
                when AFTER_UNDELETE {
                    SObjectValidator.validate(triggerContext.triggerNew, triggerContext);
                    triggerHandler.onAfterUndelete(triggerContext.triggerNew, triggerContext);
                }
            }
        }
    }
}