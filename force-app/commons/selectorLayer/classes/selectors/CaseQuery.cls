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
public inherited sharing class CaseQuery extends Query {

    public CaseQuery() {
        super(new List<String>{
            'Id',
            'AccountId',
            'CaseNumber',
            'Description',
            'Origin',
            'Priority',
            'Reason',
            'Status',
            'Subject',
            'Type'
        }, Case.SObjectType);
    }


    /**
     * Cases will include information about parent Account field through Case.AccountId field.
     */
    public CaseQuery withParentAccount() {
        selectAdditionalFields(new List<String>{
            'Account.Name'
        });
        return this;
    }


    /**
     * Filters Cases by given name
     */
    public CaseQuery bySubject(String name) {
        return bySubject(new Set<String>{name});
    }

    /**
     * Filters Cases by given names
     */
    public CaseQuery bySubject(Set<String> names) {
        return (CaseQuery) byField(Case.Subject, 'IN', names);
    }


    /**
     * Filters Cases related to given account Ids
     */
    public CaseQuery byAccountId(Id accountId) {
        return byAccountId(new Set<Id>{accountId});
    }

    /**
     * Filters Cases related to given account Ids
     */
    public CaseQuery byAccountId(Set<Id> accountIds) {
        return (CaseQuery) byField(Case.AccountId, 'IN', accountIds);
    }


    /**
     * Filters Cases related to given contact Ids
     */
    public CaseQuery byContactId(Id contactId) {
        return byContactId(new Set<Id>{contactId});
    }

    /**
     * Filters Cases related to given contact Ids
     */
    public CaseQuery byContactId(Set<Id> contactIds) {
        return (CaseQuery) byField(Case.ContactId, 'IN', contactIds);
    }
}