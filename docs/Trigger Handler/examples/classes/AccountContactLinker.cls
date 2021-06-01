public inherited sharing class AccountContactLinker implements TriggerHandler.Logic {

    /**
     * Trigger interface of this class - filters Account records that are new or changed Email and should have Contacts
     * assigned.
     */
    public void execute(List<SObject> records, TriggerContext ctx) {
        List<Account> filtered = filterRecordsToProcess(records, ctx);

        if (!filtered.isEmpty()) {
            linkContactsToAccount(filtered);
        }
    }

    /**
     * Finds Contacts with the same phone as passed accounts and links them to corresponding Account record.
     */
    public void linkContactsToAccount(List<Account> accounts) {
        Map<String, Account> accountsByPhone = (Map<String, Account>) Collection.of(accounts).mapBy(Account.Phone);
        List<Contact> contacts = Query.Contacts.byPhone(accountsByPhone.keySet()).getList();
        List<Contact> toUpdate = new List<Contact>();

        for (Contact contact : contacts) {
            Id accountId = accountsByPhone.get(contact.Phone)?.Id;

            if (contact.AccountId != accountId) {
                contact.AccountId = accountId;
                toUpdate.add(contact);
            }
        }

        update toUpdate;
    }

    /**
     * @return List of trigger Accounts that are qualified to have Contacts linked
     */
    private List<Account> filterRecordsToProcess(List<SObject> records, TriggerContext ctx) {
        List<Account> filtered = new List<Account>();

        for (Account acc : (Account[]) records) {
            if (ctx.isNew() || ctx.isChanged(acc, Account.Phone)) {
                filtered.add(acc);
            }
        }

        return filtered;
    }


}