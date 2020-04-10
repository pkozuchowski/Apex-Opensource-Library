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
public inherited sharing class EventQuery extends QueryObject {
    public final static List<SObjectField> QUERIED_FIELDS = new List<SObjectField>{
            Event.Id,
            Event.AccountId,
            Event.Description,
            Event.IsPrivate,
            Event.IsRecurrence,
            Event.IsReminderSet,
            Event.OwnerId,
            Event.Subject,
            Event.EventSubtype,
            Event.Type,
            Event.WhatId,
            Event.WhoId
    };

    public EventQuery() {
        super(QUERIED_FIELDS, Event.SObjectType);
    }


    /**
     * @return Events associated with given Account
     */
    public Event[] byAccountId(Id accountId) {
        return byField(Event.AccountId, '=', accountId);
    }

    /**
     * @return Events associated with given Accounts (List or Set)
     */
    public Event[] byAccountId(Iterable<Id> accountIds) {
        return byField(Event.AccountId, 'IN', accountIds);
    }


    /**
     * @return Events associated with given Account
     */
    public Event[] byWhatId(Id whatId) {
        return byField(Event.WhatId, '=', whatId);
    }

    /**
     * @return Events associated with given Accounts (List or Set)
     */
    public Event[] byWhatId(Iterable<Id> whatIds) {
        return byField(Event.WhatId, 'IN', whatIds);
    }


    /**
     * @return Events associated with given Account
     */
    public Event[] byWhoId(Id whoId) {
        return byField(Event.WhoId, '=', whoId);
    }

    /**
     * @return Events associated with given Accounts (List or Set)
     */
    public Event[] byWhoId(Iterable<Id> whoIds) {
        return byField(Event.WhoId, 'IN', whoIds);
    }

    protected override Set<SObjectField> getFieldsToCacheBy() {
        return new Set<SObjectField>{
                Event.Id
        };
    }
}