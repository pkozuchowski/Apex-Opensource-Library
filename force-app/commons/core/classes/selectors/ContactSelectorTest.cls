@IsTest
private class ContactSelectorTest {

    @TestSetup
    static void testSetup() {
        Account account = new Account(Name = 'Parent Account');
        insert account;

        insert new List<Contact>{
                new Contact(AccountId = account.Id, FirstName = 'John', LastName = 'Doe')
        };
    }

    @IsTest
    static void testSelectByNames() {
        List<Contact> contacts = new ContactSelector()
                .withParentAccount()
                .byNames(new List<String>{'John Doe'});

        System.assertEquals(1, contacts.size());
        System.assertEquals('Parent Account', contacts[0].Account.Name);
    }

    @IsTest
    static void testSelectByAccountId() {
        Account account = [SELECT Id FROM Account];

        Integer expected = [SELECT COUNT() FROM Contact WHERE AccountId = :account.Id];
        Integer actual = new ContactSelector().byAccountIds(new List<Id>{account.Id}).size();

        System.assertEquals(expected, actual);
    }
}