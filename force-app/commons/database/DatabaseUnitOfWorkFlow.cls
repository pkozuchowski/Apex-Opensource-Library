/* SPDX-License-Identifier: MIT */
/* Copyright 2025 Piotr Kożuchowski, apexlibra.org */

/**
 * Invocable Apex class for executing database operations using a unit of work pattern in Flows.
 */
public with sharing class DatabaseUnitOfWorkFlow {
    @TestVisible
    private static DatabaseUnitOfWork uow = new DatabaseUnitOfWork();
    private static Map<String, SObjectField> fieldMap = new Map<String, SObjectField>();

    public with sharing class Input {
        @InvocableVariable(Label='Operation Type')
        public String operationType;

        @InvocableVariable(Label='Run In Mode')
        public String runInMode;

        @InvocableVariable(Label='Upsert Field')
        public String upsertField;

        @InvocableVariable(Label='Record')
        public SObject record;
    }

    @InvocableMethod(
        Label='Database Unit of Work Operation'
        Description='Executes a unit of work in the database.'
        Category='Database'
        IconName='slds:standard:record_update'
        ConfigurationEditor='c-database-unit-of-work-properties'
    )
    public static void execute(List<Input> operations) {
        for (Integer i = 0; i < operations.size(); i++) {
            Input op = operations[i];

            switch on op.operationType {
                when 'insert' {
                    uow.insertRecord(op.record);
                }
                when 'update' {
                    uow.updateRecord(op.record);
                }
                when 'upsert' {
                    SObjectField upsertField = getSObjectField(op.record, op.upsertField);
                    uow.upsertRecord(op.record, upsertField);
                }
                when 'delete' {
                    uow.deleteRecord(op.record);
                }
                when 'commit' {
                    commitWork(op);
                    break;
                }
            }
        }
    }

    /**
     * Commits the unit of work based on the operation's run mode.
     * New operations cannot be added to this instance of unit of work after this method is called.
     */
    private static void commitWork(Input op) {
        switch on op.runInMode {
            when 'systemWithSharing' {
                uow.asSystemWithSharing();
            }
            when 'systemWithoutSharing' {
                uow.asSystemWithoutSharing();
            }
            when else {
                uow.asUser();
            }
        }

        // Prevents adding new operations to this unit of work after commit is called.
        DatabaseUnitOfWork currentUnit = DatabaseUnitOfWorkFlow.uow;
        DatabaseUnitOfWorkFlow.uow = new DatabaseUnitOfWork();
        currentUnit.commitWork();
    }

    /**
     * @return SObjectField for the specified record and field name.
     */
    private static SObjectField getSObjectField(SObject record, String field) {
        String key = '' + record.getSObjectType() + '.' + (field);
        if (!fieldMap.containsKey(key)) {
            fieldMap.put(key, record.getSObjectType()
                .getDescribe().fields.getMap().get(field));
        }

        SObjectField upsertField = fieldMap.get(key);
        return upsertField;
    }
}