/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2023 Piotr Kożuchowski
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
 *  Please find newest source code at https://github.com/amorek/Apex-Opensource-Library
 * /
 */

/**
 * This class is responsible for creating records with default fields populated for unit tests.
 * When new required field is added to the sObject, this is the only class which will have to be changed to fix unit tests.
 */
@IsTest
public inherited sharing class TestDataBuilder {
    @TestVisible private DatabaseService databaseService = new DatabaseService();
    private List<SObject> records = new List<SObject>();
    private SObject previousPrototype;


    /**
     * Creates test record with default field values, overridden by given prototype field values.
     *
     * @param prototype Example of record to create - fields specified in the constructor will override defaults
     * @throws TestDataBuilder.TestDataBuilderException when default is not defined
     *
     * @return instance of DataBuilder for subsequent calls.
     */
    public TestDataBuilder create(SObject prototype) {
        return create('', prototype);
    }

    /**
     * Creates test record with unit test default field values, overridden by given prototype field values.
     *
     * @param flavour Name of the default fields configuration - defines which default field values will be used for SObject
     * @param prototype Example of record to create - fields specified in the constructor will override defaults
     * @throws TestDataBuilder.TestDataBuilderException when flavour is not defined
     *
     * @return instance of DataBuilder for subsequent calls.
     */
    public TestDataBuilder create(String flavour, SObject prototype) {
        return create(1, flavour, prototype);
    }

    /**
     * Creates N test records with default field values, overridden by given prototype field values.
     *
     * @param count How many copies should be created.
     * @param prototype Example of record to create - fields specified in the constructor will override defaults
     * @throws TestDataBuilder.TestDataBuilderException when flavour is not defined
     *
     * @return instance of DataBuilder for subsequent calls.
     */
    public TestDataBuilder create(Integer count, SObject prototype) {
        return create(count, '', prototype);
    }

    /**
     * Creates N test record with default field values, overridden by given prototype field values.
     *
     * @param count How many copies should be created.
     * @param flavour Name of the default fields configuration - defines which default field values will be used for SObject
     * @param prototype Example of record to create - fields specified in the constructor will override defaults
     * @throws TestDataBuilder.TestDataBuilderException when flavour is not defined
     *
     * @return instance of DataBuilder for subsequent calls.
     */
    public TestDataBuilder create(Integer count, String flavour, SObject prototype) {
        for (Integer i = 0; i < count; i++) {
            SObject newRecord = TestDataDefaults.getBaseRecord(flavour, prototype);
            applyExtraFields(newRecord, prototype.getPopulatedFieldsAsMap());

            records.add(newRecord);
        }
        this.previousPrototype = prototype;

        return this;
    }


    /**
     * Creates a copy of record from previous create() or similarly() call and adjust it's values by given prototype field values.
     * This method cannot be called prior to create() or for different SObject type than prior create/similarly call.
     * Records are created with the same flavour as previous prototype.
     * <p/>
     * Usage:
     *  List<Account> accounts = TestDataBuilder.builder()
     *       .create(new Account(Name = 'Test'))
     *       .similarly(10, new Account(BillingCountry = 'Test'))
     *       .insertRecords()
     *       .getRecords();
     *  This example creates 11 accounts in total, all of them with "Test" Name and 10 with additional Billing country
     *
     * @param prototype Example of record to create - fields specified in the constructor will override defaults
     *
     * @return instance of DataBuilder for subsequent calls.
     */
    public TestDataBuilder similarly(SObject prototype) {
        return similarly(1, prototype);
    }

    /**
     * Creates a copy of record from previous create() or similarly() call and adjust it's values by given prototype field values.
     * This method cannot be called prior to create() or for different SObject type than prior create/similarly call.
     * Records are created with the same flavour as previous prototype.
     *
     * @param count How many copies should be created.
     * @param prototype Example of record to create - fields specified in the constructor will override defaults
     *
     * @return instance of TestDataBuilder for subsequent calls.
     */
    public TestDataBuilder similarly(Integer count, SObject prototype) {
        if (previousPrototype == null || prototype.getSObjectType() != previousPrototype.getSObjectType()) {
            throw new TestDataBuilderException('similarly() can be only called after create() method of the same sObject type.');
        }

        applyExtraFields(previousPrototype, prototype.getPopulatedFieldsAsMap());
        create(count, previousPrototype);
        return this;
    }


    /**
     * Inserts and returns record with default field values, overridden by given prototype field values.
     *
     * @param prototype Example of record to create - fields specified in the constructor will override defaults
     * @return instance of TestDataBuilder for subsequent calls.
     */
    public SObject insertRecord(SObject prototype) {
        return insertRecords(1, prototype)[0];
    }

    /**
     * Inserts and returns record with default field values, overridden by given prototype field values.
     *
     * @param count How many records should be created.
     * @param prototype Example of record to create - fields specified in the constructor will override defaults
     * @return instance of TestDataBuilder for subsequent calls.
     */
    public SObject[] insertRecords(Integer count, SObject prototype) {
        return insertRecords(count, '', prototype);
    }

    /**
     * Inserts and returns record with default field values, overridden by given prototype field values.
     *
     * @param count How many records should be created.
     * @param flavour Name of the default fields configuration - defines which default field values will be used for SObject
     * @param prototype Example of record to create - fields specified in the constructor will override defaults
     * @return instance of TestDataBuilder for subsequent calls.
     */
    public SObject[] insertRecords(Integer count, String flavour, SObject prototype) {
        return create(count, flavour, prototype).insertRecords();
    }


    /**
     * Inserts records stored in builder's internal storage, clears buffer and returns records.
     *
     * @return inserted records
     */
    public List<SObject> insertRecords() {
        databaseService.insertRecords(records);
        return this.getRecords();
    }

    /**
     * @return First record from Builder's internal storage and clear's storage.
     */
    public SObject getOne() {
        return getRecords().get(0);
    }

    /**
     * @return Records from Builder's internal storage.
     */
    public List<SObject> getRecords() {
        List<SObject> result = records.deepClone(true);
        this.clear();
        return result;
    }

    /**
     * Clears the builder's internal storage.
     */
    public TestDataBuilder clear() {
        this.records.clear();
        return this;
    }


    /**
     * Applies field overwrites from the input prototype onto base record.
     */
    private void applyExtraFields(SObject basePrototype, Map<String, Object> extraFields) {
        for (String field : extraFields.keySet()) {
            basePrototype.put(field, extraFields.get(field));
        }
    }


    public class TestDataBuilderException extends Exception {
    }
}