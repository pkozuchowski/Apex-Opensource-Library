/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2024 Piotr Kożuchowski
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
 * /
 * *
 */

/**
 * This DatabaseService variant does not do any DMLs until they are explicitly commited using
 * `commitWork` method. This allows for deferring lookup setting from DML order.
 *
 * Order of the DMLs by default follows the order DMLs were invoked, however it's possible to specify
 * custom order using constructors. It's possible to specify order using SObjectTypes,
 * or through DML.Order class, which allows SObjectType+Operation (+ upsert field) granularity.
 */
public virtual inherited sharing class DatabaseUnitOfWork extends DatabaseService {
    private List<DML.DMLOperation> dmlOperations = new List<DML.DMLOperation>();
    private Map<String, DML.DMLOperation> dmlOperationsMap = new Map<String, DML.DMLOperation>();
    private Map<SObjectType, List<Relation>> relationsByParentType = new Map<SObjectType, List<Relation>>();
    private List<DML.Order> order;


    /**
     * Constructs Unit of Work with no predefined DML order.
     * DMLs will be issued in the same order they are registered.
     */
    public DatabaseUnitOfWork() {}

    /**
     * Constructs Unit of Work with operation ordered by given SObjects.
     */
    public DatabaseUnitOfWork(List<SObjectType> sObjectTypes) {
        this.order = new List<DML.Order>();
        for (SObjectType sObjectType : sObjectTypes) {
            order.add(new DML.Order(sObjectType, DML.Type.INSERT_DML));
            order.add(new DML.Order(sObjectType, DML.Type.UPSERT_DML));
            order.add(new DML.Order(sObjectType, DML.Type.UPDATE_DML));
            order.add(new DML.Order(sObjectType, DML.Type.MERGE_DML));
            order.add(new DML.Order(sObjectType, DML.Type.CONVERT_LEAD_DML));
            order.add(new DML.Order(sObjectType, DML.Type.DELETE_DML));
            order.add(new DML.Order(sObjectType, DML.Type.UNDELETE_DML));
        }
    }

    /**
     * Constructs Unit of Work with operation ordered by given DML Order items.
     * This allows for granular order setup by SObjectType, Operation and upsert field.
     */
    public DatabaseUnitOfWork(List<DML.Order> order) {
        this.order = order;
    }


    /**
     * Registers relation between records. When parent is inserted, lookup on child will be populated.
     */
    public DatabaseUnitOfWork relate(SObject record, SObjectField lookupField, SObject parent) {
        if (String.isNotBlank(parent.Id)) {
            record.put(lookupField, parent.Id);

        } else {
            SObjectType parentSobjType = parent.getSObjectType();
            List<Relation> relations = relationsByParentType.get(parentSobjType) ?? new List<Relation>();
            relations.add(new Relation(record, parent, lookupField));
            relationsByParentType.put(parentSobjType, relations);
        }
        return this;
    }


    /**
     * Registers `insert` DML and relation to parent record, that will be resolved when parent is inserted.
     */
    public void insertRecord(SObject record, SObjectField lookupField, SObject parent) {
        relate(record, lookupField, parent);
        super.insertRecord(record);
    }

    /**
     * Registers `update` DML and relation to parent record, that will be resolved when parent is inserted.
     */
    public void updateRecord(SObject record, SObjectField lookupField, SObject parent) {
        relate(record, lookupField, parent);
        super.updateRecord(record);
    }

    /**
     * Registers `upsert` DML and relation to parent record, that will be resolved when parent is inserted.
     */
    public void upsertRecord(SObject record, SObjectField extId, SObjectField lookupField, SObject parent) {
        relate(record, lookupField, parent);
        super.upsertRecord(record, extId);
    }


    /**
     * Commits Database operations in order they were called or predefined using withOrder methods.
     */
    public List<DML.DMLOperation> commitWork() {
        Savepoint sp;

        try {
            if (options.isAllOrNone()) {
                sp = Database.setSavepoint();
            }

            if (order != null) {
                dmlOperations.sort(new SObjectOrderComparator(order));
            }

            for (DML.DMLOperation dmlOp : dmlOperations) {
                if (!dmlOp.dmlRows.isEmpty()) {
                    super.execute(dmlOp);

                    if (dmlOp instanceof DML.InsertDML || dmlOp instanceof DML.UpsertDML) {
                        resolveInsertedLookups(dmlOp.sObjectType);
                    }
                }
            }
        } catch (Exception e) {
            if (sp != null) {
                Database.rollback(sp);
            }
            throw e;

        } finally {
            if (sp != null) {
                Database.releaseSavepoint(sp);
            }
        }
        return discardWork();
    }

    /**
     * Discards all queued work.
     * @return Discarded DML Operations
     */
    public List<DML.DMLOperation> discardWork() {
        List<DML.DMLOperation> discardedOperations = dmlOperations;
        this.dmlOperations = new List<DML.DMLOperation>();
        this.dmlOperationsMap = new Map<String, DML.DMLOperation>();
        this.relationsByParentType = new Map<SObjectType, List<Relation>>();
        return discardedOperations;
    }

    /**
     * Instead of commiting DML, we are registering it to commit later with commitWork() call.
     */
    protected override Object execute(DML.Operation operation) {
        if (operation instanceof DML.DMLOperation) {
            DML.DMLOperation dmlOperation = (DML.DMLOperation) operation;

            if (dmlOperation.sObjectType == null) {
                registerMixedList(dmlOperation);

            } else {
                registerDmlOperation(dmlOperation);
            }

            return dmlOperation.results;
        } else {
            return super.execute(operation);
        }
    }

    /**
     * Registers DML operations for mixed list of sobjects ([Account,Contact,Opp] etc)
     */
    private void registerMixedList(DML.DMLOperation mixedOperation) {
        DML.DMLOperation previousOp;

        for (Integer i = 0; i < mixedOperation.dmlRows.size(); i++) {
            SObject record = (SObject) mixedOperation.dmlRows.get(i);

            // When List had different types of SObjects and we need to get register operation for new type
            if (previousOp?.sObjectType != record.getSObjectType()) {
                DML.DMLOperation clone = mixedOperation.clone(record.getSObjectType());
                previousOp = registerDmlOperation(clone);
            }

            previousOp.dmlRows.add(record);
        }
    }

    /**
     * Checks if we already have the same DML operation, if not - registers a new one, else return existing.
     */
    private DML.DMLOperation registerDmlOperation(DML.DMLOperation newOp) {
        DML.DMLOperation existingOp = dmlOperationsMap.get(newOp.operationId);

        if (existingOp == null) {
            dmlOperations.add(newOp);
            dmlOperationsMap.put(newOp.operationId, newOp);
            return newOp;

        } else {
            existingOp.dmlRows.addAll(newOp.dmlRows);
            return existingOp;
        }
    }

    /**
     * Adds lookup Ids when parent records are inserted.
     */
    private void resolveInsertedLookups(SObjectType sObjectType) {
        List<Relation> relations = relationsByParentType.get(sObjectType);

        for (Integer i = 0, size = relations?.size(); i < size; i++) {
            relations.get(i).resolve();
        }
    }


    /**
     * Relation between 2 records. Resolved when parent is inserted/upserted.
     */
    private class Relation {
        private SObject record;
        private SObject parent;
        private SObjectField field;

        private Relation(SObject record, SObject parent, SObjectField field) {
            this.record = record;
            this.parent = parent;
            this.field = field;
        }

        public void resolve() {
            if (parent.Id != null) {
                record.put(field, parent.Id);
            }
        }
    }

    /**
     * Sorts DML operations by SObject order.
     */
    private class SObjectOrderComparator implements System.Comparator<DML.DMLOperation> {
        private Map<String, Integer> orderMap = new Map<String, Integer>();

        public SObjectOrderComparator(List<DML.Order> order) {
            for (Integer i = 0; i < order.size(); i++) {
                DML.Order o = order.get(i);
                orderMap.put(o.operationId, i);
            }
        }

        public Integer compare(DML.DMLOperation a, DML.DMLOperation b) {
            return getOrder(a) - getOrder(b);
        }

        private Integer getOrder(DML.DMLOperation op) {
            return orderMap.get(op.operationId) ?? orderMap.get('' + op.sObjectType) ?? 9999;
        }
    }
}