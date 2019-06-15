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
 * Encapsulation for Trigger context variables.
 * This class can be used to mock triggers in unit tests or as flag interface in methods to ensure they are run in trigger context.
 */
public class TriggerContext {
    @TestVisible public Boolean isExecuting { get; private set; }
    @TestVisible public Boolean isInsert { get; private set; }
    @TestVisible public Boolean isUpdate { get; private set; }
    @TestVisible public Boolean isDelete { get; private set; }
    @TestVisible public Boolean isUndelete { get; private set; }
    @TestVisible public Boolean isBefore { get; private set; }
    @TestVisible public Boolean isAfter { get; private set; }
    @TestVisible public Integer size { get; private set; }
    @TestVisible public TriggerOperation operationType { get; private set; }
    @TestVisible public List<SObject> triggerNew { get; private set; }
    @TestVisible public List<SObject> triggerOld { get; private set; }
    @TestVisible public Map<Id, SObject> triggerNewMap { get; private set; }
    @TestVisible public Map<Id, SObject> triggerOldMap { get; private set; }

    public TriggerContext() {
        this.isExecuting = Trigger.isExecuting;
        this.isInsert = Trigger.isInsert;
        this.isUpdate = Trigger.isUpdate;
        this.isDelete = Trigger.isDelete;
        this.isUndelete = Trigger.isUndelete;
        this.isBefore = Trigger.isBefore;
        this.isAfter = Trigger.isAfter;
        this.size = Trigger.size;
        this.operationType = Trigger.operationType;
        this.triggerNew = Trigger.new;
        this.triggerOld = Trigger.old;
        this.triggerNewMap = Trigger.newMap;
        this.triggerOldMap = Trigger.oldMap;
    }
}