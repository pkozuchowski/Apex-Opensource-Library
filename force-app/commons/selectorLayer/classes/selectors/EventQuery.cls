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
 * Selector layer for Event SObjects
 */
public inherited sharing class EventQuery extends Query {

    public EventQuery() {
        super(new List<String>{
            'Id',
            'AccountId',
            'Description',
            'IsPrivate',
            'IsRecurrence',
            'IsReminderSet',
            'OwnerId',
            'Subject',
            'EventSubtype',
            'Type',
            'WhatId',
            'WhoId'
        }, Event.SObjectType);
    }


    /**
     * Filters Events associated with given Account
     */
    public EventQuery byAccountId(Id accountId) {
        return byAccountId(new Set<Id>{accountId});
    }

    /**
     * Filters Events associated with given Accounts
     */
    public EventQuery byAccountId(Set<Id> accountIds) {
        return (EventQuery) byField(Event.AccountId, 'IN', accountIds);
    }


    /**
     * Filters Events associated with given Account
     */
    public EventQuery byWhatId(Id whatId) {
        return byWhatId(new Set<Id>{whatId});
    }

    /**
     * Filters Events associated with given Accounts
     */
    public EventQuery byWhatId(Set<Id> whatIds) {
        return (EventQuery) byField(Event.WhatId, 'IN', whatIds);
    }


    /**
     * Filters Events associated with given Account
     */
    public EventQuery byWhoId(Id whoId) {
        return byWhoId(new Set<Id>{whoId});
    }

    /**
     * Filters Events associated with given Accounts
     */
    public EventQuery byWhoId(Set<Id> whoIds) {
        return (EventQuery) byField(Event.WhoId, 'IN', whoIds);
    }
}