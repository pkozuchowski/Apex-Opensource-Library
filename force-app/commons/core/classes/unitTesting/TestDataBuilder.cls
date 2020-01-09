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
public inherited sharing class TestDataBuilder {

    /**
     * Flavours of SOBject. By using different flavours, it's possible to differentiate default values for one SObject type.
     * For example if there are record types that require completely different defaults or when you want to prepopulate RecordTypeId
     * at builder stage.
     * This mechanism is not restricted to Record Types though.
     *
     * One flavour can be reused between many different SObjects.
     * Example flavours for some companies could be as follows: VANILLA, ENTERPRISE, SME (Small Medium Enterprise), Domestic
     * VANILLA flavour is the default, when flavour is not specified, builder falls back to vanilla.
     */
    public enum Flavour {
        VANILLA
    }

    private static Map<SObjectType, Map<Flavour, SObjectFactory>> sObjectFactoriesMap = new Map<SObjectType, Map<Flavour, SObjectFactory>>{
            User.SObjectType => new Map<Flavour, SObjectFactory>{
                    Flavour.VANILLA => new VanillaUserFactory()
            },
            Account.SObjectType => new Map<Flavour, SObjectFactory>{
                    Flavour.VANILLA => new VanillaAccountFactory()
            },
            Contact.SObjectType => new Map<Flavour, SObjectFactory>{
                    Flavour.VANILLA => new VanillaContactFactory()
            },
            Opportunity.SObjectType => new Map<Flavour, SObjectFactory>{
                    Flavour.VANILLA => new VanillaOpportunityFactory()
            }
    };

    private List<SObject> records = new List<SObject>();
    private SObject previousPrototype;

    /**
     * Creates test record with vanilla default field values, overridden by given prototype field values.
     *
     *  @param prototype Example of record to create - fields specified in the constructor will override defaults
     *  @throws TestDataBuilder.TestDataBuilderException when default is not defined
     *  @return Copy of the test-default record with fields overridden
     */
    public TestDataBuilder create(SObject prototype) {
        return create(Flavour.VANILLA, prototype);
    }

    /**
     * Creates test record with unit test default field values, overridden by given prototype field values.
     *
     *  @param flavour Flavour of the default - defines which default field values will be used for SObject
     *  @param prototype Example of record to create - fields specified in the constructor will override defaults
     *  @throws TestDataBuilder.TestDataBuilderException when flavour is not defined
     *  @return Copy of the test-default record with fields overridden
     */
    public TestDataBuilder create(Flavour flavour, SObject prototype) {
        return create(1, flavour, prototype);
    }

    /**
     * Creates N test records with vanilla unit test default field values, overridden by given prototype field values.
     *
     *  @param count How many copies should be created.
     *  @param prototype Example of record to create - fields specified in the constructor will override defaults
     *  @throws TestDataBuilder.TestDataBuilderException when flavour is not defined
     *  @return Copy of the test-default record with fields overridden
     */
    public TestDataBuilder create(Integer count, SObject prototype) {
        return create(count, Flavour.VANILLA, prototype);
    }

    /**
     * Creates N test record with vanilla unit test default field values, overridden by given prototype field values.
     *
     *  @param count How many copies should be created.
     *  @param flavour Flavour of the default - defines which default field values will be used for SObject
     *  @param prototype Example of record to create - fields specified in the constructor will override defaults
     *  @throws TestDataBuilder.TestDataBuilderException when flavour is not defined
     *  @return List of copies of the test-defaulted record with fields overridden
     */
    public TestDataBuilder create(Integer count, Flavour flavour, SObject prototype) {
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
     *
     * Usage:
     *  List<Account> accounts = TestDataBuilder.builder()
     *       .create(new Account(Name = 'Test'))
     *       .similarly(10, new Account(BillingCountry = 'Test'))
     *       .insertRecords()
     *       .getRecords();
     *  This example creates 11 accounts in total, all of them with "Test" Name and 10 with additional Billing country
     *
     * @param prototype Example of record to create - fields specified in the constructor will override defaults
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
     * @param prototype Example of record to create - fields specified in the constructor will override defaults
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
     * @return Records from Builder's internal storage.
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
    private SObject getBaseRecord(Flavour flav, SObject prototype) {
        SObject base;
        if (sObjectFactoriesMap.containsKey(prototype.getSObjectType())) {
            Map<Flavour, SObjectFactory> flavoursFactories = sObjectFactoriesMap.get(prototype.getSObjectType());

            if (flavoursFactories.containsKey(flav)) {
                return flavoursFactories.get(flav).create();

            } else if (flav != Flavour.VANILLA) {
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

    private class VanillaUserFactory implements SObjectFactory {
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

    private class VanillaAccountFactory implements SObjectFactory {
        public SObject create() {
            return new Account(
                    Name = 'Test Account'
            );
        }
    }

    private class VanillaContactFactory implements SObjectFactory {
        public SObject create() {
            return new Contact(
                    FirstName = 'Testy',
                    LastName = 'Jones'
            );
        }
    }

    private class VanillaOpportunityFactory implements SObjectFactory {
        public SObject create() {
            return new Opportunity(
                    Name = 'Test Opportunity'
            );
        }
    }

    public class TestDataBuilderException extends Exception {
    }
}