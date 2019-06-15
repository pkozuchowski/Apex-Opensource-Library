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

@IsTest
public inherited sharing class TestDataFactory {
    private final static String VANILIA = 'vanilia';
    private static Map<SObjectType, Map<String, SObject>> prototypes = new Map<SObjectType, Map<String, SObject>>{
            User.SObjectType => new Map<String, SObject>{
                    VANILIA => new User(
                            FirstName = 'Test',
                            LastName = 'User',
                            Email = '',
                            Username = '',
                            ProfileId = new ProfileSelector().selectByName('Standard User').Id,
                            Alias = ('tst.' + ''),
                            CommunityNickname = ('tst.' + ''),
                            TimeZoneSidKey = 'GMT',
                            LocaleSidKey = 'nl_NL',
                            EmailEncodingKey = 'UTF-8',
                            LanguageLocaleKey = 'en_US'
                    )
            }
    };



    public static SObject create(SObject prototype) {
        return create(VANILIA, prototype);
    }

    public static SObject create(String flavour, SObject prototype) {
        return create(1, flavour, prototype)[0];
    }

    public static SObject[] create(Integer count, SObject prototype) {
        return create(count, VANILIA, prototype);
    }

    public static SObject[] create(Integer count, String flavour, SObject prototype) {
        SObject basePrototype = getPrototype(flavour, prototype);
        applyExtraFields(basePrototype, prototype.getPopulatedFieldsAsMap());

        List<SObject> result = new List<SObject>();
        for (Integer i = 0; i < count; i++) {
            result.add(basePrototype.clone());
        }

        return result;
    }


    private static SObject getPrototype(String flavour, SObject prototype) {
        SObject base;
        if (prototypes.containsKey(prototype.getSObjectType())) {
            Map<String, SObject> flavours = prototypes.get(prototype.getSObjectType());

            if (flavours.containsKey(flavour)) {
                return flavours.get(flavour);
            } else {
                return flavours.get(VANILIA);
            }

        } else {
            base = prototype.clone();
        }
        return base;
    }

    private static void applyExtraFields(SObject basePrototype, Map<String, Object> extraFields) {
        for (String field : extraFields.keySet()) {
            basePrototype.put(field, extraFields.get(field));
        }
    }
}