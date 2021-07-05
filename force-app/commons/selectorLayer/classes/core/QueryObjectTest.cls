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
public class QueryObjectTest {

    private class TestUserQuery extends Query {

        private TestUserQuery() {
            super(new List<String>{
                'Id',
                'Name',
                'Email',
                'Username'
            }, User.SObjectType);
        }

        protected override Set<String> getFieldsToCacheBy() {
            return new Set<String>{
                'Id', 'Username'
            };
        }
    }


    public static void assertEquals(SObject[] expected, SObject[] actual) {
        System.assertEquals(
            new Map<Id, SObject>(expected).keySet(),
            new Map<Id, SObject>(actual).keySet()
        );
    }


    @IsTest
    static void testSelectById() {
        User user = (User) new TestUserQuery().byId(UserInfo.getUserId()).getFirstOrNull();

        System.assertEquals(UserInfo.getUserId(), user.Id);
        System.assertEquals(UserInfo.getName(), user.Name);
        System.assertEquals(UserInfo.getUserEmail(), user.Email);
    }

    @IsTest
    static void testSelectByIdSObject() {
        User user = (User) new TestUserQuery().byId(new List<User>{
            new User(Id = UserInfo.getUserId())
        }).getFirstOrNull();

        System.assertEquals(UserInfo.getUserId(), user.Id);
        System.assertEquals(UserInfo.getName(), user.Name);
        System.assertEquals(UserInfo.getUserEmail(), user.Email);
    }

    @IsTest
    static void testSelectByField() {
        User user = (User) new TestUserQuery().byField(User.Username, '=', UserInfo.getUserName()).getFirstOrNull();

        System.assertEquals(UserInfo.getUserId(), user.Id);
        System.assertEquals(UserInfo.getName(), user.Name);
        System.assertEquals(UserInfo.getUserEmail(), user.Email);
    }

    @IsTest
    static void testSelectByChild() {
        List<LoginHistory> loginHistories = [SELECT Id, UserId FROM LoginHistory LIMIT 100];
        List<User> users = new TestUserQuery().relatedToChildren(loginHistories, LoginHistory.UserId).getList();

        assertEquals(
            ([SELECT Id FROM User WHERE Id IN (SELECT UserId FROM LoginHistory WHERE Id IN :loginHistories)]),
            users
        );
    }

    @IsTest
    static void testSelectByParent() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        List<User> users = new TestUserQuery().relatedToParent(profiles, User.ProfileId).getList();

        assertEquals(
            ([SELECT Id FROM User WHERE ProfileId IN :profiles]),
            users
        );
    }

    @IsTest
    static void testSelectOne() {
        User usr = (User) new TestUserQuery().getFirstOrEmpty();
        System.assertNotEquals(null, usr, 'Should query one user');
        System.assertEquals(1, Limits.getQueryRows(), 'Should limit query to 1');
    }


    @IsTest
    static void testCountBy() {
        Integer cnt = (Integer) [SELECT COUNT(Id) cnt FROM User].get(0).get('cnt');
        Integer queryCount = new TestUserQuery().getCount();
        System.assertEquals(cnt, queryCount, 'getCount() should return Integer');
    }

    @IsTest
    static void coverage() {
        new TestUserQuery()
            .selectFields('Name')
            .selectFields(new List<String>{'Name'})
            .selectAdditionalFields(new List<String>{'Name'})
            .selectFields(Query.Fields.STANDARD)
            .selectAllFields()
            .withSharing(Sharing.WITHOUT_SHARING)
            .useCache(true)
            .stripInaccessible(AccessType.READABLE)
            .byId(UserInfo.getUserId())
            .limits(100)
            .getFirstOrNull();

        new TestUserQuery().byId(UserInfo.getUserId()).getCount();
        new TestUserQuery().byId(UserInfo.getUserId()).getMapById();
        new TestUserQuery().byId(UserInfo.getUserId()).getFirstOrNull();
        new TestUserQuery().byId(UserInfo.getUserId()).getFirstOrEmpty();
        new TestUserQuery().byId(UserInfo.getUserId()).getFirstIdOrNull();
        new TestUserQuery().byId(UserInfo.getUserId()).getQueryLocator();
        new TestUserQuery().byId(UserInfo.getUserId()).getFirstFieldOrNull(User.Name);
        new TestUserQuery().byId(UserInfo.getUserId()).getFirstFieldOrFallback(User.Name, 'fallback value');
    }


    @IsTest
    static void queryBuilderCoverage() {
        new QueryBuilder()
            .addField(Account.Id)
            .addField('Name')
            .addFields(new List<SObjectField>{Account.Id})
            .addFields(new List<String>{'Id'})
            .addSubquery(new List<String>{'Id'}, 'Contacts')
            .fromObject(Account.SObjectType)
            .setWhere('Name != NULL')
            .setGroupBy('Name')
            .setHaving('')
            .setOrderBy('Name')
            .setOffset(0)
            .setLimit(100);
    }


    @IsTest
    static void conditionFactoryCoverage() {
        QueryConditionFactory c = new QueryConditionFactory();
        c.ANDs(null, null);
        c.ANDs(null, null, null);
        c.ANDs(null, null, null, null);
        c.ANDs(null, null, null, null, null);
        c.ANDs(new List<Query.Condition>{null});

        c.ORs(null, null);
        c.ORs(null, null, null);
        c.ORs(null, null, null, null);
        c.ORs(null, null, null, null, null);
        c.ORs(new List<Query.Condition>{null});

        c.field(Account.Name).equals('Test');
        c.field(Account.Name, '=', 'Test');
        c.blank();
        c.wheres('Name IN :names', new Map<String, Object>{'names' => new List<String>{'Test'}});
        c.NOTs(c.field(Account.Name).equals('Test'));


        QueryBindings b1 = new QueryBindings();
        String soql = c.field(Account.Id).equals('test').toSOQL(b1);
        System.assertEquals('(Id = :var0)', soql);
        System.assertEquals('test', b1.getMap().get(':var0'));


        c.field(Account.Id).notEquals('test');
        c.field(Account.Id).includes('test');
        c.field(Account.Id).excludes('test');
        c.field(Account.Id).isIn('test');
        c.field(Account.Id).greaterThan('test');
        c.field(Account.Id).greaterEqualsThan('test');
        c.field(Account.Id).lessEqualsThan('test');
        c.field(Account.Id).lessThan('test');
    }

    @IsTest
    static void bindingsCoverage() {
        QueryBindings bindings = new QueryBindings();
        List<String> queryValues = new List<String>{
            '1', '2', '3'
        };

        String name = bindings.registerBinding(queryValues);

        System.assertEquals(':var0', name, 'registerBinding() should return unique variable name that can be inserted into soql string');
        System.assertEquals(':var1', bindings.registerBinding(1), 'Each binding should get unique name');
    }

    @IsTest
    static void testBindingsReplaceReferences() {
        QueryBindings bindings = new QueryBindings();

        String soql = 'Name IN :names';
        Map<String, Object> vars = new Map<String, Object>{
            'names' => new List<String>{'Acount 1', 'Account 2'}
        };

        String newSoql = bindings.replaceReferences(soql, vars);
        System.assertEquals('Name IN :var0', newSoql, 'Should replace all manually-typed variables with unique names');
        System.assertEquals(bindings.getMap().get(':var0'), vars.get('names'), 'Values should be registered in bindings');
    }

    @IsTest
    static void testAggregateQuery() {
        QueryConditionFactory c = new QueryConditionFactory();
        String soql = Query.fromSObject(User.SObjectType)
            .selectFields('COUNT(ID), Email')
            .groupBy('Email')
            .havingCondition(
                c.ANDs(
                    c.field('COUNT(ID)').greaterThan(0),
                    c.field('COUNT(ID)').lessThan(10)
                )
            )
            .toString();

        System.assertEquals(
            '(SELECT COUNT(ID), Email FROM User  GROUP BY Email HAVING ((COUNT(ID) > :var0) AND (COUNT(ID) < :var1)), {:var0=0, :var1=10})',
            soql
        );
    }
}