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
private class QueryTest {

    @IsTest
    static void coverage() {
        System.assertNotEquals(null, Query.Accounts);
        System.assertNotEquals(null, Query.Attachments);
        System.assertNotEquals(null, Query.BusinessHours);
        System.assertNotEquals(null, Query.Cases);
        System.assertNotEquals(null, Query.Contacts);
        System.assertNotEquals(null, Query.ContentDocuments);
        System.assertNotEquals(null, Query.ContentDocuments);
        System.assertNotEquals(null, Query.EmailMessages);
        System.assertNotEquals(null, Query.EmailTemplates);
        System.assertNotEquals(null, Query.Events);
        System.assertNotEquals(null, Query.Leads);
        System.assertNotEquals(null, Query.Opportunities);
        System.assertNotEquals(null, Query.OrgWideEmailAddresses);
        System.assertNotEquals(null, Query.PermissionSets);
        System.assertNotEquals(null, Query.PermissionSetAssignments);
        System.assertNotEquals(null, Query.PricebookEntries);
        System.assertNotEquals(null, Query.Pricebooks);
        System.assertNotEquals(null, Query.Products);
        System.assertNotEquals(null, Query.Profiles);
        System.assertNotEquals(null, Query.Queues);
        System.assertNotEquals(null, Query.RecordTypes);
        System.assertNotEquals(null, Query.SObjectHistory(MacroShare.SObjectType));
        System.assertNotEquals(null, Query.SObjectShares(MacroShare.SObjectType));
        System.assertNotEquals(null, Query.StaticResources);
        System.assertNotEquals(null, Query.Tasks);
        System.assertNotEquals(null, Query.UserRoles);
        System.assertNotEquals(null, Query.Users);
    }

    @IsTest
    static void testGenericQuery() {
        List<User> users = Query.fromSObject(User.SObjectType)
            .selectFields('Id, Username')
            .limits(1)
            .getList();

        System.assertEquals(1, users.size());
    }
}