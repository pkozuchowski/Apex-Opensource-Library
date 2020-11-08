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
 * This class is responsible for creating records with default fields populated for unit tests.
 * When new required field is added to the sObject, this is the only class which will have to be changed to fix unit tests.
 */
@IsTest
public inherited sharing class TestDataBuilder {
    private final static String defaults = 'default';

    /**
     * Map of SObject field defaults by type.
     * For each sObjectType, it's possible to configure separate set of defaults - for example, different for each Record Type
     * or by other classification.
     */
    private static Map<SObjectType, Map<String, SObjectFactory>> sObjectFactoriesMap = new Map<SObjectType, Map<String, SObjectFactory>>{
            User.SObjectType => new Map<String, SObjectFactory>{
                    defaults => new DefaultUserFactory()
            },
            Account.SObjectType => new Map<String, SObjectFactory>{
                    defaults => new DefaultAccountFactory()
            },
            Contact.SObjectType => new Map<String, SObjectFactory>{
                    defaults => new DefaultContactFactory()
            },
            Opportunity.SObjectType => new Map<String, SObjectFactory>{
                    defaults => new DefaultOpportunityFactory()
            }
    };

    private List<SObject> records = new List<SObject>();
    private SObject previousPrototype;


    /**
     * Creates test record with default field values, overridden by given prototype field values.
     *
     * @param prototype Example of record to create - fields specified in the constructor will override defaults
     * @throws TestDataBuilder.TestDataBuilderException when default is not defined
     *
     * @return Copy of the test-default record with fields overridden
     */
    public TestDataBuilder create(SObject prototype) {
        return create(defaults, prototype);
    }

    /**
     * Creates test record with unit test default field values, overridden by given prototype field values.
     *
     * @param flavour Name of the default fields configuration - defines which default field values will be used for SObject
     * @param prototype Example of record to create - fields specified in the constructor will override defaults
     * @throws TestDataBuilder.TestDataBuilderException when flavour is not defined
     *
     * @return Copy of the test-default record with fields overridden
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
     * @return Copy of the test-default record with fields overridden
     */
    public TestDataBuilder create(Integer count, SObject prototype) {
        return create(count, defaults, prototype);
    }

    /**
     * Creates N test record with default field values, overridden by given prototype field values.
     *
     * @param count How many copies should be created.
     * @param flavour Name of the default fields configuration - defines which default field values will be used for SObject
     * @param prototype Example of record to create - fields specified in the constructor will override defaults
     * @throws TestDataBuilder.TestDataBuilderException when flavour is not defined
     *
     * @return List of copies of the test-defaulted record with fields overridden
     */
    public TestDataBuilder create(Integer count, String flavour, SObject prototype) {
        for (Integer i = 0; i < count; i++) {
            SObject newRecord = getBaseRecord(flavour, prototype);
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
     * Inserts records stored in builder's internal storage, clears buffer and returns records.
     *
     * @return inserted records
     */
    public SObject[] insertRecords() {
        insert records;
        return this.flush();
    }

    /**
     * @return Records from Builder's internal storage.
     */
    public List<SObject> getRecords() {
        return records.deepClone(true);
    }

    /**
     * @return i'th record from Builder's internal storage.
     */
    public SObject get(Integer i) {
        return records.deepClone(true).get(i);
    }

    /**
     * @return Records from Builder's internal storage and clears the buffer.
     */
    public SObject[] flush() {
        List<SObject> result = getRecords();
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
     * @return base (default) record for given SObject and flavour.
     * If there's no factory specified for the SObject, input prototype is returned.
     * @throws TestDataBuilderException when custom flavour was demanded, but not defined in mapping
     */
    private SObject getBaseRecord(String flav, SObject prototype) {
        SObject base;
        if (sObjectFactoriesMap.containsKey(prototype.getSObjectType())) {
            Map<String, SObjectFactory> flavoursFactories = sObjectFactoriesMap.get(prototype.getSObjectType());

            if (flavoursFactories.containsKey(flav)) {
                return flavoursFactories.get(flav).create();

            } else if (flav != defaults) {
                throw new TestDataBuilderException(String.format('SObjects custom flavour is not defined: {0}:{1}', new List<Object>{
                        prototype.getSObjectType(), flav
                }));
            }

        } else {
            base = prototype.clone();
        }
        return base;
    }

    /**
     * Applies field overwrites from the input prototype onto base record.
     */
    private void applyExtraFields(SObject basePrototype, Map<String, Object> extraFields) {
        for (String field : extraFields.keySet()) {
            basePrototype.put(field, extraFields.get(field));
        }
    }


    private interface SObjectFactory {
        SObject create();
    }

    private class DefaultUserFactory implements SObjectFactory {
        private Integer counter = 0;
        private Id orgId = UserInfo.getOrganizationId();

        public SObject create() {
            counter++;
            String uid = '' + counter + Crypto.getRandomInteger();

            return new User(
                    FirstName = 'Test',
                    LastName = 'User',
                    Email = 'test@example.com',
                    Username = uid + '@' + orgId + '.test.com',
                    ProfileId = UserInfo.getProfileId(),
                    Alias = uid.left(8),
                    CommunityNickname = uid.left(40),
                    TimeZoneSidKey = 'GMT',
                    LocaleSidKey = 'en_US',
                    EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US'
            );
        }
    }

    private class DefaultAccountFactory implements SObjectFactory {
        public SObject create() {
            return new Account(
                    Name = 'Test Account'
            );
        }
    }

    private class DefaultContactFactory implements SObjectFactory {
        public SObject create() {
            return new Contact(
                    FirstName = 'Testy',
                    LastName = 'Jones'
            );
        }
    }

    private class DefaultOpportunityFactory implements SObjectFactory {
        public SObject create() {
            return new Opportunity(
                    Name = 'Test Opportunity'
            );
        }
    }

    public class TestDataBuilderException extends Exception {
    }
}