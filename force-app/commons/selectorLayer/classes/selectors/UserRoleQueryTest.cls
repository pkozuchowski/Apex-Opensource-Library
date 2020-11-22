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
private class UserRoleQueryTest {

    @IsTest
    static void testSelectByDeveloperName() {
        UserRole userRole = [SELECT Id,DeveloperName FROM UserRole LIMIT 1];

        Test.startTest();
        UserRole role = (UserRole) new UserRoleQuery().byDeveloperName(userRole.DeveloperName).getFirstOrEmpty();
        Test.stopTest();

        System.assertEquals(userRole.DeveloperName, role.DeveloperName);
    }


    @IsTest
    static void testSelectByDeveloperNames() {
        Map<Id, UserRole> expected = new Map<Id, UserRole>([SELECT Id,DeveloperName FROM UserRole]);
        Set<String> devNames = new Set<String>();
        for (UserRole userRole : expected.values()) {
            devNames.add(userRole.DeveloperName);
        }

        Test.startTest();
        Map<Id, UserRole> result = (Map<Id, UserRole>) new UserRoleQuery().byDeveloperName((Set<String>) devNames).getMapById();
        Test.stopTest();

        System.assertEquals(expected.keySet(), result.keySet());
    }


    @IsTest
    static void testSelectById() {
        UserRole userRole = [SELECT Id,DeveloperName FROM UserRole LIMIT 1];

        Test.startTest();
        UserRole result = (UserRole) new UserRoleQuery().byId(userRole.Id).getFirstOrNull();
        Test.stopTest();

        System.assertEquals(userRole.DeveloperName, result.DeveloperName);
    }


    @IsTest
    static void testSelectByIds() {
        Map<Id, UserRole> expected = new Map<Id, UserRole>([SELECT Id,DeveloperName FROM UserRole]);
        Map<Id, UserRole> result = (Map<Id, UserRole>) new UserRoleQuery().byId(expected.keySet()).getMapById();

        System.assertEquals(expected.keySet(), result.keySet());
    }


    @IsTest
    static void testSelectOfCurrentUser() {
        UserRole[] roles = [SELECT Id FROM UserRole WHERE Id = :UserInfo.getUserRoleId()];

        if (roles.isEmpty()) {
            System.assertEquals(true, new UserRoleQuery().byCurrentUser().getList().isEmpty());

        } else {
            UserRole role = roles.isEmpty() ? null : roles[0];
            System.assertEquals(role.Id, new UserRoleQuery().byCurrentUser().getFirstOrNull().Id);
        }
    }
}