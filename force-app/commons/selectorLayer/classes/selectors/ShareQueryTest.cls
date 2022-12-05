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

    @IsTest
    static void testSelectByUserOrGroup() {
        Set<Id> filterValue = new Set<Id>{UserInfo.getUserId()};
        ShareQuery query = new ShareQuery(MacroShare.SObjectType).byUserOrGroupId(filterValue);
        String soql = query.toSOQL();

        Assert.isTrue(soql.containsIgnoreCase('FROM MacroShare'));
        Assert.isTrue(soql.containsIgnoreCase('WHERE (UserOrGroupId IN :var0)'));
        Assert.areEqual(filterValue, query.getBinding(':var0'));
    }

    @IsTest
    static void testSelectByParentId() {
        Set<Id> filterValue = new Set<Id>{'0JZ000000000000'};
        ShareQuery query = new ShareQuery(MacroShare.SObjectType).byParentId(filterValue);
        String soql = query.toSOQL();

        Assert.isTrue(soql.containsIgnoreCase('FROM MacroShare'));
        Assert.isTrue(soql.containsIgnoreCase('WHERE (ParentId IN :var0)'));
        Assert.areEqual(filterValue, query.getBinding(':var0'));
    }

    @IsTest
    static void testSelectByParentIdAndUser() {
        Set<Id> parentIds = new Set<Id>{'0JZ000000000000'};
        Set<Id> userIds = new Set<Id>{UserInfo.getUserId()};


        ShareQuery query = new ShareQuery(MacroShare.SObjectType).byParentIdAndUserOrGroupId(
            parentIds, userIds
        );
        String soql = query.toSOQL();

        System.debug(soql);
        Assert.isTrue(soql.containsIgnoreCase('FROM MacroShare'));
        Assert.isTrue(soql.containsIgnoreCase('WHERE ((ParentId IN :var0) AND (UserOrGroupId IN :var1))'));
        Assert.areEqual(parentIds, query.getBinding(':var0'));
        Assert.areEqual(userIds, query.getBinding(':var1'));
    }
}