/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2019 Piotr Kożuchowski
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

public with sharing class MetadataTriggerHandler extends TriggerHandler {
    private static TriggerLogicSelector logicSelector = new TriggerLogicSelector();


    public override void beforeInsert(List<SObject> triggerNew, TriggerContext tc) {
        execute(triggerNew, tc);
    }

    public override void afterInsert(List<SObject> triggerNew, TriggerContext tc) {
        execute(triggerNew, tc);
    }

    public override void beforeUpdate(List<SObject> triggerNew, TriggerContext tc) {
        execute(triggerNew, tc);
    }

    public override void afterUpdate(List<SObject> triggerNew, TriggerContext tc) {
        execute(triggerNew, tc);
    }

    public override void beforeDelete(List<SObject> triggerOld, TriggerContext tc) {
        execute(triggerOld, tc);
    }

    public override void afterDelete(List<SObject> triggerOld, TriggerContext tc) {
        execute(triggerOld, tc);
    }

    public override void afterUndelete(List<SObject> triggerNew, TriggerContext tc) {
        execute(triggerNew, tc);
    }

    /**
     * Executes given trigger logic implementations.
     */
    private void execute(List<SObject> records, TriggerContext tc) {
        List<TriggerLogic> triggerLogics = logicSelector.getLogic(tc);

        for (TriggerLogic logic : triggerLogics) {
            logic.execute(records, tc);
        }
    }

    /**
     * Mocks Trigger Logic defined in TriggerLogic__mdt custom metadata for unit testing purposes.
     */
    @TestVisible
    private static void mockMetadata(List<TriggerLogic__mdt> logic) {
        logicSelector = new TriggerLogicSelector.MockSelector(logic);
    }
}