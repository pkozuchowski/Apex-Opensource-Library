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

/**
 * Created by piotr on 06.05.2021.
 */

@IsTest
private class AccountContactLinkerTest {
    private static final TestDataBuilder testDataBuilder = new TestDataBuilder();
    private static final String
            EMAIL_1 = 'TestEmail_1@gmail.com',
            EMAIL_2 = 'TestEmail_2@gmail.com',
            EMAIL_3 = 'TestEmail_3@gmail.com',
            USERNAME = 'AccountContactLinkerTest@client.test.com',
            EXISTING_ACCOUNT_NAME = 'Existing Account';

    private static final User
            STD_USER = (User) Query.Users.byUsername(USERNAME).getFirstOrNull();


    @TestSetup
    static void testSetup() {
        Id stdUserId = Query.Profiles.byName('Standard User').getFirstIdOrNull();
        User usr = (User) testDataBuilder.create(new User(Username = USERNAME, ProfileId = stdUserId)).insertRecords().get(0);

        System.runAs(usr) {
            testDataBuilder
                    .create(new Account(Name = EXISTING_ACCOUNT_NAME, Email__c = EMAIL_3))
                    .create(new Contact(LastName = 'Test 1', Email = EMAIL_1))
                    .create(new Contact(LastName = 'Test 2', Email = EMAIL_2))
                    .insertRecords();
        }
    }


    @IsTest
    static void whenAccountIsInsertedThenAllContactsWithSameEmailShouldLink() {
        System.runAs(STD_USER) {
            Account acc = (Account) testDataBuilder.create(new Account(Email__c = EMAIL_1)).get(0);


            Test.startTest();
            insert acc;
            Test.stopTest();


            Contact contact = (Contact) Query.Contacts.byEmail(acc.Email__c).getFirstOrNull();
            System.assertEquals(acc.Id, contact.AccountId, 'Contact should link to created Account with same email.');
        }
    }


    @IsTest
    static void whenAccountChangesEmailThenAllContactsWithNewEmailShouldLink() {
        System.runAs(STD_USER) {
            Account acc = (Account) Query.Accounts.byName(EXISTING_ACCOUNT_NAME).getFirstOrNull();


            Test.startTest();
            acc.Email__c = EMAIL_2;
            update acc;
            Test.stopTest();


            Contact contact = (Contact) Query.Contacts.byEmail(acc.Email__c).getFirstOrNull();
            System.assertEquals(acc.Id, contact.AccountId, 'Contact should link to created Account with same email.');
        }
    }
}