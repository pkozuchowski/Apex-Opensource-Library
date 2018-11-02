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
@IsTest
private class UserRoleSelectorTest {

    @IsTest
    static void testSelectUserRoleId() {
        List<UserRole> userRoles = [SELECT Id,DeveloperName FROM UserRole];

        for (UserRole userRole : userRoles) {
            System.assertEquals(userRole.Id, new UserRoleSelector().selectIdByDeveloperName(userRole.DeveloperName));
        }

        System.assertEquals(2, Limits.getQueries());
    }

    @IsTest
    static void testSelectUserRoleByDeveloperName() {
        List<UserRole> userRoles = [SELECT Id,DeveloperName FROM UserRole];

        for (UserRole userRole : userRoles) {
            System.assertEquals(userRole.DeveloperName, new UserRoleSelector().selectByDeveloperName(userRole.DeveloperName).DeveloperName);
        }

        System.assertEquals(2, Limits.getQueries());
    }

    @IsTest
    static void testSelectUserRoleById() {
        List<UserRole> userRoles = [SELECT Id,DeveloperName FROM UserRole];

        for (UserRole userRole : userRoles) {
            System.assertEquals(userRole.DeveloperName, new UserRoleSelector().selectById(userRole.Id).DeveloperName);
        }

        System.assertEquals(2, Limits.getQueries());
    }

    @IsTest
    static void testSelectUserRoleDeveloperNameById() {
        List<UserRole> userRoles = [SELECT Id,DeveloperName FROM UserRole];

        for (UserRole userRole : userRoles) {
            System.assertEquals(userRole.DeveloperName, new UserRoleSelector().selectDeveloperNameById(userRole.Id));
        }

        System.assertEquals(2, Limits.getQueries());
    }

    @IsTest
    static void testSelectMapByIds() {
        Map<Id, UserRole> expected = new Map<Id, UserRole>([SELECT Id,DeveloperName FROM UserRole]);
        Map<Id, UserRole> actual = new UserRoleSelector().selectMapByIds(expected.keySet());

        System.assertEquals(expected.keySet(), actual.keySet());
    }

    @IsTest
    static void testSelectByDeveloperNames() {
        Collection userRoles = new Collection([SELECT Id,DeveloperName FROM UserRole]);

        System.assertEquals(
                userRoles.size(),
                new UserRoleSelector().selectByDeveloperNames((Set<String>) userRoles.getUniqueValues(UserRole.DeveloperName)).size()
        );
    }
}