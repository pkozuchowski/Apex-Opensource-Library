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
* @see QueueQueryTest.cls
* */
public inherited sharing class QueueQuery extends Query {

    /**
     * Caches all Queues to save SOQL limits
     */
    static {
        new QueueQuery().byField(Group.Type, '=', 'Queue').getList();
    }


    public QueueQuery() {
        super(Group.SObjectType);
        selectFields(Query.Fields.STANDARD);
    }


    /**
     * Filters Queue for given Developer Name. If there is no such Queue, null is returned
     */
    public QueueQuery byDeveloperName(String developerName) {
        return byDeveloperName(new Set<String>{developerName});
    }

    /**
     * Filters List of Queues for given Developer Names.
     */
    public QueueQuery byDeveloperName(Set<String> developerNames) {
        return (QueueQuery) byField(Group.DeveloperName, 'IN', developerNames);
    }


    /**
     * Filters Queue for given Name (label). If there is no such Queue, null is returned
     */
    public QueueQuery byName(String name) {
        return byName(new Set<String>{name});
    }

    /**
     * Filters Queues with given names (label).
     */
    public QueueQuery byName(Set<String> names) {
        return (QueueQuery) byField(Group.Name, 'IN', names);
    }


    protected override Set<String> getFieldsToCacheBy() {
        return new Set<String>{
            'Id',
            'DeveloperName'
        };
    }
}