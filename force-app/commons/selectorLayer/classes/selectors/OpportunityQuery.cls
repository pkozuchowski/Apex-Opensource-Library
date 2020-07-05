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
public inherited sharing class OpportunityQuery extends QueryObject {

    public override List<SObjectField> getFields() {
        return new List<SObjectField>{
                Opportunity.Id,
                Opportunity.Name,
                Opportunity.AccountId,
                Opportunity.CloseDate,
                Opportunity.Description,
                Opportunity.NextStep,
                Opportunity.StageName,
                Opportunity.Type
        };
    }

    public override SObjectType getSObjectType() {
        return Opportunity.SObjectType;
    }


    /**
     * Opportunities will include information about parent Account field through Opportunity.AccountId field.
     */
    public OpportunityQuery withParentAccount() {
        this.query.addParentFields(new AccountQuery().getFields(), Opportunity.AccountId);
        return this;
    }


    /**
     * Filters Opportunities by given name
     */
    public OpportunityQuery byName(String name) {
        return byName(new List<String>{name});
    }

    /**
     * Filters Opportunities by given names (List or Set)
     */
    public OpportunityQuery byName(Iterable<String> names) {
        return (OpportunityQuery) byField(Opportunity.Name, 'IN', names);
    }


    /**
     * Filters Opportunities related to given account Ids (List or Set)
     */
    public OpportunityQuery byAccountId(Id accountId) {
        return byAccountId(new List<Id>{accountId});
    }

    /**
     * Filters Opportunities related to given account Ids (List or Set)
     */
    public OpportunityQuery byAccountId(Iterable<Id> accountIds) {
        return (OpportunityQuery) byField(Opportunity.AccountId, 'IN', accountIds);
    }


    protected override Set<SObjectField> getFieldsToCacheBy() {
        return new Set<SObjectField>{
                Opportunity.Id
        };
    }
}