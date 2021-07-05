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
@IsTest
private class QueueQueryTest {
    private static final String QUERY_NAME = 'Queue Query Test';
    private static final String QUERY_DEV_NAME = 'QueueQueryTest';

    @TestSetup
    static void testSetup() {
        insert new Group(
            Type = 'Queue',
            DeveloperName = QUERY_DEV_NAME,
            Name = QUERY_NAME
        );
    }

    @IsTest
    static void testQueueSelector() {
        Group queue = [SELECT Id, Name, DeveloperName FROM Group WHERE DeveloperName = :QUERY_DEV_NAME];
        Integer queryCounts = 1;

        new QueueQuery();
        queryCounts += 1;
        System.assertEquals(queryCounts, Limits.getQueries(), 'There should be 2 queries - one in test and another one caching all Queues in static block');


        System.assertEquals(queue.Id, new QueueQuery().byId(queue.Id).useCache(true).getFirstIdOrNull());
        System.assertEquals(queryCounts, Limits.getQueries(), 'Query by Id should use cache');

        System.assertEquals(queue.Id, new QueueQuery().byDeveloperName(queue.DeveloperName).useCache(true).getFirstIdOrNull());
        System.assertEquals(queryCounts, Limits.getQueries(), 'Query by DeveloperName should use cache');

        System.assertEquals(queue.Id, new QueueQuery().byName(queue.Name).useCache(true).getFirstIdOrNull());
        queryCounts += 1;
        System.assertEquals(queryCounts, Limits.getQueries(), 'Query by Name should NOT use cache, because Name is not unique');
    }
}