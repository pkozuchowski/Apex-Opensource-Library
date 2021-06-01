/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2021 Piotr Kożuchowski
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

@IsTest
private class AccountContactLinkerTest {
    private static final TestDataBuilder testDataBuilder = new TestDataBuilder();
    private static final String
        PHONE_1 = '121',
        PHONE_2 = '122',
        PHONE_3 = '123',
        USERNAME = 'AccountAssistantContactLinkerTest@client.test.com',
        EXISTING_ACCOUNT_NAME = 'Existing Account';

    private static final User
        STD_USER = (User) Query.Users.byUsername(USERNAME).getFirstOrNull();


    @TestSetup
    static void testSetup() {
        Id stdUserId = Query.Profiles.byName('Standard User').getFirstIdOrNull();
        User usr = (User) testDataBuilder.create(new User(Username = USERNAME, ProfileId = stdUserId)).insertRecords().get(0);

        System.runAs(usr) {
            testDataBuilder
                .create(new Account(Name = EXISTING_ACCOUNT_NAME, Phone = PHONE_3))
                .create(new Contact(LastName = 'Test 1', Phone = PHONE_1))
                .create(new Contact(LastName = 'Test 2', Phone = PHONE_2))
                .insertRecords();
        }
    }


    @IsTest
    static void whenAccountIsInsertedThenAllContactsWithSamePhoneShouldLink() {
        System.runAs(STD_USER) {
            Account acc = (Account) testDataBuilder.create(new Account(Phone = PHONE_1)).get(0);


            Test.startTest();
            insert acc;
            Test.stopTest();


            Contact contact = (Contact) Query.Contacts.byPhone(acc.Phone).getFirstOrNull();
            System.assertEquals(acc.Id, contact.AccountId, 'Contact should link to created Account with same phone.');
        }
    }


    @IsTest
    static void whenAccountChangesPhoneThenAllContactsWithNewPhoneShouldLink() {
        System.runAs(STD_USER) {
            Account acc = (Account) Query.Accounts.byName(EXISTING_ACCOUNT_NAME).getFirstOrNull();


            Test.startTest();
            acc.Phone = PHONE_2;
            update acc;
            Test.stopTest();


            Contact contact = (Contact) Query.Contacts.byPhone(acc.Phone).getFirstOrNull();
            System.assertEquals(acc.Id, contact.AccountId, 'Contact should link to created Account with same phone.');
        }
    }
}