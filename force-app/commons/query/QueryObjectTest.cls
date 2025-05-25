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

    private class TestUserQuery extends QueryObject {

        private TestUserQuery() {
            super(new List<String>{
                'Id', 'Name', 'Email', 'Username'
            }, User.SObjectType);
        }

        public TestUserQuery byUsername(String username) {
            return (TestUserQuery) byField('Username', '=', username);
        }
    }

    private class TestServiceClass {
        private List<User> users;

        public void doSomething() {
            this.users = new TestUserQuery().byUsername('Test@test.com').getList();
        }

        public void doSomething2() {
            this.users = new QueryResults([SELECT Username FROM User LIMIT 1]).getList();
        }
    }

    @IsTest
    static void testMockingQuery() {
        Query.mock(QueryObjectTest.class, 'TestServiceClass.doSomething', new List<User>{
            new User(Username = 'test')
        });

        TestServiceClass service = new TestServiceClass();
        service.doSomething();

        List<User> results = service.users;
        Assert.areEqual(1, results.size());
        Assert.areEqual('test', results.get(0).Username);
    }

    @IsTest
    static void testMockingWithList() {
        Query.mock(TestServiceClass.class, 'doSomething', new List<User>{
            new User(Username = 'test')
        });

        TestServiceClass service = new TestServiceClass();
        service.doSomething();

        List<User> results = service.users;
        Assert.areEqual(1, results.size());
        Assert.areEqual('test', results.get(0).Username);
    }

    @IsTest
    static void testMockingQueryDirectly() {
        Query.mock(TestServiceClass.class, 'doSomething2', new List<User>{
            new User(Username = 'test')
        });

        TestServiceClass service = new TestServiceClass();
        service.doSomething2();

        List<User> results = service.users;
        Assert.areEqual(1, results.size());
        Assert.areEqual('test', results.get(0).Username);
        Assert.areEqual(1, Limits.getQueries());
    }

    @IsTest
    static void testLiveQuery() {
        Set<Id> ids = new QueryResults([
            SELECT Id
            FROM User
            LIMIT 1
        ]).getIds();

        Assert.areEqual(1, ids.size());
        Assert.areEqual(1, Limits.getQueries());
    }

    @IsTest
    static void testSelectFieldsString() {
        String soql = new TestUserQuery().withFields('Parent.Name').toSOQL();
        Assert.isTrue(soql.containsIgnoreCase('SELECT Id, Name, Email, Username, Parent.Name FROM User'), soql);
    }

    @IsTest
    static void testSelectAllFields() {
        String soql = new TestUserQuery()
            .withAllFields()
            .withFields('Owner.Name')
            .toSOQL();

        Assert.isTrue(soql.containsIgnoreCase('Name'));
        Assert.isTrue(soql.containsIgnoreCase('Username'));
        Assert.isTrue(soql.containsIgnoreCase('FirstName'));
        Assert.isTrue(soql.containsIgnoreCase('Owner.Name'));
    }

    @IsTest
    static void testSelectWithChildren() {
        String soql = new TestUserQuery()
            .withChildren('Id, Preference', 'UserPreferences')
            .toSOQL();
        Assert.isTrue(soql.containsIgnoreCase('( SELECT Id, Preference FROM UserPreferences )'));
    }

    @IsTest
    static void testSelectChildrenFields() {
        String soql = new TestUserQuery()
            .withChildren(new List<SObjectField>{
                UserPreference.Id,
                UserPreference.Preference
            }, 'UserPreferences')
            .toSOQL();
        Assert.isTrue(soql.containsIgnoreCase('( SELECT Id, Preference FROM UserPreferences )'));
    }

    @IsTest
    static void testSObjectFieldConstructor() {
        String soql = new QueryObject(new List<SObjectField>{
            User.Id,
            User.Username
        }, User.SObjectType)
            .toSOQL();

        Assert.isTrue(soql.containsIgnoreCase('Id, Username'));
    }

    @IsTest
    static void testSelectWithChildrenSubquery() {
        String soql = new TestUserQuery()
            .withChildren(
                new QueryObject(UserPreference.SObjectType)
                    .withFields('Id, Preference'),
                'UserPreferences')
            .toSOQL();

        Assert.isTrue(soql.containsIgnoreCase('(SELECT Id, Preference FROM UserPreferences)'));
    }

    @IsTest
    static void testWithLimitAndOffset() {
        String soql = new TestUserQuery()
            .withLimit(10)
            .withOffset(5)
            .toSOQL();

        Assert.isNotNull(soql.containsIgnoreCase('LIMIT 10'));
        Assert.isNotNull(soql.containsIgnoreCase('OFFSET 5'));
    }

    @IsTest
    static void testGroupBy() {
        String soql = Query.fromSObject(User.SObjectType)
            .withFields('COUNT(Id) cnt, Profile.Name')
            .groupBy('Profile.Name')
            .toSOQL();

        Assert.areEqual('SELECT COUNT(Id) cnt, Profile.Name FROM User GROUP BY Profile.Name', soql);
    }

    @IsTest
    static void testGroupByHaving() {
        QueryConditions c = new QueryConditions();
        String soql = new TestUserQuery()
            .groupBy('COUNT(ID) cnt, Profile.Name', 'Profile.Name')
            .havingCondition(
                c.ANDs(
                    c.field('COUNT(ID)').greaterThan(0),
                    c.field('COUNT(ID)').lessThan(10)
                )
            )
            .toString();

        Assert.areEqual(
            '(SELECT COUNT(ID) cnt, Profile.Name FROM User ' +
            'GROUP BY Profile.Name ' +
            'HAVING ((COUNT(ID) > :var0) AND (COUNT(ID) < :var1)),' +

            ' {var0=0, var1=10})',
            soql
        );
    }

    @IsTest
    static void testHaving() {
        String soql = new TestUserQuery()
            .groupBy('COUNT(ID), ProfileId', 'ProfileId')
            .havingCondition('COUNT(ID) > 1')
            .toSOQL();

        Assert.areEqual('SELECT COUNT(ID), ProfileId' +
            ' FROM User' +
            ' GROUP BY ProfileId' +
            ' HAVING COUNT(ID) > 1', soql);
    }

    @IsTest
    static void testSelectWheres() {
        TestUserQuery query = (TestUserQuery) new TestUserQuery()
            .wheres('Id = :userIds', new Map<String, Object>{
                'userIds' => new Set<Id>{UserInfo.getUserId()}
            });

        Assert.isTrue(query.toSOQL().containsIgnoreCase('WHERE Id = :var0'));
        Assert.areEqual(new Set<Id>{UserInfo.getUserId()}, query.getBinding('var0'));
    }

    @IsTest
    static void testSelectById() {
        User user = (User) new TestUserQuery().byId(UserInfo.getUserId()).getFirstOrNull();

        Assert.areEqual(UserInfo.getUserId(), user.Id);
        Assert.areEqual(UserInfo.getName(), user.Name);
        Assert.areEqual(UserInfo.getUserEmail(), user.Email);
    }

    @IsTest
    static void testSelectByRecordTypeId() {
        String soql = new TestUserQuery().byRecordTypeId('001000000000000').toString();
        Assert.areEqual(
            '(SELECT Id, Name, Email, Username FROM User WHERE (RecordTypeId IN :var0), {var0={001000000000000AAA}})',
            soql
        );
    }

    @IsTest
    static void testSelectByRecordTypeDevName() {
        String soql = new TestUserQuery().byRecordTypeDeveloperName('DeveloperName').toString();
        Assert.areEqual(
            '(SELECT Id, Name, Email, Username FROM User WHERE (RecordType.DeveloperName IN :var0), {var0={DeveloperName}})',
            soql
        );
    }

    @IsTest
    static void testSelectByOwnerId() {
        String soql = new TestUserQuery().byOwnerId(UserInfo.getUserId()).toString();
        Assert.areEqual(
            '(SELECT Id, Name, Email, Username FROM User WHERE (OwnerId IN :var0), {var0={' + UserInfo.getUserId() + '}})',
            soql
        );
    }

    @IsTest
    static void testSelectByIdSObject() {
        User user = (User) new TestUserQuery().byId(new List<User>{
            new User(Id = UserInfo.getUserId())
        }).getFirstOrNull();

        Assert.areEqual(UserInfo.getUserId(), user.Id);
        Assert.areEqual(UserInfo.getName(), user.Name);
        Assert.areEqual(UserInfo.getUserEmail(), user.Email);
    }

    @IsTest
    static void testSelectByField() {
        User user = (User) new TestUserQuery().byField(User.Username, '=', UserInfo.getUserName()).getFirstOrNull();

        Assert.areEqual(UserInfo.getUserId(), user.Id);
        Assert.areEqual(UserInfo.getName(), user.Name);
        Assert.areEqual(UserInfo.getUserEmail(), user.Email);
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
        User usr = (User) new TestUserQuery().getFirstOrNull();
        System.assertNotEquals(null, usr, 'Should query one user');
    }

    @IsTest
    static void testOffset() {
        String query = new TestUserQuery().withOffset(50).toSOQL();
        Assert.isTrue(query.containsIgnoreCase('OFFSET 50'));
    }

    @IsTest
    static void testCountBy() {
        Integer cnt = [SELECT COUNT() FROM User];
        Integer queryCount = new TestUserQuery().getCount();
        Assert.areEqual(cnt, queryCount, 'getCount() should return Integer');
    }

    @IsTest
    static void testCountMock() {
        Query.mock(User.SObjectType, QueryObjectTest.class, 'testCountMock', 123);
        Assert.areEqual(123, new TestUserQuery().getCount());

        Query.mock(User.SObjectType, QueryObjectTest.class, 'testCountMock', new List<User>{
            new User()
        });
        Assert.areEqual(1, new TestUserQuery().getCount());
    }


    @IsTest
    static void testGetFirst() {
        Assert.isNotNull(new TestUserQuery().getFirst());
    }

    @IsTest
    static void testGetIds() {
        Query.mock('testGetIds', new List<User>{
            new User(Id = '005000000000001'),
            new User(Id = '005000000000002')
        });


        Set<Id> ids = new TestUserQuery()
            .withMockId('testGetIds')
            .getIds();

        Assert.areEqual(new Set<Id>{
            '005000000000001',
            '005000000000002'
        }, ids);
    }

    @IsTest
    static void testFilterLogic() {
        String soql = new TestUserQuery()
            .byOwnerId(UserInfo.getUserId())
            .byRecordTypeDeveloperName('test')
            .byField('LastName', '=', 'Test')
            .withFilterLogic('{0} OR ({1} AND {2})')
            .toSOQL();

        Assert.isTrue(
            soql.contains('(OwnerId IN :var0) OR ((RecordType.DeveloperName IN :var1) AND (LastName = :var2))'),
            'Incorrect clause: "' + soql + '"'
        );
    }

    @IsTest
    static void coverage() {
        QueryObject query = new TestUserQuery()
            .withFields('Name')
            .forView()
            .forUpdate()
            .forReference()
            .asUser()
            .asSystemWithSharing()
            .asSystemWithoutSharing()
            .usingCache(true)
            .byId(UserInfo.getUserId())
            .withLimit(100);

        query.getFirstOrNull();
        query.getFirstIdOrNull();
        query.getQueryLocator();
        query.getFirstFieldOrNull(User.Name);
        query.getFirstFieldOrFallback(User.Name, 'fallback value');
        query.stripInaccessible(AccessType.READABLE).getMapById();
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
            .orderBy('Name')
            .setOffset(0)
            .setLimit(100);
    }


    @IsTest
    static void conditionFactoryCoverage() {
        QueryConditions c = new QueryConditions();
        c.ANDs(null, null);
        c.ANDs(null, null, null);
        c.ANDs(null, null, null, null);
        c.ANDs(null, null, null, null, null);
        c.ANDs(new List<QueryConditions.Condition>{null});

        c.ORs(null, null);
        c.ORs(null, null, null);
        c.ORs(null, null, null, null);
        c.ORs(null, null, null, null, null);
        c.ORs(new List<QueryConditions.Condition>{null});

        c.field(Account.Name).equals('Test');
        c.field(Account.Name, '=', 'Test');
        c.blank();
        c.wheres('Name IN :names', new Map<String, Object>{'names' => new List<String>{'Test'}});
        c.NOTs(c.field(Account.Name).equals('Test'));


        QueryBindings b1 = new QueryBindings();
        String soql = c.field(Account.Id).equals('test').toSOQL(b1);
        Assert.areEqual('(Id = :var0)', soql);
        Assert.areEqual('test', b1.getMap().get('var0'));


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

        Assert.areEqual(':var0', name, 'registerBinding() should return unique variable name that can be inserted into soql string');
        Assert.areEqual(':var1', bindings.registerBinding(1), 'Each binding should get unique name');
    }

    @IsTest
    static void testBindingsReplaceReferences() {
        QueryBindings bindings = new QueryBindings();

        String soql = 'Name IN :names';
        Map<String, Object> vars = new Map<String, Object>{
            'names' => new List<String>{'Acount 1', 'Account 2'}
        };

        String newSoql = bindings.replaceReferences(soql, vars);
        Assert.areEqual('Name IN :var0', newSoql, 'Should replace all manually-typed variables with unique names');
        Assert.areEqual(bindings.getMap().get('var0'), vars.get('names'), 'Values should be registered in bindings');
    }

    @IsTest
    static void testMock() {
        List<User> mockedResult = new List<User>{
            new User(Username = 'mock@example.com')
        };
        Query.mock('getById', mockedResult);

        List<User> queryResult = new TestUserQuery()
            .withMockId('getById')
            .getList();

        Assert.areEqual(mockedResult.size(), queryResult.size());
        Assert.areEqual(mockedResult[0].Username, queryResult[0].Username);
    }

    @IsTest
    static void testMockingWithClientMethodName() {
        Query.mock(QueryObjectTest.class, 'testMockingWithClientMethodName', new List<User>{
            new User(Username = 'Test')
        });

        User[] users = new TestUserQuery().byUsername('Test').getList();
        Assert.areEqual(1, users.size());
        Assert.areEqual('Test', users.get(0).Username);
    }

    @IsTest
    static void testMockingWithRegexp() {
        Query.mock(User.SObjectType, '.*', new List<User>{
            new User(Username = 'Test')
        });

        User[] users = new TestUserQuery().byUsername('Test').getList();
        Assert.areEqual(1, users.size());
        Assert.areEqual('Test', users.get(0).Username);
    }

    @IsTest
    static void testMockingWithRegexp2() {
        Query.mock(QueryObjectTest.class, '*', new List<User>{
            new User(Username = 'Test')
        });

        User[] users = new TestUserQuery().byUsername('Test').getList();
        Assert.areEqual(1, users.size());
        Assert.areEqual('Test', users.get(0).Username);
    }

    @IsTest
    static void testGetMapByString() {
        Query.mock('test', new List<User>{
            new User(Username = '1@example.com'),
            new User(Username = '2@example.com'),
            new User(Username = '3@example.com')
        });

        Map<String, User> usersByUsername = (Map<String, User>) new TestUserQuery()
            .withMockId('test')
            .getMapByString(User.Username);

        Assert.isTrue(usersByUsername.containsKey('1@example.com'));
        Assert.isTrue(usersByUsername.containsKey('2@example.com'));
        Assert.isTrue(usersByUsername.containsKey('3@example.com'));
    }


    @IsTest
    static void testStaticCaching() {
        QueryCache.mock(User.SObjectType, new QueryCache__mdt(
            CacheFields__c = 'Username',
            Storage__c = 'Transaction'
        ));
        new TestUserQuery().byUsername(UserInfo.getUserName()).usingCache(true).getList();
        new TestUserQuery().byUsername(UserInfo.getUserName()).usingCache(true).getList();
        new TestUserQuery().byUsername(UserInfo.getUserName()).usingCache(true).getList();

        Assert.areEqual(1, Limits.getQueries(), 'Once queried users should be saved in cache.');
    }

    @IsTest
    static void testExcludeResultsCaching() {
        QueryCache.mock(User.SObjectType, new QueryCache__mdt(
            CacheFields__c = 'Username',
            Storage__c = 'Transaction'
        ));
        new TestUserQuery().byUsername(UserInfo.getUserName()).usingCache(true).cacheResults(false).getList();
        new TestUserQuery().byUsername(UserInfo.getUserName()).usingCache(true).cacheResults(false).getList();
        new TestUserQuery().byUsername(UserInfo.getUserName()).usingCache(true).cacheResults(false).getList();

        Assert.areEqual(3, Limits.getQueries(), 'Once queried users should be saved in cache.');
    }

    @IsTest
    static void testPlatformCaching() {
        QueryCache.mock(User.SObjectType,
            new QueryCache__mdt(
                CacheFields__c = 'Username',
                Storage__c = 'Organization'
            ));
        new TestUserQuery().byUsername(UserInfo.getUserName()).usingCache(true).getList();
        new TestUserQuery().byUsername(UserInfo.getUserName()).usingCache(true).getList();
        new TestUserQuery().byUsername(UserInfo.getUserName()).usingCache(true).getList();

        Assert.areEqual(1, Limits.getQueries(), 'Once queried users should be saved in cache.');
    }

    @IsTest
    static void testOrderBy() {
        String soql = new TestUserQuery().orderBy(User.CreatedDate, true, true).toSOQL();
        Assert.isTrue(soql.contains('ORDER BY CreatedDate ASC NULLS FIRST'));
    }

    @IsTest
    static void testOrderByManyFields() {
        String soql = new TestUserQuery()
            .orderBy(User.CreatedDate, true, true)
            .orderBy(User.CreatedById, false, false)
            .toSOQL();

        Assert.isTrue(soql.contains('ORDER BY CreatedDate ASC NULLS FIRST, CreatedById DESC NULLS LAST'));
    }

    @IsTest
    static void testWithAccessLevel() {
        SObject[] sObjects = new TestUserQuery()
            .asSystemWithoutSharing()
            .asSystemWithSharing()
            .withLimit(1)
            .getList();

        Assert.isNotNull(sObjects, 'Cant really test this anyhow.');
    }

    @IsTest
    static void testGenericQuery() {
        List<User> users = Query.fromSObject(User.SObjectType)
            .withFields('Id, Username')
            .withLimit(1)
            .getList();
        System.assertEquals(1, users.size());

        Query.fromSObject(Account.SObjectType).getList();
        Query.fromSObject(Account.SObjectType)
            .withChildren('Id', 'Contacts')
            .getList();
    }

    @IsTest
    static void testAssertionMethods() {
        assertSOQLContainsFieldClause(
            new QueryObject(Account.SObjectType).byField(Account.Name, '=', 'Test'),
            Account.Name,
            '=',
            'Test'
        );

        assertSOQLContainsFieldClause(
            new QueryObject(Account.SObjectType).byField(Account.Name, 'IN', new Set<String>{'Test'}),
            Account.Name,
            'IN',
            new Set<String>{'Test'}
        );
    }

    @IsTest
    static void testFieldsetException() {
        try {
            new TestUserQuery()
                .withFieldSet('TEST_USER_FIELDSET');
            Assert.fail();
        } catch (QueryException e) {
            Assert.isTrue(e.getMessage().contains('Invalid FieldSet'));
            Assert.isTrue(e.getMessage().contains('TEST_USER_FIELDSET'));
        }
    }

    @IsTest
    static void testExcludeFields() {
        String soql = new TestUserQuery()
            .withoutFields(new List<String>{
                'Username',
                'Email'
            })
            .toSOQL();

        Assert.isTrue(soql.containsIgnoreCase('SELECT Id, Name FROM User'));
        Assert.isFalse(soql.containsIgnoreCase('Username'));
        Assert.isFalse(soql.containsIgnoreCase('Email'));
    }

    @IsTest
    static void testLookupFields() {
        String soql = new TestUserQuery()
            .withLookup('Owner', new List<SObjectField>{
                User.Name
            })
            .withLookup('Owner', new Set<String>{
                'CreatedById'
            }).toSOQL();

        Assert.isTrue(soql.containsIgnoreCase('Owner.Name'));
        Assert.isTrue(soql.containsIgnoreCase('Owner.CreatedById'));
    }

    @IsTest
    static void testAggregatedResultsMocking() {
        Query.mock(User.SObjectType, QueryObjectTest.class, 'testAggregatedResultsMocking', new List<Query.AggregateResult>{
            new Query.AggregateResult(new Map<String, Object>{})
                .put('cnt', 1)
                .put('name', 'Test'),

            new Query.AggregateResult(new Map<String, Object>{
                'cnt' => 1,
                'name' => 'Test'
            })
        });

        List<Query.AggregateResult> results = Query.fromSObject(User.SObjectType)
            .withFields('COUNT(Id) cnt, Profile.Name name')
            .groupBy('Profile.Name')
            .getAggregatedResults();

        Assert.areEqual(1, results[0].get('cnt'));
        Assert.areEqual('Test', results[0].get('name'));
    }

    @IsTest
    static void testQueryOfAggregatedResultsMocking() {
        Query.mock(AggregateResult.SObjectType, 'test', new List<Query.AggregateResult>{
            new Query.AggregateResult()
                .put('cnt', 1)
                .put('name', 'Test')
        });

        List<Query.AggregateResult> results = Query.of([
            SELECT COUNT(Id), Profile.Name b
            FROM User
            GROUP BY Profile.Name
        ])
            .withMockId('test')
            .getAggregatedResults();

        results[0].put('myValue', 2);

        Assert.areEqual(1, results[0].get('cnt'));
        Assert.areEqual('Test', results[0].get('name'));
        Assert.areEqual(2, results[0].get('myValue'));
    }


    public static void assertEquals(SObject[] expected, SObject[] actual) {
        Assert.areEqual(
            new Map<Id, SObject>(expected).keySet(),
            new Map<Id, SObject>(actual).keySet()
        );
    }

    public static void assertSOQLContainsFieldInClause(QueryObject queryObject, SObjectField field, Object value) {
        assertSOQLContainsFieldClause(queryObject, field, 'IN', value);
    }

    public static void assertSOQLContainsFieldClause(QueryObject queryObject, SObjectField field, String operator, Object value) {
        String soql = queryObject.toSOQL();
        String whereClause = String.format('WHERE ({0} {1} :var0)', new List<Object>{
            field, operator
        });

        Assert.isTrue(soql.containsIgnoreCase(whereClause),
            String.format('SOQL "{0}" should contain WHERE clause: "{1}"',
                new List<Object>{soql, whereClause}
            )
        );

        assertQueryHasBinding(queryObject, 'var0', value);
    }

    public static void assertQueryHasBinding(QueryObject queryObject, String binding, Object value) {
        Object boundValue = queryObject.getBinding(binding);
        Assert.isNotNull(boundValue);
        Assert.areEqual(boundValue, value);
    }

    public static void assertSOQLContains(QueryObject queryObject, String substring) {
        String soql = queryObject.toSOQL();
        Assert.isTrue(
            soql.containsIgnoreCase(substring),
            String.format('SOQL "{0}" should contain substring "{1}"', new List<Object>{
                soql, substring
            })
        );
    }
}