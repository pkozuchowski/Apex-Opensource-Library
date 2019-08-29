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
public interface TriggerHandler {
    void onBeforeInsert(List<SObject> triggerNew, TriggerContext tc);
    void onBeforeUpdate(List<SObject> triggerNew, TriggerContext tc);
    void onBeforeDelete(List<SObject> triggerOld, TriggerContext tc);
    void onAfterInsert(List<SObject> triggerNew, TriggerContext tc);
    void onAfterUpdate(List<SObject> triggerNew, TriggerContext tc);
    void onAfterDelete(List<SObject> triggerOld, TriggerContext tc);
    void onAfterUndelete(List<SObject> triggerNew, TriggerContext tc);
}