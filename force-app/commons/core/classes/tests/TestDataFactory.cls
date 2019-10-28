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
public inherited sharing class TestDataFactory {
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


    /**
     * Creates test record with vanilla default field values, overridden by given prototype field values.
     *
     * Usage:
     * TestDataFactory.create(new User(
     *     Username = 'unique@company.test.com',
     *     ProfileId = businessAdmin.Id
     * ));
     *
     *  @param prototype Example of record to create - fields specified in the constructor will override defaults
     *  @throws TestDataFactory.FlavourException when default is not defined
     *  @return Copy of the test-default record with fields overridden
     */
    public static SObject create(SObject prototype) {
        return create(Flavour.VANILLA, prototype);
    }

    /**
     * Creates test record with unit test default field values, overridden by given prototype field values.
     *
     *  @param flavour Flavour of the default - for example if sObject has many different record types with different required fields,
     *      flavours may be defined for each record type.
     *  @param prototype Example of record to create - fields specified in the constructor will override defaults
     *  @throws TestDataFactory.FlavourException when flavour is not defined
     *  @return Copy of the test-default record with fields overridden
     */
    public static SObject create(Flavour flavour, SObject prototype) {
        return create(1, flavour, prototype)[0];
    }

    /**
     * Creates N test records with vanilla unit test default field values, overridden by given prototype field values.
     *
     *  @param count How many copies should be created.
     *  @param prototype Example of record to create - fields specified in the constructor will override defaults
     *  @throws TestDataFactory.FlavourException when flavour is not defined
     *  @return Copy of the test-default record with fields overridden
     */
    public static SObject[] create(Integer count, SObject prototype) {
        return create(count, Flavour.VANILLA, prototype);
    }

    /**
     * Creates N test record with vanilla unit test default field values, overridden by given prototype field values.
     *
     *  @param count How many copies should be created.
     *  @param flavour Flavour of the default - for example if sObject has many different record types with different required fields,
     *      flavours may be defined for each record type.
     *  @param prototype Example of record to create - fields specified in the constructor will override defaults
     *  @throws TestDataFactory.FlavourException when flavour is not defined
     *  @return List of copies of the test-defaulted record with fields overridden
     */
    public static SObject[] create(Integer count, Flavour flavour, SObject prototype) {
        List<SObject> result = new List<SObject>();

        for (Integer i = 0; i < count; i++) {
            SObject newRecord = getBaseRecord(flavour, prototype);
            applyExtraFields(newRecord, prototype.getPopulatedFieldsAsMap());

            result.add(newRecord);
        }

        return result;
    }

    /**
     * @return base (default) record for given SObject and flavour.
     * If there's no factory specified for the SObject, input prototype is returned.
     * @throws FlavourException when custom flavour was demanded, but not defined in mapping
     */
    private static SObject getBaseRecord(Flavour flav, SObject prototype) {
        SObject base;
        if (sObjectFactoriesMap.containsKey(prototype.getSObjectType())) {
            Map<Flavour, SObjectFactory> flavoursFactories = sObjectFactoriesMap.get(prototype.getSObjectType());

            if (flavoursFactories.containsKey(flav)) {
                return flavoursFactories.get(flav).create();

            } else if (flav != Flavour.VANILLA) {
                throw new FlavourException(String.format('SObjects custom flavour is not defined: {0}:{1}', new List<Object>{
                        prototype.getSObjectType(), flav
                }));
            }

        } else {
            base = prototype.clone();
        }
        return base;
    }


    /**
     * @return Builder for creating similar sets of records in subsequent calls.
     */
    public static DataBuilder builder() {
        return new DataBuilder();
    }

    /**
     * Builder class which can be used to create lists of sObject records.
     */
    public class DataBuilder {
        private List<SObject> records = new List<SObject>();
        private SObject previousPrototype;

        private DataBuilder() {
        }

        /**
         * Creates test record with vanilla default field values, overridden by given prototype field values and stores it
         * in internal builder's list.
         *
         * Usage:
         *   TestDataFactory.builder()
         *           .create(5, new Account(Name = 'Test'))
         *           .create(1, new Account(Name = 'Other'))
         *           .insertRecords()
         *           .getRecords();
         *
         *  @param prototype Example of record to create - fields specified in the constructor will override defaults
         *  @throws TestDataFactory.FlavourException when default is not defined
         *  @return instance of DataBuilder for subsequent calls.
         */
        public DataBuilder create(SObject prototype) {
            records.add(TestDataFactory.create(prototype));
            this.previousPrototype = prototype;
            return this;
        }

        /**
         * Creates test record with flavour's default field values, overridden by given prototype field values and stores it
         * in internal builder's list.
         *
         *  @param flavour Flavour of the default - for example if sObject has many different record types with different required fields,
         *      flavours may be defined for each record type.
         *  @param prototype Example of record to create - fields specified in the constructor will override defaults
         *  @throws TestDataFactory.FlavourException when default is not defined
         *  @return instance of DataBuilder for subsequent calls.
         */
        public DataBuilder create(Flavour flavour, SObject prototype) {
            records.add(TestDataFactory.create(flavour, prototype));
            this.previousPrototype = prototype;
            return this;
        }

        /**
         * Creates N test record with vanilla's default field values, overridden by given prototype field values and stores them
         * in internal builder's list.
         *
         *  @param count How many copies should be created.
         *  @param flavour Flavour of the default - for example if sObject has many different record types with different required fields,
         *      flavours may be defined for each record type.
         *  @param prototype Example of record to create - fields specified in the constructor will override defaults
         *  @throws TestDataFactory.FlavourException when default is not defined
         *  @return instance of DataBuilder for subsequent calls.
         */
        public DataBuilder create(Integer count, SObject prototype) {
            records.addAll(TestDataFactory.create(count, prototype));
            this.previousPrototype = prototype;
            return this;
        }

        /**
         * Creates N test record with flavour's default field values, overridden by given prototype field values and stores them
         * in internal builder's list.
         *
         *  @param count How many copies should be created.
         *  @param flavour Flavour of the default - for example if sObject has many different record types with different required fields,
         *      flavours may be defined for each record type.
         *  @param prototype Example of record to create - fields specified in the constructor will override defaults
         *  @throws TestDataFactory.FlavourException when default is not defined
         *  @return instance of DataBuilder for subsequent calls.
         */
        public DataBuilder create(Integer count, Flavour flavour, SObject prototype) {
            records.addAll(TestDataFactory.create(count, flavour, prototype));
            this.previousPrototype = prototype;
            return this;
        }

        /**
         * Creates a copy of record from previous create() or similarly() call and adjust it's values by given prototype field values.
         * This method cannot be called prior to create() or for different SObject type than prior create/similarly call.
         * Records are created with the same flavour as previous prototype.
         *
         * Usage:
         *  List<Account> accounts = TestDataFactory.builder()
         *       .create(new Account(Name = 'Test'))
         *       .similarly(10, new Account(BillingCountry = 'Test'))
         *       .insertRecords()
         *       .getRecords();
         *  This example creates 11 accounts in total, all of them with "Test" Name and 10 with additional Billing country
         *
         * @param prototype Example of record to create - fields specified in the constructor will override defaults
         * @return instance of DataBuilder for subsequent calls.
         */
        public DataBuilder similarly(SObject prototype) {
            return similarly(1, prototype);
        }

        /**
         * Creates a copy of record from previous create() or similarly() call and adjust it's values by given prototype field values.
         * This method cannot be called prior to create() or for different SObject type than prior create/similarly call.
         * Records are created with the same flavour as previous prototype.
         *
         * @param prototype Example of record to create - fields specified in the constructor will override defaults
         * @return instance of DataBuilder for subsequent calls.
         */
        public DataBuilder similarly(Integer count, SObject prototype) {
            if (prototype == null) {
                throw new BuilderException('Prototype cannot be null');

            } else if (previousPrototype == null || prototype.getSObjectType() != previousPrototype.getSObjectType()) {
                throw new BuilderException('similarly() can be only called after create method of the same sObject type.');
            }

            applyExtraFields(previousPrototype, prototype.getPopulatedFieldsAsMap());
            records.addAll(TestDataFactory.create(count, previousPrototype));
            return this;
        }

        /**
         * Inserts records stored in builder's internal storage.
         * @return instance of DataBuilder for subsequent calls.
         */
        public DataBuilder insertRecords() {
            insert records;
            return this;
        }

        /**
         * @return Records from Builder's internal storage.
         */
        public List<SObject> getRecords() {
            return records.deepClone(true);
        }
    }

    /**
     * Applies field overwrites from the input prototype onto base record.
     */
    private static void applyExtraFields(SObject basePrototype, Map<String, Object> extraFields) {
        for (String field : extraFields.keySet()) {
            basePrototype.put(field, extraFields.get(field));
        }
    }


    private interface SObjectFactory {
        SObject create();
    }

    private class VanillaUserFactory implements SObjectFactory {
        private Integer counter = 0;

        public SObject create() {
            counter++;
            return new User(
                    FirstName = 'Test',
                    LastName = 'User',
                    Email = 'test@example.com',
                    Alias = 'tst.' + counter,
                    CommunityNickname = 'tst.' + counter,
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

    public class FlavourException extends Exception {
    }
    public class BuilderException extends Exception {
    }
}