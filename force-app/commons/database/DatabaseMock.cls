/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2022 Piotr Kożuchowski
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
*/

/**
 * This class can be used to check if mocked DMLs inserted records and to mock DML errors for specific records.
 */
public with sharing class DatabaseMock {
    @TestVisible final static String GENERIC_ERROR = 'Mocked DML Error';
    public Map<String, Object> queryMocks = new Map<String, Object>();

    public List<SObject> insertedRecords = new List<SObject>();
    public List<SObject> updatedRecords = new List<SObject>();
    public List<SObject> upsertedRecords = new List<SObject>();
    public List<SObject> deletedRecords = new List<SObject>();
    public List<SObject> undeletedRecords = new List<SObject>();

    private final List<ErrorMatcher> errorMatchers = new List<ErrorMatcher>();


    /**
     * @param mockId Unique Id of the query
     * @param queryResults What query should return
     */
    public DatabaseMock mockQuery(String mockId, Object queryResults) {
        queryMocks.put(mockId, queryResults);
        return this;
    }

    /**
     * Any DML against records that has the same field as provided in param, will have DML Error
     */
    public DatabaseMock mockDmlError(SObject matcherRecord) {
        return mockDmlError(DmlType.ANY_DML, matcherRecord);
    }

    /**
     * Any DML of given type should fail.
     */
    public DatabaseMock mockDmlError(DmlType dmlType) {
        return mockDmlError(dmlType, null);
    }


    /**
     * Specified DML against records that has the same field as provided in param, will have DML Error
     */
    public DatabaseMock mockDmlError(DmlType dmlType, SObject matcherRecord) {
        return mockDmlError(dmlType, matcherRecord, GENERIC_ERROR);
    }

    /**
     * Specified DML against records that has the same field as provided in param, will have DML Error
     * @param dmlType INSERT/UPDATE/DELETE etc. ANY_DML to match any.
     * @param matcherRecord If not null, this record is used to match which records should have error.
     * @param errorMsg DML Error message if it's required to check specific error message
     *
     * How to use record matching:
     * <pre>
     * DatabaseMock db = service.databaseService.useMock();
     *
     * //This will match account with given External Id
     * db.mockDmlError(new Account(ExternalID__c ='123'));
     *
     * // This will match ALL contacts related to specific AccountId
     * db.mockDmlError(new Contact(AccountId = accountId));
     *
     * // This will match all Contacts and only contacts
     * db.mockDmlError(new Contact());
     * </pre>
     */
    public DatabaseMock mockDmlError(DmlType dmlType, SObject matcherRecord, String errorMsg) {
        this.errorMatchers.add(new ErrorMatcher(dmlType, matcherRecord, errorMsg));
        return this;
    }


    /**
     * @return DML Errors for given record matched by registered criteria
     */
    public List<DatabaseService.DmlError> getDMLErrors(DmlType issuedDML, SObject record) {
        for (ErrorMatcher errorMatcher : errorMatchers) {
            if (errorMatcher.matches(issuedDML, record)) {
                return new List<DatabaseService.DmlError>{
                    new DatabaseService.DmlError(errorMatcher.errorMsg)
                };
            }
        }

        return null;
    }

    /**
     * This decides when DML Error should be added - it's possible to add error on:
     * - Any DML Type
     * - Any Object
     * - Specific record that matches given fields
     */
    private class ErrorMatcher {
        private final DmlType mockedDmlType;
        private final SObjectType mockedSObjectType;
        private final Map<String, Object> matchingFieldValues;
        private final String errorMsg;

        public ErrorMatcher(DmlType mockedDmlType, SObject matchingRecord, String dmlError) {
            this.mockedDmlType = mockedDmlType == null ? DmlType.ANY_DML : mockedDmlType;
            this.mockedSObjectType = matchingRecord?.getSObjectType();
            this.matchingFieldValues = matchingRecord?.getPopulatedFieldsAsMap();
            this.errorMsg = dmlError == null ? GENERIC_ERROR : dmlError;
        }

        private Boolean matches(DmlType issuedDML, SObject record) {
            return (mockedDmlType == issuedDML || mockedDmlType == DmlType.ANY_DML)
                && (mockedSObjectType == null || mockedSObjectType == record.getSObjectType())
                && (matchingFieldValues == null || hasSameFields(record));
        }

        private Boolean hasSameFields(SObject record) {
            for (String field : matchingFieldValues.keySet()) {
                if (record.get(field) != matchingFieldValues.get(field)) {
                    return false;
                }
            }

            return true;
        }
    }
}