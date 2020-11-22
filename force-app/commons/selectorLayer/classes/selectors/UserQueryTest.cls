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
        System.assertEquals(
                [SELECT Id FROM User WHERE Name = :UserInfo.getName() LIMIT 1].Id,
                new UserQuery().byName(UserInfo.getName()).getFirstOrEmpty().Id
        );

        Set<String> names = new Set<String>{UserInfo.getName()};
        System.assertEquals(
        [SELECT COUNT() FROM User WHERE Name IN :names],
                new UserQuery().byName(names).getList().size()
        );
    }

    @IsTest
    static void testSelectByEmail() {
        System.assertEquals(
                [SELECT Id FROM User WHERE Email = :UserInfo.getUserEmail() LIMIT 1].Id,
                new UserQuery().byEmail(UserInfo.getUserEmail()).getFirstOrEmpty().Id
        );

        Set<String> emails = new Set<String>{UserInfo.getUserEmail()};
        System.assertEquals(
        [SELECT COUNT() FROM User WHERE Email IN :emails],
                new UserQuery().byEmail(emails).getList().size()
        );
    }

    @IsTest
    static void testSelectByUsername() {
        System.assertEquals(
                [SELECT Id FROM User WHERE Username = :UserInfo.getUserName()].Id,
                new UserQuery().byUsername(UserInfo.getUserName()).getFirstOrEmpty().Id
        );

        Set<String> usernames = new Set<String>{UserInfo.getUserName()};
        System.assertEquals(
        [SELECT COUNT() FROM User WHERE Username IN :usernames],
                new UserQuery().byUsername(usernames).getList().size()
        );
    }
}