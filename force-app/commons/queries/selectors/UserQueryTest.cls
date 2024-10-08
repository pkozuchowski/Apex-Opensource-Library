/**
* MIT License
*
* Copyright (c) 2018 Piotr Kożuchowski
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
private class UserQueryTest {


    @IsTest
    static void testSelectCurrentUser() {
        User currentUser = new UserQuery().getCurrentUser();
        System.assertEquals(currentUser.Id, UserInfo.getUserId());
    }

    @IsTest
    static void testSelectByName() {
        String value = UserInfo.getName();
        UserQuery query = new UserQuery().byName(value);
        QueryObjectTest.assertSOQLContainsFieldInClause(query, User.Name, new Set<String>{value});
    }

    @IsTest
    static void testSelectByEmail() {
        String value = UserInfo.getUserEmail();
        UserQuery query = new UserQuery().byEmail(value);
        QueryObjectTest.assertSOQLContainsFieldInClause(query, User.Email, new Set<String>{value});
    }

    @IsTest
    static void testSelectByUsername() {
        String value = UserInfo.getUserName();
        UserQuery query = new UserQuery().byUsername(value);
        QueryObjectTest.assertSOQLContainsFieldInClause(query, User.Username, new Set<String>{value});
    }
}