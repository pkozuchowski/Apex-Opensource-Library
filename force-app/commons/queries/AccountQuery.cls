/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2021 Piotr Kożuchowski
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
*/

/**
 * Selector layer for Account SObjects
 * Use through Query facade:
 * Query.Accounts.byName(...);
 */
public virtual inherited sharing class AccountQuery extends QueryObject {

    public AccountQuery() {
        super(new List<SObjectField>{
            Account.Id,
            Account.Name,
            Account.BillingCity,
            Account.BillingCountry,
            Account.BillingPostalCode,
            Account.BillingState,
            Account.BillingStreet
        }, Account.SObjectType);
    }


    /**
     * Accounts will be queried with related Contact records
     */
    public AccountQuery withContacts() {
        withChildren(new List<SObjectField>{
            Contact.Id
        }, 'Contacts');
        return this;
    }

    /**
     * Accounts will be queried with related Opportunity records
     */
    public AccountQuery withOpportunities() {
        withChildren(new List<SObjectField>{
            Opportunity.Id
        }, 'Opportunities');
        return this;
    }

    /**
     * Accounts will be queried with related Contact records
     */
    public AccountQuery withCases() {
        withChildren(new List<SObjectField>{
            Case.Id
        }, 'Cases');
        return this;
    }

    /**
     * Accounts will be queried with related child Account records
     */
    public AccountQuery withChildAccounts() {
        withChildren(new List<SObjectField>{
            Account.Name
        }, 'ChildAccounts');
        return this;
    }

    /**
     * Accounts will be queried with related Parent Account
     */
    public AccountQuery withParentAccount() {
        return (AccountQuery) this.withLookup('Parent',
            new List<SObjectField>{
                Account.Name
            });
    }


    /**
     * Filters Accounts with given name
     */
    public AccountQuery byName(String name) {
        return byName(new Set<String>{name});
    }

    /**
     * Filters Accounts with given names
     */
    public AccountQuery byName(Set<String> names) {
        return (AccountQuery) byField(Account.Name, 'IN', names);
    }

}