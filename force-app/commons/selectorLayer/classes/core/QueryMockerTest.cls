/**
* MIT License
*
* Copyright (c) 2020 Piotr Kożuchowski
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
private class QueryMockerTest {

    private class TestAccountQuery extends QueryObject {
        private TestAccountQuery() {
            super(new List<SObjectField>{
                    Account.Id,
                    Account.Name

            }, Account.SObjectType);
        }

        public Account[] byName(String name) {
            return this.byField(Account.Name, '=', name);
        }
    }

    @IsTest
    static void testMocking() {
        QueryMocker queryMocker = QueryMocker.getInstance();

        Test.startTest();
        queryMocker.setMock(Account.SObjectType, new AccountQueryMock());
        List<Account> resultAfterMock = new TestAccountQuery().byName('Mock Result');

        queryMocker.removeMock(Account.SObjectType);
        List<Account> resultBeforeMock = new TestAccountQuery().byName('Mock Result');
        Test.stopTest();


        System.assertEquals(true, resultBeforeMock.isEmpty());
        System.assertEquals(false, resultAfterMock.isEmpty());
        System.assertEquals('Mock Result', resultAfterMock[0].Name);
    }

    private class AccountQueryMock implements QueryMock {
        public SObject[] handleQuery(
                String caller,
                String callerMethod,
                String selector,
                String selectorMethod,
                Map<String, Object> queryBoundVariables,
                SObject[] queryResult) {

            System.debug('queryBoundVariables: ' + JSON.serializePretty(queryBoundVariables));
            System.assertEquals(QueryMockerTest.class.getName(), caller, 'Should return name of class where query was called');
            System.assertEquals('testMocking', callerMethod, 'Should return name of method where query was called');
            System.assertEquals(TestAccountQuery.class.getName(), selector, 'Should return name of the Query/Selector class');
            System.assertEquals('byName', selectorMethod, 'Should return name of the method on Query');
            System.assertEquals(new List<Object>{
                    'Mock Result'
            }, queryBoundVariables.values(), 'Should return list of parameters bound to the query');
            System.assertEquals(new List<Account>(), queryResult, 'Should return result of the query before mocking');


            return new List<Account>{
                    new Account(Name = 'Mock Result')
            };
        }
    }
}