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
@IsTest(IsParallel=true)
private class GroupSelectorTest {

    @IsTest
    static void testQueueSelector() {
        Map<Id, Group> queues = getGroups('Queue');

        Set<String> developerNames = new Set<String>();
        Set<String> names = new Set<String>();
        for (Group queue : queues.values()) {
            developerNames.add(queue.DeveloperName);
            names.add(queue.Name);

            System.assertEquals(queue.DeveloperName, new GroupSelector().selectById(queue.Id).DeveloperName);
            System.assertEquals(queue.Id, new GroupSelector().selectQueueByDeveloperName(queue.DeveloperName).Id);
            System.assertEquals(queue.Id, new GroupSelector().selectQueueByName(queue.Name).Id);
        }

        System.assertEquals(queues.size(), new GroupSelector().selectQueuesByDeveloperNames(developerNames).size());
        System.assertEquals(queues.size(), new GroupSelector().selectQueueByNames(names).size());
        System.assertEquals(queues.size(), new GroupSelector().selectByIds(queues.keySet()).size());
    }

    private static Map<Id, Group> getGroups(String type) {
        return new Map<Id, Group>([SELECT Id,Name,DeveloperName FROM Group WHERE Type = :type LIMIT 10]);
    }
}