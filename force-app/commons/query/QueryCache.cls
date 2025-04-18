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
 * Indexed storage for SObjects which groups records by fields and field values.
 * @see SObjectCacheTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.CognitiveComplexity')
public inherited sharing class QueryCache {
    public static final String CACHE_PARTITION = 'local.queries';
    private static Storage
        STATIC_STORAGE = new StaticStorage(),
        SESSION_STORAGE,
        ORG_STORAGE;

    private static final Map<SObjectType, QueryCache> cacheRegistry = new Map<SObjectType, QueryCache>();
    private static final Map<SObjectType, Map<String, SObject>> staticMap = new Map<SObjectType, Map<String, SObject>>();
    private static final Integer DEFAULT_TTL = Integer.valueOf(QueryCache__mdt.TimeToLive__c.getDescribe().getDefaultValueFormula());

    private Storage cacheStorage;
    private String query;
    private Set<String> cachedFields;
    private SObjectType sObjectType;
    private Integer ttl;


    /**
     * @return Cache registered for given sObjectType
     */
    public static QueryCache get(SObjectType sObjectType) {
        if (cacheRegistry.containsKey(sObjectType)) {
            return cacheRegistry.get(sObjectType);

        } else {
            String sobjectName = '' + sObjectType;
            QueryCache__mdt[] config = [
                SELECT SOQL__c, CacheFields__c, TimeToLive__c, Storage__c
                FROM QueryCache__mdt
                WHERE Active__c = TRUE
                AND SObject__c = :sobjectName
                LIMIT 1
            ];

            QueryCache cache = config.isEmpty() ? null : new QueryCache(sObjectType, config[0]);
            cacheRegistry.put(sObjectType, cache);
            return cache;
        }
    }

    @TestVisible
    private static void mock(SObjectType sObjectType, QueryCache__mdt config) {
        QueryCache cache = new QueryCache(sObjectType, config);
        cacheRegistry.put(sObjectType, cache);
    }

    private QueryCache(SObjectType sObjectType, QueryCache__mdt config) {
        this.query = config.SOQL__c;
        this.cachedFields = new Set<String>(config.CacheFields__c.split(','));
        this.ttl = (config.TimeToLive__c == null) ? DEFAULT_TTL : ((Integer) config.TimeToLive__c);
        this.sObjectType = sObjectType;

        switch on config.Storage__c {
            when 'Transaction' {
                this.cacheStorage = STATIC_STORAGE;
            }
            when 'Session' {
                this.cacheStorage = getSessionCacheStorage();
            }
            when 'Organization' {
                this.cacheStorage = getOrgStorage();
            }
        }
    }

    private static Storage getOrgStorage() {
        if (ORG_STORAGE == null) {
            ORG_STORAGE = getPlatformCacheStorage(true);
        }
        return ORG_STORAGE;
    }

    private static Storage getSessionCacheStorage() {
        if (SESSION_STORAGE == null) {
            SESSION_STORAGE = getPlatformCacheStorage(false);
        }
        return SESSION_STORAGE;
    }

    private static Storage getPlatformCacheStorage(Boolean isOrg) {
        try {
            Cache.Partition partition = isOrg ?
                (Cache.Partition) Cache.Org.getPartition(CACHE_PARTITION) :
                (Cache.Partition) Cache.Session.getPartition(CACHE_PARTITION);

            /*Check if there is any storage space allocated to our cache partition*/
            partition.put('partitionTest', 'test');
            if (partition.get('partitionTest') != 'test') {
                throw new QueryException('Cache not available.');
            }

            return new CacheStorage(partition);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, (isOrg ? 'Organization' : 'Session')
                + ' Platform Cache Partition not available or does not have storage allocated.\n' +
                'Falling back to static cache.\n' +
                'Create "queries" platform cache partition or allocate more storage space.');
            return STATIC_STORAGE;
        }
    }


    public interface Storage {
        Map<String, SObject> getSObjectCache(SObjectType sobjectType);
        void persistCacheMap(SObjectType sobjectType, Map<String, SObject> storageMap);
    }


    /**
     * Stores records in Static Map - available only through transaction
     */
    private class StaticStorage implements Storage {

        public Map<String, SObject> getSObjectCache(SObjectType sobjectType) {
            return staticMap.get(sobjectType);
        }

        public void persistCacheMap(SObjectType sobjectType, Map<String, SObject> storageMap) {
            staticMap.put(sobjectType, storageMap);
        }
    }

    /**
     * Stores records in  Cache
     */
    private class CacheStorage implements Storage {
        private Cache.Partition partition;

        public CacheStorage(Cache.Partition partition) {
            this.partition = partition;
        }

        public Map<String, SObject> getSObjectCache(SObjectType sobjectType) {
            return (Map<String, SObject>) partition.get('' + sobjectType + (Test.isRunningTest() ? 'test' : ''));
        }

        public void persistCacheMap(SObjectType sobjectType, Map<String, SObject> storageMap) {
            partition.put('' + sobjectType + (Test.isRunningTest() ? 'test' : ''), storageMap);
        }
    }


    /**
     * Stores SObjects in internal storage and groups them by value in given SObject field.
     * Blank values are not cached.
     */
    public Map<String, SObject> put(List<SObject> records) {
        Map<String, SObject> sObjectMap = cacheStorage.getSObjectCache(sObjectType);
        if (sObjectMap == null) {
            sObjectMap = new Map<String, SObject>();
        }

        for (String sObjectField : cachedFields) {
            for (Integer i = 0, size = records.size(); i < size; i++) {
                SObject record = records[i];
                Object fieldValue = record.get(sObjectField);

                if (fieldValue != null || fieldValue != '') {
                    String cacheKey = '' + sObjectField + '.' + fieldValue;
                    sObjectMap.put(cacheKey, record);
                }
            }
        }

        cacheStorage.persistCacheMap(sObjectType, sObjectMap);
        return sObjectMap;
    }

    /**
      * @return Pair:
      * Map<Id, SObject> Cached objects
      * List<Object> remaining values which weren't found in cache and has to be queried
      */
    public Result getCachedRecords(String field, Object value) {
        Map<String, SObject> cachedRecords = getCachedRecords(sObjectType);
        Map<Id, SObject> resultMap = new Map<Id, SObject>();
        List<Object> listOfQueryValues = getList(value);
        List<Object> remainingValues = Runtime.newListOfTheSameType(listOfQueryValues);

        for (Integer i = 0; i < listOfQueryValues.size(); i++) {
            Object val = listOfQueryValues[i];
            String cacheKey = '' + field + '.' + val;

            if (val != null && val != '' && cachedRecords.containsKey(cacheKey)) {
                SObject record = cachedRecords.get(cacheKey);
                resultMap.put(record.Id, record);

            } else {
                remainingValues.add(val);
            }
        }

        return new Result(resultMap, remainingValues);
    }

    /**
     * @return True, if field is used as cache key
     */
    public Boolean isFieldCacheKey(String sobjectField) {
        return cachedFields.contains(sobjectField);
    }

    private Map<String, SObject> getCachedRecords(SObjectType sObjectType) {
        Map<String, SObject> cachedRecords = cacheStorage.getSObjectCache(sObjectType);

        if (cachedRecords == null) {
            cachedRecords = new Map<String, SObject>();

            if (String.isNotBlank(query)) {
                List<SObject> records = Database.query(query);
                return put(records);
            }
        }

        return cachedRecords;
    }


    /**
    * Transforms value into uniform iterable:
    * - primitive V is transformed into new List<T>{V}
    * - List or Sets are casted into Iterable<Object>
    * - SObject[] is changed into Iterable<Id>
    */
    private List<Object> getList(Object value) {

        if (value instanceof SObject[]) {
            return new List<Id>(
                new Map<Id, SObject>((SObject[]) value).keySet()
            );

        } else if (value instanceof List<Object>) {
            return (List<Object>) value;

        } else {
            if (value instanceof Id) return new List<Id>{(Id) value};
            if (value instanceof String) return new List<String>{(String) value};
            if (value instanceof Date) return new List<Date>{(Date) value};
            if (value instanceof Datetime) return new List<Datetime>{(Datetime) value};
            if (value instanceof Time) return new List<Time>{(Time) value};
            if (value instanceof Decimal) return new List<Decimal>{(Decimal) value};
            if (value instanceof Boolean) return new List<Boolean>{(Boolean) value};
            if (value instanceof Set<Id>) return new List<Id>((Set<Id>) value);
            if (value instanceof Set<String>) return new List<String>((Set<String>) value);
            if (value instanceof Set<Date>) return new List<Date>((Set<Date>) value);
            if (value instanceof Set<Datetime>) return new List<Datetime>((Set<Datetime>) value);
            if (value instanceof Set<Time>) return new List<Time>((Set<Time>) value);
            if (value instanceof Set<Decimal>) return new List<Decimal>((Set<Decimal>) value);
            if (value instanceof Set<Boolean>) return new List<Boolean>((Set<Boolean>) value);

            throw new QueryException('Unrecognized value type: ' + value);
        }
    }

    /**
     * Result of Cache retrieve operation - a pair of cached records and remaining values that were not found in cache.
     */
    public class Result {
        public Map<Id, SObject> cachedRecords;
        public List<Object> remainingValues;

        private Result(Map<Id, SObject> cachedRecords, List<Object> remainingValues) {
            this.cachedRecords = cachedRecords;
            this.remainingValues = remainingValues;
        }
    }
}