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
    static void testGetUserRoleId() {
        List<UserRole> userRoles = [SELECT Id,DeveloperName FROM UserRole];
        UserRoleSelector selector = new UserRoleSelector();

        for (UserRole userRole : userRoles) {
            System.assertEquals(userRole.Id, selector.getUserRoleIdByDeveloperName(userRole.DeveloperName));
        }

        System.assertEquals(2, Limits.getQueries());
    }

    @IsTest
    static void testGetUserRoleByDeveloperName() {
        List<UserRole> userRoles = [SELECT Id,DeveloperName FROM UserRole];
        UserRoleSelector selector = new UserRoleSelector();

        for (UserRole userRole : userRoles) {
            System.assertEquals(userRole.DeveloperName, selector.getUserRoleByDeveloperName(userRole.DeveloperName).DeveloperName);
        }

        System.assertEquals(2, Limits.getQueries());
    }

    @IsTest
    static void testGetUserRoleById() {
        List<UserRole> userRoles = [SELECT Id,DeveloperName FROM UserRole];
        UserRoleSelector selector = new UserRoleSelector();

        for (UserRole userRole : userRoles) {
            System.assertEquals(userRole.DeveloperName, selector.getUserRoleById(userRole.Id).DeveloperName);
        }

        System.assertEquals(2, Limits.getQueries());
    }

    @IsTest
    static void testGetUserRoleDeveloperNameById() {
        List<UserRole> userRoles = [SELECT Id,DeveloperName FROM UserRole];
        UserRoleSelector selector = new UserRoleSelector();

        for (UserRole userRole : userRoles) {
            System.assertEquals(userRole.DeveloperName, selector.getUserRoleDeveloperNameById(userRole.Id));
        }

        System.assertEquals(2, Limits.getQueries());
    }
}