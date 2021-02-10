@IsTest
private class TestDataSuiteTest {

    @TestSetup
    static void testSetup() {
        TestDataBuilder dataBuilder = new TestDataBuilder();

        {
            TestDataSuite suite = TestDataSuite.registerSuite('Agent with account');
            User agent = (User) dataBuilder.create(new User(
                    LastName = 'Doe'
            )).insertRecords()[0];
            suite.registerRecord('Agent', agent);

            Account account = (Account) dataBuilder.create(new Account(
                    OwnerId = agent.Id
            )).insertRecords()[0];
            suite.registerRecord('', account);
        }

        {
            TestDataSuite suite = TestDataSuite.registerSuite('Agent without account');
            User agent = (User) dataBuilder.create(new User(
                    LastName = 'Boe'
            ))
                    .insertRecords()[0];
            suite.registerRecord('Agent', agent);

            Account account = (Account) dataBuilder.create(new Account()).insertRecords()[0];
            suite.registerRecord('', account);
        }


        TestDataSuite.saveSuites();
    }


    @IsTest
    static void testSuite() {
        TestDataSuite suite = TestDataSuite.getSuite('Agent with account');

        Id userId = suite.getId(User.SObjectType, 'Agent');
        User u = [SELECT Id, LastName FROM User WHERE Id = :userId];

        System.assertEquals('Doe', u.LastName);
    }

    @IsTest
    static void testSuite2() {
        TestDataSuite suite = TestDataSuite.getSuite('Agent without account');

        Id userId = suite.getId(User.SObjectType, 'Agent');
        User u = [SELECT Id, LastName FROM User WHERE Id = :userId];

        System.assertEquals('Boe', u.LastName);
    }
}