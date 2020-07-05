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
public inherited sharing class ContactQuery extends QueryObject {

    public override List<SObjectField> getFields() {
        return  new List<SObjectField>{
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
                Contact.OwnerId,
                Contact.Phone,
                Contact.Salutation,
                Contact.Title
        };
    }

    public override SObjectType getSObjectType() {
        return Contact.SObjectType;
    }


    /**
     * Contacts will include information about parent Account field through Contact.AccountId field.
     */
    public ContactQuery withParentAccount() {
        this.query.addParentFields(new AccountQuery().getFields(), Contact.AccountId);
        return this;
    }


    /**
     * Filters Contacts with given names (List or Set)
     */
    public ContactQuery byName(String name) {
        return byName(new List<String>{name});
    }

    /**
     * Filters Contacts with given names (List or Set)
     */
    public ContactQuery byName(Iterable<String> names) {
        return (ContactQuery) byField(Contact.Name, 'IN', names);
    }


    /**
     * Filters Contacts with given emails (List or Set)
     */
    public ContactQuery byEmail(String email) {
        return byEmail(new List<String>{email});
    }

    /**
     * Filters Contacts with given emails (List or Set)
     */
    public ContactQuery byEmail(Iterable<String> emails) {
        return (ContactQuery) byField(Contact.Email, 'IN', emails);
    }


    /**
     * Filters Contacts related to given account Ids (List or Set)
     */
    public ContactQuery byAccountId(Id accountId) {
        return byAccountId(new List<Id>{accountId});
    }

    /**
     * Filters Contacts related to given account Ids (List or Set)
     */
    public ContactQuery byAccountId(Iterable<Id> accountIds) {
        return (ContactQuery) byField(Contact.AccountId, 'IN', accountIds);
    }


    protected override Set<SObjectField> getFieldsToCacheBy() {
        return new Set<SObjectField>{
                Contact.Id,
                Contact.Email
        };
    }
}