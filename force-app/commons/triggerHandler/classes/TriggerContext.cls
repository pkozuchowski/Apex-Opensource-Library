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

    public Boolean isExecuting { get; private set; }
    public Boolean isInsert { get; private set; }
    public Boolean isUpdate { get; private set; }
    public Boolean isDelete { get; private set; }
    public Boolean isUndelete { get; private set; }
    public Boolean isBefore { get; private set; }
    public Boolean isAfter { get; private set; }
    public Integer size { get; private set; }
    public TriggerOperation operationType { get; private set; }
    public transient SObjectType sObjectType { get; private set; }
    private List<SObject> triggerNew { get; private set; }
    private List<SObject> triggerOld { get; private set; }
    private Map<Id, SObject> triggerNewMap { get; private set; }
    private Map<Id, SObject> triggerOldMap {
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
        this.sObjectType = getRecords().getSObjectType();
    }

    @TestVisible
    private TriggerContext(TriggerOperation operation, List<SObject> triggerNew, List<SObject> triggerOld) {
        this.isExecuting = true;
        this.operationType = operation;
        this.isInsert = operation.name().contains('INSERT');
        this.isUpdate = operation.name().contains('UPDATE');
        this.isDelete = operation.name().contains('DELETE');
        this.isUndelete = operation.name().contains('UNDELETE');
        this.isBefore = operation.name().contains('BEFORE');
        this.isAfter = operation.name().contains('AFTER');
        this.size = triggerNew.size();

        this.triggerNew = triggerNew;
        this.triggerOld = triggerOld;
        this.triggerOldMap = triggerOld == null ? null : new Map<Id, SObject>(triggerOld);
        if (triggerNew != null && operation != TriggerOperation.BEFORE_INSERT) {
            this.triggerNewMap = new Map<Id, SObject>(triggerNew);
        }
        this.sObjectType = getRecords().getSObjectType();
    }


    /**
     * @return Trigger.old in DELETE triggers and Trigger.new in all other cases
     */
    public SObject[] getRecords() {
        return triggerNew != null ? triggerNew : triggerOld;
    }

    /**
     * @return Trigger.oldMap in DELETE triggers and Trigger.newMap in all other cases
     */
    public Map<Id, SObject> getRecordsMap() {
        return triggerNewMap != null ? triggerNewMap : triggerOldMap;
    }

    /**
     * @return Set of record ids or empty set in BEFORE INSERT
     */
    public Set<Id> getRecordsIds() {
        return getRecordsMap() != null ? getRecordsMap().keySet() : new Set<Id>();
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
     * @return True if record is being inserted.
     */
    public Boolean isNew() {
        return this.isInsert;
    }

    /**
     * @return True if record is being updated.
     */
    public Boolean isChanged() {
        return this.isUpdate;
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


    /**
     * @return True if trigger is in update context and if given field was changed from one value to another on the given record.
     */
    public Boolean isChangedFromTo(SObject record, SObjectField field, Object fromValue, Object toValue) {
        if (isUpdate) {
            Object newValue = record.get(field);
            Object oldValue = getOld(record).get(field);

            return newValue != oldValue && oldValue == fromValue && newValue == toValue;
        } else {
            return false;
        }
    }

    public void cacheOldMap(TriggerDispatcher.Context ctx) {
        if (ctx != null) {
            PREVIOUS_OLD_MAPS.put(originalOldMap, triggerNewMap);
        }
    }
}