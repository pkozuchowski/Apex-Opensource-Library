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
    static void coverageWithoutSharing() {
        System.assertNotEquals(null, Query.withoutSharing().Accounts);
        System.assertNotEquals(null, Query.withoutSharing().Attachments);
        System.assertNotEquals(null, Query.withoutSharing().Cases);
        System.assertNotEquals(null, Query.withoutSharing().Contacts);
        System.assertNotEquals(null, Query.withoutSharing().ContentDocuments);
        System.assertNotEquals(null, Query.withoutSharing().ContentDocuments);
        System.assertNotEquals(null, Query.withoutSharing().EmailMessages);
        System.assertNotEquals(null, Query.withoutSharing().EmailTemplates);
        System.assertNotEquals(null, Query.withoutSharing().Events);
        System.assertNotEquals(null, Query.withoutSharing().Leads);
        System.assertNotEquals(null, Query.withoutSharing().Opportunities);
        System.assertNotEquals(null, Query.withoutSharing().PricebookEntries);
        System.assertNotEquals(null, Query.withoutSharing().Pricebooks);
        System.assertNotEquals(null, Query.withoutSharing().SObjectHistory(MacroShare.SObjectType));
        System.assertNotEquals(null, Query.withoutSharing().SObjectShares(MacroShare.SObjectType));
        System.assertNotEquals(null, Query.withoutSharing().Products);
        System.assertNotEquals(null, Query.withoutSharing().StaticResources);
        System.assertNotEquals(null, Query.withoutSharing().Tasks);
        System.assertNotEquals(null, Query.withoutSharing().Users);
    }

    @IsTest
    static void testMocking() {
        SelectorQuery.setMock(AccountSelector.class, new QueryMock());
        List<Account> result = Query.Accounts.byName('Mock Result');

        System.assertEquals(1, result.size());
        System.assertEquals('Mock Result', result[0].Name);
    }

    private class QueryMock implements SelectorQueryMock {
        public SObject[] handleQuery(
                String caller,
                String callerMethod,
                String selector,
                String selectorMethod,
                Map<String, Object> queryBoundVariables,
                SObject[] queryResult) {

            System.assertEquals(QueryTest.class.getName(), caller);
            System.assertEquals('testMocking', callerMethod);
            System.assertEquals(AccountSelector.class.getName(), selector);
            System.assertEquals('byName', selectorMethod);
            System.assertEquals(new List<Object>{'Mock Result'}, queryBoundVariables.values());
            System.assertEquals(new List<Account>(), queryResult);

            return new List<Account>{
                    new Account(Name = 'Mock Result')
            };
        }
    }
}