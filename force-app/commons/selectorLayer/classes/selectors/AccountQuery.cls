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
 * Use through Query facade:
 * Query.Accounts.byName(...);
 */
public virtual inherited sharing class AccountQuery extends QueryObject {

    public override List<SObjectField> getFields() {
        return new List<SObjectField>{
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
    }

    public override SObjectType getSObjectType() {
        return Account.SObjectType;
    }


    /**
     * Accounts will be queried with related Contact records
     */
    public AccountQuery withContacts() {
        this.query.addChildFields(new ContactQuery().getFields(), 'Contacts');
        return this;
    }

    /**
     * Accounts will be queried with related Opportunity records
     */
    public AccountQuery withOpportunities() {
        this.query.addChildFields(new OpportunityQuery().getFields(), 'Opportunities');
        return this;
    }

    /**
     * Accounts will be queried with related Contact records
     */
    public AccountQuery withCases() {
        this.query.addChildFields(new CaseQuery().getFields(), 'Cases');
        return this;
    }

    /**
     * Accounts will be queried with related child Account records
     */
    public AccountQuery withChildAccounts() {
        this.query.addChildFields(this.getFields(), 'ChildAccounts');
        return this;
    }

    /**
     * Accounts will be queried with related Parent Account
     */
    public AccountQuery withParentAccount() {
        this.query.addParentFields(getFields(), Account.ParentId);
        return this;
    }


    /**
     * Filters Accounts with given name
     */
    public AccountQuery byName(String name) {
        return byName(new List<String>{name});
    }

    /**
     * Filters Accounts with given names (List or Set)
     */
    public AccountQuery byName(Iterable<String> names) {
        return (AccountQuery) byField(Account.Name, 'IN', names);
    }


    protected override Set<SObjectField> getFieldsToCacheBy() {
        return new Set<SObjectField>{
                Account.Id
        };
    }

}