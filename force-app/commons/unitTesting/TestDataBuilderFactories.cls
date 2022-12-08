/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2022 Piotr Kożuchowski
 *  https://github.com/pkozuchowski/Apex-Opensource-Library
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
 * Container class for Factories
 */
@IsTest
public with sharing class TestDataBuilderFactories {
    public final static String defaults = '';

    /**
     * Map of SObject field defaults by type.
     * For each sObjectType, it's possible to configure separate set of defaults - for example, different for each Record Type
     * or by other classification.
     */
    private final static Map<SObjectType, Map<String, SObjectFactory>> sObjectFactoriesMap = new Map<SObjectType, Map<String, SObjectFactory>>{
        User.SObjectType => new Map<String, SObjectFactory>{
            defaults => new DefaultUserFactory()
        },

        Account.SObjectType => new Map<String, SObjectFactory>{
            defaults => new SimpleDefaultsFactory(new Account(
                Name = 'Test Account'
            ))
        },

        Contact.SObjectType => new Map<String, SObjectFactory>{
            defaults => new SimpleDefaultsFactory(new Contact(
                FirstName = 'Testy',
                LastName = 'Jones'
            ))
        },

        Opportunity.SObjectType => new Map<String, SObjectFactory>{
            defaults => new SimpleDefaultsFactory(new Opportunity(
                Name = 'Test Opportunity'
            ))
        }
    };


    /**
     * @return base (default) record for given SObject and flavour.
     * If there's no factory specified for the SObject, input prototype is returned.
     * @throws TestDataBuilderException when custom flavour was demanded, but not defined in mapping
     */
    public static SObject getBaseRecord(String flav, SObject prototype) {
        SObject base;
        String flavour = String.isEmpty(flav) ? defaults : flav;

        if (sObjectFactoriesMap.containsKey(prototype.getSObjectType())) {
            Map<String, SObjectFactory> flavoursFactories = sObjectFactoriesMap.get(prototype.getSObjectType());

            if (flavoursFactories.containsKey(flavour)) {
                base = flavoursFactories.get(flavour).create();

            } else if (flavour != defaults) {
                throw new TestDataBuilder.TestDataBuilderException(String.format('SObjects custom flavour is not defined: {0}:{1}', new List<Object>{
                    prototype.getSObjectType(), flavour
                }));
            }
        }

        return base == null ? prototype.clone(false) : base;
    }


    /**
     * Registers defaults for given sobject type and flavour in current session
     */
    public static void registerPrototype(SObjectType sobjType, String flavour, SObject prototype) {
        registerFactory(sobjType, flavour, new SimpleDefaultsFactory(prototype));
    }

    /**
     * Registers factory in cache for current request.
     */
    public static void registerFactory(SObjectType sobjType, String flavour, SObjectFactory factory) {
        sObjectFactoriesMap.get(sobjType).put(flavour, factory);
    }


    /**
     * Concrete classes implementing this interface are responsible for creating test record
     */
    public interface SObjectFactory {
        SObject create();
    }


    /**
     * Factory which takes prototype of an record and clones it.
     */
    public class SimpleDefaultsFactory implements SObjectFactory {
        private SObject prototype;

        public SimpleDefaultsFactory(SObject prototype) {
            this.prototype = prototype;
        }

        public SObject create() {
            return prototype.clone(false);
        }
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
}