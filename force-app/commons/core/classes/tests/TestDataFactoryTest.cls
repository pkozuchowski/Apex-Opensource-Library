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
private class TestDataFactoryTest {

    /**
     * TestDataFactory.create(SObject record) should create record with default values of vanilla flavour.
     * Default field values should be overwritten by passed prototype record.
     */
    @IsTest
    static void testCreateVanillaShouldCreateRecordWithDefaultValues() {
        Test.startTest();
        User user = (User) TestDataFactory.create(new User(LastName = 'Johnson'));
        Test.stopTest();


        System.assertEquals('Johnson', user.LastName);
        System.assertEquals('Test', user.FirstName);
        System.assertNotEquals(null, user.Email);
        System.assertEquals('GMT', user.TimeZoneSidKey);
        System.assertEquals('en_US', user.LocaleSidKey);
        System.assertEquals('UTF-8', user.EmailEncodingKey);
        System.assertEquals('en_US', user.LanguageLocaleKey);
    }


    /**
     * TestDataFactory.create(Integer count, SObject record) should create number of records with default values of vanilla flavour.
     * Default field values should be overwritten by passed prototype record.
     */
    @IsTest
    static void testCreateCountOfVanillaShouldCreateRecordWithDefaultValues() {
        Test.startTest();
        User[] users = TestDataFactory.create(10, new User(LastName = 'Johnson'));
        Test.stopTest();


        System.assertEquals(10, users.size());
        for (User user : users) {
            System.assertEquals('Johnson', user.LastName);
            System.assertEquals('Test', user.FirstName);
            System.assertNotEquals(null, user.Email);
            System.assertEquals('GMT', user.TimeZoneSidKey);
            System.assertEquals('en_US', user.LocaleSidKey);
            System.assertEquals('UTF-8', user.EmailEncodingKey);
            System.assertEquals('en_US', user.LanguageLocaleKey);
        }
    }


    /**
     * TestDataFactory.builder() should let developer build list of test records
     */
    @IsTest
    static void testBuilderCreate() {
        Test.startTest();
        User[] users = TestDataFactory.builder()
                .create(new User(LastName = 'Johnson'))
                .create(2, new User(LastName = 'Xian'))
                .getRecords();
        Test.stopTest();

        System.assertEquals(3, users.size());
        System.assertEquals('Johnson', users[0].LastName);
        System.assertEquals('Xian', users[1].LastName);
        System.assertEquals('Xian', users[2].LastName);

        for (User user : users) {
            System.assertEquals('Test', user.FirstName);
            System.assertNotEquals(null, user.Email);
            System.assertEquals('GMT', user.TimeZoneSidKey);
            System.assertEquals('en_US', user.LocaleSidKey);
            System.assertEquals('UTF-8', user.EmailEncodingKey);
            System.assertEquals('en_US', user.LanguageLocaleKey);
        }
    }


    /**
     *@description
     * Builder's similarly method can be called sequentially to create() method
     * to reuse previous prototype with small adjustments.
     */
    @IsTest
    static void testBuilderSimilarly() {
        Test.startTest();
        User[] users = TestDataFactory.builder()
                .create(new User(LastName = 'Johnson', Email = 'similarly@example.com'))
                .similarly(2, new User(LastName = 'Xian'))
                .similarly(new User(LastName = 'Dong'))
                .getRecords();
        Test.stopTest();

        System.assertEquals(4, users.size());
        System.assertEquals('Johnson', users[0].LastName);
        System.assertEquals('Xian', users[1].LastName);
        System.assertEquals('Xian', users[2].LastName);
        System.assertEquals('Dong', users[3].LastName);

        for (User user : users) {
            System.assertEquals('similarly@example.com', user.Email, 'Similar records should inherit overrides from previous prototype and override only LastName');
        }
    }


    /**
     *@description
     * Builder.similarly() method can be only called after create() method, to reuse first prototype.
     */
    @IsTest
    static void testBuilderSimilarlyCannotByCalledFirst() {
        Exception ex;

        try {
            Test.startTest();
            User[] users = TestDataFactory.builder()
                    .similarly(2, new User(LastName = 'Xian'))
                    .getRecords();
            Test.stopTest();

        } catch (Exception e) {
            ex = e;
        }

        System.assertNotEquals(null, ex);
        System.assert(ex instanceof TestDataFactory.TestDataFactoryException);
    }


    /**
     *@description
     * Builder.similarly() does not accept different sObject type then preceding create()
     */
    @IsTest
    static void testBuilderSimilarlyMustBeCalledOnTheSameSObjectTypeAsCreate() {
        Exception ex;

        try {
            Test.startTest();
            User[] users = TestDataFactory.builder()
                    .create(new Account())
                    .similarly(new Contact())
                    .getRecords();
            Test.stopTest();

        } catch (Exception e) {
            ex = e;
        }

        System.assertNotEquals(null, ex);
        System.assert(ex instanceof TestDataFactory.TestDataFactoryException);
    }
}