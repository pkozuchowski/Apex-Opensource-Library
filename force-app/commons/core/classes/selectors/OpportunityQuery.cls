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
public with sharing class OpportunityQuery extends QueryObject {
    public final static List<SObjectField> QUERIED_FIELDS = new List<SObjectField>{
            Opportunity.Id,
            Opportunity.Name,
            Opportunity.AccountId,
            Opportunity.CloseDate,
            Opportunity.Description,
            Opportunity.NextStep,
            Opportunity.StageName,
            Opportunity.Type
    };

    public OpportunityQuery() {
        super(QUERIED_FIELDS, Opportunity.SObjectType);
    }

    /**
     * Opportunities will include information about parent Account field through Opportunity.AccountId field.
     */
    public OpportunityQuery withParentAccount() {
        this.query.addParentFields(AccountQuery.QUERIED_FIELDS, Opportunity.AccountId);
        return this;
    }


    /**
     * @return Opportunities by given name
     */
    public Opportunity[] byName(String name) {
        return byField(Opportunity.Name, '=', name);
    }

    /**
     * @return Opportunities by given names (List or Set)
     */
    public Opportunity[] byName(Iterable<String> names) {
        return byField(Opportunity.Name, 'IN', names);
    }


    /**
     * @return Opportunities related to given account Ids (List or Set)
     */
    public Opportunity[] byAccountId(Id accountId) {
        return byField(Opportunity.AccountId, '=', accountId);
    }

    /**
     * @return Opportunities related to given account Ids (List or Set)
     */
    public Opportunity[] byAccountId(Iterable<Id> accountIds) {
        return byField(Opportunity.AccountId, 'IN', accountIds);
    }

    protected override Set<SObjectField> getFieldsToCacheBy() {
        return new Set<SObjectField>{
                Opportunity.Id
        };
    }
}