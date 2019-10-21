/**
* MIT License
*
* Copyright (c) 2018 Piotr Kożuchowski
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
 * Contains methods for creating and manipulating data with isolated sharing from the
 * client class.
 * @see DatabaseServiceTest
 */
public class DatabaseService {
    private Database.DMLOptions dmlOptions = new Database.DMLOptions();
    private DMLIssuer dmlIssuer = new InheritedSharingDMLIssuer();

    public DatabaseService() {
        this.dmlOptions.OptAllOrNone = true;
    }

    /**
     * Sets sharing mode on Database Service:
     * - With Sharing
     * - Without Sharing
     * - Inherited Sharing (default)
     */
    public DatabaseService setSharing(Sharing sharing) {
        switch on sharing {
            when WITH_SHARING {
                this.dmlIssuer = new WithSharingDMLIssuer();
            }
            when WITHOUT_SHARING {
                this.dmlIssuer = new WithoutSharingDMLIssuer();
            }
            when else {
                this.dmlIssuer = new InheritedSharingDMLIssuer();
            }
        }
        return this;
    }

    /**
     * Sets DML Options to use for DMLs issued with this service.
     */
    public DatabaseService setDMLOptions(Database.DMLOptions options) {
        this.dmlOptions = options;
        return this;
    }


    public List<SObject> query(String query) {
        return dmlIssuer.query(String.escapeSingleQuotes(query));
    }


    public Database.SaveResult doInsert(SObject record) {
        return doInsert(new List<SObject>{record})[0];
    }
    public List<Database.SaveResult> doInsert(List<SObject> records) {
        return dmlIssuer.doInsert(records, dmlOptions);
    }


    public Database.SaveResult doUpdate(SObject record) {
        return doUpdate(new List<SObject>{record})[0];
    }
    public List<Database.SaveResult> doUpdate(List<SObject> records) {
        return dmlIssuer.doUpdate(records, dmlOptions);
    }


    public Database.UpsertResult doUpsert(SObject record, SObjectField field) {
        return doUpsert(nonGenericSObjectList(record), field)[0];
    }
    public List<Database.UpsertResult> doUpsert(List<SObject> records, SObjectField field) {
        return dmlIssuer.doUpsert(records, field);
    }


    public Database.DeleteResult doDelete(SObject record) {
        return doDelete(new List<SObject>{record})[0];
    }

    public List<Database.DeleteResult> doDelete(List<SObject> records) {
        return dmlIssuer.doDelete(records, isAllOrNone());
    }


    public Database.UndeleteResult doUndelete(SObject record) {
        return doUndelete(new List<SObject>{record})[0];
    }

    public List<Database.UndeleteResult> doUndelete(List<SObject> records) {
        return dmlIssuer.doUndelete(records, isAllOrNone());
    }


    /**
     * Upsert will not work on generic List<SObject>, it requires concrete type.
     */
    private List<SObject> nonGenericSObjectList(SObject record) {
        List<SObject> records = (List<SObject>) Type.forName('List<' + record.getSObjectType() + '>')
                .newInstance();
        records.add(record);
        return records;
    }

    private Boolean isAllOrNone() {
        return dmlOptions.OptAllOrNone == null ? true : dmlOptions.OptAllOrNone;
    }


    /**
    * Interface for classes that will handle DML operations
    * */
    public interface DMLIssuer {
        List<Database.SaveResult> doInsert(List<SObject> records, Database.DMLOptions options);
        List<Database.SaveResult> doUpdate(List<SObject> records, Database.DMLOptions options);
        List<Database.UpsertResult> doUpsert(List<SObject> records, SObjectField field);
        List<Database.DeleteResult> doDelete(List<SObject> records, Boolean allOrNone);
        List<Database.UndeleteResult> doUndelete(List<SObject> records, Boolean allOrNone);
        List<SObject> query(String query);
    }


    /**
    * Issues DMLs with sharing
    * */
    public with sharing class WithSharingDMLIssuer implements DMLIssuer {

        public List<Database.SaveResult> doInsert(List<SObject> records, Database.DMLOptions options) {
            return Database.insert(records, options);
        }

        public List<Database.SaveResult> doUpdate(List<SObject> records, Database.DMLOptions options) {
            return Database.update(records, options);
        }

        public List<Database.UpsertResult> doUpsert(List<SObject> records, SObjectField field) {
            return Database.upsert(records, field);
        }

        public List<Database.DeleteResult> doDelete(List<SObject> records, Boolean allOrNone) {
            return Database.delete(records, allOrNone);
        }

        public List<Database.UndeleteResult> doUndelete(List<SObject> records, Boolean allOrNone) {
            return Database.undelete(records, allOrNone);
        }

        public List<SObject> query(String query) {
            return Database.query(query);
        }
    }


    /**
    * Issues DMLs without sharing
    * */
    public without sharing class WithoutSharingDMLIssuer implements DMLIssuer {

        public List<Database.SaveResult> doInsert(List<SObject> records, Database.DMLOptions options) {
            return Database.insert(records, options);
        }

        public List<Database.SaveResult> doUpdate(List<SObject> records, Database.DMLOptions options) {
            return Database.update(records, options);
        }

        public List<Database.UpsertResult> doUpsert(List<SObject> records, SObjectField field) {
            return Database.upsert(records, field);
        }

        public List<Database.DeleteResult> doDelete(List<SObject> records, Boolean allOrNone) {
            return Database.delete(records, allOrNone);
        }

        public List<Database.UndeleteResult> doUndelete(List<SObject> records, Boolean allOrNone) {
            return Database.undelete(records, allOrNone);
        }

        public List<SObject> query(String query) {
            return Database.query(query);
        }
    }


    /**
    * Issues DMLs with inherited sharing
    * */
    public inherited sharing class InheritedSharingDMLIssuer implements DMLIssuer {

        public List<Database.SaveResult> doInsert(List<SObject> records, Database.DMLOptions options) {
            return Database.insert(records, options);
        }

        public List<Database.SaveResult> doUpdate(List<SObject> records, Database.DMLOptions options) {
            return Database.update(records, options);
        }

        public List<Database.UpsertResult> doUpsert(List<SObject> records, SObjectField field) {
            return Database.upsert(records, field);
        }

        public List<Database.DeleteResult> doDelete(List<SObject> records, Boolean allOrNone) {
            return Database.delete(records, allOrNone);
        }

        public List<Database.UndeleteResult> doUndelete(List<SObject> records, Boolean allOrNone) {
            return Database.undelete(records, allOrNone);
        }

        public List<SObject> query(String query) {
            return Database.query(query);
        }
    }
}