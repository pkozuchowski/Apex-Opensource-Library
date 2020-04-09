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
 * This class is used as flag interface in methods to ensure they are run in trigger context,
 * but may also be used to mock trigger execution in unit tests.
 * It also contains helper method for checking field changes.
 */
public virtual class TriggerContext {
    private final static Map<Map<Id, SObject>, Map<Id, SObject>> PREVIOUS_NEW_MAPS = new Map<Map<Id, SObject>, Map<Id, SObject>>();

    public Boolean isExecuting { get; protected set; }
    public Boolean isInsert { get; protected set; }
    public Boolean isUpdate { get; protected set; }
    public Boolean isDelete { get; protected set; }
    public Boolean isUndelete { get; protected set; }
    public Boolean isBefore { get; protected set; }
    public Boolean isAfter { get; protected set; }
    public Integer size { get; protected set; }
    public TriggerOperation operationType { get; protected set; }
    public transient SObjectType sObjectType { get; protected set; }
    protected List<SObject> triggerNew { get; protected set; }
    protected List<SObject> triggerOld { get; protected set; }
    protected Map<Id, SObject> triggerNewMap { get; protected set; }

    /**
    * This is different from Trigger.oldMap in subsequent trigger runs:
    * if trigger is run over the same set of records (WF field update), then this variable will resolve to Trigger.newMap
    * from previous trigger iteration.
    * Meaning, if code checks for difference between old and new field value, it will not rerun on WF field update unless WF really updated the field.
    */
    protected Map<Id, SObject> triggerOldMap {
        get;
        protected set {
            if (value != null) {
                this.originalOldMap = value;
                this.triggerOldMap = PREVIOUS_NEW_MAPS.containsKey(originalOldMap) ? PREVIOUS_NEW_MAPS.get(value) : value;
            }
        }
    }
    protected Map<Id, SObject> originalOldMap;

    protected TriggerContext() {
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
        if (getRecords() != null) {
            this.sObjectType = getRecords().getSObjectType();
        }
    }


    /**
     * @return Trigger.old in DELETE triggers and Trigger.new in all other cases
     */
    public SObject[] getRecords() {
        return triggerNew == null ? triggerOld : triggerNew;
    }

    /**
     * @return Trigger.oldMap in DELETE trsiggers and Trigger.newMap in all other cases
     */
    public Map<Id, SObject> getRecordsMap() {
        return triggerNewMap == null ? triggerOldMap : triggerNewMap;
    }

    /**
     * @return Set of record ids or empty set in BEFORE INSERT
     */
    public Set<Id> getRecordsIds() {
        return getRecordsMap() == null ? new Set<Id>() : getRecordsMap().keySet();
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
    * @return Trigger Old Map
    */
    public Map<Id, SObject> getOldMap() {
        return triggerOldMap;
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

    protected Map<Map<Id, SObject>, Map<Id, SObject>> getPreviousMapsCache() {
        return PREVIOUS_NEW_MAPS;
    }
}