// SPDX-License-Identifier: MIT
// Copyright 2019 Piotr Kożuchowski

/**
 * Encapsulation for Trigger context variables.
 * This class is used as flag interface in methods to ensure they are run in trigger context,
 * but may also be used to mock trigger execution in unit tests.
 * It also contains helper method for checking field changes.
 */
@SuppressWarnings('PMD')
public virtual class TriggerContext {
    private final static Map<String, Integer> PROCESSED_COUNT = new Map<String, Integer>();
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
    protected Map<Id, SObject> triggerOldMap { get; protected set; }

    /**
     * @return Instance of TriggerContext object if ran during trigger or test execution, null otherwise.
     */
    public static TriggerContext getInstance() {
        if (Trigger.isExecuting || Test.isRunningTest()) {
            return new TriggerContext();

        } else {
            return null;
        }
    }

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
        this.triggerOld = Trigger.old;

        if (getRecords() != null) {
            this.sObjectType = getRecords().getSObjectType();
        }
    }

    public TriggerContext(TriggerOperation operation, List<SObject> triggerNew, List<SObject> triggerOld) {
        this.isExecuting = true;
        this.operationType = operation;
        String op = operation.name();
        this.isInsert = op.contains('INSERT');
        this.isUpdate = op.contains('UPDATE');
        this.isDelete = op.contains('_DELETE');
        this.isUndelete = op.contains('UNDELETE');
        this.isBefore = op.contains('BEFORE');
        this.isAfter = op.contains('AFTER');

        this.triggerNew = triggerNew;
        this.triggerOld = triggerOld;
        this.triggerOldMap = triggerOld == null ? null : new Map<Id, SObject>(triggerOld);
        if (triggerNew != null && operation != TriggerOperation.BEFORE_INSERT) {
            this.triggerNewMap = new Map<Id, SObject>(triggerNew);
        }
        this.sObjectType = getRecords().getSObjectType();
        this.size = getRecords().size();
    }


    /**
     * @return Trigger.old in DELETE triggers and Trigger.new in all other cases
     */
    public SObject[] getRecords() {
        return triggerNew ?? triggerOld;
    }

    /**
     * @return Trigger.oldMap in DELETE triggers and Trigger.newMap in all other cases
     */
    public Map<Id, SObject> getRecordsMap() {
        return triggerNewMap ?? triggerOldMap;
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

    /**
     * @return Records where the field changed
     */
    public List<SObject> getChanged(SObjectField sObjectField) {
        List<SObject> changed = new List<SObject>();

        for (Integer i = 0, j = triggerNew.size(); i < j; i++) {
            SObject record = triggerNew[i];

            if (isChanged(record, sObjectField)) {
                changed.add(record);
            }
        }
        return changed;
    }

    /**
     * @param sObjectField Changed field
     * @param values Set of new accepted values
     *
     * @return List of records which had the specified field changed to any of the accepted values
     */
    public List<SObject> getChangedToValue(SObjectField sObjectField, Set<Object> values) {
        List<SObject> changed = new List<SObject>();

        for (Integer i = 0, j = triggerNew.size(); i < j; i++) {
            SObject record = triggerNew[i];

            if (isChanged(record, sObjectField) && values.contains(record.get(sObjectField))) {
                changed.add(record);
            }
        }
        return changed;
    }

    /**
     * @param sObjectField Changed field
     * @param values Set of old values
     *
     * @return List of records which had the specified field changed from any of the provided values
     */
    public List<SObject> getChangedFromValue(SObjectField sObjectField, Set<Object> values) {
        List<SObject> changed = new List<SObject>();

        for (Integer i = 0, j = triggerNew.size(); i < j; i++) {
            SObject record = triggerNew[i];

            if (isChanged(record, sObjectField) && values.contains(getOld(record).get(sObjectField))) {
                changed.add(record);
            }
        }
        return changed;
    }

    /**
     * @param featureName Name of class or feature that is calling this method.
     * It is used to cover scenario where record did not initially meet criteria to process, but was updated by flow/another DML to meet the criteria.
     * @param recordId Id of record in trigger
     * @return True if record is executed in the trigger for the first time.
     * If this is second (recurrent) run of a trigger for same records and you execute this method in after trigger,
     * it will return true.
     */
    public Boolean isFirstRun(String featureName, Id recordId) {
        return getRunCount(featureName, recordId) == 0;
    }

    /**
     * @param featureName Name of class or feature that is calling this method.
     * It is used to cover scenario where record did not initially meet criteria to process, but was updated by flow/another DML to meet the criteria.
     * @param recordId Id of record in trigger
     */
    public void setExecuted(String featureName, Id recordId) {
        Integer count = getRunCount(featureName, recordId);
        String key = '' + recordId + featureName;
        PROCESSED_COUNT.put(key, count + 1);
    }

    /**
     * @param recordId Id of record in trigger
     * @return How many times this record was in given trigger phase (ex. how many times record was in TriggerOperation.AFTER_UPDATE)
     */
    public Integer getRunCount(String featureName, Id recordId) {
        String key = '' + recordId + featureName;
        Integer count = PROCESSED_COUNT.get(key);
        return count == null ? 0 : count;
    }
}