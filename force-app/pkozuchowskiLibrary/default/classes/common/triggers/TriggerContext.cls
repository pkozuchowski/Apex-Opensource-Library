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
    public Boolean isExecuting = Trigger.isExecuting;
    public Boolean isInsert = Trigger.isInsert;
    public Boolean isUpdate = Trigger.isUpdate;
    public Boolean isDelete = Trigger.isDelete;
    public Boolean isUndelete = Trigger.isUndelete;
    public Boolean isBefore = Trigger.isBefore;
    public Boolean isAfter = Trigger.isAfter;
    public Integer size = Trigger.size;
    public TriggerOperation operationType = Trigger.operationType;

    public List<SObject> triggerNew = Trigger.new;
    public List<SObject> triggerOld = Trigger.old;
    public Map<Id, SObject> triggerNewMap = Trigger.newMap;
    public Map<Id, SObject> triggerOldMap = Trigger.oldMap;
}