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
public class SelectorTest {
    private class TestUserSelector extends Selector {
        private TestUserSelector() {
            super(new List<SObjectField>{
                    User.Id,
                    User.Name,
                    User.Email,
                    User.Username
            }, User.SObjectType);
        }
    }

    @IsTest
    static void testSelectById() {
        User user = (User) new TestUserSelector().byId(UserInfo.getUserId());

        System.assertEquals(UserInfo.getUserId(), user.Id);
        System.assertEquals(UserInfo.getName(), user.Name);
        System.assertEquals(UserInfo.getUserEmail(), user.Email);
    }

    @IsTest
    static void testSelectByField() {
        User user = (User) new TestUserSelector().oneRecordByField(User.Username, '=', UserInfo.getUserName());

        System.assertEquals(UserInfo.getUserId(), user.Id);
        System.assertEquals(UserInfo.getName(), user.Name);
        System.assertEquals(UserInfo.getUserEmail(), user.Email);
    }

    @IsTest
    static void testSelectAll() {
        assertEquals(
                ([SELECT Id FROM User]),
                new TestUserSelector().all()
        );
    }

    @IsTest
    static void testSelectByChild() {
        List<LoginHistory> loginHistories = [SELECT Id, UserId FROM LoginHistory LIMIT 100];
        List<User> users = new TestUserSelector().relatedToChildren(LoginHistory.UserId, loginHistories);

        assertEquals(
                ([SELECT Id FROM User WHERE Id IN (SELECT UserId FROM LoginHistory WHERE Id IN :loginHistories)]),
                users
        );
    }

    @IsTest
    static void testSelectByParent() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        List<User> users = new TestUserSelector().relatedToParent(User.ProfileId, profiles);

        assertEquals(
                ([SELECT Id FROM User WHERE ProfileId IN :profiles]),
                users
        );
    }

    @IsTest
    static void testSelectOne() {
        User usr = (User) new TestUserSelector().one();
        System.assertNotEquals(null, usr);
    }

    public static void assertEquals(SObject[] expected, SObject[] actual) {
        System.assertEquals(
                new Map<Id, SObject>(expected).keySet(),
                new Map<Id, SObject>(actual).keySet()
        );
    }

    @IsTest
    static void testMocking() {
        SelectorQuery.setMock(TestUserSelector.class, new QueryMock());
        List<User> result = new TestUserSelector().byField(User.Id, 'IN', new List<Id>{'005000000000000'});

        System.assertEquals(1, result.size());
        System.assertEquals('Mock Result', result[0].Username);
    }

    private class QueryMock implements SelectorQueryMock {
        public SObject[] handleQuery(
                String caller,
                String callerMethod,
                String selector,
                String selectorMethod,
                Map<String, Object> queryBoundVariables,
                SObject[] queryResult) {

            System.assertEquals(SelectorTest.class.getName(), caller);
            System.assertEquals('testMocking', callerMethod);
            System.assertEquals(TestUserSelector.class.getName(), selector);
            System.assertEquals('byField', selectorMethod);
            System.assertEquals(new List<Object>{
                    new List<Id>{Id.valueOf('005000000000000')}
            }, queryBoundVariables.values());
            System.assertEquals(new List<User>(), queryResult);


            return new List<User>{
                    new User(Username = 'Mock Result')
            };
        }
    }

    @IsTest
    static void queryBuilderCoverage() {
        new SelectorQuery()
                .selectField(Account.Id)
                .selectField('Name')
                .selectFields(new List<SObjectField>{Account.Id})
                .selectFields(new List<String>{'Id'})
                .addChildFields(new List<SObjectField>{Contact.Id}, 'Contacts')
                .fromObject(Account.SObjectType)
                .setWhere('Name != NULL')
                .setGroupBy('Name')
                .setHaving('')
                .setOrderBy('Name')
                .setOffset(0)
                .setLimit(100);
    }
}