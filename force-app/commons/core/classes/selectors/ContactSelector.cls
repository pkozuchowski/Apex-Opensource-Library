/**
 *
 */
public with sharing class ContactSelector extends Selector {
    public final static List<SObjectField> QUERIED_FIELDS = new List<SObjectField>{
            Contact.Id,
            Contact.FirstName,
            Contact.LastName,
            Contact.Name,
            Contact.Email,
            Contact.MailingAddress,
            Contact.MailingCity,
            Contact.MailingCountry,
            Contact.MailingPostalCode,
            Contact.MailingState,
            Contact.MailingStreet,
            Contact.OtherCity,
            Contact.OtherCountry,
            Contact.OtherPhone,
            Contact.OtherPostalCode,
            Contact.OtherState,
            Contact.OtherStreet,
            Contact.Phone,
            Contact.Salutation,
            Contact.Title,
            Contact.OwnerId
    };


    public ContactSelector() {
        super(QUERIED_FIELDS, Contact.SObjectType);
    }


    /**
     * Contacts will include information about parent Account field through Contact.AccountId field.
     */
    public ContactSelector withParentAccount() {
        this.query.addParentFields(AccountSelector.QUERIED_FIELDS, Contact.AccountId);
        return this;
    }


    /**
     * @param recordIds List<Id> or (Iterable<Id>) Set<Id>
     * @return Records by given Salesforce Ids
     */
    public SObject[] byNames(Iterable<String> names) {
        query.setWhere('Name IN :names');
        return Database.query(query.build());
    }
}