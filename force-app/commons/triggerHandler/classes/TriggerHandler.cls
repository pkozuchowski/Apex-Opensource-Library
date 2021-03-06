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
public virtual class TriggerHandler  {
    public virtual void handleBeforeInsert(List<SObject> triggerNew, TriggerContext tc){}
    public virtual void handleAfterInsert(List<SObject> triggerNew, TriggerContext tc){}

    public virtual void handleBeforeUpdate(List<SObject> triggerNew, TriggerContext tc){}
    public virtual void handleAfterUpdate(List<SObject> triggerNew, TriggerContext tc){}

    public virtual void handleBeforeDelete(List<SObject> triggerOld, TriggerContext tc){}
    public virtual void handleAfterDelete(List<SObject> triggerOld, TriggerContext tc){}

    public virtual void handleAfterUndelete(List<SObject> triggerNew, TriggerContext tc){}


    /**
     * Executes given trigger logic implementations.
     */
    public void execute(List<SObject> records, TriggerContext tc, List<Logic> triggerLogics) {
        for (Logic logic : triggerLogics) {
            logic.execute(records, tc);
        }
    }

    /**
     * Executes given trigger logic implementations asynchronously, each logic in separate Queueable.
     */
    public void executeAsync(List<SObject> records, TriggerContext tc, List<AsyncLogic> triggerLogics) {
        for (AsyncLogic logic : triggerLogics) {
            List<SObject> filtered = logic.filter(records, tc);

            if (!filtered.isEmpty()) {
                if (logic instanceof Queueable) {
                    System.enqueueJob(logic);
                } else {
                    System.enqueueJob(new AsyncLogicQueueableAdapter(filtered, logic));
                }
            }
        }
    }



    /**
     * This interface marks classes which should execute on trigger event.
     * Implementing classes are defined in TriggerLogic custom metadata.
     */
    public interface Logic {
        void execute(List<SObject> records, TriggerContext ctx);
    }


    /**
     * This interface marks classes which should execute asynchronously (using Queueable) on trigger event.
     * Implementing classes does not have to implement Queueable interface, but may do that if needed.
     * Implementing classes are defined in TriggerLogic custom metadata.
     */
    public interface AsyncLogic {
        List<SObject> filter(List<SObject> records, TriggerContext ctx);
        void execute(List<SObject> records, QueueableContext ctx);
    }


    /**
     * This interface marks classes which can be parametrized through TriggerLogic__mdt.Parameters__c field.
     * Value of the field will be passed to setParameters method.
     */
    public interface Parameterizable {
        void setParameters(String parameters);
    }


    /**
     * Adapter between TriggerAsyncLogic interface and Queueable interface
     */
    private class AsyncLogicQueueableAdapter implements Queueable, Database.AllowsCallouts {
        private List<SObject> records;
        private AsyncLogic asyncLogic;

        public AsyncLogicQueueableAdapter(List<SObject> records, AsyncLogic asyncLogic) {
            this.records = records;
            this.asyncLogic = asyncLogic;
        }

        public void execute(QueueableContext qc) {
            this.asyncLogic.execute(records, qc);
        }
    }
}