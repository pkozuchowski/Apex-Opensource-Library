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
@IsTest(IsParallel=true)
private class ContactQueryTest {

    @IsTest
    static void testSelectWithParentAccount() {
        String soql = new ContactQuery()
            .withParentAccount()
            .toSOQL();

        Assert.isTrue(soql.containsIgnoreCase('Account.Name'));
    }

    @IsTest
    static void testSelectByName() {
        String value = 'John Doe';
        ContactQuery query = new ContactQuery().byName(value);
        QueryObjectTest.assertSOQLContainsFieldInClause(query, Contact.Name, new Set<String>{value});
    }

    @IsTest
    static void testSelectByEmail() {
        String value = 'john@test.com';
        ContactQuery query = new ContactQuery().byEmail(value);
        QueryObjectTest.assertSOQLContainsFieldInClause(query, Contact.Email, new Set<String>{value});
    }

    @IsTest
    static void testSelectByAccountId() {
        Id value = '001000000000000';
        ContactQuery query = new ContactQuery().byAccountId(value);
        QueryObjectTest.assertSOQLContainsFieldInClause(query, Contact.AccountId, new Set<Id>{value});
    }

    @IsTest
    static void testSelectByPhone() {
        String value = '123 456 789';
        ContactQuery query = new ContactQuery().byPhone(value);
        QueryObjectTest.assertSOQLContainsFieldInClause(query, Contact.Phone, new Set<String>{value});
    }
}