/**
* MIT License
*
* Copyright (c) 2018 Piotr Kożuchowski
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
* Selector Layer for Queues.
* Queues are cached to save SOQL queries in subsequent calls.
* @see QueueSelectorTest.cls
* */
public inherited sharing class QueueSelector {
    private static SObjectCache cache = new SObjectCache([
            SELECT Id,Type,DeveloperName,Name
            FROM Group
            WHERE Type = 'Queue'

    ], new List<SObjectField>{
            Group.Id,
            Group.Name,
            Group.DeveloperName
    });


    /**
     * @return Group with given Id or null.
     */
    public Group byId(Id groupId) {
        return (Group) cache.retrieveFirst(Group.Id, groupId);
    }

    /**
     * @return List of Groups with given ids.
     */
    public Group[] byId(Iterable<Id> ids) {
        return cache.retrieveAll(Group.Id, (Iterable<Object>) ids);
    }


    /**
     * @return Queue for given Developer Name. If there is no such Queue, null is returned
     */
    public Group byDeveloperName(String developerName) {
        return (Group) cache.retrieveFirst(Group.DeveloperName, developerName);
    }

    /**
     * @return List of Queues for given Developer Names.
     */
    public Group[] byDeveloperName(Iterable<String> developerNames) {
        return cache.retrieveAll(Group.DeveloperName, (Iterable<Object>) developerNames);
    }


    /**
     * @return Queue for given Name (label). If there is no such Queue, null is returned
     */
    public Group byName(String name) {
        return (Group) cache.retrieveFirst(Group.Name, name);
    }

    /**
     * @return Queues with given names (label).
     */
    public Group[] byName(Iterable<String> names) {
        return cache.retrieveAll(Group.Name, (Iterable<Object>) names);
    }
}