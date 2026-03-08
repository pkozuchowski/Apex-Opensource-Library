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
@SuppressWarnings('PMD')
public inherited sharing class QueryCache {
    public static final String CACHE_PARTITION = 'local.queries';
    private static final Map<SObjectType, QueryCache> REGISTRY = new Map<SObjectType, QueryCache>();
    private static final Map<SObjectType, Map<String, SObject>> STATIC_CACHE = new Map<SObjectType, Map<String, SObject>>();
    private static final Integer DEFAULT_TTL = Integer.valueOf(QueryCache__mdt.TimeToLive__c.getDescribe().getDefaultValueFormula());

    private static Storage staticStorage = new StaticStorage();
    private static Storage sessionStorage;
    private static Storage orgStorage;

    private Storage cacheStorage;
    private String initializationQuery;
    private Set<String> cachedFields;
    private SObjectType sObjectType;
    private Integer ttl;


    /**
     * @return Cache registered for given sObjectType
     */
    public static QueryCache get(SObjectType sObjectType) {
        if (REGISTRY.containsKey(sObjectType)) {
            return REGISTRY.get(sObjectType);

        } else {
            String sobjectName = '' + sObjectType;
            QueryCache__mdt[] config = [
                SELECT SOQL__c, CacheFields__c, TimeToLive__c, Storage__c
                FROM QueryCache__mdt
                WHERE Active__c = TRUE
                AND SObject__c = :sobjectName
                WITH SYSTEM_MODE
                LIMIT 1
            ];

            QueryCache cache = config.isEmpty() ? null : new QueryCache(sObjectType, config[0]);
            REGISTRY.put(sObjectType, cache);
            return cache;
        }
    }

    @TestVisible
    private static void mock(SObjectType sObjectType, QueryCache__mdt config) {
        QueryCache cache = new QueryCache(sObjectType, config);
        REGISTRY.put(sObjectType, cache);
    }

    private QueryCache(SObjectType sObjectType, QueryCache__mdt config) {
        this.initializationQuery = config.SOQL__c;
        this.cachedFields = new Set<String>(config.CacheFields__c.split(','));
        this.ttl = (config.TimeToLive__c == null) ? DEFAULT_TTL : ((Integer) config.TimeToLive__c);
        this.sObjectType = sObjectType;

        switch on config.Storage__c {
            when 'Transaction' {
                this.cacheStorage = staticStorage;
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
        if (orgStorage == null) {
            orgStorage = getPlatformCacheStorage(true);
        }
        return orgStorage;
    }

    private static Storage getSessionCacheStorage() {
        if (sessionStorage == null) {
            sessionStorage = getPlatformCacheStorage(false);
        }
        return sessionStorage;
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
            return staticStorage;
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
            return STATIC_CACHE.get(sobjectType);
        }

        public void persistCacheMap(SObjectType sobjectType, Map<String, SObject> storageMap) {
            STATIC_CACHE.put(sobjectType, storageMap);
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
        Result result = new Result();
        result.initializeLists(value);

        Map<String, SObject> cachedRecords = getCachedRecords(sObjectType);
        Map<Id, SObject> resultMap = new Map<Id, SObject>();

        for (Object val : result.requestedValues) {
            String cacheKey = '' + field + '.' + val;

            if (val != null && val != '' && cachedRecords.containsKey(cacheKey)) {
                SObject record = cachedRecords.get(cacheKey);
                resultMap.put(record.Id, record);

            } else {
                result.remainingValues.add(val);
            }
        }

        result.cachedRecords = resultMap;
        return result;
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

            if (String.isNotBlank(initializationQuery)) {
                List<SObject> records = Database.query(initializationQuery);
                return put(records);
            }
        }

        return cachedRecords;
    }


    /**
     * Result of Cache retrieve operation - a pair of cached records
     * and remaining values that were not found in cache.
     */
    public class Result {
        public Map<Id, SObject> cachedRecords;
        public Iterable<Object> requestedValues;
        public List<Object> remainingValues;

        /**
        * Initializes requested and remaining value lists based on the type of the provided value.
        */
        private void initializeLists(Object value) {
            if (value instanceof Id) {
                requestedValues = new List<Id>{(Id) value};
                remainingValues = new List<Id>();

            } else if (value instanceof String) {
                requestedValues = new List<String>{(String) value};
                remainingValues = new List<String>();

            } else if (value instanceof Iterable<Id>) {
                requestedValues = (Iterable<Object>) value;
                remainingValues = new List<Id>();

            } else if (value instanceof Iterable<String>) {
                requestedValues = (Iterable<Object>) value;
                remainingValues = new List<String>();
            }
        }
    }
}