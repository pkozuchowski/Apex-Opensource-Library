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
private class QueueQueryTest {

    @IsTest
    static void testQueueSelector() {
        Map<Id, Group> queues = new Map<Id, Group>([SELECT Id,Name,DeveloperName FROM Group WHERE Type = 'Queue' LIMIT 10]);

        Set<String> developerNames = new Set<String>();
        Set<String> names = new Set<String>();
        for (Group queue : queues.values()) {
            developerNames.add(queue.DeveloperName);
            names.add(queue.Name);

            System.assertEquals(queue.DeveloperName, new QueueQuery().byId(queue.Id).getFirstOrNull().get('DeveloperName'));
            System.assertEquals(queue.Id, new QueueQuery().byDeveloperName(queue.DeveloperName).getFirstOrNull().Id);
        }

        /*Dev names are cached*/
        System.assertEquals(queues.size(), new QueueQuery().byDeveloperName(developerNames).getList().size());
        System.assertEquals(queues.size(), new QueueQuery().byDeveloperName(developerNames).getList().size());

        /*+ 2 SOQL queries*/
        System.assertEquals(queues.size(), new QueueQuery().byName((Set<String>) names).getList().size());
        System.assertEquals(queues.size(), new QueueQuery().byName((Set<String>) names).getList().size());

        /*Ids are cached*/
        System.assertEquals(queues.size(), new QueueQuery().byId((Set<Id>) queues.keySet()).getList().size());
        System.assertEquals(queues.size(), new QueueQuery().byId((Set<Id>) queues.keySet()).getList().size());

        System.assertEquals(4, Limits.getQueries());
    }
}