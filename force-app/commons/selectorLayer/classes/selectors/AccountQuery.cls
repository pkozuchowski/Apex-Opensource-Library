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
 * /
 * *
 *  Please find newest source code at https://github.com/amorek/Apex-Opensource-Library
 * /
 */

/**
 * Selector layer for Account SObjects
 * Use through Query facade:
 * Query.Accounts.byName(...);
 */
public virtual inherited sharing class AccountQuery extends Query {

    public AccountQuery() {
        super(new List<String>{
            'Id',
            'Name',
            'BillingCity',
            'BillingCountry',
            'BillingPostalCode',
            'BillingState',
            'BillingStreet',
            'ShippingCity',
            'ShippingCountry',
            'ShippingPostalCode',
            'ShippingState',
            'ShippingStreet'
        }, Account.SObjectType);
    }


    /**
     * Accounts will be queried with related Contact records
     */
    public AccountQuery withContacts() {
        selectSubquery(new List<String>{
            'Id'
        }, 'Contacts');
        return this;
    }

    /**
     * Accounts will be queried with related Opportunity records
     */
    public AccountQuery withOpportunities() {
        selectSubquery(new List<String>{
            'Id'
        }, 'Opportunities');
        return this;
    }

    /**
     * Accounts will be queried with related Contact records
     */
    public AccountQuery withCases() {
        selectSubquery(new List<String>{
            'Id'
        }, 'Cases');
        return this;
    }

    /**
     * Accounts will be queried with related child Account records
     */
    public AccountQuery withChildAccounts() {
        selectSubquery(new List<String>{
            'Name'
        }, 'ChildAccounts');
        return this;
    }

    /**
     * Accounts will be queried with related Parent Account
     */
    public AccountQuery withParentAccount() {
        return (AccountQuery) this.selectFields(new List<String>{
            'Parent.Name'
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