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
private class ShareQueryTest {

    @TestSetup
    static void testSetup() {
        insert new Macro(Name = 'ShareQueryTest');
    }

    @IsTest
    static void testSelectByUserOrGroup() {
        Set<Id> userIds = new Set<Id>{UserInfo.getUserId()};
        List<MacroShare> expected = [SELECT Id FROM MacroShare WHERE UserOrGroupId IN :userIds];
        List<MacroShare> actual = new ShareQuery(MacroShare.SObjectType).byUserOrGroupId(userIds).getList();

        System.assertEquals(
                new Map<Id, MacroShare>(expected).keySet(),
                new Map<Id, MacroShare>(actual).keySet()
        );
    }

    @IsTest
    static void testSelectByParentId() {
        Set<Id> parentIds = new Set<Id>{[SELECT Id FROM Macro LIMIT 1][0].Id};
        List<MacroShare> expected = [SELECT Id FROM MacroShare WHERE ParentId IN :parentIds];
        List<MacroShare> actual = new ShareQuery(MacroShare.SObjectType).byParentId(parentIds).getList();

        System.assertEquals(
                new Map<Id, MacroShare>(expected).keySet(),
                new Map<Id, MacroShare>(actual).keySet()
        );
    }

    @IsTest
    static void testSelectByParentIdAndUser() {
        Set<Id> parentIds = new Set<Id>{[SELECT Id FROM Macro LIMIT 1][0].Id};
        Set<Id> userIds = new Set<Id>{UserInfo.getUserId()};

        List<MacroShare> expected = [SELECT Id FROM MacroShare WHERE ParentId IN :parentIds AND UserOrGroupId IN :userIds];
        List<MacroShare> actual = new ShareQuery(MacroShare.SObjectType).byParentIdAndUserOrGroupId(parentIds, userIds).getList();

        System.assertEquals(
                new Map<Id, MacroShare>(expected).keySet(),
                new Map<Id, MacroShare>(actual).keySet()
        );
    }

    @IsTest
    static void coverage() {
        Set<Id> userIds = new Set<Id>{UserInfo.getUserId()};

        new ShareQuery(AssetShare.SObjectType).byUserOrGroupId(userIds);
    }
}