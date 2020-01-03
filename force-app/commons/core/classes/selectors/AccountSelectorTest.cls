@IsTest
public class AccountSelectorTest {

    @TestSetup
    static void testSetup() {
        Profile stdUser = Query.Profiles.byName('Standard User');

        List<User> users = new TestDataBuilder()
                .create(new User(Username = 'AccountSelectorTest@unittest.com', ProfileId = stdUser.Id))
                .create(new User(Username = 'AccountSelectorTest2@unittest.com', ProfileId = stdUser.Id))
                .insertRecords();


        System.runAs(users[0]) {
            TestDataBuilder builder = new TestDataBuilder();
            List<Account> accounts = builder
                    .create(10, new Account(Name = 'Test'))
                    .insertRecords();

            for (Account account : accounts) {
                builder.create(new Contact(AccountId = account.Id, LastName = 'Test'));
            }
            for (Account account : accounts) {
                builder.create(new Account(ParentId = account.Id, Name = 'Child'));
            }
            builder.insertRecords();


//            List<Account> accounts = new List<Account>{
//                    new Account(Name = 'Test 0'),
//                    new Account(Name = 'Test 1'),
//                    new Account(Name = 'Test 2'),
//                    new Account(Name = 'Test 3'),
//                    new Account(Name = 'Test 4')
//            };
//            insert accounts;
        }
    }

    /**
     *@description
     *
     */
    @IsTest
    static void testX() {
        User u = Query.Users.byUsername('AccountSelectorTest@unittest.com');
        System.runAs(u) {
            System.debug([SELECT ID FROM Account]);
            System.assertEquals(1, Query.Accounts.all().size());
        }


        User u2 = Query.Users.byUsername('AccountSelectorTest2@unittest.com');
        System.runAs(u2) {
            System.debug([SELECT ID FROM Account]);
            System.assertEquals(0, Query.Accounts.all().size());
//            System.assertEquals(0, QueryWithoutSharing.Accounts.all().size());
        }
    }


    @IsTest
    static void testSelectWithRelatedByNames() {
        List<String> names = new List<String>{'Test'};
        List<Account> expected = [
                SELECT Id, (SELECT Id FROM Contacts), (SELECT Id FROM ChildAccounts), Parent.Name
                FROM Account
                WHERE Name IN :names
        ];

        List<Account> actual = new AccountSelector()
                .withContacts()
                .withParentAccount()
                .withChildrenAccounts()
                .byNames(names);

        System.assertEquals(expected.size(), actual.size());
        System.assertEquals(expected[0].Contacts.size(), actual[0].Contacts.size());
        System.assertEquals(expected[0].ChildAccounts.size(), actual[0].ChildAccounts.size());
    }
}