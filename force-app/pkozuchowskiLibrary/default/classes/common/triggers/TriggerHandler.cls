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

/**
 * Abstract class used as basis to enforce uniform Trigger handling.
 * All triggers for individual SObject types should have one Trigger Handler class extending this class and provide
 * their own handling for each trigger event by overriding virtual methods.
 *
 * This handler provides special behaviour for workflow field updates, which under normal circumstances execute trigger
 * with original old map. This handler uses new map from previous trigger run for optimization.
 * Logic classes will see only workflow field updates changes.
 */
public abstract class TriggerHandler {
    private final static Map<Map<Id, SObject>, Map<Id, SObject>> PREVIOUS_OLD_MAPS = new Map<Map<Id, SObject>, Map<Id, SObject>>();

    @TestVisible
    protected final TriggerContext triggerContext = new TriggerContext();

    public void run() {
        if (triggerContext.isExecuting && !Bypass_Settings__c.getInstance().Bypass_Triggers__c) {
            switch on triggerContext.operationType {
                when BEFORE_INSERT {
                    onBeforeInsert(triggerContext.triggerNew);
                }
                when BEFORE_UPDATE {
                    onBeforeUpdate(triggerContext.triggerNewMap, getOldMap());
                }
                when BEFORE_DELETE {
                    onBeforeDelete(triggerContext.triggerOldMap);
                }
                when AFTER_INSERT {
                    onAfterInsert(triggerContext.triggerNewMap);
                }
                when AFTER_UPDATE {
                    onAfterUpdate(triggerContext.triggerNewMap, getOldMap());
                    cacheOldMap();
                }
                when AFTER_DELETE {
                    onAfterDelete(triggerContext.triggerOldMap);
                }
                when AFTER_UNDELETE {
                    onAfterUndelete(triggerContext.triggerNewMap);
                }
            }
        }
    }


    /**
     * @return Trigger old map in normal context and previous Trigger.newMap if current execution happened as result of Workflow update.
     */
    private Map<Id, SObject> getOldMap() {
        return PREVIOUS_OLD_MAPS.containsKey(triggerContext.triggerOldMap) ? PREVIOUS_OLD_MAPS.get(triggerContext.triggerOldMap) : triggerContext.triggerOldMap;
    }

    private void cacheOldMap() {
        PREVIOUS_OLD_MAPS.put(triggerContext.triggerOldMap, triggerContext.triggerNewMap);
    }


    protected virtual void onBeforeInsert(List<SObject> triggerNew) {
    }
    protected virtual void onBeforeUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
    }
    protected virtual void onBeforeDelete(Map<Id, SObject> triggerOldMap) {
    }

    protected virtual void onAfterInsert(Map<Id, SObject> triggerNewMap) {
    }
    protected virtual void onAfterUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
    }
    protected virtual void onAfterDelete(Map<Id, SObject> triggerOldMap) {
    }
    protected virtual void onAfterUndelete(Map<Id, SObject> triggerNewMap) {
    }
}