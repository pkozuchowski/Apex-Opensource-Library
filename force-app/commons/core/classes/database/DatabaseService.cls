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
        this.dmlOptions.optAllOrNone = true;
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


    /**
     * Executes database query
     * @param query Query string (ex. 'SELECT Id FROM Account')
     */
    public List<SObject> query(String query) {
        return query(query, null);
    }

    /**
     * Executes database query with given bound variables
     * @param query Query string (ex. 'SELECT Id FROM Account WHERE Name IN: names')
     * @param boundVars Variables to bind to query ex. {'names' => ['Name 1', 'Name 2']}
     */
    public List<SObject> query(String query, Map<String, Object> boundVars) {
        return dmlIssuer.query(query, boundVars == null ? new Map<String, Object>() : boundVars);
    }


    /**
     * @param query Query string (ex. 'SELECT Id FROM Account')
     * @return QueryLocator for given query
     */
    public Database.QueryLocator getQueryLocator(String query) {
        return getQueryLocator(query, null);
    }

    /**
     * @param query Query string (ex. 'SELECT Id FROM Account')
     * @param boundVars Variables to bind to query ex. {'names' => ['Name 1', 'Name 2']}
     * @return QueryLocator for given query and bound variables
     */
    public Database.QueryLocator getQueryLocator(String query, Map<String, Object> boundVars) {
        return dmlIssuer.getQueryLocator(query, boundVars == null ? new Map<String, Object>() : boundVars);
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
        List<SObject> query(String query, Map<String, Object> boundVars);
        Database.QueryLocator getQueryLocator(String query, Map<String, Object> boundVars);
    }


    private abstract inherited sharing class AbstractDMLIssuer implements DMLIssuer {
        public virtual List<SObject> query(String query, Map<String, Object> boundVars) {
            Object var0, var1, var2, var3, var4, var5, var6, var7, var8, var9;
            String finalQuery = query;

            Integer i = 0;
            for (String var : boundVars.keySet()) {
                finalQuery = finalQuery.replace(':' + var, ':var' + i);

                if (i == 0) var0 = boundVars.get(var);
                if (i == 1) var1 = boundVars.get(var);
                if (i == 2) var2 = boundVars.get(var);
                if (i == 3) var3 = boundVars.get(var);
                if (i == 4) var4 = boundVars.get(var);
                if (i == 5) var5 = boundVars.get(var);
                if (i == 6) var6 = boundVars.get(var);
                if (i == 7) var7 = boundVars.get(var);
                if (i == 8) var8 = boundVars.get(var);
                if (i == 9) var9 = boundVars.get(var);
                i++;
            }

            return Database.query(finalQuery);
        }

        public virtual Database.QueryLocator getQueryLocator(String query, Map<String, Object> boundVars) {
            Object var0, var1, var2, var3, var4, var5, var6, var7, var8, var9;
            String finalQuery = query;

            Integer i = 0;
            for (String var : boundVars.keySet()) {
                finalQuery = finalQuery.replace(':' + var, ':var' + i);

                if (i == 0) var0 = boundVars.get(var);
                if (i == 1) var1 = boundVars.get(var);
                if (i == 2) var2 = boundVars.get(var);
                if (i == 3) var3 = boundVars.get(var);
                if (i == 4) var4 = boundVars.get(var);
                if (i == 5) var5 = boundVars.get(var);
                if (i == 6) var6 = boundVars.get(var);
                if (i == 7) var7 = boundVars.get(var);
                if (i == 8) var8 = boundVars.get(var);
                if (i == 9) var9 = boundVars.get(var);
                i++;
            }

            return Database.getQueryLocator(finalQuery);
        }
    }


    /**
    * Issues DMLs with sharing
    * */
    private with sharing class WithSharingDMLIssuer extends AbstractDMLIssuer {

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

        public override List<SObject> query(String query, Map<String, Object> boundVars) {
            return super.query(query, boundVars);
        }

        public override Database.QueryLocator getQueryLocator(String query, Map<String, Object> boundVars) {
            return super.getQueryLocator(query, boundVars);
        }
    }


    /**
    * Issues DMLs without sharing
    * */
    private without sharing class WithoutSharingDMLIssuer extends AbstractDMLIssuer {

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

        public override List<SObject> query(String query, Map<String, Object> boundVars) {
            return super.query(query, boundVars);
        }

        public override Database.QueryLocator getQueryLocator(String query, Map<String, Object> boundVars) {
            return super.getQueryLocator(query, boundVars);
        }
    }


    /**
    * Issues DMLs with inherited sharing
    * */
    private inherited sharing class InheritedSharingDMLIssuer extends AbstractDMLIssuer {

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

        public override List<SObject> query(String query, Map<String, Object> boundVars) {
            return super.query(query, boundVars);
        }

        public override Database.QueryLocator getQueryLocator(String query, Map<String, Object> boundVars) {
            return super.getQueryLocator(query, boundVars);
        }
    }
}