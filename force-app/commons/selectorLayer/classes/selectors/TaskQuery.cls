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
 * Selector layer for Task SObjects
 */
public inherited sharing class TaskQuery extends Query {

    public TaskQuery() {
        super(new List<String>{
            'Id',
            'AccountId',
            'CompletedDateTime',
            'Description',
            'IsClosed',
            'IsRecurrence',
            'IsReminderSet',
            'OwnerId',
            'Status',
            'Subject',
            'TaskSubtype',
            'Type',
            'WhatId',
            'WhoId'
        }, Task.SObjectType);
    }


    /**
     * Filters Tasks associated with given Account
     */
    public TaskQuery byAccountId(Id accountId) {
        return byAccountId(new Set<Id>{accountId});
    }

    /**
     * Filters Tasks associated with given Accounts
     */
    public TaskQuery byAccountId(Set<Id> accountIds) {
        return (TaskQuery) byField(Task.AccountId, 'IN', accountIds);
    }


    /**
     * Filters Tasks associated with given Account
     */
    public TaskQuery byWhatId(Id whatId) {
        return byWhatId(new Set<Id>{whatId});
    }

    /**
     * Filters Tasks associated with given Accounts
     */
    public TaskQuery byWhatId(Set<Id> whatIds) {
        return (TaskQuery) byField(Task.WhatId, 'IN', whatIds);
    }


    /**
     * Filters Tasks associated with given Account
     */
    public TaskQuery byWhoId(Id whoId) {
        return byWhoId(new Set<Id>{whoId});
    }

    /**
     * Filters Tasks associated with given Accounts
     */
    public TaskQuery byWhoId(Set<Id> whoIds) {
        return (TaskQuery) byField(Task.WhoId, 'IN', whoIds);
    }


    protected override Set<String> getFieldsToCacheBy() {
        return new Set<String>{
            'Id'
        };
    }

}