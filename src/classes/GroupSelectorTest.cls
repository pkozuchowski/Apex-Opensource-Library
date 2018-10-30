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
private class GroupSelectorTest {

    @IsTest
    static void testQueueSelector() {
        List<Group> queues = getGroups('Queue');

        for (Group queue : queues) {
            System.assertEquals(queue.DeveloperName, new GroupSelector().getQueueById(queue.Id).DeveloperName);
            System.assertEquals(queue.Id, new GroupSelector().getQueueByDeveloperName(queue.DeveloperName).Id);
            System.assertEquals(queue.Id, new GroupSelector().getQueueByName(queue.Name).Id);
        }
    }

    private static List<Group> getGroups(String type) {
        return [SELECT Id,Name,DeveloperName FROM Group WHERE Type = :type LIMIT 10];
    }
}