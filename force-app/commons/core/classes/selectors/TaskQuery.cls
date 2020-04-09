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
public inherited sharing class TaskQuery extends QueryObject {
    public final static List<SObjectField> QUERIED_FIELDS = new List<SObjectField>{
            Task.Id,
            Task.AccountId,
            Task.CompletedDateTime,
            Task.Description,
            Task.IsClosed,
            Task.IsRecurrence,
            Task.IsReminderSet,
            Task.OwnerId,
            Task.Status,
            Task.Subject,
            Task.TaskSubtype,
            Task.Type,
            Task.WhatId,
            Task.WhoId
    };

    public TaskQuery() {
        super(QUERIED_FIELDS, Task.SObjectType);
    }


    /**
     * @return Tasks associated with given Account
     */
    public Task[] byAccountId(Id accountId) {
        return byField(Task.AccountId, '=', accountId);
    }

    /**
     * @return Tasks associated with given Accounts (List or Set)
     */
    public Task[] byAccountId(Iterable<Id> accountIds) {
        return byField(Task.AccountId, 'IN', accountIds);
    }


    /**
     * @return Tasks associated with given Account
     */
    public Task[] byWhatId(Id whatId) {
        return byField(Task.WhatId, '=', whatId);
    }

    /**
     * @return Tasks associated with given Accounts (List or Set)
     */
    public Task[] byWhatId(Iterable<Id> whatIds) {
        return byField(Task.WhatId, 'IN', whatIds);
    }


    /**
     * @return Tasks associated with given Account
     */
    public Task[] byWhoId(Id whoId) {
        return byField(Task.WhoId, '=', whoId);
    }

    /**
     * @return Tasks associated with given Accounts (List or Set)
     */
    public Task[] byWhoId(Iterable<Id> whoIds) {
        return byField(Task.WhoId, 'IN', whoIds);
    }

    protected override Set<SObjectField> getFieldsToCacheBy() {
        return new Set<SObjectField>{
                Task.Id
        };
    }

}