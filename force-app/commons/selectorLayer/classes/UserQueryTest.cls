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
        User currentUser = new UserQuery().currentUser();
        System.assertEquals(currentUser.Id, UserInfo.getUserId());
    }

    @IsTest
    static void testSelectByName() {
        System.assertEquals(
                [SELECT Id FROM User WHERE Name = :UserInfo.getName()].Id,
                new UserQuery().byName(UserInfo.getName()).Id
        );

        List<String> names = new List<String>{UserInfo.getName()};
        System.assertEquals(
        [SELECT COUNT() FROM User WHERE Name IN :names],
                new UserQuery().byName(names).size()
        );
    }

    @IsTest
    static void testSelectByEmail() {
        System.assertEquals(
                [SELECT Id FROM User WHERE Email = :UserInfo.getUserEmail()].Id,
                new UserQuery().byEmail(UserInfo.getUserEmail()).Id
        );

        List<String> emails = new List<String>{UserInfo.getUserEmail()};
        System.assertEquals(
        [SELECT COUNT() FROM User WHERE Email IN :emails],
                new UserQuery().byEmail(emails).size()
        );
    }

    @IsTest
    static void testSelectByUsername() {
        System.assertEquals(
                [SELECT Id FROM User WHERE Username = :UserInfo.getUserName()].Id,
                new UserQuery().byUsername(UserInfo.getUserName()).Id
        );

        List<String> usernames = new List<String>{UserInfo.getUserName()};
        System.assertEquals(
        [SELECT COUNT() FROM User WHERE Username IN :usernames],
                new UserQuery().byUsername(usernames).size()
        );
    }
}