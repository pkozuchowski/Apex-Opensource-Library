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
 * Selector layer for Pricebook2 SObject.
 * All records are queried on the first run and cached to limit number of SOQLs issued in transaction.
 * @see PricebookSelectorTest
 */
public inherited sharing class PricebookSelector {
    private static SObjectCache cache = new SObjectCache();
    static {
        List<Pricebook2> pricebook2s = [
                SELECT Id,
                        Name,
                        IsStandard
                FROM Pricebook2
                WHERE IsActive = TRUE
        ];

        cache.store(Pricebook2.Id, pricebook2s);
        cache.store(Pricebook2.Name, pricebook2s);
        cache.store(Pricebook2.IsStandard, pricebook2s);
    }


    /**
     * @return Cached Pricebook2 record with given id or null.
     */
    public Pricebook2 selectById(Id id) {
        return (Pricebook2) cache.retrieveFirst(Pricebook2.Id, id);
    }

    /**
     * @return Cached Pricebook2 records with given ids.
     */
    public Pricebook2[] selectByIds(Set<Id> ids) {
        return cache.retrieve(Pricebook2.Id, (List<Object>) new List<Id>(ids));
    }


    /**
     * @return Cached Pricebook2 record with given name or null.
     */
    public Pricebook2 selectByName(String name) {
        return (Pricebook2) cache.retrieveFirst(Pricebook2.Name, name);
    }

    /**
     * @return Cached Pricebook2 records with given names.
     */
    public Pricebook2[] selectByNames(Set<String> names) {
        return cache.retrieve(Pricebook2.Name, (List<Object>) new List<String>(names));
    }

    /**
     * @return Id of Standard Pricebook. In Unit Test context Test.getStandardPricebookId() value is returned.
     */
    public Id selectStandardPricebookId() {
        if (Test.isRunningTest()) {
            return Test.getStandardPricebookId();
        } else {
            Pricebook2[] standardPb = cache.retrieve(Pricebook2.IsStandard, true);
            return standardPb.isEmpty() ? null : standardPb[0].Id;
        }
    }
}