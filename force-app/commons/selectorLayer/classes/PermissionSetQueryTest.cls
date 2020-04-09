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
private class PermissionSetQueryTest {
    private final static PermissionSetQuery permissionSetSelector = new PermissionSetQuery();
    private final static PermissionSet[] permissionSets = [SELECT Id, Name FROM PermissionSet WHERE IsOwnedByProfile = FALSE];

    @IsTest
    static void testSelectNull() {
        System.assertEquals(null, permissionSetSelector.byName('PermissionSetQueryTest'));
        System.assertEquals(null, permissionSetSelector.idByName('PermissionSetQueryTest'));
        System.assertEquals(null, permissionSetSelector.byId('001000000000000'));
    }

    @IsTest
    static void testSelectById() {
        if (!permissionSets.isEmpty()) {
            PermissionSet permissionSet = permissionSets[0];

            System.assertEquals(
                    permissionSet.Id,
                    permissionSetSelector.byId(permissionSet.Id).Id
            );

            System.assertEquals(1, permissionSetSelector.byId(new List<Id>{permissionSet.Id}).size());
        }
    }

    @IsTest
    static void testSelectByName() {
        if (!permissionSets.isEmpty()) {
            PermissionSet permissionSet = permissionSets[0];

            System.assertEquals(
                    permissionSet.Id,
                    ((PermissionSet) permissionSetSelector.byName(permissionSet.Name)).Id
            );
        }
    }

    @IsTest
    static void testSelectIdByName() {
        if (!permissionSets.isEmpty()) {
            PermissionSet permissionSet = permissionSets[0];

            System.assertEquals(
                    permissionSet.Id,
                    permissionSetSelector.idByName(permissionSet.Name)
            );
        }
    }

    @IsTest
    static void testSelectByCurrentUser() {
        PermissionSet[] expected = [
                SELECT Id, Name
                FROM PermissionSet
                WHERE IsOwnedByProfile = FALSE AND Id IN (
                        SELECT PermissionSetId
                        FROM PermissionSetAssignment
                        WHERE AssigneeId = :UserInfo.getUserId()
                )
        ];
        PermissionSet[] actual = new PermissionSetQuery().ofCurrentUser();

        System.assertEquals(expected, actual);
    }
}