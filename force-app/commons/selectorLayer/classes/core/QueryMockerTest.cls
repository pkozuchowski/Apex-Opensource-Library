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
    private static final String MOCK_NAME = 'AccountByName';

    public class TestAccountQuery extends Query {
        public TestAccountQuery() {
            super(new List<String>{
                'Id',
                'Name'
            }, Account.SObjectType);
        }

        public TestAccountQuery byName(String name) {
            setMockName(MOCK_NAME);
            return (TestAccountQuery) this.byField(Account.Name, '=', name);
        }
    }


    @IsTest
    static void testIsMocked() {
        QueryMocker queryMocker = QueryMocker.getInstance();

        System.assertEquals(false, queryMocker.isMocked(MOCK_NAME));
        queryMocker.setMock(MOCK_NAME, new List<Account>{
            new Account()
        });
        System.assertEquals(true, queryMocker.isMocked(MOCK_NAME));
    }


    @IsTest
    static void testMockingByMethod() {
        QueryMocker queryMocker = QueryMocker.getInstance();
        queryMocker.setMock(MOCK_NAME, new List<Account>{
            new Account(Name = 'Mock Result 1'),
            new Account(Name = 'Mock Result 2'),
            new Account(Name = 'Mock Result 3')
        });


        Test.startTest();
        List<Account> resultAfterMock = new TestAccountQuery().byName('Mock Result').getList();

        queryMocker.removeMock(MOCK_NAME);

        List<Account> resultBeforeMock = new TestAccountQuery().byName('Mock Result').getList();
        Test.stopTest();


        System.assertEquals(true, resultBeforeMock.isEmpty());
        System.assertEquals(3, resultAfterMock.size());
        System.assertEquals('Mock Result 1', resultAfterMock[0].Name);
        System.assertEquals('Mock Result 2', resultAfterMock[1].Name);
        System.assertEquals('Mock Result 3', resultAfterMock[2].Name);
    }


    @IsTest
    static void testMockingByInterface() {
        QueryMocker queryMocker = QueryMocker.getInstance();

        Test.startTest();
        queryMocker.setMock(MOCK_NAME, new AccountQueryMock());
        List<Account> resultAfterMock = new TestAccountQuery().byName('Mock Result').getList();

        queryMocker.removeMock(MOCK_NAME);
        List<Account> resultBeforeMock = new TestAccountQuery().byName('Mock Result').getList();
        Test.stopTest();


        System.assertEquals(true, resultBeforeMock.isEmpty());
        System.assertEquals(false, resultAfterMock.isEmpty());
        System.assertEquals('Mock Result 1', resultAfterMock[0].Name);
        System.assertEquals('Mock Result 2', resultAfterMock[1].Name);
        System.assertEquals('Mock Result 3', resultAfterMock[2].Name);
    }

    private class AccountQueryMock implements Query.Mock {

        public SObject[] mockQuery() {
            return new List<Account>{
                new Account(Name = 'Mock Result 1'),
                new Account(Name = 'Mock Result 2'),
                new Account(Name = 'Mock Result 3')
            };
        }
    }
}