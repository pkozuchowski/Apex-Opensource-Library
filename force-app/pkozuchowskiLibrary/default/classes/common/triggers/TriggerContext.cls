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
    private final static Map<Map<Id, SObject>, Map<Id, SObject>> PREVIOUS_OLD_MAPS = new Map<Map<Id, SObject>, Map<Id, SObject>>();

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
    @TestVisible public Map<Id, SObject> triggerOldMap {
        get;
        private set {
            if (value != null) {
                this.originalOldMap = value;
                this.triggerOldMap = PREVIOUS_OLD_MAPS.containsKey(value) ? PREVIOUS_OLD_MAPS.get(value) : value;
            }
        }
    }
    private Map<Id, SObject> originalOldMap;

    public TriggerContext() {
        this.isExecuting = Trigger.isExecuting == true;
        this.isInsert = Trigger.isInsert == true;
        this.isUpdate = Trigger.isUpdate == true;
        this.isDelete = Trigger.isDelete == true;
        this.isUndelete = Trigger.isUndelete == true;
        this.isBefore = Trigger.isBefore == true;
        this.isAfter = Trigger.isAfter == true;
        this.size = Trigger.size;
        this.operationType = Trigger.operationType;
        this.triggerNew = Trigger.new;
        this.triggerNewMap = Trigger.newMap;
        this.triggerOldMap = Trigger.oldMap;
        this.triggerOld = triggerOldMap == null ? null : triggerOldMap.values();
    }


    /**
     * @return Old version of the record in update trigger context and null in any other context.
     */
    public SObject getOld(SObject record) {
        if (isUpdate) {
            return triggerOldMap.get(record.Id);
        } else {
            return null;
        }
    }

    /**
     * @return True if trigger is in update context and if given field was changed on the given record.
     */
    public Boolean isChanged(SObject record, SObjectField field) {
        if (isUpdate) {
            Object newValue = record.get(field);
            Object oldValue = getOld(record).get(field);

            return newValue != oldValue;
        } else {
            return false;
        }
    }

    /**
     * @return True if trigger is in update context and if given field was changed to the value on the given record.
     */
    public Boolean isChangedTo(SObject record, SObjectField field, Object toValue) {
        if (isUpdate) {
            Object newValue = record.get(field);
            Object oldValue = getOld(record).get(field);

            return newValue != oldValue && newValue == toValue;
        } else {
            return false;
        }
    }

    /**
     * @return True if trigger is in update context and if given field was changed from the value on the given record.
     */
    public Boolean isChangedFrom(SObject record, SObjectField field, Object fromValue) {
        if (isUpdate) {
            Object newValue = record.get(field);
            Object oldValue = getOld(record).get(field);

            return newValue != oldValue && oldValue == fromValue;
        } else {
            return false;
        }
    }

    public void cacheOldMap() {
        PREVIOUS_OLD_MAPS.put(originalOldMap, triggerNewMap);
    }
}