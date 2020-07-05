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
 * Selector layer for Case SObjects
 */
public inherited sharing class CaseQuery extends QueryObject {

    public override List<SObjectField> getFields() {
        return new List<SObjectField>{
                Case.Id,
                Case.AccountId,
                Case.CaseNumber,
                Case.Description,
                Case.Origin,
                Case.Priority,
                Case.Reason,
                Case.Status,
                Case.Subject,
                Case.Type
        };
    }

    public override SObjectType getSObjectType() {
        return Case.SObjectType;
    }


    /**
     * Cases will include information about parent Account field through Case.AccountId field.
     */
    public CaseQuery withParentAccount() {
        this.query.addParentFields(new AccountQuery().getFields(), Case.AccountId);
        return this;
    }


    /**
     * Filters Cases by given name
     */
    public CaseQuery bySubject(String name) {
        return bySubject(new List<String>{name});
    }

    /**
     * Filters Cases by given names (List or Set)
     */
    public CaseQuery bySubject(Iterable<String> names) {
        return (CaseQuery) byField(Case.Subject, 'IN', names);
    }


    /**
     * Filters Cases related to given account Ids (List or Set)
     */
    public CaseQuery byAccountId(Id accountId) {
        return byAccountId(new List<Id>{accountId});
    }

    /**
     * Filters Cases related to given account Ids (List or Set)
     */
    public CaseQuery byAccountId(Iterable<Id> accountIds) {
        return (CaseQuery) byField(Case.AccountId, 'IN', accountIds);
    }


    /**
     * Filters Cases related to given contact Ids (List or Set)
     */
    public CaseQuery byContactId(Id contactId) {
        return byContactId(new List<Id>{contactId});
    }

    /**
     * Filters Cases related to given contact Ids (List or Set)
     */
    public CaseQuery byContactId(Iterable<Id> contactIds) {
        return (CaseQuery) byField(Case.ContactId, 'IN', contactIds);
    }


    protected override Set<SObjectField> getFieldsToCacheBy() {
        return new Set<SObjectField>{
                Case.Id
        };
    }
}