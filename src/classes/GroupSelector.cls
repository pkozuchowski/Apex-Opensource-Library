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
* */
public inherited sharing class GroupSelector {
    private static Boolean areQueuesQueried = false;
    private static List<Group> groups = new List<Group>();
    private static Map<Id, Group> groupsByIds = new Map<Id, Group>();
    private static Map<String, Group> groupsByDevName = new Map<String, Group>();
    private static Map<String, Group> groupsByName = new Map<String, Group>();


    /**
     * Returns Queue for given Developer Name. If there is no such Queue, null is returned
     * @param developerName DeveloperName of a Group
     * @return Group record or null
     */
    public Group selectQueueByDeveloperName(String developerName) {
        queryQueues();
        return groupsByDevName.get(developerName);
    }


    /**
     * @return List of Queues for given Developer Names.
     */
    public Group[] selectQueuesByDeveloperNames(Set<String> developerNames) {
        queryQueues();
        List<Group> result = new List<Group>();

        for (String name : developerNames) {
            result.add(groupsByDevName.get(name));
        }

        return result;
    }

    /**
     * Returns Queue for given Name (label). If there is no such Queue, null is returned
     * @param name Name/Label of a Group
     * @return Group record or null
     */
    public Group selectQueueByName(String name) {
        queryQueues();
        return groupsByName.get(name);
    }

    public Group selectQueueById(Id groupId) {
        queryQueues();
        return groupsByIds.get(groupId);
    }

    public Group[] selectQueuesByIds(Set<Id> Ids) {
        queryQueues();
        List<Group> result = new List<Group>();

        for (Id id : Ids) {
            result.add(groupsByIds.get(id));
        }

        return result;
    }


    private static void queryQueues() {
        if (!areQueuesQueried) {
            for (Group queue : [SELECT Id,Type,DeveloperName,Name FROM Group WHERE Type = 'Queue']) {
                groups.add(queue);
                groupsByIds.put(queue.Id, queue);
                groupsByDevName.put(queue.DeveloperName, queue);
                groupsByName.put(queue.Name, queue);
            }
            areQueuesQueried = true;
        }
    }
}