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
 * Selector layer for Opportunity SObjects
 */
public inherited sharing class OpportunityQuery extends Query {

    public OpportunityQuery() {
        super(new List<String>{
            'Id',
            'Name',
            'AccountId',
            'CloseDate',
            'Description',
            'NextStep',
            'StageName',
            'Type'
        }, Opportunity.SObjectType);
    }


    /**
     * Opportunities will include information about parent Account field through Opportunity.AccountId field.
     */
    public OpportunityQuery withParentAccount() {
        selectAdditionalFields(new List<String>{
            'Account.Name'
        });
        return this;
    }


    /**
     * Filters Opportunities by given name
     */
    public OpportunityQuery byName(String name) {
        return byName(new Set<String>{name});
    }

    /**
     * Filters Opportunities by given names
     */
    public OpportunityQuery byName(Set<String> names) {
        return (OpportunityQuery) byField(Opportunity.Name, 'IN', names);
    }


    /**
     * Filters Opportunities related to given account Ids
     */
    public OpportunityQuery byAccountId(Id accountId) {
        return byAccountId(new Set<Id>{accountId});
    }

    /**
     * Filters Opportunities related to given account Ids
     */
    public OpportunityQuery byAccountId(Set<Id> accountIds) {
        return (OpportunityQuery) byField(Opportunity.AccountId, 'IN', accountIds);
    }


    protected override Set<String> getFieldsToCacheBy() {
        return new Set<String>{
            'Id'
        };
    }
}