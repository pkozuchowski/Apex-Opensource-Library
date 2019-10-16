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
* Selector Layer for Groups and Queues.
* Performs lazy query of groups by type and exposes methods to retrieve group by Developer name, label or id
* Groups are initialized by type - Only queues are retrieved in one query, if this class gets bigger, it might
* include Role groups initialization and so on.
* @see GroupSelectorTest
* */
public inherited sharing class GroupSelector {
    private static Boolean areQueuesQueried = false;
    private static SObjectCache cache = new SObjectCache();


    /**
     * @return Group with given Id or null.
     */
    public Group selectById(Id groupId) {
        queryQueues();
        return (Group) cache.retrieveFirst(Group.Id, groupId);
    }

    /**
     * @return List of Groups with given ids.
     */
    public Group[] selectByIds(Set<Id> ids) {
        queryQueues();
        return cache.retrieve(Group.Id, new List<Id>(ids));
    }


    /**
     * @return Queue for given Developer Name. If there is no such Queue, null is returned
     */
    public Group selectQueueByDeveloperName(String developerName) {
        queryQueues();
        return (Group) cache.retrieveFirst(Group.DeveloperName, developerName);
    }

    /**
     * @return List of Queues for given Developer Names.
     */
    public Group[] selectQueuesByDeveloperNames(Set<String> developerNames) {
        queryQueues();
        return cache.retrieve(Group.DeveloperName, new List<String>(developerNames));
    }


    /**
     * @return Queue for given Name (label). If there is no such Queue, null is returned
     */
    public Group selectQueueByName(String name) {
        queryQueues();
        return (Group) cache.retrieveFirst(Group.Name, name);
    }

    /**
     * @return Queues with given names (label).
     */
    public Group[] selectQueueByNames(Set<String> names) {
        queryQueues();
        return cache.retrieve(Group.Name, new List<String>(names));
    }


    private static void queryQueues() {
        if (!areQueuesQueried) {
            List<Group> queues = [SELECT Id,Type,DeveloperName,Name FROM Group WHERE Type = 'Queue'];

            cache.store(Group.Id, queues);
            cache.store(Group.DeveloperName, queues);
            cache.store(Group.Name, queues);

            areQueuesQueried = true;
        }
    }
}