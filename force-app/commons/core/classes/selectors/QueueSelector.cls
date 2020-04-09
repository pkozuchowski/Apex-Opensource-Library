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
public inherited sharing class QueueSelector extends Selector {

    public QueueSelector() {
        super(new List<SObjectField>{
                Group.Id,
                Group.Type,
                Group.DeveloperName,
                Group.Name
        }, Group.SObjectType);
    }


    /**
     * @return Queue for given Developer Name. If there is no such Queue, null is returned
     */
    public Group byDeveloperName(String developerName) {
        return (Group) firstOrNull(byDeveloperName(new List<String>{developerName}));
    }

    /**
     * @return List of Queues for given Developer Names.
     */
    public Group[] byDeveloperName(Iterable<String> developerNames) {
        return byField(Group.DeveloperName, 'IN', developerNames);
    }


    /**
     * @return Queue for given Name (label). If there is no such Queue, null is returned
     */
    public Group[] byName(String name) {
        return byName(new List<String>{name});
    }

    /**
     * @return Queues with given names (label).
     */
    public Group[] byName(Iterable<String> names) {
        return byField(Group.Name, 'IN', names);
    }

    protected override List<SObject> getRecordsToCache() {
        return byField(Group.Type, '=', 'Queue');
    }

    protected override Set<SObjectField> getFieldsToCacheBy() {
        return new Set<SObjectField>{
                Group.Id,
                Group.DeveloperName
        };
    }
}