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

/**
 * Selector layer for Contact SObjects
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
     * @param names List<String> or (Iterable<String>) Set<String>
     * @return Contacts with given names
     */
    public SObject[] byNames(Iterable<String> names) {
        return byField(Contact.Name, names);
    }

    /**
     * @return Contacts related to given account Ids
     */
    public SObject[] byAccountIds(Iterable<Id> accountIds) {
        return byField(Contact.AccountId, accountIds);
    }
}