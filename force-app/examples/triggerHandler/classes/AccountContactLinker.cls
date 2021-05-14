public inherited sharing class AccountContactLinker implements TriggerHandler.Logic {

    /**
     * Finds Contacts with the same emails as passed accounts and links them to corresponding Account record.
     */
    public void linkContactsToAccount(List<Account> accounts) {
        Map<String, Account> accountsByEmail = (Map<String, Account>) Collection.of(accounts).mapBy(Account.Email__c);
        List<Contact> contacts = Query.Contacts.byEmail(accountsByEmail.keySet()).getList();

        for (Contact contact : contacts) {
            contact.AccountId = accountsByEmail.get(contact.Email)?.Id;
        }

        update contacts;
    }


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
     * @return List of trigger Accounts that are qualified to have Contacts linked
     */
    private List<Account> filterRecordsToProcess(List<SObject> records, TriggerContext ctx) {
        List<Account> filtered = new List<Account>();

        for (Account acc : (Account[]) records) {
            Boolean shouldProcess = (ctx.isNew() || ctx.isChanged(acc, Account.Email__c))
                    && String.isNotEmpty(acc.Email__c);

            if (shouldProcess) {
                filtered.add(acc);
            }
        }

        return filtered;
    }


}