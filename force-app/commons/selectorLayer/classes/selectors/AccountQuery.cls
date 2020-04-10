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
 * Selector layer for Account SObjects
 * User through Query facade:
 * Query.Accounts.byName(...);
 */
public virtual inherited sharing class AccountQuery extends QueryObject {
    public final static List<SObjectField> QUERIED_FIELDS = new List<SObjectField>{
            Account.Id,
            Account.Name,
            Account.BillingCity,
            Account.BillingCountry,
            Account.BillingPostalCode,
            Account.BillingState,
            Account.BillingStreet,
            Account.ShippingCity,
            Account.ShippingCountry,
            Account.ShippingPostalCode,
            Account.ShippingState,
            Account.ShippingStreet
    };

    public AccountQuery() {
        super(QUERIED_FIELDS, Account.SObjectType);
    }

    /**
     * Accounts will be queried with related Contact records
     */
    public AccountQuery withContacts() {
        this.query.addChildFields(ContactQuery.QUERIED_FIELDS, 'Contacts');
        return this;
    }

    /**
     * Accounts will be queried with related Opportunity records
     */
    public AccountQuery withOpportunities() {
        this.query.addChildFields(OpportunityQuery.QUERIED_FIELDS, 'Opportunities');
        return this;
    }

    /**
     * Accounts will be queried with related Contact records
     */
    public AccountQuery withCases() {
        this.query.addChildFields(CaseQuery.QUERIED_FIELDS, 'Cases');
        return this;
    }

    /**
     * Accounts will be queried with related child Account records
     */
    public AccountQuery withChildrenAccounts() {
        this.query.addChildFields(QUERIED_FIELDS, 'ChildAccounts');
        return this;
    }

    /**
     * Accounts will be queried with related Parent Account
     */
    public AccountQuery withParentAccount() {
        this.query.addParentFields(QUERIED_FIELDS, Account.ParentId);
        return this;
    }


    /**
     * @return Accounts with given name
     */
    public Account[] byName(String name) {
        return byField(Account.Name, '=', name);
    }

    /**
     * @return Accounts with given names (List or Set)
     */
    public Account[] byName(Iterable<String> names) {
        return byField(Account.Name, 'IN', names);
    }

    /**
    * @return Selector will not reuse cached records to limit SOQLs query limit
    */
    public AccountQuery withoutCached() {
        return (AccountQuery) withoutCache();
    }

    protected override Set<SObjectField> getFieldsToCacheBy() {
        return new Set<SObjectField>{
                Account.Id
        };
    }

}